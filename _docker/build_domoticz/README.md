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

### Provenance des plugins

Les plugins ne sont pas versionnés dans ce dépôt : le workflow [`build-domoticz.yml`](../../.github/workflows/build-domoticz.yml) les télécharge à chaque build (jobs `download-linky` et `download-deconz`, artefacts déposés dans `linky/` et `deconz/`).

| Plugin | Dépôt source | Référence | Remarque |
|---|---|---|---|
| Linky | `guillaumezin/DomoticzLinky` (upstream) | `refs/heads/master` — **non épinglée** | Upstream non maintenu ; le fork maintenu `vzwingma/DomoticzLinky` n'est **pas** consommé aujourd'hui. Rétrodoc : [RETROCONCEPTION.md](https://github.com/vzwingma/DomoticzLinky/blob/master/docs/RETROCONCEPTION.md) |
| deCONZ | `Smanar/Domoticz-deCONZ` | `refs/heads/master` — **non épinglée** | — |

> ⚠️ Un build reprend la tête de `master` des dépôts amont : le contenu de l'image n'est pas reproductible à l'identique. Voir [`docs/ARCHITECTURE.md` § 5.4](../../docs/ARCHITECTURE.md#54-plugins-python-domoticz-linky-deconz).

---

## Construction de l'image

> ⚠️ L'image est destinée à une **architecture ARM**.
> **Plateforme réellement construite par la CI : `linux/arm/v7`** (variable `DOCKER_TARGET_PLATFORM` de `build-domoticz.yml`). Les exemples ci-dessous utilisent `linux/arm64` : adapter la plateforme à celle de l'hôte cible (l'image publiée par la CI est `linux/arm/v7`).

```bash
# Construction sur ARM (Raspberry Pi)
docker build -t vzwingmadomatic/domoticz:latest .

# Construction multi-arch depuis x86_64 (adapter la plateforme : la CI utilise linux/arm/v7)
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

> ⚠️ **Montage de `userdata`** : l'exemple ci-dessus monte `$DOMOTICZ_PATH/database` sur **tout** `/opt/domoticz/userdata`. Ce montage **masque** les répertoires de l'image, dont `plugins/` (Linky, deCONZ) et `scripts/` : les plugins n'apparaîtraient plus dans Domoticz tant que ce répertoire hôte ne les contient pas. Le compose de production (`_docker/envs/nas`) ne monte que le fichier `domoticz.db` (et `scripts/dzVents`). Privilégier ce montage ciblé (jetons OAuth et cache du plugin Linky sont stockés dans `domoticz.db`).

---

## Déploiement via Docker Compose

Les manifests sont dans `_docker/envs/` : `envs/nas/domotique-compose.yml` (Domoticz + tydom-bridge + httpd-proxy) et `envs/pi/domotique-compose.yml` (deCONZ). Il n'existe pas de `_docker/domotique-compose.yml`. **Watchtower** n'est défini dans aucun de ces fichiers.

```bash
cd _docker/envs/nas
docker compose -f domotique-compose.yml up -d
```

---

## CI/CD

L'image est reconstruite automatiquement à chaque push sur `master` via GitHub Actions :

[![Build Domoticz ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-domoticz.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-domoticz.yml)
