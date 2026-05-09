---
description: Specificites projet domotique pour l'agent DEVon (dev)
applyTo: "**"
---

# Specificites projet - domotique (Dev)

## Workflow

1. Recuperer les todos owner=dev en pending sans dependances bloquantes.
2. Passer le todo en in_progress.
3. Implementer selon les conventions dzVents ci-dessous.
4. Passer le todo en done quand le code est pret et verifie.

## Stack technique reelle

- Domoticz + dzVents (Lua) pour l'automatisation evenementielle.
- Integrations externes via bridges Node.js (notamment tydom-bridge).
- Deploiement principal via Docker Compose.

## Conventions de code dzVents

### Structure type d'un script

```lua
return {
    on = { ... },
    data = { ... },
    logging = { level = domoticz.LOG_INFO, marker = "[Domaine] " },
    execute = function(domoticz, item)
        -- logique
    end
}
```

### Evenements et etat

- Utiliser explicitement les triggers (timer, devices, customEvents, httpResponses, system).
- scenePhase doit etre pilotee via l'evenement Scene Phase (pas d'ecriture directe hors script dedie).
- Conserver la valeur Inconnue comme etat possible au boot.

### Appels HTTP et IDs techniques

- Toujours passer par les helpers centralises dans global_data.lua.
- Ne jamais hard-coder un deviceId/endpointId Tydom.
- Utiliser TYDOM_DEVICES, getTydomHeatURI, getTydomDeviceNumberFromDzItem, getDzItemFromTydomDeviceId.

### Groupes

- Tout realignement groupe <- items doit utiliser verifyGroupeFromItem.
- Ne pas re-implementer la logique localement.

### Logging

- marker au format [Domaine].
- Prefixer les messages avec [uuid] pour la correlation.
- tostring() obligatoire pour toute valeur potentiellement nil avant concatenation.

## Ce que tu ne fais pas

- Ne pas modifier README ou la documentation (role DOCly), sauf demande explicite.
- Ne pas introduire de nouvelle librairie ou pattern architectural sans validation ARCos.
- Ne pas renommer des objets Domoticz (devices/groupes/scenes/variables) sans plan de migration.
- Ne pas modifier les IDs Tydom hors TYDOM_DEVICES.

## Regle index des plans

- .github/plans/README.md doit rester limite a plans + statut global.
- Si un statut global de plan change dans ton lot, synchroniser cet index dans le meme changement.
