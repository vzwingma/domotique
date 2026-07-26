---
name: update-opencode
description: >
  Audite le code source et les fichiers de bonnes pratiques pour compléter et
  amender le fichier AGENTS.md. Utiliser quand : "mets à jour la config OpenCode",
  "complète AGENTS.md depuis le code",
  "synchronise les instructions avec le projet".
agent: agent
---

# Mise à jour de la Configuration OpenCode

Mission : **auditer et mettre à jour** le fichier `AGENTS.md` d'un projet existant.

## 📋 Étapes

### 1. Lire le fichier AGENTS.md existant

Lire intégralement `AGENTS.md` pour comprendre la configuration actuelle.

### 2. Analyser le projet

Parcourir le dépôt et identifier les changements depuis la dernière initialisation :
- Nouveaux dossiers ou modules
- Changements de stack technique
- Nouvelles commandes (scripts package.json, Makefile, etc.)
- Évolution des conventions de code

### 3. Mettre à jour AGENTS.md

Mettre à jour les sections pertinentes du fichier :
- Structure du projet (si changée)
- Commandes (si nouvelles)
- Conventions (si changées)

### 4. Mettre à jour les fichiers instructions

Vérifier et mettre à jour les 4 fichiers dans `.opencode/instructions/` :
- `architect.instructions.md`
- `dev.instructions.md`
- `qa.instructions.md`
- `doc.instructions.md`

## ✅ Checklist

- [ ] `AGENTS.md` audité et mis à jour
- [ ] 4 fichiers `.opencode/instructions/*.instructions.md` vérifiés
- [ ] Tous les placeholders remplacés
- [ ] Commandes réelles et à jour
- [ ] Pas d'informations obsolètes
