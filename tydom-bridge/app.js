// Required when testing against a local Tydom hardware
// to fix "self signed certificate" errors
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
//process.env.DEBUG 'tydom-client'; =

// *****************************
//       Connexion à Tydom
// *****************************
const {createClient} = require('tydom-client');
// Port exposé
const port = process.env.PORT || 9001;
const host = process.env.HOST || 'mediation.tydom.com'; // '192.168.1.13';
const username = process.env.MAC;
const password = process.env.PASSWD;
const resultatOK = { resultat : true }

// *****************************
//       API du bridge
// *****************************
const express = require('express');
const basicAuth = require('express-basic-auth');
const morganbody = require('morgan-body');

let webServer;

// Fonction de validation de la Basic Auth
function apiBasicAuthorizer(calledUsername, calledPassword) {
    const userMatches = basicAuth.safeCompare(calledUsername, process.env.AUTHAPI);
    const passwordMatches = basicAuth.safeCompare(calledPassword, process.env.PASSWDAPI);
    return userMatches & passwordMatches;
}
// Mise à jour des entêtes
function updateHeaders(req, res) {
	res.setHeader('Content-Type', 'text/plain');
	let corrId = req.get('X-CorrId');
	if (corrId != undefined) { 
		res.setHeader('X-CorrId', corrId); 
	} else {
		res.setHeader('X-CorrId', "undefined"); 
	}
}

(async () => {
    // Lancement de la connexion à la box Tydom
    let hostname = host;
    console.log("Connexion à la box Tydom [" + username + "] @ [" + hostname + "]");
    const client = createClient({username, password, hostname});
    // Connexion
    await client.connect();

    // Si OK, on expose l'API express
    const app = express();
    // must parse body before morganBody as body will be logged
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    // Basic Auth
    console.log("Activation de l'authentification sur les API de la passerelle")
    app.use(basicAuth( { authorizer: apiBasicAuthorizer } ))
    // hook morganBody to express app
    morganbody(app);
    
    // Info
	app.get('/_info', function (req, res) {
		updateHeaders(req, res);
        const tydomOK = { resultat : 'Le bridge Tydom [ ' + username + ' ] est opérationnel' };
        res.send(JSON.stringify(tydomOK));
	})
    // INFO Tydom
    app.get('/info', async function(req, res) {
        const info = await client.get('/info');
		updateHeaders(req, res);
        res.end(JSON.stringify(info));
    })
    // Liste des devices
    .get('/devices/data', async function(req, res) {
        const devices = await client.get('/devices/data');
		updateHeaders(req, res);
        res.end(JSON.stringify(devices));
    })
    // Etat d'un device
    .get('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        const info = await client.get('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data');
		updateHeaders(req, res);
		res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(info));
    })
    // Mise à jour d'un état d'un device
    .put('/device/:devicenum/endpoints/:endpointnum', async function(req, res) {
        await client.put('/devices/' + req.params.devicenum + '/endpoints/' + req.params.endpointnum + '/data', [req.body]);
		updateHeaders(req, res);
		res.setHeader('X-Request-DeviceId', req.params.devicenum);
        res.setHeader('X-Request-EndpointId', req.params.endpointnum);
        res.end(JSON.stringify(resultatOK));
    })
    // Refresh des valeurs du jumeau numérique par rapport aux équipements physiques
    .post('/refresh/all', async function(req, res) {
        await client.post('/refresh/all');
		updateHeaders(req, res);
        res.end(JSON.stringify(resultatOK));
    })	
    // Erreur
    .use(function(req, res, next){
		updateHeaders(req, res);
        res.status(404).send('{"message" : "Page introuvable !"}');
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