'use strict';

// ─── Mode TLS permissif ──────────────────────────────────────────────────────
// Nécessaire pour les box Tydom locales (certificat auto-signé).
// Désactivable en production en positionnant NODE_TLS_REJECT_UNAUTHORIZED=1.
if (process.env.NODE_TLS_REJECT_UNAUTHORIZED === undefined) {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
    console.warn('[WARN] TLS verification disabled (NODE_TLS_REJECT_UNAUTHORIZED=0). Définir NODE_TLS_REJECT_UNAUTHORIZED=1 pour forcer la vérification TLS.');
}

// ─── Validation des variables d'environnement ────────────────────────────────
const REQUIRED_ENV = ['MAC', 'PASSWD', 'AUTHAPI', 'PASSWDAPI'];
const missingEnv   = REQUIRED_ENV.filter(k => !process.env[k]);
if (missingEnv.length > 0) {
    console.error('[FATAL] Variables d\'environnement manquantes : ' + missingEnv.join(', '));
    console.error('[FATAL] Le bridge ne peut pas démarrer. Définissez ces variables et relancez.');
    process.exit(1);
}

// ─── Configuration ───────────────────────────────────────────────────────────
const port     = process.env.PORT || 9001;
const hostname = process.env.HOST || 'mediation.tydom.com';
const username = process.env.MAC;
const password = process.env.PASSWD;

// ─── Dépendances ─────────────────────────────────────────────────────────────
const { createClient } = require('tydom-client');
const express          = require('express');
const basicAuth        = require('express-basic-auth');
const morganbody       = require('morgan-body');

// ─── État interne de connexion au backend Tydom ───────────────────────────────
// Valeurs : 'connecting' | 'connected' | 'disconnected' | 'degraded'
const backendState = {
    status:    'disconnected',
    lastError: null,
    since:     new Date().toISOString(),
};

function setState(status, err) {
    backendState.status    = status;
    backendState.lastError = err ? (err.message || String(err)) : null;
    backendState.since     = new Date().toISOString();
}

// ─── Client Tydom ─────────────────────────────────────────────────────────────
let client = null;

async function connectTydom() {
    setState('connecting');
    console.log(`[INFO] Connexion à la box Tydom [${username}] @ [${hostname}]`);
    try {
        client = createClient({ username, password, hostname });
        await client.connect();
        setState('connected');
        console.log('[INFO] Connexion Tydom établie.');
    } catch (err) {
        setState('degraded', err);
        console.error('[ERROR] Connexion Tydom échouée :', err.message || err);
        // Le bridge reste opérationnel en mode dégradé — le serveur HTTP est déjà démarré.
    }
}

// ─── Helpers HTTP ─────────────────────────────────────────────────────────────
function setCommonHeaders(req, res) {
    res.setHeader('Content-Type', 'application/json');
    const corrId = req.get('X-CorrId');
    res.setHeader('X-CorrId', corrId || 'undefined');
}

/** Vérifie que le client Tydom est connecté ; répond 503 si ce n'est pas le cas. */
function requireConnected(res) {
    if (!client || backendState.status !== 'connected') {
        res.status(503).json({
            error:     'backend_unavailable',
            message:   'Le client Tydom n\'est pas connecté.',
            status:    backendState.status,
            lastError: backendState.lastError,
        });
        return false;
    }
    return true;
}

/** Enveloppe un handler async et renvoie 500 en cas d'exception non gérée. */
function asyncRoute(fn) {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(err => {
            console.error('[ERROR] Route async :', err.message || err);
            if (!res.headersSent) {
                res.status(500).json({
                    error:   'internal_error',
                    message: err.message || 'Erreur interne.',
                });
            }
        });
    };
}

// ─── Authorizer Basic Auth ────────────────────────────────────────────────────
function apiBasicAuthorizer(calledUsername, calledPassword) {
    const userMatches     = basicAuth.safeCompare(calledUsername, process.env.AUTHAPI);
    const passwordMatches = basicAuth.safeCompare(calledPassword, process.env.PASSWDAPI);
    return userMatches && passwordMatches; // && logique (et non & bit-à-bit)
}

// ─── Application Express ──────────────────────────────────────────────────────
const app = express();

// Parseurs de corps (avant tout middleware)
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ─── Routes de santé — SANS authentification ─────────────────────────────────
// Enregistrées AVANT le middleware basicAuth afin d'être accessibles librement.

/** Liveness : le process Node est vivant → toujours 200 */
app.get('/health/live', (req, res) => {
    res.status(200).json({ status: 'up' });
});

/** Readiness : le bridge est prêt à proxifier → 200 si Tydom connecté, 503 sinon */
app.get('/health/ready', (req, res) => {
    if (backendState.status === 'connected') {
        res.status(200).json({ status: 'ready', backend: backendState });
    } else {
        res.status(503).json({ status: 'not_ready', backend: backendState });
    }
});

/** Statut détaillé du bridge et du backend */
app.get('/health/status', (req, res) => {
    res.status(200).json({
        bridge:  { status: 'up', uptime: process.uptime() },
        backend: backendState,
    });
});

// ─── Activation de la Basic Auth pour toutes les routes suivantes ─────────────
console.log('[INFO] Activation de l\'authentification sur les API de la passerelle.');
app.use(basicAuth({ authorizer: apiBasicAuthorizer }));

// Journalisation des requêtes/réponses (après auth pour éviter les logs de tentatives non authentifiées)
morganbody(app, {
    noColors:         true,
    logReqHeaderList: false,
    logResHeaderList: false,
});

// ─── Routes métier ────────────────────────────────────────────────────────────

/** Statut interne du bridge (authentifié) */
app.get('/_info', (req, res) => {
    setCommonHeaders(req, res);
    res.json({
        resultat: `Le bridge Tydom [${username}] est opérationnel`,
        backend:  backendState,
    });
});

/** Info Tydom */
app.get('/info', asyncRoute(async (req, res) => {
    setCommonHeaders(req, res);
    if (!requireConnected(res)) return;
    const info = await client.get('/info');
    res.json(info);
}));

/** Liste des devices */
app.get('/devices/data', asyncRoute(async (req, res) => {
    setCommonHeaders(req, res);
    if (!requireConnected(res)) return;
    const devices = await client.get('/devices/data');
    res.json(devices);
}));

/** État d'un endpoint d'un device */
app.get('/device/:devicenum/endpoints/:endpointnum', asyncRoute(async (req, res) => {
    setCommonHeaders(req, res);
    res.setHeader('X-Request-DeviceId',   req.params.devicenum);
    res.setHeader('X-Request-EndpointId', req.params.endpointnum);
    if (!requireConnected(res)) return;
    const info = await client.get(`/devices/${req.params.devicenum}/endpoints/${req.params.endpointnum}/data`);
    res.json(info);
}));

/** Mise à jour d'un endpoint d'un device */
app.put('/device/:devicenum/endpoints/:endpointnum', asyncRoute(async (req, res) => {
    setCommonHeaders(req, res);
    res.setHeader('X-Request-DeviceId',   req.params.devicenum);
    res.setHeader('X-Request-EndpointId', req.params.endpointnum);
    if (!requireConnected(res)) return;
    await client.put(`/devices/${req.params.devicenum}/endpoints/${req.params.endpointnum}/data`, [req.body]);
    res.json({ resultat: true });
}));

/** Refresh du jumeau numérique */
app.post('/refresh/all', asyncRoute(async (req, res) => {
    setCommonHeaders(req, res);
    if (!requireConnected(res)) return;
    await client.post('/refresh/all');
    res.json({ resultat: true });
}));

/** 404 catch-all */
app.use((req, res) => {
    setCommonHeaders(req, res);
    res.status(404).json({ error: 'not_found', message: 'Route introuvable.' });
});

// ─── Arrêt propre ─────────────────────────────────────────────────────────────
let webServer = null;

async function shutdown(signal) {
    console.log(`[INFO] Signal ${signal} reçu — arrêt en cours…`);
    if (webServer) {
        await new Promise(resolve => webServer.close(resolve));
        console.log('[INFO] Serveur HTTP fermé.');
    }
    if (client && typeof client.disconnect === 'function') {
        try {
            await client.disconnect();
            console.log('[INFO] Client Tydom déconnecté.');
        } catch (err) {
            console.warn('[WARN] Erreur à la déconnexion Tydom :', err.message || err);
        }
    }
    setState('disconnected');
    process.exit(0);
}

process.on('SIGINT',  () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

// ─── Bootstrap ────────────────────────────────────────────────────────────────
(async () => {
    // Démarrage du serveur HTTP — indépendant de la connexion Tydom
    webServer = app.listen(port, () => {
        console.log(`[INFO] Bridge Tydom démarré sur le port ${port}`);
    });

    // Connexion Tydom en parallèle (non bloquante pour le démarrage HTTP)
    connectTydom().catch(err => {
        console.error('[ERROR] Erreur inattendue dans connectTydom :', err.message || err);
    });
})();