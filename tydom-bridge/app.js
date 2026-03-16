// =============================================================================
// tydom-bridge/app.js — version hardened
// Baseline : tydom-client@0.13.4
// =============================================================================

// ---------------------------------------------------------------------------
// 1. TLS conditionnel
// ---------------------------------------------------------------------------
if (!process.env.NODE_TLS_REJECT_UNAUTHORIZED) {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
}

// ---------------------------------------------------------------------------
// 2. Validation des variables d'environnement requises
// ---------------------------------------------------------------------------
const REQUIRED_ENV = ['MAC', 'PASSWD', 'AUTHAPI', 'PASSWDAPI'];
const missingEnv = REQUIRED_ENV.filter(v => !process.env[v]);
if (missingEnv.length > 0) {
    console.error('[FATAL] Variables d\'environnement manquantes : ' + missingEnv.join(', '));
    process.exit(1);
}

// ---------------------------------------------------------------------------
// 3. Chargement des dépendances
// ---------------------------------------------------------------------------
const { createClient } = require('tydom-client');
const express          = require('express');
const basicAuth        = require('express-basic-auth');
const morganbody       = require('morgan-body');

// ---------------------------------------------------------------------------
// 4. Configuration
// ---------------------------------------------------------------------------
const PORT     = process.env.PORT     || 9001;
const HOST     = process.env.HOST     || 'mediation.tydom.com';
const username = process.env.MAC;
const password = process.env.PASSWD;

const RETRY_BASE_MS = 5_000;
const RETRY_MAX_MS  = 60_000;

// ---------------------------------------------------------------------------
// 5. État interne du bridge
// ---------------------------------------------------------------------------
const backendState = {
    status:    'disconnected', // 'connecting' | 'connected' | 'disconnected' | 'degraded'
    lastError: null,
    since:     new Date().toISOString()
};

function setState(status, lastError = null) {
    backendState.status    = status;
    backendState.lastError = lastError;
    backendState.since     = new Date().toISOString();
}

// ---------------------------------------------------------------------------
// 6. Client Tydom (référence mutable pour les retries)
// ---------------------------------------------------------------------------
let client = null;

// ---------------------------------------------------------------------------
// 7. connectTydom() — retry exponentiel illimité
// ---------------------------------------------------------------------------
async function connectTydom() {
    let attempt = 0;
    // eslint-disable-next-line no-constant-condition
    while (true) {
        attempt++;
        setState('connecting');
        console.log('[tydom] Tentative de connexion #' + attempt + ' à ' + HOST + ' pour [' + username + ']');
        try {
            // Fermer le client précédent s'il existe
            if (client) {
                try { client.close(); } catch (err) { console.error('[tydom] Erreur lors de la fermeture du client :', err); }
                client = null;
            }
            client = createClient({ username, password, hostname: HOST });
            await client.connect();
            setState('connected');
            console.log('[tydom] Connexion établie (tentative #' + attempt + ')');
            return; // succès → on sort de la boucle
        } catch (err) {
            const delay = Math.min(RETRY_BASE_MS * Math.pow(2, attempt - 1), RETRY_MAX_MS);
            const msg   = err?.message ?? String(err);
            setState('degraded', msg);
            console.error('[tydom] Échec tentative #' + attempt + ' : ' + msg
                + ' — nouvelle tentative dans ' + (delay / 1000) + 's');
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
}

// ---------------------------------------------------------------------------
// 8. Helpers HTTP
// ---------------------------------------------------------------------------
const RESULT_OK = { resultat: true };

/**
 * Positionne les en-têtes communs (Content-Type JSON + corrélation).
 */
function updateHeaders(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('X-CorrId', req.get('X-CorrId') || 'undefined');
}

/**
 * Enveloppe un handler async et renvoie 500 JSON en cas d'exception.
 */
function asyncRoute(fn) {
    return function (req, res, next) {
        Promise.resolve(fn(req, res, next)).catch(err => {
            console.error('[route] Erreur non gérée :', err);
            res.status(500).json({
                error:     'internal_error',
                message:   err?.message ?? 'Erreur interne',
                status:    backendState.status,
                lastError: backendState.lastError
            });
        });
    };
}

/**
 * Guard : bloque la requête si Tydom n'est pas connecté.
 * Retourne true si la requête peut continuer, false sinon.
 */
function requireConnected(res) {
    if (backendState.status !== 'connected') {
        res.status(503).json({
            error:     'tydom_not_connected',
            message:   'Le bridge Tydom n\'est pas connecté',
            status:    backendState.status,
            lastError: backendState.lastError
        });
        return false;
    }
    return true;
}

// ---------------------------------------------------------------------------
// 9. Application Express
// ---------------------------------------------------------------------------
const app = express();

// Body parsers (avant morgan-body)
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ---------------------------------------------------------------------------
// 10. Routes de santé — SANS authentification
// ---------------------------------------------------------------------------

// GET /health/live — liveness : toujours 200
app.get('/health/live', function (req, res) {
    res.status(200).json({ status: 'up' });
});

// GET /health/ready — readiness : 200 si connecté, 503 sinon
app.get('/health/ready', function (req, res) {
    if (backendState.status === 'connected') {
        res.status(200).json({ status: 'ready', backend: backendState });
    } else {
        res.status(503).json({ status: 'not_ready', backend: backendState });
    }
});

// GET /health/status — état détaillé du bridge
app.get('/health/status', function (req, res) {
    res.status(200).json({
        bridge: {
            status: backendState.status,
            uptime: process.uptime()
        },
        backend: backendState
    });
});

// ---------------------------------------------------------------------------
// 11. Authentification Basic Auth (appliquée après les routes de santé)
// ---------------------------------------------------------------------------
function apiBasicAuthorizer(calledUsername, calledPassword) {
    const userMatches     = basicAuth.safeCompare(calledUsername, process.env.AUTHAPI);
    const passwordMatches = basicAuth.safeCompare(calledPassword, process.env.PASSWDAPI);
    return userMatches && passwordMatches;
}

console.log('[bridge] Activation de l\'authentification sur les API de la passerelle');
app.use(basicAuth({ authorizer: apiBasicAuthorizer }));

// hook morganBody après basicAuth
morganbody(app);

// ---------------------------------------------------------------------------
// 12. Routes métier — toutes protégées par basicAuth + asyncRoute + requireConnected
// ---------------------------------------------------------------------------

// GET /_info — état du bridge
app.get('/_info', asyncRoute(async function (req, res) {
    updateHeaders(req, res);
    if (!requireConnected(res)) return;
    res.json({ resultat: 'Le bridge Tydom [ ' + username + ' ] est opérationnel' });
}));

// POST /reconnect — force une reconnexion manuelle
app.post('/reconnect', asyncRoute(async function (req, res) {
    updateHeaders(req, res);
    console.log('[bridge] Reconnexion manuelle demandée');
    // Lancer la reconnexion en arrière-plan (ne pas await ici)
    connectTydom().catch(err => console.error('[bridge] Erreur reconnexion :', err));
    res.status(202).json({ resultat: 'Reconnexion en cours', status: backendState.status });
}));

// GET /info — info Tydom
app.get('/info', asyncRoute(async function (req, res) {
    updateHeaders(req, res);
    if (!requireConnected(res)) return;
    const info = await client.get('/info');
    res.json(info);
}));

// GET /devices/data — liste des équipements
app.get('/devices/data', asyncRoute(async function (req, res) {
    updateHeaders(req, res);
    if (!requireConnected(res)) return;
    const devices = await client.get('/devices/data');
    res.json(devices);
}));

// GET /device/:devicenum/endpoints/:endpointnum — état d'un endpoint
app.get('/device/:devicenum/endpoints/:endpointnum', asyncRoute(async function (req, res) {
    updateHeaders(req, res);
    res.setHeader('X-Request-DeviceId',   req.params.devicenum);
    res.setHeader('X-Request-EndpointId', req.params.endpointnum);
    if (!requireConnected(res)) return;
    const info = await client.get(
        '/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data'
    );
    res.json(info);
}));

// PUT /device/:devicenum/endpoints/:endpointnum — mise à jour d'un endpoint
app.put('/device/:devicenum/endpoints/:endpointnum', asyncRoute(async function (req, res) {
    updateHeaders(req, res);
    res.setHeader('X-Request-DeviceId',   req.params.devicenum);
    res.setHeader('X-Request-EndpointId', req.params.endpointnum);
    if (!requireConnected(res)) return;
    await client.put(
        '/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data',
        [req.body]
    );
    res.json(RESULT_OK);
}));

// POST /refresh/all — refresh du jumeau numérique
app.post('/refresh/all', asyncRoute(async function (req, res) {
    updateHeaders(req, res);
    if (!requireConnected(res)) return;
    await client.post('/refresh/all');
    res.json(RESULT_OK);
}));

// 404 catch-all
app.use(function (req, res) {
    updateHeaders(req, res);
    res.status(404).json({ error: 'not_found', message: 'Route introuvable' });
});

// ---------------------------------------------------------------------------
// 13. Shutdown propre
// ---------------------------------------------------------------------------
let webServer = null;

function shutdown() {
    console.log('[bridge] Arrêt du bridge Tydom en cours...');
    setState('disconnected');

    if (webServer) {
        webServer.close(() => {
            console.log('[bridge] Serveur HTTP fermé.');
        });
    }

    if (client) {
        try { client.close(); } catch (err) { console.error('[bridge] Erreur lors de la fermeture du client :', err); }
        client = null;
    }

    // Laisser le temps au serveur HTTP de finir ses requêtes en cours
    setTimeout(() => {
        console.log('[bridge] Arrêt terminé.');
        process.exit(0);
    }, 500);
}

process.on('SIGINT',  shutdown);
process.on('SIGTERM', shutdown);

// ---------------------------------------------------------------------------
// 14. Bootstrap — HTTP démarre en premier, connectTydom en parallèle
//     N'exécuté que si le fichier est lancé directement (pas require)
// ---------------------------------------------------------------------------
if (require.main === module) {
    webServer = app.listen(PORT, function () {
        console.log('[bridge] Serveur HTTP démarré sur le port ' + PORT);
    });

    // Connexion Tydom en arrière-plan — ne bloque pas l'API HTTP
    connectTydom().catch(err => {
        console.error('[tydom] Erreur fatale lors de la connexion initiale :', err);
    });
} else {
    // Export pour les tests unitaires
    module.exports = { app, backendState, connectTydom };
}