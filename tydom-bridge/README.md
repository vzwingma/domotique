# Tydom Bridge

Proxy HTTP minimal entre les scripts consommateurs du workspace et l'écosystème DeltaDore/Tydom.

Le bridge expose une API REST locale protégée par Basic Auth et traduit les appels entrants en requêtes vers le client `tydom-client`.

---

## Prérequis

- **Node.js** : `>=18` (testé sur v22)
- **tydom-client** : `0.13.4` (baseline figée — voir note de migration ci-dessous)

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

## Arrêt propre

Le bridge écoute `SIGINT` et `SIGTERM` :
1. Fermeture du serveur HTTP (fin des connexions en cours).
2. Déconnexion du client Tydom.

---

## Dépendance critique — `tydom-client`

La baseline retenue est **`tydom-client@0.13.4`**.

La version `0.15.x` introduit des changements de comportement (protocole distant, gestion des timeouts) non encore qualifiés dans ce contexte. La migration vers `0.15.x` fera l'objet d'un chantier dédié après validation en environnement contrôlé.

---

## Crédits

- [mgcrea/node-tydom-client](https://github.com/mgcrea/node-tydom-client) — client Node.js pour Tydom