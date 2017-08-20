var express = require('express');
var app = express();

// Info
app.get('/_info', function (req, res) {
   res.send('NodeJS GPIO app running');
})

// Réception de commande
app.get('/cmd/receptionDHT11', function (req, res) {
	res.send('NodeJS GPIO app listening');
	// var exec = require('child_process').exec;
	//exec('receptionDHT11')
})


// Lancement du serveur HTTP
var server = app.listen(9000, function () {
   var host = server.address().address
   var port = server.address().port
   
   console.log("NodeJS GPIO app listening at [%s]", port)
})
