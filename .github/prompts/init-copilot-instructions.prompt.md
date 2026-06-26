---
name: init-copilot-instructions
description: >
  Initialise les instructions Copilot pour un nouveau projet. Utiliser pour :
  "initialise les instructions Copilot", "génère les instructions pour ce projet",
  "crée un copilot-instructions.md", "configure Copilot pour ce projet".
  Prend en paramètre le type de projet et extrait les informations du code source.
agent: agent
---

# Initialisation des Instructions Copilot

> **Prérequis** : Avant lancer prompt, fichiers suivants doivent exister projet cible (copiés depuis dépôt transverse) :
> - `.github/agents/` — 5 agents génériques (`Maina.agent.md`, `Arcos.agent.md`, `Devon.agent.md`, `Qalvin.agent.md`, `Docly.agent.md`)
> - `.github/prompts/` — prompts réutilisables
> - `.github/PLANS.md` — guide Plans d'Action
>
> Prompt initialise uniquement fichiers **spécifiques projet** : `copilot-instructions.md` et 4 fichiers `instructions/`.
> Pour copier prérequis, utiliser d'abord prompt `migrate-to-template`.

Mission : **générer et initialiser** fichier `.github/copilot-instructions.md` pour nouveau projet, basé sur :

1. **Template générique** (`.github/copilot-instructions.template.md`) présent dans dépôt transverse
2. **Analyse code source** projet cible
3. **Conventions réelles** appliquées dans code

## 📋 Étapes

### 1. Lire le template générique

Lire intégralement `.github/copilot-instructions.template.md` pour comprendre structure base.

### 2. Analyser le projet cible

Parcourir dépôt et identifier :

- **Structure projet** : Explorer dossiers principaux (src/, app/, lib/, etc.)
- **Stack technologique** : Identifier langage (TypeScript, Python, Go, etc.), framework principal (React, Vue, Django, Spring, etc.)
- **Type projet** : Catégoriser (frontend, backend, fullstack, mobile, CLI, lib, etc.)
- **Plateforme** : Web, mobile (iOS/Android), desktop, CLI, API, etc.
- **Gestion état** : Context API, Redux, Zustand, MobX, etc. (si pertinent)
- **Patterns architecturaux** : Couches (components, services, models), DDD, MVVM, etc.
- **Conventions existantes** : Naming files, imports, styling, testing patterns, etc.

### 3. Remplir les sections du template

Pour chaque placeholder `[...]` du template, fournir valeur adaptée :

| Placeholder | Source d'information | Exemple |
|---|---|---|
| `[NOM_DU_PROJET]` | Nom repo ou package.json name | "Domoticz Mobile", "API-Gateway", "Design System" |
| **Présentation du Projet** | README, description, package.json, main.swift, etc. | Stack tech, domaine métier, plateformes |
| **Commandes** | package.json scripts, Makefile, build scripts, etc. | `npm start`, `npm test`, `go build`, etc. |
| **Architecture** | Structure dossiers + patterns observés | Diagram ASCII ou description hiérarchique |
| **Conventions Clés** | Fichiers existants du code | Nommage, TypeScript config, ESLint, Prettier, etc. |
| **État du Projet** | Code analysis + notes | État maintenance, patterns erreur, dépendances clés |

> 💡 **Parallélisation possible** : Étapes 4 et 5 (génération `copilot-instructions.md` et 4 fichiers `instructions/`) peuvent être exécutées en parallèle avec `/fleet` si infos analyse (étape 2) disponibles.

### 4. Générer le fichier

Créer `.github/copilot-instructions.md` en :
1. Copiant template
2. Remplaçant tous placeholders par valeurs projet
3. Supprimant sections `[📌 À COMPLÉTER : ...]` si remplies
4. Conservant sections génériques (agents, workflow, plans d'action, diagrammes)

### 5. Générer les fichiers d'instructions agents

Lire 4 templates dans `.github/instructions/` du dépôt transverse :
- `architect.instructions.template.md` — template instructions pour agent ARCos
- `dev.instructions.template.md` — template instructions pour agent DEVon
- `qa.instructions.template.md` — template instructions pour agent QALvin
- `doc.instructions.template.md` — template instructions pour agent DOCly

Pour chaque fichier, remplir placeholders avec valeurs identifiées lors analyse (étape 2) :
- `[NOM_DU_PROJET]` → nom projet
- `[DESCRIPTION_COURTE_DU_PROJET]` → description courte (ex: frontend React/TypeScript)
- Pour `dev.instructions.md` : stack, versions, fichiers constantes, service HTTP, dossiers conventions
- Pour `qa.instructions.md` : framework test, commandes CI, chemins rapport couverture, noms contexts
- Pour `doc.instructions.md` : chemin docs/ local, noms fichiers documentation, frameworks + versions pour `.puml`
- Pour `architect.instructions.md` : couches projet, noms providers état, service HTTP, routing

Créer 4 fichiers dans `.github/instructions/` du projet cible (ou mettre à jour si existent déjà), nommés `architect.instructions.md`, `dev.instructions.md`, `qa.instructions.md`, `doc.instructions.md`.
Si certaines valeurs non déterminables depuis code, conserver placeholders `[...]` et signaler explicitement.

### 6. Auditer et enrichir (optionnel)

Si projet dispose autres fichiers référence (CONTRIBUTING.md, ARCHITECTURE.md, BEST_PRACTICES.md, etc.), les lire et enrichir sections correspondantes fichier généré.

## ✅ Checklist de Livraison

- [ ] Fichier `.github/copilot-instructions.md` créé
- [ ] Fichiers `.github/instructions/*.instructions.md` créés depuis templates `*.instructions.template.md` (4 fichiers : architect, dev, qa, doc)
- [ ] Tous placeholders `[...]` remplacés par valeurs réelles
- [ ] Placeholders critiques remplacés (minimum : NOM_DU_PROJET, stack technique)
- [ ] Sections `[📌 À COMPLÉTER : ...]` supprimées ou complétées
- [ ] Structure sections conservée (ordre, hiérarchie)
- [ ] Sections génériques intactes (Agents, Workflow, Plans d'Action, Diagrammes)
- [ ] Exemples code issus codebase réel (si pertinent)
- [ ] Pas références fichiers inexistants
- [ ] Langue française conservée pour tout texte narratif
- [ ] Fichier lisible et bien formaté (Markdown)
- [ ] `.github/agents/` contient 5 fichiers (`Maina.agent.md`, `Arcos.agent.md`, `Devon.agent.md`, `Qalvin.agent.md`, `Docly.agent.md`)
- [ ] `.github/skills/` contient 4 skills partagés (`plan-phase-execution/SKILL.md`, `plan-creation/SKILL.md`, `fleet-guide/SKILL.md`, `adr-writing/SKILL.md`)
- [ ] `.github/PLANS.md` accessible
- [ ] `docs/ARCHITECTURE.md` existe (créer depuis template : `cp docs/ARCHITECTURE.template.md docs/ARCHITECTURE.md`)
- [ ] `docs/adr/` existe (créer si absent : `mkdir -p docs/adr`)

## 💡 Conseils

1. **Soyez précis** : Observer et décrire ce qui existe réellement, pas hypothèses
2. **Soyez concis** : Instructions Copilot lues régulièrement ; rester synthétique
3. **Soyez pratiques** : Inclure commandes réelles, patterns réels observés
4. **Conservez la structure** : Pas réorganiser sections template, sauf si très pertinent
5. **Exemples du code** : Quand utile, inclure patterns extraits code source réel

## 🎯 Résultat

À fin, fichier `.github/copilot-instructions.md` doit être **source de vérité** pour Copilot :
- Décrit fidèlement état projet
- Fournit conventions claires et appliquées
- Guide agents dans contexte projet spécifique
- Reste à jour et maintenu par projet