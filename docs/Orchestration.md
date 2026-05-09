# Orchestration technique dzVents

## Objectif

Ce document décrit l'orchestration **runtime** des scripts `domoticz\scripts\dzVents` : couches logiques, bus d'evenements, et flux inter-scripts qui pilotent presence, scenes, chauffage, volets et supervision.

## Architecture en couches

```text
COUCHE SCENARIO
  Scene_0..Scene_4_Nuit_2 -> emettent "Scene Phase"

COUCHE METIER
  Device_Mode_Domicile
  Device_Presence_Domicile
  Device_Label_Scene_Phase
  Devices_Telephones
  Devices_Lampes
  Devices_Ouvertures
  Devices_TempHumidity

COUCHE CONTROLE COMPOSITE
  Groupes_Lampes
  Groupes_Volets

COUCHE INTEGRATION EXTERNE
  Freebox_login / Freebox_statut / Freebox_LAN_statuts
  Tydom_heat_* / Tydom_volets_* / Tydom_refresh_values

COUCHE SOCLE
  global_data.lua
  global_HTTP_response.lua
  Config_check.lua
  Health_check_dzVents.lua
```

## Bus d'evenements interne

Evenements personnalisés principaux :

- `Scene Phase`
- `Presence Domicile`
- `Scenario Nuit`
- `Supervision Ouverture`
- `freebox_initsession`
- `freebox_session`
- `freebox_endsession`

La diffusion des contextes metier est evenementielle : chaque script publie ou consomme ces evenements, sans orchestration centralisee unique.

## Etat partage critique

Le point central est `domoticz.globalData.scenePhase`, alimente par `Device_Label_Scene_Phase.lua`.

Cycle de vie :

1. Initialisation implicite a `nil` dans `global_data.lua`.
2. Au boot (`systemStart`), restauration depuis le device texte `Phase` si la valeur est valide.
3. Fallback a `'Inconnue'` si la valeur est absente/invalide.
4. Ecrasement nominal a chaque evenement `Scene Phase`.

`global_data.lua` est la dependance transversale majeure : constantes, helpers, wrappers HTTP, table `TYDOM_DEVICES` (source de verite unique des IDs Tydom), et helpers de realignement.

## Flux fonctionnels majeurs

### Presence domicile

1. `Freebox_LAN_statuts.lua` compte les telephones connectes.
2. Ecriture dans `Equipements Personnels`.
3. `Devices_Telephones.lua` debounce puis emet `Presence Domicile`.
4. `Device_Presence_Domicile.lua` met a jour `Presence`, rejoue la scene et recalcule le chauffage.
5. `Devices_Lampes.lua` adapte l'eclairage selon presence et phase.

### Phase de journee

1. Une scene `Scene_*` s'exécute.
2. Emission de `Scene Phase`.
3. `Device_Label_Scene_Phase.lua` met a jour `scenePhase` et le device `Phase`.
4. Les scripts metier consomment la phase (chauffage, lampes, rejeux).

### Chauffage Tydom

1. Scene/presence calcule une consigne.
2. Setpoint pousse sur `Tydom Thermostat`.
3. `Tydom_heat_setPoint.lua` envoie le PUT via `getTydomHeatURI(domoticz)`.
4. `Tydom_heat_getTemp.lua` relit periodiquement temperature et consigne.
5. Re-alignement Domoticz <- etat reel Tydom.

### Volets Tydom

1. Scene ou groupe commande les volets.
2. `Tydom_volets_setPosition.lua` traduit le niveau Domoticz vers Tydom.
3. Realignement groupe <- items via `verifyGroupeFromItem(...)`.
4. `Tydom_volets_getPosition.lua` recale periodiquement les niveaux sur l'etat reel.

### Supervision Freebox

1. `Freebox_login.lua` ouvre une session (`/login` puis `/login/session`).
2. Emission de `freebox_session`.
3. `Freebox_statut.lua` et `Freebox_LAN_statuts.lua` lisent WAN/LAN.
4. `freebox_endsession` cloture la session.

## Observabilite et garde-fous

- `Config_check.lua` (boot) verifie pre-requis Domoticz (devices, groupes, scenes, variables) et journalise les manques.
- `Health_check_dzVents.lua` (08:00) controle l'etat global (`scenePhase`, `Phase`, Freebox, Tydom Temperature) et notifie en cas de degradation.
- Convention de logs attendue :
  - `marker` : `"[Domaine] "`
  - message : `"[" .. uuid .. "] " .. message`
  - niveaux : `LOG_DEBUG`, `LOG_INFO`, `LOG_ERROR`
  - toute variable potentiellement `nil` doit etre journalisee via `tostring(...)`.

## Regles de non-regression d'orchestration

- Toutes les scenes doivent emettre `Scene Phase`; ne pas ecrire `globalData.scenePhase` directement.
- Ne jamais hardcoder un `deviceId`/`endpointId` Tydom dans un script metier.
- Utiliser `getTydomHeatURI(domoticz)` pour le thermostat.
- Utiliser `verifyGroupeFromItem(...)` pour tout realignement groupe <- items.

