---
name: update-copilot-instructions
description: >
  Audite le code source et les fichiers de bonnes pratiques pour compléter et
  amender le fichier copilot-instructions.md. Utiliser quand : "mets à jour les
  instructions Copilot", "complète copilot-instructions depuis le code",
  "synchronise les instructions avec le projet", "ajoute les bonnes pratiques
  aux instructions Copilot".
agent: agent
tools:
  - read_file
  - file_search
  - grep_search
  - semantic_search
  - replace_string_in_file
  - multi_replace_string_in_file
---

# Mise à jour de `copilot-instructions.md`

Ta mission est d'auditer le code source
et les fichiers de référence fournis, puis de **compléter et amender**
`.github/copilot-instructions.md` pour qu'il reflète fidèlement l'état réel du
projet et les bonnes pratiques en vigueur.

## Fichiers de bonnes pratiques à lire (si présents)

Lire chacun des fichiers suivants s'ils existent dans le dépôt :

| Chemin (relatif à la racine) | Rôle attendu |
|---|---|
| `docs/BEST_PRACTICES.md` | Bonnes pratiques de développement du projet |
| `docs/CODING_STANDARDS.md` | Standards de code (nommage, structure, patterns) |
| `docs/ARCHITECTURE.md` | Décisions d'architecture (ADR) |
| `docs/CONTRIBUTING.md` | Guide de contribution / workflow Git |
| `CHANGELOG.md` | Historique des changements (pour détecter les évolutions récentes) |
| `.eslintrc.json` / `eslint.config.*` | Règles de lint actives (conventions enforced) |


> Si d'autres fichiers de référence ont été fournis en contexte par l'utilisateur, les lire également.

## Étapes d'audit du code source

### 1. Lire les instructions existantes

Lire intégralement `.github/copilot-instructions.md` pour identifier :
- Les sections déjà présentes
- Les informations potentiellement obsolètes ou incomplètes
- Les conventions décrites mais non vérifiées dans le code
- Les chapitres indiqués <em>à compléter</em> ou <em>à valider</em>

### 2. Explorer la structure du projet

- Lister `src/` pour détecter tout nouveau dossier ou domaine non documenté

### 3. Extraire les conventions réelles du code

Pour chaque couche, rechercher et noter les patterns réellement utilisés :

**Interfaces **
- Nommage des interfaces
- Structure type d'une interface de données

**Services**
- Pattern d'injection 
- Composition des API calls (gestion des erreurs, utilisation du service d'URL/config pour les endpoints, etc.)
- Gestion des erreurs HTTP

**Composants de pages**
- Structure type d'un composant 

**Composants réutilisables**
- Pattern de cycle de vie

**Fonctions utilitaires**
- Conventions de nommage des fichiers
- Pattern des fonctions pures

**Tests**
- Structure des suites 
- Outils de mock utilisés
- Pattern de setup

**CSS / Styles**
- Tokens CSS définis
- Conventions de nommage des classes locales

### 4. Vérifier la cohérence avec les instructions existantes

Pour chaque convention documentée dans `copilot-instructions.md` :
- Confirmer qu'elle est bien appliquée dans le code
- Signaler toute divergence entre la doc et le code réel
- Identifier les conventions présentes dans le code mais absentes des instructions

### 5. Auditer les fichiers d'instructions agents

Lire les 4 fichiers suivants dans `.github/instructions/` :
- `architect.instructions.md`
- `dev.instructions.md`
- `qa.instructions.md`
- `doc.instructions.md`

Pour chaque fichier, vérifier sa cohérence avec le code source :
- `dev.instructions.md` : versions des librairies, noms des fichiers de constantes, chemins des dossiers
- `qa.instructions.md` : versions des packages de test, commandes CI, chemins de rapport de couverture
- `doc.instructions.md` : chemins docs/ locaux, noms des fichiers de doc, versions pour les diagrammes `.puml`
- `architect.instructions.md` : noms des couches, providers d'état, service HTTP, stratégie de routing

En complément :
- Identifier les placeholders `[...]` non remplis et les signaler comme action nécessaire
- Identifier les valeurs devenues obsolètes (ex : version de librairie outdatée)

### 6. Auditer les skills partagés

Lire les 4 skills suivants dans `.github/skills/` (s'ils existent) :
- `plan-phase-execution/SKILL.md`
- `plan-creation/SKILL.md`
- `fleet-guide/SKILL.md`
- `adr-writing/SKILL.md`

Pour chaque skill, vérifier :
- Que le frontmatter `applyTo: "**"` est présent (inclusion automatique dans le contexte agent)
- Que le contenu est cohérent avec `.github/PLANS.md` (pas de divergence de format)
- Que les agents `.github/agents/*.agent.md` référencent bien les skills dans leurs sections AP et /fleet (et ne répètent pas le contenu)
- Identifier tout contenu encore dupliqué entre un skill et un agent (candidat à l'extraction)

> 💡 **Parallélisation possible** : Les étapes 2 (exploration structure), 3 (extraction conventions), 5 (audit instructions/) et 6 (audit skills/) sont **indépendantes** et peuvent être lancées en `/fleet` pour accélérer l'audit global.

## Règles de rédaction des amendements

1. **Ne pas supprimer** de sections existantes sans raison explicite — préférer amender ou compléter
2. **Vérifier dans le code** chaque convention avant de l'ajouter : ne pas documenter des hypothèses
3. **Rester concis** : les instructions Copilot sont lues à chaque session ; éviter la verbosité
4. **Conserver la langue française** pour tout le texte narratif
5. **Utiliser des exemples de code** issus du code source réel quand c'est utile
6. **Structurer les ajouts** dans la section la plus pertinente existante, ou créer une nouvelle section titrée si nécessaire
7. **Ne pas dupliquer** des informations déjà présentes dans les fichiers agents (`.github/agents/`)

## Format de livraison

Avant d'appliquer les modifications :

1. Présenter un **diff résumé** des changements proposés :
   - Sections à **ajouter** (avec justification et source dans le code)
   - Sections à **amender** (avec la valeur actuelle et la valeur corrigée)
   - Sections à **supprimer** (si obsolètes — demander confirmation)
   - Sections **validées** (conformes au code, aucun changement)
   - Vérification que les agents `.github/agents/*.agent.md` sont à leur version courante (v2.0+)
   - Vérification que les skills `.github/skills/*/SKILL.md` sont présents et cohérents avec `PLANS.md`
   - Modifications proposées pour chaque fichier `.github/instructions/*.instructions.md`
   - Signalement séparé des placeholders non remplis vs des valeurs obsolètes

2. Attendre la **validation du 👤 Développeur humain** avant d'appliquer les modifications.

3. Une fois validé, appliquer les changements dans `.github/copilot-instructions.md` et, si nécessaire, dans les fichiers `.github/instructions/*.instructions.md` avec `replace_string_in_file` ou `multi_replace_string_in_file`.

4. Résumer les modifications appliquées en une liste à puces.

