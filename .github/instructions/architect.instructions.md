---
description: Specificites projet domotique pour l'agent ARCos (architect)
applyTo: "**"
---

# Specificites projet - domotique (Architect)

## Lecture obligatoire au demarrage

- Lire .github/copilot-instructions.md.
- Lire .github/tasks/todo/RETROCONCEPTION_dzVents.md avant tout changement d'architecture/comportement.
- Lire .github/tasks/todo/PLAN_ACTIONS_dzVents.md avant toute proposition de roadmap/refactoring.
- Lire domoticz/scripts/dzVents/global_data.lua avant toute decision impactant les scripts dzVents.
- Si docs/ARCHITECTURE.md est absent (cas actuel), planifier une tache DOCly pour le creer en fin d'initiative.

## Conventions architecturales dzVents

- Couches:
  - Scene_*: orchestration des phases journalieres
  - Device_* / Devices_*: comportement metier
  - Groupes_*: synchronisation groupes et equipements
  - Freebox_* / Tydom_*: integrations externes
  - global_*: helpers, constantes, wrappers HTTP, etat partage
- Etat global:
  - scenePhase est une donnee transverse et doit etre alimentee via l'evenement custom Scene Phase.
  - Le script Device_Label_Scene_Phase.lua gere la restauration au boot.
- HTTP:
  - Les appels vers Tydom passent par les helpers centralises de global_data.lua.
  - Les IDs Tydom sont centralises dans TYDOM_DEVICES uniquement.
- Observabilite:
  - Toute chaine d'appel doit conserver la tracabilite uuid dans les logs.

## ADR et documentation d'architecture

Toute decision architecturale majeure doit produire une tache DOCly pour creer un ADR dans docs/adr/ (quand ce dossier sera initialise), avec:
- contexte
- decision
- alternatives
- consequences

## Protocole de handoff SQL

Quand une initiative est prete a etre executee, inserer les taches avec ce format:

```sql
INSERT INTO todos (id, title, description, status) VALUES
  ('feat-xxx-dev', 'Titre dev',  'owner: dev - fichiers a modifier et comportement attendu', 'pending'),
  ('feat-xxx-qa',  'Titre qa',   'owner: qa - validations nominales, erreurs, regressions',   'pending'),
  ('feat-xxx-doc', 'Titre doc',  'owner: doc - README, copilot-instructions, docs/ si present', 'pending');

INSERT INTO todo_deps (todo_id, depends_on) VALUES
  ('feat-xxx-qa',  'feat-xxx-dev'),
  ('feat-xxx-doc', 'feat-xxx-dev');
```

Convention IDs: feat-<nom>-dev / feat-<nom>-qa / feat-<nom>-doc.

## Interactions avec agents partenaires

- Contrats integration Tydom: coordonnes avec le composant tydom-bridge.
- Contrats integration Freebox: preservent la sequence d'authentification et la robustesse.
- Tout nouveau endpoint de bridge doit etre absorbe via global_data.lua avant usage metier.

## Regle index des plans

- .github/plans/README.md reste un index synthetique: plans + statut global uniquement.
- Toute creation de plan ou changement de statut global met a jour cet index dans le meme change set.
