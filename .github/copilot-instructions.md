# Copilot instructions for `dzVents`

These instructions apply first when working in `domoticz\scripts\dzVents`.

## Scope and source of truth

- Read `.github\tasks\todo\RETROCONCEPTION_dzVents.md` before changing architecture or behavior.
- Read `.github\tasks\todo\PLAN_ACTIONS_dzVents.md` before proposing refactoring or roadmap work.
- Read `domoticz\scripts\dzVents\global_data.lua` before editing any dzVents script because constants, helpers, device names, HTTP wrappers, **Tydom device IDs (`TYDOM_DEVICES`)**, and shared state are centralized there.
- `TYDOM_DEVICES` in `global_data.lua` is the **single source of truth** for all Tydom `deviceId` / `endpointId` values. Never hard-code a Tydom ID in a business script.
- `Config_check.lua` is the authoritative list of Domoticz prerequisites (devices, groups, scenes, user variables). Keep it updated when adding new critical objects to the system.
- If documentation and code diverge, trust the code first, then update documentation in the same change when relevant.

## Architectural rules

- Treat the dzVents folder as an event-driven system built around scenes, devices, groups, custom events, and HTTP callbacks.
- Preserve the role split between:
  - `global_*` scripts for shared helpers and shared state,
  - `Freebox_*` and `Tydom_*` for external integrations,
  - `Device_*` and `Devices_*` for business behavior,
  - `Groupes_*` for group synchronization,
  - `Scene_*` for daily orchestration.
- Keep `domoticz.globalData.scenePhase` coherent across scene-related changes.
- Preserve `uuid` propagation and log correlation across chained events and HTTP calls.

## Work priorities

Until stabilization is complete, prioritize in this order:

1. fix confirmed bugs,
2. secure shared state and scene phase handling,
3. improve HTTP error handling and integration robustness,
4. reduce hard-coded coupling,
5. refactor duplication and improve observability,
6. only then add new features.

## Vigilances DEV-1 — patterns à respecter

Les défauts suivants ont été corrigés dans le lot DEV-1. Ces entrées sont conservées comme règles de non-régression : ne pas réintroduire ces patterns.

- `Tydom_heat_getTemp.lua` : toujours utiliser `nil`, jamais `null` en Lua.
- `global_data.lua` : déclarer systématiquement les variables temporaires avec `local` ; éviter toute variable globale implicite.
- `Device_Mode_Domicile.lua` : mettre à jour `previousMode` en fin de traitement après chaque changement de mode.
- `Device_Presence_Domicile.lua` : comparer et stocker une valeur simple (ex. `levelName`), jamais un objet device.
- `Scene_4_Nuit_2.lua` : toutes les scènes doivent émettre l'événement `Scene Phase` ; ne jamais écrire `globalData.scenePhase` directement.

## Vigilances DEV-2 — initialisation de `scenePhase` au boot

Les points suivants ont été livrés dans le lot DEV-2 et constituent des règles de non-régression.

- `Device_Label_Scene_Phase.lua` écoute `systemStart` en plus de l'événement `Scene Phase`. **Ne pas supprimer ce déclencheur.**
- Au boot, `scenePhase` est restaurée depuis le device texte `Phase` si la valeur est reconnue dans la table `validPhases`. **Si une nouvelle phase est créée dans un script `Scene_*`, l'ajouter obligatoirement à cette table.**
- Si la valeur lue est absente, vide ou non reconnue, `scenePhase` est initialisée à `'Inconnue'`. **Cette valeur est intentionnelle et doit rester tolérée par tous les consommateurs de `scenePhase`.**
- `getMomentJournee` retourne `nil` quand `scenePhase == 'Inconnue'`. **Ce comportement est attendu, pas un bug.**
- `global_data.lua` journalise `moment` via `tostring(moment)`. **Ne jamais journaliser directement une variable pouvant être `nil` : utiliser `tostring()`.**

## Vigilances DEV-4 — centralisation Tydom et prérequis Domoticz

Les points suivants ont été livrés dans le lot DEV-4 et constituent des règles de non-régression.

- `global_data.lua` contient la table `TYDOM_DEVICES` avec les identifiants `deviceId` / `endpointId` de chaque équipement Tydom (thermostat et volets). **Ne jamais écrire un ID Tydom en dur dans un script métier.**
- `getTydomHeatURI(domoticz)` est le helper dédié pour construire l'URI REST du thermostat. **Toujours l'utiliser dans `Tydom_heat_getTemp.lua` et `Tydom_heat_setPoint.lua` ; ne pas reconstruire l'URI manuellement.**
- En cas de remplacement matériel Tydom, **modifier uniquement `TYDOM_DEVICES`** dans `global_data.lua`. Aucun autre script n'est à toucher.
- `Config_check.lua` déclenché au `systemStart` vérifie la présence des devices, groupes, scènes et variables Domoticz critiques. **Tout ajout d'objet Domoticz critique au système doit s'accompagner d'une entrée dans ce script.** Les erreurs émises sont informatives (pas de blocage de flux).

## Vigilances DEV-5 — factorisation des groupes, logs homogènes, health check

Les points suivants ont été livrés dans le lot DEV-5 et constituent des règles de non-régression.

- `global_data.lua` expose le helper `verifyGroupeFromItem(groupe, items, uuid, domoticz)`. **Tout réalignement groupe ← items doit passer par ce helper.** Ne jamais ré-implémenter cette logique localement.
  - Il compare les niveaux des items (via `getLevelFromState`) et réaligne le groupe silencieusement (`.silent()`) si tous les items partagent le même niveau et que le groupe diffère.
  - Il est applicable aux volets comme aux lampes.
- `Groupes_Volets.lua`, `Tydom_volets_setPosition.lua`, `Devices_Lampes_Groupe.lua` utilisent exclusivement `verifyGroupeFromItem`. **Toute modification de hiérarchie de groupes doit mettre à jour les appels dans ces scripts.**
- `Health_check_dzVents.lua` déclenché à 08:00 vérifie quotidiennement quatre indicateurs : `scenePhase` exploitable, device `Phase` < 25 h, Freebox < 5 min, Tydom Temperature < 90 min. **En cas d'ajout d'une intégration critique ou de changement de polling, ajouter ou réviser l'indicateur correspondant dans ce script.**
- Convention de logs à respecter dans tout script dzVents :
  - `marker` : `"[Domaine] "` entre crochets ;
  - format du message : `"[" .. uuid .. "] " .. message` ;
  - niveaux : `LOG_DEBUG` pour le détail technique, `LOG_INFO` pour les résumés nominaux et réalignements effectués, `LOG_ERROR` pour les anomalies et alertes ;
  - **ne jamais journaliser directement une variable pouvant être `nil`** : utiliser `tostring()`.

## Points faibles ouverts à traiter

When you touch the relevant scripts, check these issues:

- `global_HTTP_response.lua`: current behavior is mostly logging only, with limited resilience.
## Editing rules for dzVents scripts

- Make small, surgical changes scoped to one functional flow at a time.
- Do not refactor multiple domains in one change unless necessary to keep behavior correct.
- Before editing a script, identify:
  - its triggers,
  - emitted custom events,
  - devices, scenes, groups, and variables it reads,
  - side effects on Domoticz, Freebox, and Tydom.
- Preserve existing event names unless a migration is explicitly part of the task.
- Do not rename Domoticz devices, groups, scenes, or user variables unless the task explicitly includes a migration plan.
- Do not remove existing `uuid` logging patterns without providing an equivalent traceability mechanism.

## Rules by domain

### Scenes

- Keep phase tracking consistent with `Device_Label_Scene_Phase.lua`.
- Verify impacts on heating, lights, shutters, and presence-driven replays.
- Avoid introducing divergent behavior between equivalent day-phase scenes unless intentional and documented.
- **When adding a new scene phase**, add the phase name to the `validPhases` table in `Device_Label_Scene_Phase.lua` so it is recognized at boot.
- **Never assume `scenePhase` holds a valid business phase**: at boot it can be `'Inconnue'` until a scene runs. All consumers of `scenePhase` must tolerate this value without crashing.

### Presence

- Revalidate the full flow `Freebox_LAN_statuts` -> `Devices_Telephones` -> `Device_Presence_Domicile` -> downstream consumers.
- Be careful with debounce logic and replay side effects.

### Tydom

- Distinguish clearly between write flows and read/reconciliation flows.
- Avoid leaving Domoticz state inconsistent with the real Tydom state.
- **Never hard-code a Tydom `deviceId` or `endpointId` in a script.** Always read from `domoticz.helpers.TYDOM_DEVICES`.
- Use `getTydomHeatURI(domoticz)` for thermostat URI construction.
- Use `getTydomDeviceNumberFromDzItem` / `getDzItemFromTydomDeviceId` for shutter mappings.
- When adding a new Tydom device, add it to `TYDOM_DEVICES` in `global_data.lua` only.

### Freebox

- Preserve the authentication sequence unless the task explicitly redesigns it.
- Treat shell command construction as sensitive.
- Prefer robustness and safety over optimization.

### Groups

- Validate both directions: group to items and items to group.
- Avoid breaking intermediate levels or silent realignment logic.
- **Always use `domoticz.helpers.verifyGroupeFromItem(groupe, items, uuid, domoticz)` for any group ← items realignment.** Never re-implement this logic locally.
- When changing a group hierarchy, update all calls to `verifyGroupeFromItem` in the affected scripts (`Groupes_Volets.lua`, `Tydom_volets_setPosition.lua`, `Devices_Lampes_Groupe.lua`).

## Validation expectations

For dzVents changes, validate at least:

- the direct script behavior,
- the full cross-script flow impacted by the change,
- shared state consistency, especially `scenePhase`,
- logging clarity for the modified path (marker, uuid prefix, correct level),
- group realignment correctness in both directions when groups are involved,
- `Health_check_dzVents.lua` indicators and thresholds when polling or integrations change,
- related documentation when behavior or assumptions change.

## What not to do

- Do not rewrite the whole dzVents architecture in one pass.
- Do not mix bug fixes, new features, and broad refactors in the same change without a clear reason.
- Do not introduce new external dependencies casually.
- Do not assume hard-coded IDs or names are safe to change without checking all dependent scripts.
