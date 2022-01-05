// Required when testing against a local Tydom hardware
// to fix "self signed certificate" errors
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
process.env.DEBUG= 'tydom-client';

const {createClient} = require('tydom-client');
const express = require('express');
const morganbody = require('morgan-body');

// Port exposé
const port = process.env.PORT || 9001;
// Connexion à Tydom
const host = process.env.HOST || 'mediation.tydom.com'; // '192.168.1.13';
const username = process.env.MAC;
const password = process.env.PASSWD;

let webServer;

(async () => {

    let hostname = host;
    console.log("Connexion à la box Tydom [" + username + "] @ [" + hostname + "]");
    const client = createClient({username, password, hostname});
    const socket = await client.connect();

    const resultatOK = { resultat : true }

    const app = express();
    // must parse body before morganBody as body will be logged
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    // hook morganBody to express app
    morganbody(app);
    
    // **** Info ****
	app.get('/_info', function (req, res) {
	    res.send('Le bridge Tydom [ ' + username + ' ] est opérationnel');
	})
    // INFO Tydom
    app.get('/info', async function(req, res) {
        const info = await client.get('/info');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(info));
    })
    // ********************
    // **     CONFIG     **
    // ********************
    // Configuration
    .get('/configs/file', async function(req, res) {
        const configs = await client.get('/configs/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(configs));
    })
    // Moments
    .get('/moments/file', async function(req, res) {
        const moments = await client.get('/moments/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(moments));
    })
    // Groupes
    .get('/groups/file', async function(req, res) {
        const groups = await client.get('/groups/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(groups));
    })
    // Liste des scénarios
    .get('/scenarios/file', async function(req, res) {
        const scenarios = await client.get('/scenarios/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(scenarios));
    })
    // Protocoles disponibles
    .get('/protocols', async function(req, res) {
        const protocols = await client.get('/protocols');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(protocols));
    })
    // ********************
    // **    DEVICES     **
    // ********************
    // Liste des devices
    .get('/devices/data', async function(req, res) {
        const devices = await client.get('/devices/data');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
    })
    // Liste Meta des devices
    .get('/devices/meta', async function(req, res) {
        const devices = await client.get('/devices/meta');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
    })
    // Liste CMeta des devices
    .get('/devices/cmeta', async function(req, res) {
        const devices = await client.get('/devices/cmeta');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
    })
    // ********************
    // **     DEVICE     **
    // ********************    
    // Etat d'un device
    .get('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        const info = await client.get('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data');
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(info));
    })
    // Mise à jour d'un état d'un device
    .put('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        await client.put('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data', [req.body]);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(resultatOK));
    })
    // Commande d'un état d'un device
    .put('/device/:devicenum/endpoints/:endpointnum/commande/:command', async function(req, res) {
        await client.put('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/cdata?name=' + req.params.command, []);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(resultatOK));
    })
    // ********************
    // **    GROUPES     **
    // ********************
    // Mise à jour d'un état d'un device
    .put('/group/:groupnum', async function(req, res) {
        await client.put('/groups/' + req.params.groupnum, [req.body]);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-GroupId', req.params.groupnum);
        res.end(JSON.stringify(resultatOK));
    })    
    // ********************
    // **    REFRESH     **
    // ********************    
    // Refresh des valeurs du jumeau numérique par rapport aux équipements physiques
    .post('/refresh/all', async function(req, res) {
        await client.post('/refresh/all');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(resultatOK));
    })	
    // Erreur
    .use(function(req, res, next){
        res.setHeader('Content-Type', 'text/plain');
        res.status(404).send('Page introuvable !');
    });

    webServer = app.listen(port, function () {
        
        console.log("Bridge Tydom démarré sur " + port );
    });
})();

process.on("SIGINT", async () => {
    
    if (webServer) {
        
        webServer.close(() => {
            
            console.log('Arrêt du bridge Tydom.');
        });
    }
    process.removeAllListeners("SIGINT");
});