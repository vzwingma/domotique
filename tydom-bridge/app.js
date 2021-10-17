// Required when testing against a local Tydom hardware
// to fix "self signed certificate" errors
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
//process.env.DEBUG= 'tydom-client';

const {createClient} = require('tydom-client');
const express = require('express');
const morgan = require('morgan');
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
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    app.use(morgan('combined'))

    // Info
	app.get('/_info', function (req, res) {
        console.log("------ Start request : GET /_info");

	    res.send('Le bridge Tydom [ ' + username + ' ] est opérationnel');

        console.log("------ Finished : GET /_info");
	})
    // INFO Tydom
    app.get('/info', async function(req, res) {
        console.log("------ Start request : GET /info");

        const info = await client.get('/info');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(info));
        
        console.log(JSON.stringify(info));
        console.log("------ Finished : GET /info");
    })
    // Liste des devices
    .get('/devices/data', async function(req, res) {
        console.log("------ Start request : GET /devices/data");

        const devices = await client.get('/devices/data');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
        console.log(JSON.stringify(devices));
        console.log("------ Finished : GET /devices/data");
    })
    .get('/devices/meta', async function(req, res) {
        console.log("------ Start request : GET /devices/meta");

        const devices = await client.get('/devices/meta');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
        console.log(JSON.stringify(devices));
        console.log("------ Finished : GET /devices/meta");
    })
    .get('/devices/cmeta', async function(req, res) {
        console.log("------ Start request : GET /devices/cmeta");

        const devices = await client.get('/devices/cmeta');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(devices));
        console.log(JSON.stringify(devices));
        console.log("------ Finished : GET /devices/cmeta");
    })
    .get('/configs/file', async function(req, res) {
        console.log("------ Start request : GET /configs/file");

        const configs = await client.get('/configs/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(configs));
        console.log(JSON.stringify(configs));
        console.log("------ Finished : GET /configs/file");
    })
    .get('/moments/file', async function(req, res) {
        console.log("------ Start request : GET /moments/file");

        const moments = await client.get('/moments/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(moments));
        console.log(JSON.stringify(moments));
        console.log("------ Finished : GET /moments/file");
    })
    .get('/scenarios/file', async function(req, res) {
        console.log("------ Start request : GET /scenarios/file");

        const scenarios = await client.get('/scenarios/file');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(scenarios));
        console.log(JSON.stringify(scenarios));
        console.log("------ Finished : GET /scenarios/file");
    })
    .get('/protocols', async function(req, res) {
        console.log("------ Start request : GET /protocols");

        const protocols = await client.get('/protocols');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(protocols));
        console.log(JSON.stringify(protocols));
        console.log("------ Finished : GET /protocols");
    })
    .get('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        console.log("------ Start request : GET /devices/" + req.params.devicenum + "/endpoints/" + req.params.endpointnum );

        const info = await client.get('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data');
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(info));
        console.log(JSON.stringify(info));
        console.log("------ Finished : GET /devices");
    })
    .put('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        console.log("------ Start request : PUT /devices/" + req.params.devicenum + "/endpoints/" + req.params.endpointnum );

        const command = await client.put('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data', [req.body]);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(command));
        console.log(JSON.stringify(command));
        console.log("------ Finished : PUT /devices")
    })
    .post('/refresh/all', async function(req, res) {
        console.log("------ Start request : POST /refresh/all")

        const refresh = await client.post('/refresh/all');
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(refresh));
        console.log(JSON.stringify(refresh));
        console.log("------ Finished : POST /refresh/all")
    })	
    .use(function(req, res, next){
        console.log("------ Start request : GET " + req.url)

        res.setHeader('Content-Type', 'text/plain');
        res.status(404).send('Page introuvable !');

        console.log("------ Finished : GET /" + req.url)
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