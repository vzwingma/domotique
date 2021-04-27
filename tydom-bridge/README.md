Cette application permet de gerer les équipements DeltaDore.

### Installation

```
npm install
```

## Configuration
```
const port = ''; // Port d'écoute du serveur web
const host = ''; // Adresse IP de la box
const username = ''; // Nom d'utilisateur de la box
const password = ''; // Mot de passe de la box
const isremote = 0; // 1=Accés depuis le cloud DeltaDore, 0=Accés depuis la box en local

```

## Démarrage

```
node app.js
```

## Utilisation

L'application crée une api web afin de récupérer les informations via des requetes http.

## Credits

- [mgcrea/node-tydom-client](https://github.com/mgcrea/node-tydom-client) pour le client nodeJs
- [mathman/tydom](https://github.com/mathman/tydom) pour l'api nodeJs