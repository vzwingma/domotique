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

Les plugins ne sont pas versionnés dans ce dépôt : le workflow [`build-domoticz.yml`](../../.github/workflows/build-domoticz.yml) les télécharge à chaque build (jobs `download-linky` et `download-deconz`, artefacts déposés dans `linky/` et `deconz/`), **épinglés sur le SHA de commit d'un tag** ([ADR 007](../../docs/adr/007-plugins-domoticz-provenance-epinglee.md)).

| Plugin | Dépôt source | Référence (`ref:` du workflow) | Tag | Remarque |
|---|---|---|---|---|
| Linky | `vzwingma/DomoticzLinky` (fork maintenu) | `a7b232042a0ac725390583416043e327882510d5` | `v2.7.0` | Pin initial : `v2.6.1` (`f3df2584…`) ; monté en `v2.7.0` le 2026-11-25 (masquage des secrets dans les logs, correctifs). L'upstream (`guillaumezin`) n'est plus maintenu ni consommé (avant l'ADR 007, la CI reprenait sa branche `master`). Rétrodoc : [RETROCONCEPTION.md](https://github.com/vzwingma/DomoticzLinky/blob/master/docs/RETROCONCEPTION.md) |
| deCONZ | `Smanar/Domoticz-deCONZ` | `95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a` | `1.0.35` | — |

**Reproductibilité** : un SHA de commit est immuable ; deux builds du même commit de ce dépôt embarquent donc exactement les mêmes plugins. Chaque job trace dans son *Step Summary* le SHA récupéré et la `version=` du `plugin.py`, et l'upload de l'artefact échoue s'il est vide (`if-no-files-found: error`). Voir aussi [`docs/ARCHITECTURE.md` § 5.4](../../docs/ARCHITECTURE.md#54-plugins-python-domoticz-linky-deconz).

### Montée de version d'un plugin

La montée de version est **toujours volontaire et revue** : Renovate n'a pas d'automerge sur ces deux dépendances.

1. **Publier un tag** sur le dépôt du plugin (pour Linky : tag `vX.Y.Z` sur le fork `vzwingma/DomoticzLinky`).
2. **PR Renovate** : Renovate (customManager regex sur `build-domoticz.yml`, datasource `github-tags`, configuré dans [`renovate.json`](../../renovate.json)) détecte le nouveau tag et propose une PR qui met à jour la ligne `ref: <sha> # <tag>`.
   *Alternative manuelle* : modifier la ligne `ref:` qui suit `repository:` dans le job concerné, au format `ref: <sha40> # <tag>`, avec `SHA = git rev-list -n1 <tag>` (SHA du **commit**, pas de l'objet tag annoté). Conserver `ref:` immédiatement après `repository:` (requis par la regex Renovate).
3. **Revue** de la PR : écart entre l'ancien et le nouveau tag, SHA = commit du tag.
4. **Merge** sur `master` : le build reconstruit l'image `latest` avec le nouveau plugin ; vérifier la version dans le log Domoticz après redéploiement.

**Retour arrière** : `git revert` du commit de montée de version (ou re-pin manuel sur l'ancien couple `<sha> # <tag>`), puis merge ; l'image est reconstruite avec le plugin précédent.

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
> En production, le compose NAS (`_docker/envs/nas/domotique-compose.yml`) **monte** ce dossier (`/volume1/home/vinz/domoticz/scripts/dzVents` → `/opt/domoticz/userdata/scripts/dzVents/generated_scripts`) : les scripts de l'image sont alors remplacés par ceux de l'hôte.

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
