var express = require('express');
var app = express();
var exec = require('child_process').exec;


//**********************************
//  Commandes
//**********************************
function executeCommande(commande, response){
	console.log("Execution de la commande [%s]", commande)
	exec('/data/'+commande, 
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
   res.send('NodeJS GPIO app running');
})
// Réception de commande
app.get('/cmd/:commande', function (request, response) {
	// Réception commande
	executeCommande(request.params.commande, response)
})


// Lancement du serveur HTTP
var server = app.listen(9000, function () {
   var host = server.address().address
   var port = server.address().port
   
   console.log("NodeJS GPIO app listening at [%s]", port)
})
