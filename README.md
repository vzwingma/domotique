# Domotique

Système domotique résidentiel basé sur **Domoticz** et une série de bridges Node.js, déployé sur Raspberry Pi via Docker.

## Architecture globale

```
  https://domatique.freeboxos.fr:38243/
          │  (DNS Free → IP publique)
  ┌───────▼──────────────────────────────────────────────────┐
  │  Freebox (routeur FAI)                                   │
  │  NAT : port 38243 (public) → 8243 (Raspberry Pi LAN)     │
  └───────────────────────┬──────────────────────────────────┘
                          │ HTTPS :8243
  ┌─────────────────────────────────────────────────────────┐
  │  Externe : HTTPS :8243      Local : HTTP :8280          │
  │         httpd-proxy (Apache 2.4)                        │
  │  TLS termination            CORS + accès libre          │
  │  Auth déléguée Domoticz     Proxy HTTP                  │
  └───────────────────────┬─────────────────────────────────┘
                          │ ProxyPass
        ┌─────────────────▼──────────────────────────────┐
        │                      Domoticz                  │
        │          (moteur central d'automatisation)     │
        │   scripts dzVents (Lua)  ←→  BDD SQLite        │
        │   :8080 (HTTP interne)   :8443 (HTTPS interne) │
        └──────────────┬──────────────────────────────────┘
                       │
        ┌──────────────▼───────────┐
        │    tydom-bridge          │
        │    (Node.js 26 ARM64)    │
        │    port 9001 / 9101      │
        └──────────┬───────────────┘
                   │
        ┌──────────▼───────────┐
        │    Box Tydom         │
       │    (Delta Dore)      │
       │  volets + chauffage  │
       └──────────────────────┘

       ┌──────────────────────┐
       │       deCONZ         │
       │  (passerelle Zigbee) │
       │  port 9102 / 9143    │
       └──────────┬───────────┘
                  │ plugin Domoticz-deCONZ
       ┌──────────▼───────────┐
       │       Domoticz       │
       │   (capteurs Zigbee)  │
       └──────────────────────┘
```

### Accès réseau à Domoticz

| Chemin | URL / Port exposé | Protocole | Filtrage | Cible |
|---|---|---|---|---|
| Accès externe public | `https://domatique.freeboxos.fr:38243/` → Pi `:8243` | HTTPS (TLS terminé par Apache) | Auth déléguée à Domoticz | Domoticz `:8443` |
| Accès local LAN | `:8280` | HTTP | Aucun (`Require all granted`) + CORS `*` | Domoticz `:8080` |
| Direct interne | `:8080` | HTTP | Réseau Docker uniquement | — |
| Direct interne TLS | `:8443` | HTTPS | Réseau Docker uniquement | — |

Le **proxy httpd** est le seul point d'entrée depuis l'extérieur. Il assure :
- la terminaison TLS avec un certificat auto-signé embarqué dans l'image Docker, aligné sur `domatique.freeboxos.fr` (CN/SAN),
- la transmission transparente vers Domoticz — **l'authentification est déléguée à Domoticz** (login natif),
- la réécriture des headers CORS sur le VirtualHost local (`:8280`).

Le **routeur Freebox** assure le NAT : le port public `38243` est redirigé vers le port `8243` du Raspberry Pi sur le LAN.

> Voir [`_docker/build_httpd/README.md`](_docker/build_httpd/README.md) pour le détail de la configuration Apache.

## Composants

| Composant | Rôle | Technologie |
|---|---|---|
| [`domoticz/`](domoticz/README.md) | Moteur d'automatisation + scripts Lua dzVents | Domoticz + dzVents |
| [`tydom-bridge/`](tydom-bridge/README.md) | Pont Domoticz ↔ box Tydom (Delta Dore) — volets et thermostat | Node.js 26 (ARM64) |
| [`deCONZ/`](deCONZ/README.md) | Intégration des capteurs Zigbee via passerelle deCONZ | deCONZ (Phoscon) |
| Plugin Linky ([fork `vzwingma/DomoticzLinky`](https://github.com/vzwingma/DomoticzLinky), [rétrodoc](https://github.com/vzwingma/DomoticzLinky/blob/master/docs/RETROCONCEPTION.md)) | Plugin Python Domoticz : consommation / production du compteur Linky (Enedis, via proxy tiers). Embarqué dans l'image Domoticz par la CI (aujourd'hui depuis l'upstream `guillaumezin/DomoticzLinky`, branche `master` non épinglée) — voir [`docs/ARCHITECTURE.md` § 5.4](docs/ARCHITECTURE.md#54-plugins-python-domoticz-linky-deconz) | Python 3 (plugin Domoticz) |
| [`_docker/build_httpd/`](_docker/build_httpd/README.md) | Proxy Apache frontal : TLS, filtrage User-Agent, deux VirtualHosts | Apache 2.4 (Alpine) |
| [`_docker/`](_docker/build_domoticz/README.md) | Images Docker custom et manifests de déploiement | Docker Compose |

## Prérequis

- **Docker** et **Docker Compose** (déploiement recommandé sur Raspberry Pi)
- **Node.js ≥ 20** (pour tydom-bridge — `tydom-client@0.15.x` utilise `fetch` natif)
- **Architecture ARM** (Raspberry Pi) ou **amd64** selon les images utilisées

## Déploiement rapide

```bash
# Cloner le dépôt
git clone https://github.com/vzwingma/domotique.git
cd domotique/_docker/envs/nas   # ou envs/pi pour deCONZ

# Variables du bridge Tydom : déclarées dans stack.env (lu via env_file par le
# service tydom-bridge du compose NAS ; elles ne sont pas dans domotique-compose.yml).
# stack.env les référence sous forme de placeholders `${NOM}` : fournir leurs valeurs
# via l'environnement de déploiement ou en les renseignant dans stack.env (sans le commiter) :
#   MAC, PASSWD, AUTHAPI, PASSWDAPI pour le bridge Tydom

# Démarrer la stack complète
docker compose -f domotique-compose.yml up -d
```

> **Watchtower** : mentionné comme mécanisme de mise à jour automatique des images, mais **aucun service Watchtower n'est défini** dans les fichiers compose versionnés (`_docker/envs/nas`, `_docker/envs/pi`). À déployer séparément si souhaité.

## CI/CD

### DomoticZ

Lien vers le wiki : https://github.com/vzwingma/domotique/wiki/

[![Build Domoticz ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-domoticz.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-domoticz.yml)

### Passerelle TYDOM

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=tydom_bridge&metric=alert_status)](https://sonarcloud.io/dashboard?id=tydom_bridge)
[![CodeQL](https://github.com/vzwingma/domotique/actions/workflows/codeql-analysis.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/codeql-analysis.yml)

[![Build Tydom Bridge ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/actions/workflows/build-tydom.yml)

### Proxy HTTPD

[![Build httpd ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-httpd.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/blob/master/.github/workflows/build-httpd.yml)

## Documentation

- [Wiki du projet](https://github.com/vzwingma/domotique/wiki/)
- [dzVents — Orchestration technique](docs/Orchestration.md)
- [dzVents — Rétroconception technique](docs/Retroconception.md)
- [tydom-bridge — README détaillé](tydom-bridge/README.md)
- [domoticz — Scripts dzVents](domoticz/README.md)
- [deCONZ — Capteurs Zigbee](deCONZ/README.md)
- [Plugins Python Domoticz (Linky, deCONZ) — Architecture](docs/ARCHITECTURE.md#54-plugins-python-domoticz-linky-deconz)
- [Plugin Linky — Rétroconception technique (fork)](https://github.com/vzwingma/DomoticzLinky/blob/master/docs/RETROCONCEPTION.md)
- [Docker — Image Domoticz](_docker/build_domoticz/README.md)
- [Docker — Proxy httpd](_docker/build_httpd/README.md)
