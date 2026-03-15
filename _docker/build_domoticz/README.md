# Image Docker Domoticz

Image Docker custom basée sur `domoticz/domoticz:latest`, enrichie des scripts dzVents, du plugin Linky et du plugin deCONZ.

---

## Contenu de l'image

L'image est construite depuis `Dockerfile` et embarque :

- **Base** : `domoticz/domoticz:latest` (image officielle Domoticz)
- **Scripts dzVents** : tous les fichiers `*.lua` du répertoire courant, copiés dans `/opt/domoticz/userdata/scripts/dzVents/generated_scripts`
- **Plugin Linky** : `linky/plugin.py` → `/opt/domoticz/userdata/plugins/DomoticzLinky/`
- **Plugin deCONZ** : `deconz/*.py` → `/opt/domoticz/userdata/plugins/Domoticz-deCONZ/`
- **Dépendances système** : `python3-dev`, `curl`

---

## Construction de l'image

> ⚠️ L'image est destinée à une **architecture ARM** (Raspberry Pi).
> Pour construire sur x86_64, utiliser `--platform linux/arm64`.

```bash
# Construction sur ARM (Raspberry Pi)
docker build -t vzwingmadomatic/domoticz:latest .

# Construction multi-arch depuis x86_64
docker buildx build --platform linux/arm64 -t vzwingmadomatic/domoticz:latest .
```

## Téléchargement depuis Docker Hub

```bash
docker pull vzwingmadomatic/domoticz:latest
```

---

## Exécution du conteneur

```bash
docker run --name=domoticz -d \
  --privileged \
  --restart=always \
  -p 8080:8080 \
  -p 8443:443 \
  -e TZ=Europe/Paris \
  -v /etc/timezone:/etc/timezone:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -v $DOMOTICZ_PATH/database:/opt/domoticz/userdata \
  -v $DOMOTICZ_PATH/scripts/dzVents:/opt/domoticz/userdata/scripts/dzVents/generated_scripts \
  -t vzwingmadomatic/domoticz:latest
```

### Variables

| Variable | Description |
|---|---|
| `$DOMOTICZ_PATH/database` | Répertoire vers la BDD Domoticz (fichier `domoticz.db`) |
| `$DOMOTICZ_PATH/scripts/dzVents` | Répertoire vers les scripts Lua dzVents (montage optionnel, remplace ceux embarqués dans l'image) |
| `TZ` | Fuseau horaire (ex : `Europe/Paris`) |

> **Note :** Le volume `scripts/dzVents` est optionnel. S'il est monté, il remplace les scripts embarqués dans l'image.
> En production, les scripts sont embarqués dans l'image (pas de volume) pour garantir la cohérence image/scripts.

---

## Déploiement via Docker Compose

Voir `_docker/domotique-compose.yml` pour le déploiement complet de la stack (Domoticz + tydom-bridge + deCONZ + httpd-proxy + Watchtower).

```bash
cd _docker
docker compose -f domotique-compose.yml up -d
```

---

## CI/CD

L'image est reconstruite automatiquement à chaque push sur `master` via GitHub Actions :

[![Build Domoticz ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-domoticz.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-domoticz.yml)
