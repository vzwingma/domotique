// Required when testing against a local Tydom hardware
// to fix "self signed certificate" errors
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
//process.env.DEBUG= 'tydom-client';

const {createClient} = require('tydom-client');
const express = require('express');
const bodyParser = require('body-parser');

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

    const app = express();
    
    app.use(bodyParser.json());
    app.use(bodyParser.urlencoded({ extended: true }));

    // Info
	app.get('/_info', function (req, res) {
        res.setHeader('Content-Type', 'application/json');
	    res.send('Le bridge Tydom [ ' + username + ' ] est opérationnel');
	})
    app.get('/info', async function(req, res) {

        const info = await client.get('/info');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(info));
    })
    .get('/devices/data', async function(req, res) {

        const devices = await client.get('/devices/data');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
    })
    .get('/devices/meta', async function(req, res) {

        const devices = await client.get('/devices/meta');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
    })
    .get('/devices/cmeta', async function(req, res) {

        const devices = await client.get('/devices/cmeta');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
    })
    .get('/configs/file', async function(req, res) {

        const configs = await client.get('/configs/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(configs));
    })
    .get('/moments/file', async function(req, res) {

        const moments = await client.get('/moments/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(moments));
    })
    .get('/scenarios/file', async function(req, res) {

        const scenarios = await client.get('/scenarios/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(scenarios));
    })
    .get('/protocols', async function(req, res) {

        const protocols = await client.get('/protocols');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(protocols));
    })
    .get('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        const info = await client.get('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data');
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(info));
    })
    .put('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        const command = await client.put('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data', [req.body]);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(command));
    })
    .post('/refresh/all', async function(req, res) {
        const refresh = await client.post('/refresh/all');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(refresh));
    })	
    .use(function(req, res, next){
        res.setHeader('Content-Type', 'application/json');
        const labelError = '{ "error": 1, "label_error": "Service introuvable" }'
        res.status(404).send(labelError);
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