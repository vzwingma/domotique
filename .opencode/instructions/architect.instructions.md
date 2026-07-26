---
description: Spécificités projet domotique pour l'agent ARCos (architect)
applyTo: "**"
---

# Spécificités projet — domotique

> Fichier auto-lu par agent 🟠 ARCos au démarrage.
> Contient spécificités projet `domotique` (système domotique centralisé sur Domoticz avec dzVents Lua, intégrations Tydom et Freebox, déploiement Docker Compose).

## Lecture du document d'architecture

**Au démarrage**, lis `docs/ARCHITECTURE.md` :
- Comprendre stack dzVents (couches Scene_, Device_, global_, intégrations Tydom/Freebox)
- Assurer cohérence décisions planification avec architecture existante
- Architecture couvre : réseau (proxy Apache TLS), orchestration scènes quotidiennes, gestion état global (scenePhase, joursFeries)

Lectures additionnelles obligatoires :
- `.opencode/copilot-instructions.md` — contexte global projet
- `.opencode/tasks/todo/RETROCONCEPTION_dzVents.md` — avant tout changement d'architecture/comportement
- `.opencode/tasks/todo/PLAN_ACTIONS_dzVents.md` — avant toute proposition roadmap/refactoring
- `domoticz/scripts/dzVents/global_data.lua` — avant toute décision impactant dzVents

## Conventions architecturales

**Couches dzVents** :
- `Scene_*` : orchestration des phases quotidiennes
- `Device_* / Devices_*` : comportement métier événementiel
- `Groupes_*` : synchronisation groupes ↔ items unitaires
- `Freebox_* / Tydom_*` : intégrations externes (présence, volets, chauffage)
- `global_*` : helpers centralisés, constantes, wrappers HTTP, état partagé

**État global** :
- `scenePhase` : alimentée **uniquement** via l'événement custom `Scene Phase` (jamais écriture directe hors `Device_Label_Scene_Phase.lua`)
- `joursFeries` : chargé via API gouvernementale + health check quotidien

**HTTP & IDs techniques** :
- Tous les appels Tydom passent par helpers centralisés de `global_data.lua`
- IDs Tydom centralisés **uniquement** dans table `TYDOM_DEVICES` de `global_data.lua`
- Pas de hard-code deviceId/endpointId Tydom dans les scripts métier

**Observabilité** :
- Chaque flux doit conserver traçabilité `uuid` (v4) propagée dans logs, événements, headers HTTP (`X-CorrId`)
- Marker au format `[Domaine]`
- Niveau log cohérent : `LOG_DEBUG` (détails), `LOG_INFO` (nominal), `LOG_ERROR` (anomalies)

## Documentation des décisions architecturales (ADR)

Chaque décision architecturale majeure doit produire fichier ADR dans `docs/adr/` :

- **Nommage** : `docs/adr/NNN-titre-court.md` (ex: `docs/adr/001-orchestration-phases.md`)
- **Contenu minimal** : contexte, décision prise, alternatives considérées, conséquences
- **Quand créer ADR** : nouveau pattern dzVents, changement intégration (Tydom/Freebox), refactoring couche, déploiement Docker
- Déléguer création ADR à 🟣 DOCly après validation décision

## Protocole de handoff SQL

Quand tâche prête à être réalisée, insère todos dans table SQL avec ce format :

```sql
INSERT INTO todos (id, title, description, status) VALUES
  ('feat-xxx-dev', 'Titre dev',  'Description précise : fichiers à créer/modifier, interfaces/patterns à respecter', 'pending'),
  ('feat-xxx-qa',  'Titre QA',   'Tests à valider : cas nominaux, erreurs HTTP, non-régression DEV-*, flux cross-scripts', 'pending'),
  ('feat-xxx-doc', 'Titre Doc',  'Documentation : README, docs/ARCHITECTURE.md, docs/adr/ si ADR, copilot-instructions.md', 'pending');

INSERT INTO todo_deps (todo_id, depends_on) VALUES
  ('feat-xxx-qa',  'feat-xxx-dev'),
  ('feat-xxx-doc', 'feat-xxx-dev');
```

Convention nommage IDs : `feat-<nom>-dev` / `feat-<nom>-qa` / `feat-<nom>-doc`.

## Interactions avec l'agent partenaire (tydom-bridge, Freebox)

- Contrats API (URL, paramètres, codes retour) définis en coordination avec composants respectifs
- Tout nouveau endpoint Tydom/Freebox doit être reflété dans `global_data.lua` avant usage métier
- Préserver robustesse et séquencing (ex: authentification Freebox avant lecture LAN statuts)

## Agents du projet

| Icône | Nom      | Fichier agent              | Rôle                          |
|-------|----------|---------------------------|-------------------------------|
| 🔵    | DEVon    | `.opencode/agents/Devon.agent.md` | Implémentation dzVents      |
| 🟢    | QALvin   | `.opencode/agents/Qalvin.agent.md` | Validation et tests          |
| 🟣    | DOCly    | `.opencode/agents/Docly.agent.md` | Documentation              |

## Règle d'index des plans (obligatoire)

- Fichier `.opencode/plans/README.md` est **index synthétique** : doit contenir uniquement liste plans et leur **statut global**
- Pas afficher statuts phases
- Toute création plan ou changement statut global doit inclure, dans même changement, mise à jour `.opencode/plans/README.md`
