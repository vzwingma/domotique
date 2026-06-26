---
description: Spécificités projet domotique pour l'agent 🟣 DOCly (doc)
applyTo: "**"
---

# Spécificités projet — domotique (Doc)

> Fichier auto-lu par agent 🟣 DOCly au démarrage.
> Contient spécificités projet `domotique` (documentation architecture dzVents, déploiement Docker, composants intégration).

## Workflow

1. Consulte todos `*-doc` dont dépendances sont `done`
2. Passe todo en `in_progress`
3. Identifie fichiers doc impactés
4. Update ciblé (pas réécriture complète sauf si nécessaire)
5. Passe en `done`

## Fichiers sous responsabilité

### Dans la racine du projet
- `README.md` – description générale, prérequis, démarrage rapide
- `.github/copilot-instructions.md` – contexte futures sessions Copilot

### Dans `docs/` (documentation versionnée)
- `docs/ARCHITECTURE.md` (**obligatoire**) – architecture projet (stack dzVents, couches, structure scripts, orchestration scènes, intégrations Tydom/Freebox/API)
- `docs/adr/` – Architecture Decision Records produits par ARCos (ex: `docs/adr/001-orchestration-phases.md`)
- `docs/scenarios.puml` – diagrammes PlantUML C2/C3 (orchestration scènes quotidiennes)

### Dans `.github/`
- `.github/plans/README.md` – index synthétique plans d'action + statut global (pas phases)
- `.github/copilot-instructions.md` – contexte sessions et conventions globales

### Documentation de composants (README.md de chaque sous-dossier)
- `domoticz/README.md` – scripts dzVents, conventions nommage, état partagé
- `tydom-bridge/README.md` – bridge HTTP Tydom, endpoints, authentification
- `deCONZ/README.md` – passerelle Zigbee
- `_docker/build_domoticz/README.md` – build image Domoticz personnalisée
- `_docker/build_httpd/README.md` – build Apache proxy TLS, gestion certificat Let's Encrypt

## Conventions de documentation

- **Langue** : français pour texte narratif, anglais pour blocs de code
- **`docs/ARCHITECTURE.md` obligatoire** : tout projet doit avoir fichier décrivant architecture complète
- **ADRs** : chaque décision architecturale majeure produit fichier `docs/adr/NNN-titre.md`
- **Versions à maintenir** : dzVents dans `docs/scenarios.puml`, versions Docker dans `.github/copilot-instructions.md`
- **Cohérence code/doc** : si écart doc/code découvert, corriger doc dans même changement que code
- **Ne pas dupliquer** : instructions agents (`.github/instructions/`) restent indépendantes; pas copier contenu dans docs/ARCHITECTURE.md

## Ce que tu ne fais PAS

- Pas modifier code source (`*.lua`, `*.js`, `*.sh`, etc.)
- Pas créer nouveaux tests (rôle 🟢 QALvin)
- Pas prendre décisions architecturales (rôle 🟠 ARCos)

## Règle d'index des plans (obligatoire)

- `.github/plans/README.md` doit rester **synthétique** : plans + statut global **uniquement** (sans phases)
- Toute création de plan ou changement de statut global doit inclure, dans même changement, mise à jour `.github/plans/README.md`
