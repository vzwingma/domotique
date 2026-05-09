# Retroconception technique dzVents

## Perimetre

Cette retroconception couvre le sous-systeme `domoticz\scripts\dzVents` et ses interactions avec :

- objets Domoticz (devices, groupes, scenes, variables utilisateur),
- integration Freebox,
- integration Tydom.

## Structure fonctionnelle reconstituee

Le systeme est organise en couches implicites :

1. **Socle** (`global_data.lua`, `global_HTTP_response.lua`, `Config_check.lua`, `Health_check_dzVents.lua`)
2. **Integrations externes** (`Freebox_*`, `Tydom_*`)
3. **Metier** (`Device_*`, `Devices_*`)
4. **Composite** (`Groupes_*`)
5. **Scenario** (`Scene_*`)

Le couplage principal est porte par `global_data.lua` (constantes, helpers, wrappers HTTP, table `TYDOM_DEVICES`, etat global `scenePhase`).

## Inventaire technique des scripts

| Famille | Scripts | Responsabilite |
|---|---|---|
| Socle | `global_data.lua` | Helpers partages, etat global, IDs Tydom centralises |
| Socle | `global_HTTP_response.lua` | Callback HTTP generique et logs de reponse |
| Socle | `Config_check.lua` | Verification des pre-requis Domoticz au boot |
| Socle | `Health_check_dzVents.lua` | Controle quotidien d'etat (phase, Freebox, Tydom) |
| Freebox | `Freebox_login.lua`, `Freebox_statut.lua`, `Freebox_LAN_statuts.lua` | Session Freebox, supervision WAN/LAN, detection presence telephones |
| Tydom | `Tydom_heat_*`, `Tydom_volets_*`, `Tydom_refresh_values.lua` | Pilotage thermostat/volets et reconciliation etat reel |
| Metier | `Device_*`, `Devices_*` | Presence, mode domicile, label phase, lampes, ouvertures, capteurs |
| Groupes | `Groupes_Lampes.lua`, `Groupes_Volets.lua` | Synchronisation groupe -> items |
| Scenes | `Scene_0_*` ... `Scene_4_*` | Sequencement journalier et emission `Scene Phase` |

## Mecanismes d'activation

### Timers

- `Freebox_login.lua` : toutes les minutes
- `Tydom_heat_getTemp.lua` : toutes les heures
- `Tydom_volets_getPosition.lua` : toutes les 30 min
- `Tydom_refresh_values.lua` : toutes les 12 min
- `Devices_Lampes.lua` : 30 min apres lever de soleil
- `Health_check_dzVents.lua` : 08:00 quotidien

### Evenements et callbacks

- Entrees : changements devices, scenes, evenements personnalises, reponses HTTP/shell
- Bus interne : `Scene Phase`, `Presence Domicile`, `Scenario Nuit`, `Supervision Ouverture`, `freebox_*session`

## Etats et configuration critiques

### `scenePhase`

Machine d'etat implicite :

1. valeur initiale `nil`,
2. restauration au `systemStart` depuis le device `Phase` si valeur valide,
3. fallback explicite `'Inconnue'` sinon,
4. mise a jour nominale a chaque `Scene Phase`.

Consigne de robustesse : tous les consommateurs doivent tolerer `'Inconnue'` et les logs de variables potentiellement `nil` passent par `tostring(...)`.

### Configuration Tydom

- `TYDOM_DEVICES` dans `global_data.lua` est la **source de verite unique** des `deviceId`/`endpointId`.
- Thermostat : URI construite via `getTydomHeatURI(domoticz)`.
- Volets : mappings via `getTydomDeviceNumberFromDzItem` et `getDzItemFromTydomDeviceId`.

### Prerequis Domoticz

`Config_check.lua` verifie au boot la presence des elements critiques :

- devices,
- groupes,
- scenes,
- variables utilisateur.

Le script journalise les ecarts sans bloquer l'execution globale.

## Flux metier reconstitues

### Flux presence

`Freebox_LAN_statuts` -> `Devices_Telephones` -> `Device_Presence_Domicile` -> rejeu scene + adaptation chauffage/lampes.

### Flux phase

`Scene_*` -> event `Scene Phase` -> `Device_Label_Scene_Phase` -> `scenePhase` + device `Phase` -> consommateurs metier.

### Flux chauffage Tydom

Decision metier (scene/presence) -> update setpoint Domoticz -> `Tydom_heat_setPoint` (PUT) -> `Tydom_heat_getTemp` (polling) -> reconciliation.

### Flux volets Tydom

Commande scene/groupe -> `Tydom_volets_setPosition` -> realignement groupes via helper central -> `Tydom_volets_getPosition` (polling) -> reconciliation.

### Flux Freebox

`Freebox_login` (challenge/session) -> `freebox_session` -> lecture WAN/LAN -> `freebox_endsession`.

## Couplages et risques techniques

### Couplages

- Couplage fort aux noms Domoticz (devices/groupes/scenes/variables)
- Couplage transversal a `global_data.lua`
- Couplage infra a OpenSSL/shell et disponibilite reseau Freebox/Tydom

### Risques encore sensibles

- Defaillance d'integration externe (latence, indisponibilite)
- Desynchronisation ponctuelle Domoticz vs etat terrain
- Regressions sur la propagation `uuid` en cas de refactoring

## Correctifs majeurs deja integres (historique)

### DEV-1 (bugs confirms)

- `nil`/`null` corrige sur Tydom Heat
- suppression globale implicite (`suffixeMode`)
- correction suivi `previousMode`
- correction stockage/comparaison presence (`levelName`)
- emission `Scene Phase` uniformisee (plus d'ecriture directe `scenePhase`)

### DEV-2 (boot `scenePhase`)

- restauration au `systemStart`
- fallback `'Inconnue'`
- logs robustes via `tostring(...)`

### DEV-4 (decouplage configuration)

- centralisation `TYDOM_DEVICES`
- helper `getTydomHeatURI`
- ajout `Config_check.lua`

### DEV-5 (factorisation et observabilite)

- helper unique `verifyGroupeFromItem(...)`
- realignements groupes homogenises
- ajout `Health_check_dzVents.lua`
- standardisation des logs (`marker`, `uuid`, niveaux)

## Regles de maintenance

- Ne pas hardcoder les IDs Tydom.
- Ne pas contourner `verifyGroupeFromItem(...)` pour les realignements.
- Ne pas supprimer le trigger `systemStart` de `Device_Label_Scene_Phase.lua`.
- Si nouvelle phase `Scene_*`, l'ajouter dans la table des phases valides.

