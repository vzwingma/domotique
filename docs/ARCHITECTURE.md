# Architecture — Système domotique Domoticz / dzVents

> Document de référence architecture. Dernière mise à jour : juin 2026.

---

## 1. Vue d'ensemble

Le système domotique repose sur **Domoticz** comme plateforme centrale, avec des scripts d'automatisation écrits en **dzVents (Lua)**. Deux intégrations externes matérielles sont pilotées via des bridges HTTP. L'accès distant passe par un **proxy Apache HTTPD** avec terminaison TLS, exposé via le NAT de la Freebox.

### 1.1 Flux réseau complet (Internet → Domoticz)

```
  https://domatique.freeboxos.fr:38243/
          │  DNS Free → IP publique domicile
          ▼
  ┌─────────────────────────────────────┐
  │  Freebox (routeur FAI)              │
  │  NAT : 38243 public → 8243 Pi LAN  │
  └───────────────┬─────────────────────┘
                  │ HTTPS :8243
                  ▼
  ┌─────────────────────────────────────┐
  │  httpd-proxy (Apache 2.4)           │
  │  VHost :8243 — TLS termination      │
  │  Certificat auto-signé              │
  │  SSLProxy → Domoticz :8443          │
  └───────────────┬─────────────────────┘
                  │ HTTPS (SSLProxy)
                  ▼
  ┌─────────────────────────────────────┐
  │  Domoticz :8443 (HTTPS interne)     │
  │  Auth native (login Domoticz)       │
  └─────────────────────────────────────┘
```

### 1.2 Scripts dzVents — Couches applicatives

```
┌─────────────────────────────────────────────────────────┐
│                      Domoticz                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  global_*    │  │  Scene_*     │  │  Device_*    │  │
│  │  (socle)     │  │  (orchestr.) │  │  (métier)    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Freebox_*   │  │  Tydom_*     │  │  JoursFeries_│  │
│  │  (présence)  │  │  (volets/    │  │  (API gouv.) │  │
│  │              │  │   chauffage) │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└───────────────────┬──────────────────────┬──────────────┘
                    │                      │
          ┌─────────▼──────┐   ┌──────────▼──────┐
          │  Tydom Bridge  │   │  Freebox API    │
          │  (volets,      │   │  (LAN, WAN,     │
          │   thermostat)  │   │   présence)     │
          └────────────────┘   └─────────────────┘
```

**Intégrations externes :**

| Intégration | Rôle | Protocole |
|---|---|---|
| **Tydom Bridge** | Pilotage volets + thermostat Delta Dore | HTTP REST local |
| **Freebox** | Détection présence réseau (smartphones) | HTTP REST local |
| **API Jours Fériés** | Calendrier officiel des jours fériés français | HTTPS REST public |

---

## 1bis. Point d'entrée externe et gestion des certificats TLS

### Accès distant

L'accès depuis Internet passe par :

| Étape | Composant | Détail |
|---|---|---|
| DNS public | `domatique.freeboxos.fr` | Domaine Free/Freebox pointant sur l'IP publique du domicile |
| Port externe | `38243` | Port exposé sur Internet via règle NAT Freebox |
| NAT Freebox | Freebox (routeur FAI) | Redirige `38243` → `8243` sur le Raspberry Pi (LAN) |
| Proxy Apache | `httpd-proxy` (container Docker) | Écoute `:8243`, termine TLS, SSLProxy vers Domoticz `:8443` |
| Backend Domoticz | `domoticz` (container Docker) | Auth native Domoticz, écoute `:8443` |

URL d'accès : **`https://domatique.freeboxos.fr:38243/`**

### Gestion du certificat TLS

| Propriété | Valeur |
|---|---|
| Type | Certificat **auto-signé** (self-signed) |
| Algorithme | RSA |
| Emplacement dans l'image | `/usr/local/apache2/conf/ssl_conf/httpddomoticzserver.crt` + `.key` |
| Intégration | Embarqué dans l'image Docker lors du build (`COPY` dans le Dockerfile) |
| Renouvellement | **Manuel** — régénérer le certificat puis rebuilder/republier l'image via CI/CD |

**Pipeline CI/CD :**
- Le `ServerName` Apache est injecté depuis le secret GitHub `SERVER_NAME` lors du build (`__SERVER_NAME__` remplacé dans `httpd.conf`)
- Le certificat et la clé sont stockés dans `_docker/build_httpd/certs/` et copiés dans l'image
- L'image est reconstruite et publiée automatiquement sur push `master` (workflow `build-httpd.yml`)

**Vérification côté proxy (SSLProxy) :**

La vérification du certificat Domoticz (auto-signé) est désactivée côté Apache :

```apache
SSLProxyVerify none
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
SSLProxyCheckPeerExpire off
```

> ⚠️ Le certificat auto-signé génère un avertissement dans les navigateurs. Il n'y a pas de renouvellement automatique (pas de Let's Encrypt / ACME). À surveiller lors de l'expiration.

---

## 2. Couches applicatives

L'architecture est organisée implicitement en cinq familles de scripts dzVents.

### 2.1 `global_*` — Socle partagé

| Script | Rôle |
|---|---|
| `global_data.lua` | Constantes de nommage Domoticz, helpers métier, wrappers HTTP Tydom/Freebox, état partagé (`scenePhase`, `joursFeries`), table `TYDOM_DEVICES` (source de vérité unique des identifiants Tydom) |
| `global_HTTP_response.lua` | Callback HTTP générique — journalisation succès/erreurs |

**Helpers clés** (accessibles via `domoticz.helpers.*`) :

| Helper | Description |
|---|---|
| `uuid()` | UUID v4 pour la corrélation des logs et headers HTTP |
| `isJourFerie(domoticz)` | Vérifie si la date du jour est un jour férié (lookup dans `globalData.joursFeries`) ; déclenche `JoursFeries Refresh` si la liste est vide |
| `getLevelFromState(item)` | Niveau d'un device : `item.level` (dimmer), `100` (On), `0` (Off) |
| `verifyGroupeFromItem(groupe, items, uuid, domoticz)` | Réalignement état groupe ↔ items unitaires |
| `callTydomBridgeGET(path, uuid, domoticz)` | GET authentifié vers le bridge Tydom |
| `callTydomBridgePUT(path, data, uuid, cb, domoticz)` | PUT authentifié vers le bridge Tydom |
| `getTydomDeviceNumberFromDzItem(name, domoticz)` | Retourne `{ deviceId, endpointId }` Tydom depuis le nom Domoticz |
| `JOURS_FERIES_API_URL` | Constante URL de base de l'API `calendrier.api.gouv.fr` |

### 2.2 `Device_*` / `Devices_*` — Logique métier événementielle

Scripts réagissant aux changements de devices Domoticz ou aux événements internes :

| Script | Rôle |
|---|---|
| `Device_Mode_Domicile.lua` | Gestion du mode Normal / Vacances / Été |
| `Device_Presence_Domicile.lua` | Conversion présence téléphones → présence domicile ; rejeu de scène |
| `Device_Label_Scene_Phase.lua` | Mise à jour de la phase courante (`globalData.scenePhase`) et restauration au démarrage |
| `Devices_Telephones.lua` | Debounce du nombre de téléphones connectés |
| `Devices_TempHumidity.lua` | Agrégation température/humidité multi-capteurs |
| `Devices_Lampes.lua` | Gestion éclairage selon présence, phase de nuit et lever du soleil |
| `Devices_Lampes_Groupe.lua` | Réalignement groupes de lampes |
| `Devices_Ouvertures.lua` | Supervision ouverture prolongée (porte/fenêtre) avec alertes croissantes |
| `Supervision_IoT_devices.lua` | Contrôle batterie et fraîcheur des équipements IoT |

### 2.3 `Groupes_*` — Synchronisation groupes ↔ items

| Script | Rôle |
|---|---|
| `Groupes_Lampes.lua` | Cascade groupe → lampes unitaires |
| `Groupes_Volets.lua` | Cascade groupe → volets unitaires |

### 2.4 `Scene_*` — Orchestration des phases quotidiennes

| Script | Phase | Heure semaine | Heure week-end / férié |
|---|---|---|---|
| `Scene_0_PreparationChauffage.lua` | PreparationChauffage | 7h00 | 8h00 |
| `Scene_1_Reveil.lua` | Reveil | 7h45 | 9h50 |
| `Scene_2a_Journee.lua` | Journee (mode Normal) | 8h05 | 10h00 |
| `Scene_2b_Journee_Ete.lua` | Journee Ete | 10h00 | 10h00 |
| `Scene_2c_Journee_Vacs.lua` | Journee Vacs | 10h00 | 10h00 |
| `Scene_3_Soiree.lua` | Soiree | coucher du soleil +45 min | idem |
| `Scene_4_Nuit.lua` | Nuit | — | — |
| `Scene_4_Nuit_2.lua` | Nuit 2 | 1h00 | 3h00 |

Chaque script `Scene_*` émet systématiquement un événement `Scene Phase` pour mettre à jour `globalData.scenePhase` et le device texte `Phase`.

### 2.5 `Freebox_*`, `Tydom_*`, `JoursFeries_*` — Intégrations externes

| Script | Rôle |
|---|---|
| `Freebox_login.lua` | Authentification Freebox (HMAC via shell `openssl`) et gestion de session |
| `Freebox_statut.lua` | Supervision WAN Freebox |
| `Freebox_LAN_statuts.lua` | Supervision LAN et détection smartphones |
| `Tydom_heat_getTemp.lua` | Lecture température et consigne thermostat |
| `Tydom_heat_setPoint.lua` | Envoi consigne thermostat (PUT) |
| `Tydom_volets_getPosition.lua` | Récupération périodique des positions réelles des volets |
| `Tydom_volets_setPosition.lua` | Envoi position volet et réalignement groupes |
| `Tydom_refresh_values.lua` | Forçage refresh Tydom (`POST /refresh/all`) |
| `JoursFeries_API.lua` | Chargement des jours fériés depuis `calendrier.api.gouv.fr` |

---

## 3. Orchestration des scènes — Cycle journalier

### 3.1 Séquence nominale

```
00:05 / 1er janv.  ──► JoursFeries_API ──► globalData.joursFeries
       ↓
07:00 (sem) / 08:00 (WE/férié)
       ├──► Scene_0_PreparationChauffage
       │       └──► Thermostat consigne matin
       ↓
07:45 (sem) / 09:50 (WE/férié)
       ├──► Scene_1_Reveil
       │       └──► Volet chambre ouverture partielle
       ↓
08:05 (sem) / 10:00 (WE/férié)
       ├──► Scene_2a_Journee  [mode Normal]
       │       └──► Volets ouverts + thermostat
       ├── ou Scene_2b_Journee_Ete  [mode Été]
       └── ou Scene_2c_Journee_Vacs  [mode Vacances]
       ↓
coucher soleil +45 min
       ├──► Scene_3_Soiree
       │       ├──► Fermeture volets (individuelle, au max)
       │       └──► Lampe salon allumée si présence
       ↓
01:00 (sem) / 03:00 (WE)
       └──► Scene_4_Nuit_2
               ├──► Thermostat nuit
               └──► Extinction lumières
```

### 3.2 Logique jours fériés

Les scènes 0, 1 et 2a ont deux horaires planifiés dans Domoticz :

- **Slot tôt** (7h00, 7h45, 8h05) : déclenché en semaine → ignoré si `isJourFerie(domoticz) == true`
- **Slot tardif** (8h00, 9h50, 10h00) : déclenché le week-end → exécuté aussi si `isJourFerie(domoticz) == true`

> ⚠️ **Action manuelle Domoticz requise** : il faut ajouter dans le planificateur Domoticz un **3e déclenchement lun-ven** (à l'heure tardive) pour chaque scène concernée :
>
> | Scène | 3e déclenchement à ajouter |
> |---|---|
> | PreparationChauffage | lun-ven 08:00 |
> | Reveil | lun-ven 09:50 |
> | Journee | lun-ven 10:00 |
>
> Sans ce 3e slot, les jours fériés tombant un jour de semaine ne déclenchent pas la version "tardive" de la scène.

---

## 4. Gestion de l'état partagé

### 4.1 `globalData.scenePhase`

Défini dans `global_data.lua` (`data = { scenePhase = { initial = nil } }`), alimenté par `Device_Label_Scene_Phase.lua`.

**Cycle de vie :**

1. `nil` à l'initialisation du module.
2. **Restauration au boot** (`systemStart`) : lecture du device texte `Phase` → si valeur reconnue (`PreparationChauffage`, `Reveil`, `Journee`, `Journee Ete`, `Journee Vacs`, `Soiree`, `Nuit`, `Nuit 2`), restauration ; sinon `'Inconnue'`.
3. **Mise à jour nominale** : à chaque événement `Scene Phase`, la valeur est écrasée.

Consommé par : `getMomentJournee`, `Device_Presence_Domicile.lua`, `Devices_Lampes.lua`.

### 4.2 `globalData.joursFeries`

Défini dans `global_data.lua` (`data = { joursFeries = { initial = {} } }`), alimenté par `JoursFeries_API.lua`.

**Structure :**
```lua
-- { ['2025-01-01'] = true, ['2025-05-01'] = true, ... }
domoticz.globalData.joursFeries
```

**Cycle de vie :**
1. Table vide `{}` à l'initialisation.
2. **Chargement annuel** : timer `at 00:05 on 1/1` → GET `calendrier.api.gouv.fr/jours-feries/metropole/{année}.json`.
3. **Failsafe mensuel** : timer `at 00:10 on 1` (1er de chaque mois) → rechargement si liste vide après redémarrage.
4. **On-demand** : événement `JoursFeries Refresh` émis par `isJourFerie()` si liste vide au moment de la vérification, ou par le health check.

Consommé par : `domoticz.helpers.isJourFerie(domoticz)` (dans `global_data.lua`), `Health_check_dzVents.lua`.

---

## 5. Composants d'intégration

### 5.1 Tydom Bridge (volets + chauffage)

Le **Tydom Bridge** est un service HTTP local qui traduit les commandes REST en protocole Tydom Delta Dore.

**Flux chauffage :**
```
Scène / Présence → Tydom Thermostat (device Domoticz)
    → Tydom_heat_setPoint.lua → PUT /heat/setpoint
    → Tydom_heat_getTemp.lua (timer horaire) → GET → réalignement
```

**Flux volets :**
```
Scène / Groupe → volet device Domoticz
    → Tydom_volets_setPosition.lua → PUT /volets/position
    → Tydom_volets_getPosition.lua (timer 30 min) → GET → réalignement
```

**Configuration :** identifiants Tydom centralisés dans `TYDOM_DEVICES` de `global_data.lua`. Variables Domoticz : `tydom_bridge_host`, `tydom_bridge_auth`.

### 5.2 Freebox (présence réseau)

La Freebox expose une API locale pour superviser les équipements connectés au LAN.

**Flux d'authentification :**
```
timer 1 min → Freebox_login.lua → /login (challenge)
    → shell openssl HMAC → /login/session → token
    → event freebox_session
    → Freebox_statut.lua + Freebox_LAN_statuts.lua
```

**Détection présence :**
```
Freebox_LAN_statuts → nb smartphones → Equipements Personnels (device)
    → Devices_Telephones.lua (debounce) → event Presence Domicile
    → Device_Presence_Domicile.lua → Présence (device) + rejeu scène
```

**Configuration :** Variables Domoticz : `freebox_host`, `freebox_apptoken`, `livebox_devices`.

### 5.3 API Jours Fériés (calendrier.api.gouv.fr)

API publique officielle du gouvernement français listant les jours fériés en métropole.

**URL :** `https://calendrier.api.gouv.fr/jours-feries/metropole/{année}.json`

**Format de réponse :**
```json
{
  "2025-01-01": "1er janvier",
  "2025-05-01": "Fête du Travail",
  ...
}
```

**Intégration :** `JoursFeries_API.lua` transforme ce dictionnaire en table de lookup Lua `{ ['2025-01-01'] = true, ... }` stockée dans `globalData.joursFeries`. Le helper `isJourFerie(domoticz)` effectue la consultation et déclenche un rechargement automatique si la liste est vide.

---

## 6. Supervision et observabilité

### 6.1 Config_check.lua (boot)

Déclenché au `systemStart`. Vérifie la présence de tous les devices, groupes, scènes et variables critiques. Émet `LOG_ERROR` par prérequis absent — purement informatif, n'interrompt aucun flux.

### 6.2 Health_check_dzVents.lua (quotidien, 08:00)

Contrôle quotidien de **5 indicateurs de santé** :

| # | Indicateur | Seuil |
|---|---|---|
| 1 | `scenePhase` | Valeur exploitable (pas `nil` ni `'Inconnue'` > 25h) |
| 2 | Device `Phase` | Dernière mise à jour < 25 heures |
| 3 | Device `Freebox` | Dernière mise à jour < 10 minutes |
| 4 | Device `Tydom Temperature` | Dernière mise à jour < 90 minutes |
| 5 | `globalData.joursFeries` | Liste non vide ; déclenche `JoursFeries Refresh` sinon |

En cas d'indicateur dégradé : `LOG_ERROR` + notification Signal. Si tout est nominal : `LOG_INFO` de synthèse.

---

## 7. Bus d'événements internes

Les scripts communiquent via des événements Domoticz personnalisés (`emitEvent` / `customEvents`) :

| Événement | Émetteur | Récepteur(s) |
|---|---|---|
| `Scene Phase` | Tous les scripts `Scene_*` | `Device_Label_Scene_Phase.lua` |
| `Presence Domicile` | `Devices_Telephones.lua` | `Device_Presence_Domicile.lua`, `Devices_Lampes.lua` |
| `Scenario Nuit` | `Scene_4_Nuit.lua`, `Scene_4_Nuit_2.lua` | `Devices_Lampes.lua` |
| `Supervision Ouverture` | `Devices_Ouvertures.lua` | `Devices_Ouvertures.lua` (auto) |
| `freebox_initsession` | Divers | `Freebox_login.lua` |
| `freebox_session` | `Freebox_login.lua` | `Freebox_statut.lua`, `Freebox_LAN_statuts.lua` |
| `freebox_endsession` | `Freebox_LAN_statuts.lua` | `Freebox_login.lua` |
| `JoursFeries Refresh` | `isJourFerie()`, `Health_check_dzVents.lua` | `JoursFeries_API.lua` |

---

## 8. Conventions de nommage

| Préfixe | Famille | Rôle |
|---|---|---|
| `global_*` | Socle | Constantes, helpers, état partagé |
| `Device_*` | Métier device | Logique sur un device métier spécifique |
| `Devices_*` | Métier famille | Logique transverse sur une famille de devices |
| `Groupes_*` | Groupes | Synchronisation groupe ↔ items unitaires |
| `Scene_<N>_*` | Orchestration | Scène chronologique de la journée (N = ordre) |
| `Freebox_*` | Intégration | Présence réseau via Freebox |
| `Tydom_*` | Intégration | Volets et chauffage via bridge Tydom |
| `JoursFeries_*` | Intégration | Calendrier jours fériés via API gouvernementale |

Convention de traçabilité : chaque traitement utilise un `uuid` (v4) propagé dans les logs, événements et headers HTTP (`X-CorrId`) pour corréler les flux asynchrones.
