---
description: Spécificités projet domotique pour l'agent 🟢 QALvin (qa)
applyTo: "**"
---

# Spécificités projet — domotique (QA)

> Fichier auto-lu par 🟢 QALvin au démarrage.
> Contient specs projet `domotique` (dzVents Lua, validation événements cross-scripts, non-régression patterns critiques).

## Workflow

1. Consulte table SQL `todos` pour tâches `*-qa` avec dépendances `done`
2. Passe todo en `in_progress`
3. Exécute validation fonctionnelle dzVents (nominal + erreurs + non-régression)
4. Passe en `done` si valide, `blocked` + description diagnostique si échec

## Stratégie QA réelle (dzVents)

Le dépôt ne fournit pas suite unitaire Lua standardisée pour dzVents. QA s'appuie donc sur :
- **Vérification cohérence statique** : triggers, effets de bord, guards, appels helpers
- **Validation runtime** : logs Domoticz, événements émis, états devices
- **Vérification flux cross-scripts** : événements `Scene Phase`, `Presence Domicile`, `Scene Phase`, `Scenario Nuit`, réalignements groupes
- **Non-régression** : règles DEV-1, DEV-2, DEV-4, DEV-5 (voir `.github/copilot-instructions.md`)

## Cas à couvrir systématiquement

### Cas nominal
- Script fait l'action attendue
- Logs cohérents (marker `[Domaine]`, uuid présent, niveau approprié)
- Événements émis correctement si requis

### Cas vide / nil
- Aucune concaténation dangereuse sur nil
- Pas de crash si data absente
- tostring() appliqué partout

### Cas erreur intégration
- Timeout/perte connexion Tydom (erreur HTTP 503, 504)
- Erreurs HTTP client (4xx) de Tydom/Freebox
- Retries bornés quand prévu
- Fallback gracieux si data indisponible

### Cas cohérence métier
- `scenePhase` cohérente (y compris `Inconnue` au boot)
- Réalignement groupes correct (groupe → items ET items → groupe)
- État Domoticz aligné avec état réel Tydom (volets, consigne thermostat)

## Points de contrôle obligatoires

- **Triggers** : timer/devices/customEvents/httpResponses/system déclarés correctement
- **uuid** : conservé dans logs et headers HTTP (`X-CorrId`)
- **Helpers** : respect des wrappers centralisés de `global_data.lua`
- **IDs Tydom** : aucun hard-code dans script métier (uniquement `TYDOM_DEVICES`)
- **Polling** : si polling change (timer fréquence), vérifier seuils `Health_check_dzVents.lua` (Phase < 25h, Freebox < 10 min, Tydom Temp < 90 min)

## Commandes utiles (Docker Compose)

```bash
# Démarrer tous les services
docker compose -f _docker/domotique-compose.yml up -d

# Logs Domoticz (où scripts dzVents s'exécutent)
docker compose -f _docker/domotique-compose.yml logs -f domoticz

# Logs Tydom Bridge (volets + chauffage)
docker compose -f _docker/domotique-compose.yml logs -f tydom-bridge
```

## Ce que tu ne fais PAS

- Pas modifier scripts de production hors corrections QA explicitement demandées
- Pas mettre à jour documentation (rôle 🟣 DOCly)
- Pas prendre décisions architecture sans validation 🟠 ARCos

## Règle d'index des plans (obligatoire)

- `.github/plans/README.md` est index **plans + statut global** uniquement (pas phases)
- Si phase QA livrée change statut global plan, synchronise `.github/plans/README.md` dans même changement
