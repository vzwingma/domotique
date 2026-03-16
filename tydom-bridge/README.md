# Tydom Bridge

Proxy HTTP minimal entre les scripts consommateurs du workspace et l'écosystème DeltaDore/Tydom.

Le bridge expose une API REST locale protégée par Basic Auth et traduit les appels entrants en requêtes vers le client `tydom-client`.

---

## Prérequis

- **Node.js** : `>=18` (compatible avec `tydom-client@0.13.4`)
- **tydom-client** : `0.13.4`

---

## Installation

```bash
npm install
```

---

## Configuration

Toutes les valeurs sont passées via variables d'environnement. Les cinq premières sont **obligatoires** ; le bridge refuse de démarrer si l'une d'elles est absente.

| Variable | Obligatoire | Défaut | Description |
|---|---|---|---|
| `MAC` | ✅ | — | Adresse MAC / identifiant de la box Tydom |
| `PASSWD` | ✅ | — | Mot de passe de la box Tydom |
| `AUTHAPI` | ✅ | — | Login pour la Basic Auth de l'API du bridge |
| `PASSWDAPI` | ✅ | — | Mot de passe pour la Basic Auth de l'API du bridge |
| `HOST` | ✗ | `mediation.tydom.com` | Adresse IP ou hostname de la box (local) ou du cloud |
| `PORT` | ✗ | `9001` | Port d'écoute HTTP du bridge |
| `NODE_TLS_REJECT_UNAUTHORIZED` | ✗ | `0` | Mettre à `1` pour forcer la vérification TLS (production) |

> **Note TLS** : par défaut, la vérification du certificat TLS est désactivée pour la compatibilité avec les box Tydom locales (certificat auto-signé). En production ou en mode cloud, définir `NODE_TLS_REJECT_UNAUTHORIZED=1`.

---

## Démarrage

```bash
# Exemple de démarrage local
MAC=001A2B3C4D5E \
PASSWD=motdepassetydom \
AUTHAPI=admin \
PASSWDAPI=secret \
HOST=192.168.1.13 \
node app.js
```

Le serveur HTTP démarre **immédiatement**, indépendamment de la connexion Tydom. Si la connexion Tydom échoue, le bridge reste disponible en mode dégradé et répond `503` sur les routes métier.

---

## Comportement de démarrage

1. Validation des variables d'environnement (échec fatal si variable manquante).
2. Démarrage du serveur HTTP Express sur `PORT`.
3. Tentative de connexion à la box Tydom en parallèle (non bloquante).
4. Les routes de santé `/health/*` sont disponibles **sans authentification** dès le démarrage.
5. Les routes métier répondent `503` jusqu'à ce que la connexion Tydom soit établie.

---

## API

### Santé (sans authentification)

| Méthode | Route | Description |
|---|---|---|
| `GET` | `/health/live` | **Liveness** : le process Node est vivant → toujours `200 up` |
| `GET` | `/health/ready` | **Readiness** : Tydom connecté → `200 ready`, sinon `503 not_ready` |
| `GET` | `/health/status` | Statut détaillé : uptime du bridge + état complet du backend Tydom |

### Métier (Basic Auth requise)

| Méthode | Route | Description |
|---|---|---|
| `GET` | `/_info` | Statut interne du bridge et état de connexion Tydom |
| `POST` | `/reconnect` | Force une reconnexion immédiate au boîtier Tydom (retour immédiat, reconnexion en arrière-plan) |
| `GET` | `/info` | Proxy `GET /info` vers Tydom |
| `GET` | `/devices/data` | Liste de tous les devices Tydom |
| `GET` | `/device/:devicenum/endpoints/:endpointnum` | État d'un endpoint d'un device |
| `PUT` | `/device/:devicenum/endpoints/:endpointnum` | Mise à jour d'un endpoint (body JSON) |
| `POST` | `/refresh/all` | Refresh du jumeau numérique depuis les équipements physiques |

Toutes les réponses sont en `application/json`. Les en-têtes `X-CorrId`, `X-Request-DeviceId` et `X-Request-EndpointId` sont propagés.

### Format des erreurs

```json
{
  "error": "backend_unavailable",
  "message": "Le client Tydom n'est pas connecté.",
  "status": "degraded",
  "lastError": "connect ECONNREFUSED 192.168.1.13:443"
}
```

---

## Comportement de robustesse

- **Retry exponentiel** : si la box Tydom est indisponible au démarrage ou en cours de fonctionnement, `connectTydom()` relance automatiquement la connexion avec un backoff exponentiel (départ 5 s, max 60 s, tentatives illimitées).
- **Mode dégradé 503** : toutes les routes métier retournent une réponse `503 application/json` structurée tant que la connexion Tydom n'est pas établie — le bridge reste toujours joignable.
- **Health endpoints** : `/health/live` et `/health/ready` permettent de distinguer la vivacité du process de la disponibilité effective du backend Tydom.

---

## Tests

```bash
cd tydom-bridge
npm test
```

La suite Jest + supertest couvre les cas nominaux et dégradés :

- validation de configuration (variables manquantes → refus de démarrage) ;
- health endpoints sans authentification ;
- Basic Auth valide / invalide ;
- routes métier avec backend simulé connecté ;
- routes métier avec backend déconnecté → `503` ;
- gestion d'erreur async → `500` ;
- headers de corrélation `X-CorrId` ;
- route inconnue → `404`.

---

## Arrêt propre

Le bridge écoute `SIGINT` et `SIGTERM` :
1. Fermeture du serveur HTTP (fin des connexions en cours).
2. Déconnexion du client Tydom.

---

## Dépendance critique — `tydom-client`

La baseline retenue est **`tydom-client@0.13.4`**, pinned en exact dans `package.json`.

Une migration vers `0.15.1` a été tentée et qualifiée en sandbox isolé. Elle a été **annulée (No-Go définitif)** en raison d'une incompatibilité fonctionnelle confirmée avec le backend Tydom réel. Un rollback complet vers `0.13.4` a été réalisé.

La migration vers une version supérieure de `tydom-client` n'est pas prévue dans le backlog courant.

> **Note :** `tydom-client@0.13.4` utilise `got` pour les appels HTTP et est compatible Node.js ≥ 18. L'image Docker officielle utilise `node:22-slim`. Vérifier la version du runtime avant tout déploiement hors conteneur.

---

## Crédits

- [mgcrea/node-tydom-client](https://github.com/mgcrea/node-tydom-client) — client Node.js pour Tydom