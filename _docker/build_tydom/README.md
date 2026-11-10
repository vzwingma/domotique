# Image Docker tydom-bridge

Préparation de l'image candidate du bridge Tydom : **Node 26.13.0 bookworm-slim / `linux/arm64`**.
La base est épinglée par digest dans le Dockerfile. Cette candidate n'est pas encore qualifiée avec la box Tydom.

> Le NAS AS1102T utilise un noyau 4.9.119, inférieur au minimum officiel Node 26 ARM64 (4.18).
> Son démarrage ARM64 a été observé, mais le fonctionnement sur ce NAS reste expérimental.
> Le service GitOps NAS et son image `latest` ne sont pas modifiés par cette préparation.

---

## Contenu de l'image

- **Base** : `node:26.13.0-bookworm-slim`, épinglée par digest
- **Application** : `tydom-bridge/app.js` — proxy REST entre Domoticz et la box Tydom
- **Dépendances** : installées via `npm ci --omit=dev` depuis le lockfile ; candidate `tydom-client@0.16.1`, qualification réelle requise
- **Port exposé** : `9001`

---

## Construction de l'image

```bash
# Depuis la racine du dépôt, sans publication
docker buildx build --platform linux/arm64 \
  --file _docker/build_tydom/Dockerfile \
  --tag tydom-candidate:local --load tydom-bridge
```

Le contexte est `tydom-bridge/` ; seuls les manifestes et `app.js` sont copiés.
Ne pas construire depuis le dossier contenant le Dockerfile ni réutiliser des `node_modules` locaux.

---

## Exécution du conteneur

```bash
docker run --name=tydom-bridge -d \
  --restart=always \
  -p 9101:9001 \
  -e HOST=tydom.local \
  -e MAC=<ADRESSE_MAC_TYDOM> \
  -e PASSWD=<MOT_DE_PASSE_TYDOM> \
  -e PORT=9001 \
  -e AUTHAPI=<LOGIN_API> \
  -e PASSWDAPI=<MOT_DE_PASSE_API> \
  vzwingmadomatic/domoticz-tydom:latest
```

### Variables d'environnement

| Variable | Obligatoire | Défaut | Description |
|---|---|---|---|
| `MAC` | ✅ | — | Adresse MAC / identifiant de la box Tydom |
| `PASSWD` | ✅ | — | Mot de passe de la box Tydom |
| `AUTHAPI` | ✅ | — | Login pour la Basic Auth de l'API du bridge |
| `PASSWDAPI` | ✅ | — | Mot de passe pour la Basic Auth de l'API du bridge |
| `HOST` | ✗ | `mediation.tydom.com` | Adresse IP ou hostname de la box (local) ou du cloud Tydom |
| `PORT` | ✗ | `9001` | Port d'écoute HTTP du bridge |
| `NODE_TLS_REJECT_UNAUTHORIZED` | ✗ | `0` | Mettre à `1` pour forcer la vérification TLS (production cloud) |

---

## Déploiement via Docker Compose

Le déploiement NAS existant est défini dans
[`_docker/envs/nas/domotique-compose.yml`](../envs/nas/domotique-compose.yml).
L'exemple historique ci-dessous utilise `latest` ; **ne pas y substituer la candidate avant qualification et autorisation de bascule** :

```yaml
tydom-bridge:
  image: vzwingmadomatic/domoticz-tydom:latest
  environment:
    - HOST=tydom.local
    - MAC=#Set TYDOM MAC address
    - PASSWD=#Set TYDOM password
    - PORT=9001
    - AUTHAPI=#Set Auth login for API
    - PASSWDAPI=#Set Auth password for API
  ports:
    - 9101:9001
  restart: always
```

---

## CI/CD

Le workflow valide `main`, `master` et les branches de développement existantes :
tests Node 26, construction ARM64 et chargement de `tydom-client` dans l'image sans accès réseau.
Les pull requests et push ne publient aucune image.

La publication éventuelle exige un lancement manuel avec `publish=true`, les validations CI et
l'environnement `PROD`. Seul le tag `candidate-node26-arm64-<SHA complet>` est publié, avec refus
d'écrasement d'un candidat existant. L'image à publier est testée avant le push ; son digest figure
dans le résumé du job. Aucune publication automatique de `latest` n'est conservée pendant cette qualification.

Le build CI sous QEMU ne remplace pas la qualification native sur le NAS.
Voir le [plan 007](../../docs/plans/007_tydom_node26_arm64.plan.md) pour les gates et le retour arrière.

[![Build Tydom Bridge ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml)

---

## Documentation complète

Voir [`tydom-bridge/README.md`](../../tydom-bridge/README.md) pour la documentation complète du bridge (API, comportement de robustesse, format d'erreur, etc.).
