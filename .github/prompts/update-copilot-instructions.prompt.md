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
- Chapitres indiqués _à compléter_ ou _à valider_

### 2. Explorer la structure du projet

Lister racine et sous-dossiers clés pour détecter nouveau domaine non documenté

### 3. Extraire les conventions réelles du code

Pour chaque couche/domaine identifié, rechercher et noter patterns réellement utilisés:

**Architecture**
- Couches applicatives (ex: Scene_*, Device_*, Groupes_*, Freebox_*, Tydom_*, global_*)
- Orchestration des flux (ex: scenePhase, événements custom, cross-scripts)
- Intégrations externes (HTTP, APIs tierces)
- Gestion d'état (état global, contexte, data locales)

**Conventions de nommage**
- Préfixes fichiers par domaine
- Noms variables globales
- Format événements personnalisés
- Conventions IDs/identifiants

**Sécurité**
- Gestion credentials (variables Domoticz, ENV vars)
- Pas hardcode secrets/URLs sensibles
- Auth patterns (oauth, tokens, etc.)

**Observabilité**
- Format logs (markers, uuid, niveaux)
- Tracing/correlation (uuid propagation)
- Health checks existants

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

> Si un fichier est absent, le créer depuis le template correspondant dans `.github/instructions/` (fichiers `.template.md`) et remplir les placeholders avec les valeurs du projet.

Pour chaque fichier, vérifier cohérence avec code source:
- `architect.instructions.md`: couches dzVents, patterns orchestration, décisions architecture, helpers centralisés
- `dev.instructions.md`: conventions dzVents, structure scripts, triggers, appels HTTP, nommage, logging
- `qa.instructions.md`: stratégie test dzVents, cas à couvrir, points de contrôle critiques
- `doc.instructions.md`: fichiers documentation, conventions rédaction, versions à maintenir

En complément:
- Identifier placeholders `[...]` non remplis et signaler comme action nécessaire
- Identifier valeurs obsolètes (ex: nom fichier, référence module changé)
- Vérifier cohérence workflow : ARCos (planification) → DEVon (impl) → QALvin (test) → DOCly (doc) comme point d'entrée principal

### 6. Auditer les skills partagés

Lire 4 skills suivants dans `.github/skills/` (si existent):
- `plan-phase-execution/SKILL.md`
- `plan-creation/SKILL.md`
- `fleet-guide/SKILL.md`
- `adr-writing/SKILL.md`

Pour chaque skill, vérifier:
- Frontmatter `applyTo: "**"` présent (inclusion auto dans contexte agent)
- Contenu cohérent avec `.github/plans/README.md` (pas divergence format)
- Agents `.github/instructions/*.instructions.md` référencent skills et workflow dans sections pertinentes
- Identifier contenu dupliqué entre skill et agent instructions (candidat extraction)

> 💡 **Parallélisation possible**: Étapes 2 (exploration structure), 3 (extraction conventions), 5 (audit instructions/) et 6 (audit skills/) sont **indépendantes** et peuvent être lancées en `/fleet` pour accélérer audit global.

## Règles de rédaction des amendements

1. **Pas supprimer** sections existantes sans raison explicite — préférer amender ou compléter
2. **Vérifier dans code** chaque convention avant ajouter: pas documenter hypothèses
3. **Rester concis**: instructions Copilot lues chaque session; éviter verbosité
4. **Conserver langue française** pour texte narratif, anglais pour blocs code
5. **Utiliser exemples code** issus code source réel quand utile
6. **Structurer ajouts** dans section pertinente existante, ou créer nouvelle section titrée si nécessaire
7. **Pas dupliquer** infos déjà présentes dans fichiers agents (`.github/instructions/`)

## Format de livraison

Avant appliquer modifications:

1. Présenter **diff résumé** changements proposés:
   - Sections **ajouter** (avec justification et source dans code)
   - Sections **amender** (avec valeur actuelle et valeur corrigée)
   - Sections **supprimer** (si obsolètes — demander confirmation)
   - Sections **validées** (conformes au code, aucun changement)
   - Vérification agents instructions (v4.2+ pour DEVon/QALvin/DOCly)
   - Vérification skills `.github/skills/*/SKILL.md` présents et cohérents
   - Modifications proposées pour chaque fichier `.github/instructions/*.instructions.md`
   - Signalement séparé placeholders non remplis vs valeurs obsolètes

2. Attendre **validation 👤 Développeur humain** avant appliquer modifications.

3. Une fois validé, appliquer changements dans `.github/copilot-instructions.md` et, si nécessaire, dans fichiers `.github/instructions/*.instructions.md` avec `replace_string_in_file` ou `multi_replace_string_in_file`.

4. Résumer modifications appliquées en liste à puces.