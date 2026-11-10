# Image Docker tydom-bridge

Image du bridge Tydom : **Node 26.13.0 bookworm-slim / `linux/arm64`**, publiée sous `vzwingmadomatic/domoticz-tydom:latest`.
La base est épinglée par digest dans le Dockerfile. Qualifiée sur le NAS avec la box Tydom réelle le 2026-11-10 ([plan 007](../../docs/plans/007_tydom_node26_arm64.plan.md), [ADR 006](../../docs/adr/006-tydom-node26-arm64-tls-legacy.md)).

> Le NAS AS1102T utilise un noyau 4.9.119, inférieur au minimum officiel Node 26 ARM64 (4.18).
> Le bridge y fonctionne, mais cette configuration reste hors support officiel Node.
> Depuis la bascule Node 26, `latest` n'est plus l'image ARM32 Node 16 ; l'ancienne image de rollback a été supprimée du NAS.

---

## Contenu de l'image

- **Base** : `node:26.13.0-bookworm-slim`, épinglée par digest
- **Application** : `tydom-bridge/app.js` — proxy REST entre Domoticz et la box Tydom
- **Dépendances** : installées via `npm ci --omit=dev` depuis le lockfile ; `tydom-client@0.16.1` (épinglé en exact)
- **TLS legacy** : `OPENSSL_CONF=/usr/local/etc/tydom-openssl.cnf`, générée au build, active `UnsafeLegacyRenegotiation` et `CipherString = DEFAULT:@SECLEVEL=0`
- **Port exposé** : `9001`

> La box Tydom locale exige la renégociation TLS legacy, refusée par défaut par OpenSSL 3 (Node 26) :
> sans cette configuration, `fetch failed` / `ERR_SSL_UNSAFE_LEGACY_RENEGOTIATION_DISABLED`.
> Son certificat auto-signé a une clé trop courte (< 1024 bits, `EE certificate key too weak` jusqu'à `SECLEVEL=1`) : le niveau 0 est nécessaire.
> Ce choix affaiblit TLS pour tout le processus du conteneur, et pour lui seul. Ne pas réutiliser cette image pour d'autres flux.
> Le fichier [`openssl.cnf`](openssl.cnf) en est la version de référence lisible ; il n'est pas copié par le build (contexte `tydom-bridge/`).
> La section racine doit s'appeler `nodejs_conf` : Node ignore `openssl_conf` sauf avec `--openssl-shared-config`.

---

## Construction de l'image

```bash
# Depuis la racine du dépôt, sans publication
docker buildx build --platform linux/arm64 \
  --file _docker/build_tydom/Dockerfile \
  --tag tydom-bridge:local --load tydom-bridge
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

Le workflow [build-tydom.yml](../../.github/workflows/build-tydom.yml) s'exécute sur `main`, `master` et `feat/tydom` (push et pull requests) :
tests unitaires Node 26, scan Sonar, construction ARM64 sous QEMU et vérification de l'image sans réseau
(architecture `arm64`, Node 26, version de `tydom-client` identique à `package.json`, configuration OpenSSL `nodejs_conf` /
`UnsafeLegacyRenegotiation` / `@SECLEVEL=0`).

Seul `master` publie : un push (ou un lancement manuel depuis `master`) reconstruit, revérifie puis pousse
`vzwingmadomatic/domoticz-tydom:latest`, via l'environnement `PROD`. Le digest publié figure dans le résumé du job.
Les pull requests et les autres branches ne publient rien. Tout push sur `master` republie `latest`, même sans changement Tydom.

Le Compose NAS suit `latest` sans digest : une publication ne se déploie pas seule.
Pour déployer, télécharger explicitement **la seule image Tydom** (`docker pull --platform linux/arm64 vzwingmadomatic/domoticz-tydom:latest`
ou Portainer > Images > Pull), puis recréer uniquement le conteneur `tydom-bridge`. Ne pas utiliser « Re-pull image » sur toute la stack :
HTTPD et Domoticz suivent aussi `latest`. Vérifier ensuite que le digest du conteneur correspond à celui du résumé du job.

Avant tout pull de `latest`, conserver l'image en cours sous un tag local de retour arrière
(ex. `vzwingmadomatic/domoticz-tydom:rollback-AAAAMMJJ`) : le pull déplace le tag `latest`.

Le build CI sous QEMU ne remplace pas une vérification sur le NAS après déploiement (`/health/ready` = 200).

[![Build Tydom Bridge ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml)

---

## Documentation complète

Voir [`tydom-bridge/README.md`](../../tydom-bridge/README.md) pour la documentation complète du bridge (API, comportement de robustesse, format d'erreur, etc.).
