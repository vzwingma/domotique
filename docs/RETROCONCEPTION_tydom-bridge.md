# Rétroconception et plan d'actions pour `tydom-bridge`

## 1. Objet

Ce document présente :

- la rétroconception du module `tydom-bridge` ;
- une analyse critique du code actuel ;
- un plan d'actions priorisé pour améliorer sa robustesse, sa fiabilité et sa maintenabilité ;
- un focus spécifique sur la régression observée lors du passage de `tydom-client` de `0.13.x` à `0.15.x`.

Le périmètre analysé est le répertoire `tydom-bridge\`.

---

## 2. Vue d'ensemble de l'architecture

`tydom-bridge` est un pont HTTP très compact entre les scripts consommateurs du workspace et l'écosystème Tydom.

Architecture logique :

1. un processus Node.js unique démarre ;
2. il ouvre une connexion au client `tydom-client` ;
3. si cette connexion réussit, il expose une API HTTP Express sur le port `9001` par défaut ;
4. les routes HTTP traduisent les appels entrants en appels `client.get`, `client.put` et `client.post` vers Tydom ;
5. les réponses sont renvoyées telles quelles, sans couche métier, sans cache et sans persistance locale.

En pratique, le bridge joue le rôle de proxy applicatif minimal.

### 2.1 Composants majeurs

- `app.js`
  - point d'entrée unique ;
  - contient toute la logique de bootstrap, sécurité, journalisation et exposition des routes ;
  - instancie `tydom-client`.

- `express`
  - expose l'API HTTP locale consommée par le reste du système.

- `express-basic-auth`
  - protège l'API du bridge avec un couple login/mot de passe distinct de l'authentification Tydom.

- `morgan-body`
  - journalise les requêtes HTTP côté bridge.

- `tydom-client`
  - encapsule la communication avec Tydom ;
  - constitue la dépendance critique du projet.

### 2.2 Flux principal au démarrage

1. lecture des variables d'environnement :
   - `PORT`
   - `HOST`
   - `MAC`
   - `PASSWD`
   - `AUTHAPI`
   - `PASSWDAPI`
2. création du client Tydom via `createClient({ username, password, hostname })` ;
3. appel `await client.connect()` ;
4. si la connexion aboutit, création du serveur Express ;
5. activation de la Basic Auth et des middlewares ;
6. exposition des routes REST.

Conséquence importante : si `client.connect()` échoue, le bridge ne démarre pas.

---

## 3. Inventaire des fichiers et responsabilités

### 3.1 `app.js`

Fichier central et unique du bridge.

Responsabilités observées :

- désactivation globale du contrôle TLS via `NODE_TLS_REJECT_UNAUTHORIZED = '0'` ;
- lecture de la configuration d'environnement ;
- instanciation de `tydom-client` ;
- ouverture de la connexion ;
- initialisation du serveur Express ;
- protection Basic Auth ;
- exposition des routes HTTP ;
- arrêt partiel sur `SIGINT`.

### 3.2 `package.json`

Responsabilités :

- description du module Node.js ;
- déclaration des dépendances runtime.

Constat important :

- `tydom-client` est déclaré en `^0.15.0`.

### 3.3 `package-lock.json`

Responsabilités :

- verrouillage théorique des versions.

Constat important :

- le lockfile pointe vers `tydom-client@0.15.1` ;
- le lockfile signale une exigence Node.js `>=20` pour cette version.

### 3.4 `node_modules\tydom-client\package.json`

Constat local observé :

- la version réellement présente dans l'arbre local est `0.13.4`.

Cela révèle un écart entre :

- la version déclarée ;
- la version verrouillée ;
- la version réellement installée dans le workspace courant.

### 3.5 `README.md`

Responsabilités :

- documenter le bridge.

Constats :

- documentation très légère ;
- la configuration décrite n'est plus totalement alignée avec le code réel ;
- la variable `isremote` est documentée mais absente du code applicatif actuel.

---

## 4. API exposée par le bridge

Le bridge expose les routes suivantes :

- `GET /_info`
  - endpoint de statut applicatif minimal.

- `GET /info`
  - proxy de `client.get('/info')`.

- `GET /devices/data`
  - proxy de `client.get('/devices/data')`.

- `GET /device/:devicenum/endpoints/:endpointnum`
  - proxy de lecture d'un endpoint Tydom.

- `PUT /device/:devicenum/endpoints/:endpointnum`
  - proxy d'écriture d'un endpoint Tydom avec payload `req.body`.

- `POST /refresh/all`
  - proxy d'un refresh global.

Le bridge recopie aussi certains en-têtes applicatifs (`X-CorrId`, `X-Request-DeviceId`, `X-Request-EndpointId`).

---

## 5. Analyse détaillée du code

## 5.1 Points positifs

- code très court et facile à parcourir ;
- faible dispersion : un seul point d'entrée ;
- exposition API simple et lisible ;
- corrélation HTTP partielle déjà présente via `X-CorrId`.

## 5.2 Fragilités de conception

### a. Démarrage couplé à la connexion Tydom

Le serveur HTTP n'est démarré qu'après `await client.connect()`.

Effets :

- aucune API locale disponible si Tydom est momentanément indisponible ;
- absence de mode dégradé ;
- difficulté pour superviser le bridge lui-même.

### b. Absence de gestion d'erreur sur les routes async

Les routes appellent directement :

- `await client.get(...)`
- `await client.put(...)`
- `await client.post(...)`

sans `try/catch`.

Effets :

- erreurs 500 non cadrées ;
- comportement dépendant de la version de Node / Express ;
- manque de diagnostic API côté appelant.

### c. Contrat HTTP imprécis

La fonction `updateHeaders` force :

- `Content-Type: text/plain`

alors que les réponses envoyées sont du JSON sérialisé.

Effets :

- contrat API ambigu ;
- intégration moins robuste côté clients.

### d. Sécurité perfectible

Le code contient :

- `process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'`

Effets :

- désactive globalement la vérification TLS ;
- acceptable pour certains contextes locaux de test, mais risqué en production ;
- impacte potentiellement tout appel TLS du process.

Autre point :

- l'authorizer Basic Auth retourne `userMatches & passwordMatches` ;
- c'est un opérateur bit-à-bit et non un opérateur booléen logique.

Même si cela peut "fonctionner" par coercition, ce n'est pas le contrat attendu.

### e. Arrêt incomplet

Le handler `SIGINT` :

- ferme le serveur Express ;
- ne ferme pas explicitement le client Tydom.

Effets :

- fermeture potentiellement incomplète ;
- risque de session ou socket non nettoyé.

### f. Configuration non validée

Le code lit directement :

- `MAC`
- `PASSWD`
- `AUTHAPI`
- `PASSWDAPI`
- `HOST`
- `PORT`

sans validation formelle.

Effets :

- erreurs tardives ;
- logs peu explicites ;
- démarrage fragile.

### g. Observabilité limitée

Le bridge journalise les requêtes HTTP entrantes mais n'expose pas :

- l'état de connexion courant au backend Tydom ;
- un healthcheck détaillé ;
- des métriques de reconnexion, échec, timeout.

### h. Documentation obsolète

Le `README.md` ne reflète pas exactement le comportement réel :

- `isremote` documenté mais absent ;
- variables d'environnement réelles non présentées clairement ;
- pas de prérequis Node.js documenté.

---

## 6. Analyse spécifique de la régression `tydom-client` `0.13.x` -> `0.15.x`

## 6.1 Constat local vérifié

Dans le dépôt :

- `package.json` demande `^0.15.0` ;
- `package-lock.json` résout `0.15.1` ;
- `node_modules\tydom-client\package.json` indique `0.13.4`.

Le workspace est donc dans un état incohérent.

Cela signifie qu'un `npm install` ou un rebuild propre peut changer brutalement le comportement du bridge, même si le code source n'a pas bougé.

## 6.2 Impact probable du passage à `0.15.x`

L'analyse du package et de ses évolutions montre plusieurs zones à risque :

### a. Changement majeur de runtime

La version `0.15.x` introduit une exigence Node.js `>=20`.

Conséquence :

- si le runtime effectif n'est pas conforme, le bridge peut casser au démarrage ou au premier appel réseau.

### b. Changement interne de l'implémentation du client

Le passage de `0.13.x` à `0.15.x` s'accompagne d'une refonte interne du paquet `tydom-client`.

L'analyse réalisée sur cette évolution pointe une régression probable sur la gestion des trames de communication à distance, notamment autour du préfixe protocolaire utilisé par le canal Tydom distant.

Conséquences possibles :

- requêtes non reconnues ou mal parsées ;
- timeouts systématiques ;
- reconnexions en boucle ;
- promesses rejetées plus explicitement qu'en `0.13.x`, ce qui expose davantage l'absence de `try/catch` dans `app.js`.

### c. Changement de comportement sur les timeouts

La branche `0.15.x` semble plus stricte sur les erreurs de timeout.

Dans le contexte de ce bridge, cela amplifie les fragilités déjà présentes :

- routes async non protégées ;
- absence de gestion structurée des erreurs ;
- démarrage très couplé à la connexion.

## 6.3 Conclusion sur la régression

Le non-fonctionnement observé après passage à `0.15` n'est pas seulement un problème de compatibilité de dépendance.

C'est la combinaison de :

1. une dépendance critique modifiée ;
2. une exigence Node.js plus élevée ;
3. un bridge applicatif très mince ;
4. une absence de garde-fous autour des erreurs et de la connectivité.

Autrement dit, `tydom-bridge` est actuellement trop fragile pour absorber sereinement une montée de version de `tydom-client`.

---

## 7. Risques prioritaires

### Risque 1 — Déploiement non reproductible

L'écart entre `package.json`, `package-lock.json` et `node_modules` rend l'état du bridge non déterministe.

### Risque 2 — Bridge indisponible au moindre problème Tydom

L'API locale dépend entièrement de la réussite de la connexion initiale.

### Risque 3 — Erreurs runtime mal cadrées

Le bridge ne transforme pas correctement les erreurs backend en réponses HTTP stables et explicites.

### Risque 4 — Supervision insuffisante

Il manque des signaux simples permettant de savoir si le bridge est :

- démarré ;
- connecté ;
- dégradé ;
- en boucle de reconnexion.

### Risque 5 — Sécurité et exploitation

La désactivation globale de TLS et la journalisation brute peuvent poser problème selon le contexte d'exécution.

---

## 8. Plan d'actions priorisé

## Phase 1 — Stabilisation immédiate

### Action 1.1 — Décider explicitement de la version cible de `tydom-client`

Deux options réalistes :

- **Option A : revenir temporairement à `0.13.4`**
  - pour retrouver un fonctionnement connu ;
  - en attendant une investigation et une validation de `0.15.x`.

- **Option B : conserver `0.15.x`**
  - mais seulement après validation Node.js, revue des changements du package et tests d'intégration.

### Action 1.2 — Réaligner l'état du projet

Il faut rendre cohérents :

- `package.json`
- `package-lock.json`
- l'installation réelle

Objectif :

- supprimer tout état ambigu ;
- garantir qu'un `npm install` reproduit exactement le comportement attendu.

### Action 1.3 — Documenter le prérequis Node.js

Si `0.15.x` est retenu, documenter explicitement :

- Node.js `>=20`.

---

## Phase 2 — Durcir le bridge

### Action 2.1 — Ajouter une validation de configuration au démarrage

Vérifier explicitement les variables d'environnement requises.

Attendu :

- erreur de démarrage claire ;
- message actionnable ;
- pas d'échec silencieux.

### Action 2.2 — Découpler le démarrage HTTP de la connexion Tydom

Faire en sorte que le serveur Express démarre même si la connexion Tydom initiale échoue.

Le bridge doit pouvoir répondre :

- "up but disconnected"
- plutôt que "absent".

### Action 2.3 — Ajouter des `try/catch` systématiques sur les routes async

Attendu :

- codes HTTP cohérents ;
- payload d'erreur propre ;
- logs exploitables.

### Action 2.4 — Corriger le contrat HTTP

- répondre en `application/json` ;
- homogénéiser les réponses succès/erreur ;
- garder la corrélation `X-CorrId`.

### Action 2.5 — Corriger la Basic Auth

Remplacer le `&` par un opérateur logique booléen.

---

## Phase 3 — Robustesse opérationnelle

### Action 3.1 — Exposer un vrai healthcheck

Créer par exemple :

- `/health/live`
- `/health/ready`

avec indicateurs :

- process vivant ;
- serveur HTTP prêt ;
- client Tydom connecté ou non ;
- dernière erreur connue.

### Action 3.2 — Gérer proprement les fermetures

- fermer explicitement le client Tydom ;
- nettoyer les ressources à l'arrêt.

### Action 3.3 — Réduire les logs sensibles

Revoir `morgan-body` pour éviter :

- surjournalisation ;
- fuite potentielle de données sensibles ;
- logs trop verbeux en production.

### Action 3.4 — Encadrer le mode TLS permissif

Ne pas désactiver TLS globalement par défaut.

Prévoir un mode explicite de compatibilité locale si nécessaire.

---

## Phase 4 — Validation de la montée vers `0.15.x`

### Action 4.1 — Produire un protocole de test de non-régression

Cas à couvrir :

- connexion locale ;
- connexion distante ;
- `GET /info` ;
- `GET /devices/data` ;
- lecture d'endpoint ;
- écriture d'endpoint ;
- `POST /refresh/all` ;
- reconnexion après perte réseau ;
- timeout backend ;
- arrêt/redémarrage.

### Action 4.2 — Isoler précisément la rupture `0.13 -> 0.15`

Comparer en environnement contrôlé :

- version de Node ;
- comportement de connexion ;
- logs côté bridge ;
- comportement des appels simples.

### Action 4.3 — Décider de la stratégie long terme

Choix possibles :

- rester durablement sur `0.13.4` en version figée ;
- patcher `0.15.x` localement ;
- contribuer un correctif upstream ;
- remplacer `tydom-client` si la dépendance ne redevient pas fiable.

---

## 9. Recommandation stratégique

La meilleure trajectoire court terme est :

1. figer immédiatement une version fonctionnelle reproductible ;
2. durcir le bridge pour qu'il survive aux erreurs de connexion ;
3. seulement ensuite reprendre l'analyse de la migration vers `0.15.x`.

En l'état, migrer directement sans renforcer le bridge continuerait à mélanger :

- problème de dépendance ;
- problème d'environnement Node ;
- fragilité structurelle du code.

---

## 10. Synthèse

`tydom-bridge` est aujourd'hui un proxy utile mais extrêmement mince et fragile.

Ses qualités actuelles sont sa simplicité et sa lisibilité.

Ses principaux défauts sont :

- une forte dépendance au succès immédiat de la connexion Tydom ;
- une gestion d'erreur insuffisante ;
- une observabilité limitée ;
- une documentation partiellement obsolète ;
- un état de dépendances incohérent ;
- une migration vers `tydom-client@0.15.x` non maîtrisée.

Le chantier recommandé n'est pas un refactoring massif, mais une sécurisation en couches :

1. reproductibilité de la dépendance ;
2. durcissement du bootstrap et des erreurs ;
3. healthchecks et exploitation ;
4. validation contrôlée de la montée de version.
