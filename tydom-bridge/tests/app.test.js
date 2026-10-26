/**
 * Tests unitaires pour tydom-bridge/app.js
 *
 * Stratégie de mock :
 *   - tydom-client est intégralement mocké : aucune connexion réelle au boîtier Tydom.
 *   - Le module app.js est chargé une seule fois. backendState (exporté) est muté
 *     entre les tests pour simuler les états connected / disconnected.
 *   - connectTydom() est appelé une fois dans beforeAll pour initialiser la
 *     variable interne `client` du module avec l'instance mockée.
 *
 * Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
 */
'use strict';

// ---------------------------------------------------------------------------
// Mock tydom-client — doit être déclaré AVANT tout require (Jest le hisse)
// ---------------------------------------------------------------------------
jest.mock('tydom-client', () => ({
    createClient: jest.fn(() => ({
        connect: jest.fn().mockResolvedValue(undefined),
        close:   jest.fn(),
        get:     jest.fn(),
        put:     jest.fn(),
        post:    jest.fn(),
        on:      jest.fn(),
    })),
}));

const request    = require('supertest');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const tydomMod   = require('tydom-client');
const { app, backendState, connectTydom } = require('../app');

// ---------------------------------------------------------------------------
// Helpers Basic Auth
// ---------------------------------------------------------------------------
const VALID_AUTH = 'Basic ' + Buffer.from('testuser:testpass').toString('base64');
const WRONG_AUTH = 'Basic ' + Buffer.from('baduser:wrongpass').toString('base64');

// ---------------------------------------------------------------------------
// Initialisation globale
// ---------------------------------------------------------------------------

/**
 * Référence vers le mock client créé lors du premier appel à connectTydom().
 * Récupérée après le beforeAll pour pointer exactement sur l'instance utilisée
 * par la variable `client` interne au module.
 */
let mockClient;

beforeAll(async () => {
    // Initialise la variable `client` interne au module avec l'instance mockée.
    // connect() est mocké pour résoudre immédiatement → setState('connected').
    await connectTydom();
    mockClient = tydomMod.createClient.mock.results[0].value;
});

beforeEach(() => {
    // Repart toujours dans l'état déconnecté — chaque suite configure son propre état.
    backendState.status    = 'disconnected';
    backendState.lastError = null;

    // Réinitialise les historiques d'appels et les implémentations des mocks.
    if (mockClient) {
        mockClient.get.mockReset();
        mockClient.put.mockReset();
        mockClient.post.mockReset();
        mockClient.close.mockReset();
    }
});

// ===========================================================================
// A. Validation de configuration
// ===========================================================================
describe('A. Validation de configuration', () => {
    test.each(['MAC', 'PASSWD', 'AUTHAPI', 'PASSWDAPI'])(
        'process.exit(1) si la variable %s est manquante',
        variable => {
            const result = spawnSync(process.execPath, ['-e', 'require("./app")'], {
                cwd: path.resolve(__dirname, '..'),
                env: { ...process.env, [variable]: '' },
                encoding: 'utf8',
                timeout: 5_000,
            });

            expect(result.error).toBeUndefined();
            expect(result.status).toBe(1);
            expect(result.stderr).toContain(
                '[FATAL] Variables d\'environnement manquantes : ' + variable
            );
        }
    );
});

// ===========================================================================
// B. Health endpoints — sans authentification
// ===========================================================================
describe('B. Health endpoints — sans authentification', () => {
    test('GET /health/live → 200 { status: "up" } (même si backend déconnecté)', async () => {
        // backendState.status = 'disconnected' par défaut (beforeEach)
        const res = await request(app).get('/health/live');
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ status: 'up' });
    });

    test('GET /health/ready — backend non connecté → 503 not_ready', async () => {
        backendState.status = 'disconnected';
        const res = await request(app).get('/health/ready');
        expect(res.status).toBe(503);
        expect(res.body.status).toBe('not_ready');
        expect(res.body).toHaveProperty('backend');
        expect(res.body.backend.status).toBe('disconnected');
    });

    test('GET /health/ready — backend connecté → 200 ready', async () => {
        backendState.status = 'connected';
        const res = await request(app).get('/health/ready');
        expect(res.status).toBe(200);
        expect(res.body.status).toBe('ready');
        expect(res.body).toHaveProperty('backend');
        expect(res.body.backend.status).toBe('connected');
    });

    test('GET /health/status → 200 avec bridge.uptime (number) et backend', async () => {
        const res = await request(app).get('/health/status');
        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('bridge');
        expect(res.body).toHaveProperty('backend');
        expect(typeof res.body.bridge.uptime).toBe('number');
    });
});

// ===========================================================================
// C. Authentification Basic Auth
// ===========================================================================
describe('C. Authentification Basic Auth', () => {
    beforeEach(() => {
        // /_info exige requireConnected — on positionne l'état à 'connected'
        // pour que seul le mécanisme d'auth soit la variable de test.
        backendState.status = 'connected';
    });

    test('GET /_info sans Authorization → 401', async () => {
        const res = await request(app).get('/_info');
        expect(res.status).toBe(401);
    });

    test('GET /_info avec mauvais credentials → 401', async () => {
        const res = await request(app).get('/_info').set('Authorization', WRONG_AUTH);
        expect(res.status).toBe(401);
    });

    test('GET /_info avec credentials corrects → 200 JSON', async () => {
        const res = await request(app).get('/_info').set('Authorization', VALID_AUTH);
        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('resultat');
        expect(typeof res.body.resultat).toBe('string');
    });
});

// ===========================================================================
// D. Routes métier — backend déconnecté
// ===========================================================================
describe('D. Routes métier — backend déconnecté (503)', () => {
    beforeEach(() => {
        backendState.status = 'disconnected';
    });

    const cases = [
        ['GET',  '/info',                     undefined],
        ['GET',  '/devices/data',             undefined],
        ['GET',  '/device/123/endpoints/456', undefined],
        ['PUT',  '/device/123/endpoints/456', undefined],
        ['POST', '/refresh/all',              undefined],
    ];

    test.each(cases)('%s %s → 503 backend_unavailable', async (method, path) => {
        const res = await request(app)
            [method.toLowerCase()](path)
            .set('Authorization', VALID_AUTH);

        expect(res.status).toBe(503);
        expect(res.body).toHaveProperty('error');
        // La valeur exacte est 'tydom_not_connected'
        expect(res.body.error).toBe('tydom_not_connected');
    });
});

// ===========================================================================
// E. Routes métier — backend connecté (mock tydom-client)
// ===========================================================================
describe('E. Routes métier — backend connecté', () => {
    beforeEach(() => {
        backendState.status = 'connected';
    });

    test('GET /info → 200 JSON avec données mockées', async () => {
        const mockData = [{ id: 'info-mock', name: 'Tydom mock' }];
        mockClient.get.mockResolvedValue(mockData);

        const res = await request(app).get('/info').set('Authorization', VALID_AUTH);

        expect(res.status).toBe(200);
        expect(res.body).toEqual(mockData);
        expect(mockClient.get).toHaveBeenCalledWith('/info');
    });

    test('GET /devices/data → 200 JSON avec données mockées', async () => {
        const mockDevices = [{ id: 'device-1', name: 'Lampe salon' }];
        mockClient.get.mockResolvedValue(mockDevices);

        const res = await request(app).get('/devices/data').set('Authorization', VALID_AUTH);

        expect(res.status).toBe(200);
        expect(res.body).toEqual(mockDevices);
        expect(mockClient.get).toHaveBeenCalledWith('/devices/data');
    });

    test('GET /device/123/endpoints/456 → 200 JSON, headers X-Request-DeviceId et X-Request-EndpointId présents', async () => {
        const mockEndpoint = [{ name: 'onOff', value: true }];
        mockClient.get.mockResolvedValue(mockEndpoint);

        const res = await request(app)
            .get('/device/123/endpoints/456')
            .set('Authorization', VALID_AUTH);

        expect(res.status).toBe(200);
        expect(res.body).toEqual(mockEndpoint);
        expect(res.headers['x-request-deviceid']).toBe('123');
        expect(res.headers['x-request-endpointid']).toBe('456');
        expect(mockClient.get).toHaveBeenCalledWith('/devices/123/endpoints/456/data');
    });

    test('PUT /device/123/endpoints/456 → 200 { resultat: true }, headers présents', async () => {
        mockClient.put.mockResolvedValue(undefined);

        const res = await request(app)
            .put('/device/123/endpoints/456')
            .set('Authorization', VALID_AUTH)
            .set('Content-Type', 'application/json')
            .send({ name: 'onOff', value: false });

        expect(res.status).toBe(200);
        expect(res.body).toEqual({ resultat: true });
        expect(res.headers['x-request-deviceid']).toBe('123');
        expect(res.headers['x-request-endpointid']).toBe('456');
        expect(mockClient.put).toHaveBeenCalledWith(
            '/devices/123/endpoints/456/data',
            [{ name: 'onOff', value: false }]
        );
    });

    test('POST /refresh/all → 200 { resultat: true }', async () => {
        mockClient.post.mockResolvedValue(undefined);

        const res = await request(app).post('/refresh/all').set('Authorization', VALID_AUTH);

        expect(res.status).toBe(200);
        expect(res.body).toEqual({ resultat: true });
        expect(mockClient.post).toHaveBeenCalledWith('/refresh/all');
    });
});

// ===========================================================================
// F. Gestion des erreurs
// ===========================================================================
describe('F. Gestion des erreurs', () => {
    beforeEach(() => {
        backendState.status = 'connected';
    });

    test('GET /info — client.get() lance une exception → 500 internal_error', async () => {
        mockClient.get.mockRejectedValue(new Error('Connexion perdue'));

        const res = await request(app).get('/info').set('Authorization', VALID_AUTH);

        expect(res.status).toBe(500);
        expect(res.body.error).toBe('internal_error');
        expect(res.body.message).toBe('Connexion perdue');
    });

    test('GET /devices/data — client.get() lance une exception → 500 internal_error', async () => {
        mockClient.get.mockRejectedValue(new Error('Timeout Tydom'));

        const res = await request(app).get('/devices/data').set('Authorization', VALID_AUTH);

        expect(res.status).toBe(500);
        expect(res.body.error).toBe('internal_error');
        expect(res.body.message).toBe('Timeout Tydom');
    });

    test('GET /route-inexistante → 404 not_found (avec auth)', async () => {
        const res = await request(app)
            .get('/route-inexistante')
            .set('Authorization', VALID_AUTH);

        expect(res.status).toBe(404);
        expect(res.body.error).toBe('not_found');
    });

    test('GET /route-inexistante sans auth → 401 (basicAuth avant le 404 handler)', async () => {
        const res = await request(app).get('/route-inexistante');
        expect(res.status).toBe(401);
    });
});

// ===========================================================================
// G. Headers de corrélation (X-CorrId)
// ===========================================================================
describe('G. Headers de corrélation', () => {
    beforeEach(() => {
        // /_info nécessite un backend connecté
        backendState.status = 'connected';
    });

    // ===========================================================================
    // H. Reconnexion avec backoff exponentiel
    // ===========================================================================
    describe('H. Reconnexion avec backoff exponentiel', () => {
        afterEach(() => {
            jest.clearAllTimers();
            jest.useRealTimers();
        });

        test.each([
            [1, 5_000],
            [2, 15_000],
            [3, 35_000],
            [4, 75_000],
            [5, 135_000],
            [6, 195_000],
        ])('%i échec(s) avant reconnexion après %i ms', async (failures, elapsed) => {
            jest.useFakeTimers();
            const retryClient = {
                connect: jest.fn().mockResolvedValue(undefined),
                close: jest.fn(),
            };
            for (let index = 0; index < failures; index++) {
                retryClient.connect.mockRejectedValueOnce(new Error('Tydom indisponible'));
                tydomMod.createClient.mockReturnValueOnce(retryClient);
            }
            tydomMod.createClient.mockReturnValueOnce(retryClient);

            const connection = connectTydom();
            const settled = jest.fn();
            connection.then(settled);
            await jest.advanceTimersByTimeAsync(0);

            expect(backendState.status).toBe('degraded');
            expect(backendState.lastError).toBe('Tydom indisponible');
            expect(retryClient.connect).toHaveBeenCalledTimes(1);

            await jest.advanceTimersByTimeAsync(elapsed - 1);
            expect(retryClient.connect).toHaveBeenCalledTimes(failures);
            expect(settled).not.toHaveBeenCalled();

            await jest.advanceTimersByTimeAsync(1);
            await connection;
            expect(retryClient.connect).toHaveBeenCalledTimes(failures + 1);
            expect(retryClient.close).toHaveBeenCalledTimes(failures);
            expect(backendState.status).toBe('connected');
            expect(backendState.lastError).toBeNull();
            expect(settled).toHaveBeenCalledTimes(1);
            expect(jest.getTimerCount()).toBe(0);
        });
    });

    test('GET /_info avec header X-CorrId → réponse recopie la valeur', async () => {
        const res = await request(app)
            .get('/_info')
            .set('Authorization', VALID_AUTH)
            .set('X-CorrId', 'test-id-123');

        expect(res.status).toBe(200);
        // Les headers HTTP sont normalisés en minuscules par Node/supertest
        expect(res.headers['x-corrid']).toBe('test-id-123');
    });

    test('GET /_info sans X-CorrId → réponse contient X-CorrId: "undefined"', async () => {
        const res = await request(app)
            .get('/_info')
            .set('Authorization', VALID_AUTH);

        expect(res.status).toBe(200);
        expect(res.headers['x-corrid']).toBe('undefined');
    });
});
