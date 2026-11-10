# Image Docker tydom-bridge

Image du bridge Tydom : **Node 26.13.0 bookworm-slim / `linux/arm64`**, publiée sous `vzwingmadomatic/domoticz-tydom:latest`.
La base est épinglée par digest dans le Dockerfile. Qualification avec la box Tydom réelle en cours (plan 007).

> Le NAS AS1102T utilise un noyau 4.9.119, inférieur au minimum officiel Node 26 ARM64 (4.18).
> Son démarrage ARM64 a été observé, mais le fonctionnement sur ce NAS reste expérimental.
> Depuis la bascule Node 26, `latest` n'est plus l'image ARM32 Node 16 : le retour arrière repose sur l'image sauvegardée localement sur le NAS.

---

## Contenu de l'image

- **Base** : `node:26.13.0-bookworm-slim`, épinglée par digest
- **Application** : `tydom-bridge/app.js` — proxy REST entre Domoticz et la box Tydom
- **Dépendances** : installées via `npm ci --omit=dev` depuis le lockfile ; candidate `tydom-client@0.16.1`, qualification réelle requise
- **TLS legacy** : `OPENSSL_CONF=/usr/local/etc/tydom-openssl.cnf`, générée au build, active `UnsafeLegacyRenegotiation`
- **Port exposé** : `9001`

> La box Tydom locale exige la renégociation TLS legacy, refusée par défaut par OpenSSL 3 (Node 26) :
> sans cette configuration, `fetch failed` / `ERR_SSL_UNSAFE_LEGACY_RENEGOTIATION_DISABLED`.
> Ce choix affaiblit TLS pour tout le processus du conteneur, et pour lui seul. Ne pas réutiliser cette image pour d'autres flux.
> Le fichier [`openssl.cnf`](openssl.cnf) en est la version de référence lisible ; il n'est pas copié par le build (contexte `tydom-bridge/`).

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

Le déploiement NAS est défini dans
[`_docker/envs/nas/domotique-compose.yml`](../envs/nas/domotique-compose.yml) :
`vzwingmadomatic/domoticz-tydom:latest` avec `platform: linux/arm64` explicite. Exemple générique :

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
tests Node 26, construction ARM64, chargement de `tydom-client` et présence de la configuration OpenSSL legacy dans l'image, sans accès réseau.
Il ne se déclenche que sur les changements de `tydom-bridge/**` ou `_docker/build_tydom/**`, hors fichiers Markdown
(et du workflow lui-même pour les pull requests) : un commit du Compose ou de la documentation ne republie pas `latest`.
Les pull requests et les push hors `master` ne publient aucune image.
Un push sur `master` construit, vérifie puis publie l'image ARM64 sous `vzwingmadomatic/domoticz-tydom:latest`,
après les tests, le smoke test ARM64 et le scan Sonar.

La publication d'une candidate exige un lancement manuel avec `publish=true`, les validations CI et
l'environnement `PROD`. Dans ce mode, seul le tag `candidate-node26-arm64-<SHA complet>` est publié, avec refus
d'écrasement d'un candidat existant. L'image à publier est testée avant le push ; son digest figure
dans le résumé du job. Les deux modes de publication utilisent l'environnement `PROD`.

Le Compose NAS suit `latest` sans digest : une publication ne se déploie pas seule.
Pour déployer, télécharger explicitement **la seule image Tydom** (`docker pull --platform linux/arm64 vzwingmadomatic/domoticz-tydom:latest`
ou Portainer > Images > Pull), puis recréer uniquement le conteneur `tydom-bridge`. Ne pas utiliser « Re-pull image » sur toute la stack :
HTTPD et Domoticz suivent aussi `latest`. Vérifier ensuite que le digest du conteneur correspond à celui du résumé du job.

Avant tout pull de `latest`, conserver l'image en cours sous un tag local de retour arrière
(ex. `vzwingmadomatic/domoticz-tydom:rollback-before-node26` pour l'ancienne image ARM32) : le pull déplace le tag `latest`.

Le build CI sous QEMU ne remplace pas la qualification native sur le NAS.
Voir le [plan 007](../../docs/plans/007_tydom_node26_arm64.plan.md) pour les gates et le retour arrière.

[![Build Tydom Bridge ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml)

---

## Documentation complète

Voir [`tydom-bridge/README.md`](../../tydom-bridge/README.md) pour la documentation complète du bridge (API, comportement de robustesse, format d'erreur, etc.).
