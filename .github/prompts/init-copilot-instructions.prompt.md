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

> **Prérequis** : Avant de lancer ce prompt, les fichiers suivants doivent déjà être présents dans le projet cible (copiés depuis le dépôt transverse) :
> - `.github/agents/` — les 4 agents génériques (`Arcos.agent.md`, `Devon.agent.md`, `Qalvin.agent.md`, `Docly.agent.md`)
> - `.github/prompts/` — les prompts réutilisables
> - `.github/PLANS.md` — le guide des Plans d'Action
>
> Ce prompt initialise uniquement les fichiers **spécifiques au projet** : `copilot-instructions.md` et les 4 fichiers `instructions/`.
> Pour copier les prérequis, utiliser d'abord le prompt `migrate-to-template`.

Ta mission est de **générer et initialiser** le fichier `.github/copilot-instructions.md` pour un nouveau projet, en te basant sur :

1. Le **template générique** (`.github/copilot-instructions.template.md`) présent dans ce dépôt transverse
2. L'**analyse du code source** du projet cible
3. Les **conventions réelles** appliquées dans le code

## 📋 Étapes

### 1. Lire le template générique

Lire intégralement `.github/copilot-instructions.template.md` pour comprendre la structure de base.

### 2. Analyser le projet cible

Parcourir le dépôt et identifier :

- **Structure du projet** : Explorer les dossiers principaux (src/, app/, lib/, etc.)
- **Stack technologique** : Identifier le langage (TypeScript, Python, Go, etc.), le framework principal (React, Vue, Django, Spring, etc.)
- **Type de projet** : Catégoriser (frontend, backend, fullstack, mobile, CLI, lib, etc.)
- **Plateforme** : Web, mobile (iOS/Android), desktop, CLI, API, etc.
- **Gestion d'état** : Context API, Redux, Zustand, MobX, etc. (le cas échéant)
- **Patterns architecturaux** : Couches (components, services, models), DDD, MVVM, etc.
- **Conventions existantes** : Naming files, imports, styling, testing patterns, etc.

### 3. Remplir les sections du template

Pour chaque placeholder `[...]` du template, fournir une valeur adaptée :

| Placeholder | Source d'information | Exemple |
|---|---|---|
| `[NOM_DU_PROJET]` | Nom du repo ou package.json name | "Domoticz Mobile", "API-Gateway", "Design System" |
| **Présentation du Projet** | README, description, package.json, main.swift, etc. | Stack tech, domaine métier, plateformes |
| **Commandes** | package.json scripts, Makefile, build scripts, etc. | `npm start`, `npm test`, `go build`, etc. |
| **Architecture** | Structure des dossiers + patterns observés | Diagram ASCII ou description hiérarchique |
| **Conventions Clés** | Fichiers existants du code | Nommage, TypeScript config, ESLint, Prettier, etc. |
| **État du Projet** | Code analysis + notes | État de maintenance, patterns d'erreur, dépendances clés |

> 💡 **Parallélisation possible** : Les étapes 4 et 5 (génération de `copilot-instructions.md` et des 4 fichiers `instructions/`) peuvent être exécutées en parallèle avec `/fleet` si les informations de l'analyse (étape 2) sont disponibles.

### 4. Générer le fichier

Créer `.github/copilot-instructions.md` en :
1. Copiant le template
2. Remplaçant tous les placeholders par les valeurs du projet
3. Supprimant les sections `[📌 À COMPLÉTER : ...]` si elles ont été remplies
4. Conservant les sections génériques (agents, workflow, plans d'action, diagrammes)

### 5. Générer les fichiers d'instructions agents

Lire les 4 templates dans `.github/instructions/` du dépôt transverse :
- `architect.instructions.md` — instructions pour l'agent ARCos
- `dev.instructions.md` — instructions pour l'agent DEVon
- `qa.instructions.md` — instructions pour l'agent QUALvin
- `doc.instructions.md` — instructions pour l'agent DOCly

Pour chaque fichier, remplir les placeholders avec les valeurs identifiées lors de l'analyse (étape 2) :
- `[NOM_DU_PROJET]` → nom du projet
- `[DESCRIPTION_COURTE_DU_PROJET]` → description courte (ex: frontend React/TypeScript)
- Pour `dev.instructions.md` : stack, versions, fichiers de constantes, service HTTP, dossiers conventions
- Pour `qa.instructions.md` : framework de test, commandes CI, chemins de rapport de couverture, noms des contexts
- Pour `doc.instructions.md` : chemin docs/ local, noms des fichiers de documentation, frameworks + versions pour les `.puml`
- Pour `architect.instructions.md` : couches du projet, noms des providers d'état, service HTTP, routing

Créer les 4 fichiers dans `.github/instructions/` du projet cible (ou les mettre à jour s'ils existent déjà).
Si certaines valeurs ne peuvent pas être déterminées depuis le code, conserver les placeholders `[...]` et les signaler explicitement.

### 6. Auditer et enrichir (optionnel)

Si le projet dispose d'autres fichiers de référence (CONTRIBUTING.md, ARCHITECTURE.md, BEST_PRACTICES.md, etc.), les lire et enrichir les sections correspondantes du fichier généré.

## ✅ Checklist de Livraison

- [ ] Fichier `.github/copilot-instructions.md` créé
- [ ] Fichiers `.github/instructions/*.instructions.md` créés (4 fichiers : architect, dev, qa, doc)
- [ ] Tous les placeholders `[...]` remplacés par des valeurs réelles
- [ ] Placeholders critiques remplacés (au minimum : NOM_DU_PROJET, stack technique)
- [ ] Sections `[📌 À COMPLÉTER : ...]` supprimées ou complétées
- [ ] Structure des sections conservée (ordre, hiérarchie)
- [ ] Sections génériques intactes (Agents, Workflow, Plans d'Action, Diagrammes)
- [ ] Exemples de code issus du codebase réel (si pertinent)
- [ ] Pas de références à des fichiers inexistants
- [ ] Langue française conservée pour tout le texte narratif
- [ ] Fichier lisible et bien formaté (Markdown)
- [ ] `.github/agents/` contient 4 fichiers (`Arcos.agent.md`, `Devon.agent.md`, `Qalvin.agent.md`, `Docly.agent.md`)
- [ ] `.github/skills/` contient 4 skills partagés (`plan-phase-execution/SKILL.md`, `plan-creation/SKILL.md`, `fleet-guide/SKILL.md`, `adr-writing/SKILL.md`)
- [ ] `.github/PLANS.md` est accessible
- [ ] `docs/ARCHITECTURE.md` existe (créer depuis le template : `cp docs/ARCHITECTURE.template.md docs/ARCHITECTURE.md`)
- [ ] `docs/adr/` existe (créer si absent : `mkdir -p docs/adr`)

## 💡 Conseils

1. **Soyez précis** : Observer et décrire ce qui existe réellement, pas des hypothèses
2. **Soyez concis** : Les instructions Copilot sont lues régulièrement ; rester synthétique
3. **Soyez pratiques** : Inclure les commandes réelles, les patterns réels observés
4. **Conservez la structure** : Ne pas réorganiser les sections du template, sauf si très pertinent
5. **Exemples du code** : Quand utile, inclure des patterns extraits du code source réel

## 🎯 Résultat

À la fin, le fichier `.github/copilot-instructions.md` doit être une **source de vérité** pour Copilot :
- Décrit fidèlement l'état du projet
- Fournit des conventions claires et appliquées
- Guide les agents dans le contexte du projet spécifique
- Reste à jour et maintenu par le projet
