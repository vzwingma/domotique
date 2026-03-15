# deCONZ — Intégration des capteurs Zigbee

Composant de la stack domotique gérant la passerelle Zigbee **deCONZ** (firmware Phoscon / RaspBee). Il assure la communication entre les capteurs et actionneurs Zigbee et Domoticz via un plugin dédié.

---

## Rôle dans la stack

```
Capteurs/actionneurs Zigbee
         │  (protocole Zigbee)
         ▼
   [deCONZ / Phoscon]  ←→  Interface web Phoscon (port 9102)
         │  (plugin Domoticz-deCONZ)
         ▼
      Domoticz
```

deCONZ tourne en tant que conteneur Docker et expose :
- **Port 9102** : interface web Phoscon (configuration, appairage des capteurs)
- **Port 9143** : WebSocket (pour l'intégration temps réel avec le plugin Domoticz)

---

## Déploiement Docker

Le service deCONZ est déclaré dans `_docker/domotique-compose.yml` :

```yaml
deconz:
  image: deconzcommunity/deconz:latest
  ports:
    - 9102:9102    # Interface web Phoscon
    - 9143:9143    # WebSocket
  environment:
    - DECONZ_WS_PORT=9143
    - DECONZ_WEB_PORT=9102
  devices:
    - /dev/ttyAMA0:/dev/ttyAMA0   # RaspBee (UART Raspberry Pi)
  volumes:
    - /etc/timezone:/etc/timezone:ro
    - /etc/localtime:/etc/localtime:ro
    - /home/pi/appli/deCONZ:/opt/deCONZ   # Persistance config et BDD réseau Zigbee
  restart: always
```

Le volume `/home/pi/appli/deCONZ` (monté sur `/opt/deCONZ` dans le conteneur) contient :
- `config.ini` — configuration deCONZ (contrôleur, HTTP, réseau Zigbee)
- `zll.db` — base de données SQLite du réseau Zigbee (nœuds, groupes, scènes)
- `zcldb.txt` — base de données ZCL (Zigbee Cluster Library)

---

## Intégration avec Domoticz

Le plugin **Domoticz-deCONZ** est installé directement dans l'image Docker de Domoticz
(voir `_docker/build_domoticz/Dockerfile`).

Il se connecte à deCONZ via le WebSocket (port 9143) pour recevoir les événements Zigbee en temps réel
et expose les capteurs/actionneurs comme devices Domoticz natifs.

### Configuration du plugin dans Domoticz

Dans le panneau **Configuration → Hardware** de Domoticz :
- Type : `deCONZ`
- Remote Address : `deconz` (nom du service Docker) ou adresse IP
- Port : `9102`
- WebSocket port : `9143`

---

## Configuration deCONZ (`config.ini`)

Paramètres clés du fichier de configuration :

| Section | Paramètre | Valeur | Description |
|---|---|---|---|
| `[http]` | `port` | `9102` | Port de l'interface web Phoscon |
| `[controller]` | `apsAcksEnabled` | `false` | Acquittements APS désactivés |
| `[discovery]` | `zdp\mgmtLqiInterval` | `180` | Intervalle de scan LQI (qualité signal) |
| `[remote]` | `default\ip` | `127.0.0.1` | Adresse de Domoticz pour la liaison retour |
| `[remote]` | `default\port` | `8080` | Port de Domoticz |

---

## Accès à l'interface Phoscon

```
http://<IP_RASPBERRYPI>:9102
```

L'interface Phoscon permet :
- L'appairage de nouveaux capteurs Zigbee
- La visualisation du réseau Zigbee (carte des nœuds)
- La gestion des groupes et scènes Zigbee
- La mise à jour OTA des firmwares des équipements

---

## Remarques

- Le fichier `zll.db` contient l'état complet du réseau Zigbee — **toujours inclure ce fichier dans les sauvegardes**.
- En cas de remplacement du RaspBee, le réseau Zigbee doit être recréé (réappairage de tous les capteurs).
- Le contrôleur Zigbee est accessible via `/dev/ttyAMA0` (UART Raspberry Pi) — ce device doit être disponible sur l'hôte.