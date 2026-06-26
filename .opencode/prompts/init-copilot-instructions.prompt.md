---
name: init-opencode
description: >
  Initialise la configuration OpenCode pour un nouveau projet. Utiliser pour :
  "initialise les agents OpenCode", "génère la configuration pour ce projet",
  "crée un AGENTS.md", "configure OpenCode pour ce projet".
  Prend en paramètre le type de projet et extrait les informations du code source.
agent: agent
---

# Initialisation de la Configuration OpenCode

> **Prérequis** : Avant de lancer ce prompt, les fichiers suivants doivent exister dans le projet cible (copiés depuis le dépôt transverse) :
> - `.opencode/agents/` — 4 agents génériques (`Arcos.agent.md`, `Devon.agent.md`, `Qalvin.agent.md`, `Docly.agent.md`)
> - `.opencode/skills/` — skills partagés
> - `.opencode/PLANS.md` — guide Plans d'Action

Mission : **générer et initialiser** le fichier `AGENTS.md` pour un nouveau projet, basé sur :

1. **Analyse du code source** du projet cible
2. **Conventions réelles** appliquées dans le code

## 📋 Étapes

### 1. Analyser le projet cible

Parcourir le dépôt et identifier :

- **Structure du projet** : Explorer les dossiers principaux (src/, app/, lib/, etc.)
- **Stack technologique** : Identifier le langage (TypeScript, Python, Go, etc.), le framework principal (React, Vue, Django, Spring, etc.)
- **Type de projet** : Catégoriser (frontend, backend, fullstack, mobile, CLI, lib, etc.)
- **Plateforme** : Web, mobile (iOS/Android), desktop, CLI, API, etc.
- **Conventions existantes** : Nommage des fichiers, imports, styling, patterns de test, etc.

### 2. Générer le fichier AGENTS.md

Créer `AGENTS.md` à la racine du projet en suivant la structure OpenCode standard :
- Description du projet
- Structure des répertoires
- Conventions de code
- Commandes disponibles (build, test, lint, etc.)
- Workflow des agents

### 3. Générer les fichiers d'instructions agents

Lire les 4 templates dans `.opencode/instructions/` du dépôt transverse et créer les fichiers correspondants dans `.opencode/instructions/` du projet cible, en remplissant les placeholders avec les valeurs identifiées lors de l'analyse.

## ✅ Checklist de Livraison

- [ ] Fichier `AGENTS.md` créé
- [ ] Fichiers `.opencode/instructions/*.instructions.md` créés depuis les templates (4 fichiers)
- [ ] Tous les placeholders `[...]` remplacés par des valeurs réelles
- [ ] Structure des sections conservée
- [ ] Exemples de code issus de la codebase réelle (si pertinent)
- [ ] Langue française conservée pour tout texte narratif

## 💡 Conseils

1. **Soyez précis** : Observer et décrire ce qui existe réellement, pas des hypothèses
2. **Soyez concis** : Les instructions sont lues régulièrement ; rester synthétique
3. **Soyez pratiques** : Inclure les commandes réelles, les patterns réels observés
