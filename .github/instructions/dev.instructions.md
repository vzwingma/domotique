---
description: Spécificités projet domotique pour l'agent 🔵 DEVon (dev)
applyTo: "**"
---

# Spécificités projet — domotique (Dev)

> Fichier auto-lu par agent 🔵 DEVon au démarrage. Contient specs projet `domotique` (dzVents Lua, automatisation événementielle Domoticz, intégrations HTTP Tydom/Freebox).

## Workflow

1. Lire le Plan d'Action validé et les tâches qui te sont assignées.
2. Vérifier dépendances et gate précédent `GO`.
3. Implémenter uniquement le scope assigné; ne pas modifier tests ni documentation.
4. Exécuter les vérifications disponibles pour le composant touché et rendre les preuves dans le handoff.

## Stack technique

- **dzVents (Lua)** – scripts événementiels dans Domoticz
- **Domoticz** – plateforme centrale (auth native, API interne)
- **Tydom Bridge** (HTTP REST local) – volets + chauffage Delta Dore
- **Freebox API** (HTTP REST local) – détection présence réseau
- **API Jours Fériés** (calendrier.api.gouv.fr) – calendrier officiel

## Conventions de code dzVents

### Structure type d'un script

```lua
return {
    on = { triggers = { ... } },
    data = { state = { initial = ... } },
    logging = { level = domoticz.LOG_INFO, marker = "[Domaine] " },
    execute = function(domoticz, item)
        -- logique metier
    end
}
```

### Événements et état

- **Triggers déclaratifs** : `timer`, `devices`, `customEvents`, `httpResponses`, `system`
- **scenePhase** : alimentée **uniquement** via événement `Scene Phase` (jamais écriture directe)
- **Boot** : tolère état `Inconnue` si scenePhase non restaurée ; restauration via `Device_Label_Scene_Phase.lua`
- **État global** : uniquement via `domoticz.globalData` + `domoticz.globalData.joursFeries`

### Appels HTTP et IDs techniques

```lua
-- TOUJOURS passer par helpers centralises
local uuid = domoticz.helpers.uuid()
local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(name, domoticz)
domoticz.helpers.callTydomBridgePUT(path, data, uuid, callback, domoticz)
```

- **Jamais** hard-coder deviceId/endpointId Tydom
- Utiliser helpers : `TYDOM_DEVICES`, `getTydomHeatURI()`, `getTydomDeviceNumberFromDzItem()`, `getTydomBridgeGET()`, `getTydomBridgePUT()`
- **Config centralisée** dans `global_data.lua` uniquement

### Groupes

- Tout réalignement groupe ↔ items doit utiliser `verifyGroupeFromItem(groupe, items, uuid, domoticz)`
- Pas réimplémenter logique localement

### Logging

```lua
-- Format OBLIGATOIRE :
-- [Domaine] [uuid] message
-- ex: [Thermostat] [a1b2c3d4] consigne mise à 19.5°C

local marker = "[Thermostat] "
local msg = "[" .. tostring(uuid) .. "] consigne mise à " .. tostring(consigne) .. "°C"
domoticz.log(marker .. msg, domoticz.LOG_INFO)
```

- **marker** au format `[Domaine]`
- **Préfixer messages** avec `[uuid]` pour corrélation
- **tostring()** obligatoire pour toute variable potentiellement `nil`
- **Niveaux** : `LOG_DEBUG` (détails technique), `LOG_INFO` (nominal + réalignements), `LOG_ERROR` (anomalies)

## Ce que tu ne fais PAS

- Pas modifier fichiers documentation (`README.md`, `docs/`, `copilot-instructions.md`) — rôle 🟣 DOCly
- Pas introduire nouvelle librairie ou pattern architectural sans validation 🟠 ARCos
- Pas renommer devices/groupes/scènes/variables Domoticz sans plan de migration validé
- Pas modifier IDs Tydom hors `TYDOM_DEVICES` dans `global_data.lua`
- Pas écrire directement `globalData.scenePhase` — émettre événement `Scene Phase` uniquement
- Avant une évolution dzVents, lire `docs/RETROCONCEPTION_dzVents.md`; avant refactor/roadmap, lire `.github/tasks/todo/PLAN_ACTIONS_dzVents.md`.
- Les tests Jest du bridge se lancent avec `npm test --prefix tydom-bridge`. Le dépôt ne fournit pas de commande commune de build/lint ni de suite unitaire dzVents; ne pas annoncer de vérifications non exécutées.

## Règle d'index des plans (obligatoire)

- `docs/plans/README.md` limité aux **plans + statut global** (sans détail phases)
- Si travail change statut global plan, MAJ `docs/plans/README.md` dans même changement
