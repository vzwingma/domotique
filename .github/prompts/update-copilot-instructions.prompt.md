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

Mission: auditer code source et fichiers référence, puis compléter/amender `.github/copilot-instructions.md` pour refléter état réel projet et bonnes pratiques.

## Fichiers de bonnes pratiques à lire (si présents)

Lire fichiers suivants si existent:

| Chemin (relatif à la racine) | Rôle attendu |
|---|---|
| `docs/BEST_PRACTICES.md` | Bonnes pratiques développement projet |
| `docs/CODING_STANDARDS.md` | Standards code (nommage, structure, patterns) |
| `docs/ARCHITECTURE.md` | Décisions architecture (ADR) |
| `docs/CONTRIBUTING.md` | Guide contribution / workflow Git |
| `CHANGELOG.md` | Historique changements (pour détecter évolutions récentes) |
| `.eslintrc.json` / `eslint.config.*` | Règles lint actives (conventions enforced) |

> Si autres fichiers référence fournis en contexte, lire aussi.

## Étapes d'audit du code source

### 1. Lire les instructions existantes

Lire intégralement `.github/copilot-instructions.md` pour identifier:
- Sections déjà présentes
- Infos potentiellement obsolètes ou incomplètes
- Conventions décrites mais non vérifiées dans code
- Chapitres indiqués <em>à compléter</em> ou <em>à valider</em>

### 2. Explorer la structure du projet

Lister `src/` pour détecter nouveau dossier ou domaine non documenté

### 3. Extraire les conventions réelles du code

Pour chaque couche, rechercher et noter patterns réellement utilisés:

**Interfaces**
- Nommage interfaces
- Structure type interface données

**Services**
- Pattern injection
- Composition API calls (gestion erreurs, utilisation service URL/config pour endpoints, etc.)
- Gestion erreurs HTTP

**Composants de pages**
- Structure type composant

**Composants réutilisables**
- Pattern cycle vie

**Fonctions utilitaires**
- Conventions nommage fichiers
- Pattern fonctions pures

**Tests**
- Structure suites
- Outils mock utilisés
- Pattern setup

**CSS / Styles**
- Tokens CSS définis
- Conventions nommage classes locales

### 4. Vérifier la cohérence avec les instructions existantes

Pour chaque convention documentée dans `copilot-instructions.md`:
- Confirmer appliquée dans code
- Signaler divergence entre doc et code réel
- Identifier conventions présentes dans code mais absentes instructions

### 5. Auditer les fichiers d'instructions agents

Lire 4 fichiers suivants dans `.github/instructions/`:
- `architect.instructions.md`
- `dev.instructions.md`
- `qa.instructions.md`
- `doc.instructions.md`

> Si un fichier est absent, le créer depuis le template correspondant dans `.github/instructions/` du dépôt transverse (`architect.instructions.template.md`, `dev.instructions.template.md`, `qa.instructions.template.md`, `doc.instructions.template.md`) et remplir les placeholders avec les valeurs du projet.

Pour chaque fichier, vérifier cohérence avec code source:
- `dev.instructions.md`: versions librairies, noms fichiers constantes, chemins dossiers
- `qa.instructions.md`: versions packages test, commandes CI, chemins rapport couverture
- `doc.instructions.md`: chemins docs/ locaux, noms fichiers doc, versions pour diagrammes `.puml`
- `architect.instructions.md`: noms couches, providers état, service HTTP, stratégie routing

En complément:
- Identifier placeholders `[...]` non remplis et signaler comme action nécessaire
- Identifier valeurs obsolètes (ex: version librairie outdatée)
- Vérifier cohérence workflow avec `MAINa` comme point d'entrée principal (si `Maina.agent.md` présent)

### 6. Auditer les skills partagés

Lire 4 skills suivants dans `.github/skills/` (si existent):
- `plan-phase-execution/SKILL.md`
- `plan-creation/SKILL.md`
- `fleet-guide/SKILL.md`
- `adr-writing/SKILL.md`

Pour chaque skill, vérifier:
- Frontmatter `applyTo: "**"` présent (inclusion auto dans contexte agent)
- Contenu cohérent avec `.github/PLANS.md` (pas divergence format)
- Agents `.github/agents/*.agent.md` référencent skills dans sections AP et /fleet (et répètent pas contenu)
- Identifier contenu dupliqué entre skill et agent (candidat extraction)

> 💡 **Parallélisation possible**: Étapes 2 (exploration structure), 3 (extraction conventions), 5 (audit instructions/) et 6 (audit skills/) sont **indépendantes** et peuvent être lancées en `/fleet` pour accélérer audit global.

## Règles de rédaction des amendements

1. **Pas supprimer** sections existantes sans raison explicite — préférer amender ou compléter
2. **Vérifier dans code** chaque convention avant ajouter: pas documenter hypothèses
3. **Rester concis**: instructions Copilot lues chaque session; éviter verbosité
4. **Conserver langue française** pour texte narratif
5. **Utiliser exemples code** issus code source réel quand utile
6. **Structurer ajouts** dans section pertinente existante, ou créer nouvelle section titrée si nécessaire
7. **Pas dupliquer** infos déjà présentes dans fichiers agents (`.github/agents/`)

## Format de livraison

Avant appliquer modifications:

1. Présenter **diff résumé** changements proposés:
   - Sections **ajouter** (avec justification et source dans code)
   - Sections **amender** (avec valeur actuelle et valeur corrigée)
   - Sections **supprimer** (si obsolètes — demander confirmation)
   - Sections **validées** (conformes au code, aucun changement)
   - Vérification agents `.github/agents/*.agent.md` à version courante (v3.0+)
   - Vérification skills `.github/skills/*/SKILL.md` présents et cohérents avec `PLANS.md`
   - Modifications proposées pour chaque fichier `.github/instructions/*.instructions.md` (créés depuis `*.instructions.template.md` si absents)
   - Signalement séparé placeholders non remplis vs valeurs obsolètes

2. Attendre **validation 👤 Développeur humain** avant appliquer modifications.

3. Une fois validé, appliquer changements dans `.github/copilot-instructions.md` et, si nécessaire, dans fichiers `.github/instructions/*.instructions.md` avec `replace_string_in_file` ou `multi_replace_string_in_file`.

4. Résumer modifications appliquées en liste à puces.