var express = require('express');
var app = express();
var extapp = express();
var exec = require('child_process').exec;


//**********************************
//  Commandes
//**********************************
function executeCommande(commande, response){
	console.log("Execution de la commande [%s]", commande)
	exec('/data/bin/'+commande, 
		function(error, stdout, stderr) {
			// command output is in stdout
		  if(stdout != null){
			console.log(stdout);
			response.setHeader('Content-Type', 'application/json');
			response.writeHead(200); // return 200 HTTP OK status
			response.end(stdout);
		  }
		  else{
			  response.writeHead(500);
			  response.end(stderr);
		  }
		});
}


//**********************************
//  Mapping HTTP
//**********************************
// Info
app.get('/_info', function (req, res) {
   res.send('Le moteur de commande GPIO est fonctionnel');
})
extapp.get('/_info', function (req, res) {
   res.send('Le moteur de commande GPIO est fonctionnel');
})

// Réception de commande
app.get('/cmd/:commande', function (request, response) {
	// Réception commande
	executeCommande(request.params.commande, response)
})


// Lancement du serveur HTTP interne
var server = app.listen(9000, function () {
   console.log("NodeJS GPIO démarré sur [%s]", server.address().port)
})
// Lancement du serveur HTTP externe
var extserver = extapp.listen(9100, function () {
   console.log("GPIO app démarré sur [%s]", extserver.address().port)
})
