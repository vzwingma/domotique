# Image Docker tydom-bridge

Image Docker du bridge Tydom, basée sur `node:22-slim` (plateforme `linux/amd64`).

---

## Contenu de l'image

- **Base** : `node:22-slim` (Node.js 22 LTS, image minimale)
- **Application** : `tydom-bridge/app.js` — proxy REST entre Domoticz et la box Tydom
- **Dépendances** : installées via `npm install` lors du build
- **Port exposé** : `9001`

---

## Construction de l'image

```bash
# Depuis le répertoire tydom-bridge/
cd tydom-bridge
docker build -t vzwingmadomatic/domoticz-tydom:latest .
```

> L'image est construite pour `linux/amd64`. Pour une cible ARM (Raspberry Pi) :
>
> ```bash
> docker buildx build --platform linux/arm64 -t vzwingmadomatic/domoticz-tydom:latest .
> ```

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

Voir `_docker/domotique-compose.yml` :

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

L'image est reconstruite automatiquement à chaque push sur `master` via GitHub Actions :

[![Build Tydom Bridge ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml)

---

## Documentation complète

Voir [`tydom-bridge/README.md`](../../tydom-bridge/README.md) pour la documentation complète du bridge (API, comportement de robustesse, format d'erreur, etc.).
