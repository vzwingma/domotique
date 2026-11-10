# 🤖 Agents Copilot — Architecture Multi-Agents

Système orchestré de 5 agents spécialisés pour structurer développement via GitHub Copilot.

## ⚙️ Configuration

Modèle, outils et sous-agents autorisés : voir le frontmatter de chaque `*.agent.md`.

### Périmètre vérifié

Cette projection vise uniquement GitHub Copilot CLI. Versions observées : `1.0.99-0`, puis `1.0.99-1`.
VS Code et cloud agent sont hors périmètre ; aucune affirmation de support ou de parité ne s'applique à ces
surfaces.

Les cinq profils sont générés depuis `.github/`. Les outils sont dérivés par
`scripts/copilot-mapping.psd1` ; ARCos reçoit `[read, search, web]`. Les alias source sont `opus` →
`claude-opus-5.5` et `sonnet` → `claude-sonnet-5.5`. Le champ `agents` de MAINa est informatif et non vérifié.

La CLI lit `.github/skills/` et `.github/skills/` ; `.github/` gagne à nom identique. Le chargement est fait
selon pertinence, non de façon déterministe : chaque profil porte une consigne explicite de chargement.
Les conventions sont projetées en `.github/instructions/<rôle>.instructions.template.md`.

## 🎯 Agents

### ⚫ [MAINa](./Maina.agent.md) — Maître Orchestrateur

**Quand** : Point d'entrée pour tout travail complexe

Rôle : Comprendre besoin, créer le Plan d'Action, orchestrer workflow strict, imposer validations humaines entre phases.

**Workflow strict** :
1. Intake → Clarifier besoin
2. ARCos → Analyse solutions (≥2 options + reco)
3. Gate #0 → Choix solution par développeur
4. MAINa → Crée le Plan d'Action
5. Gate #1 → Validation plan
6. DEVon → Implémentation
7. Gate #2 → Validation code
8. QALvin → Tests
9. Gate #3 → Validation tests
10. DOCly → Documentation
11. Gate #4 → Clôture

---

### 🟠 [ARCos](./Arcos.agent.md) — Architecte (consulté par MAINa)

**Quand** : "Conçois une architecture pour", "Analyse les options pour"

Rôle : Analyse de solutions, conception, décisions architecturales. **MAINa** crée le Plan d'Action.

**Responsabilités** :
- Poser clarifications nécessaires
- Présenter ≥2 solutions alternatives + comparaison
- Fournir une recommandation motivée à MAINa
- Concevoir solution retenue + préparer contenu ADR
- Fournir le découpage candidat comme entrée au Plan d'Action de MAINa

**Points clés** :
- ✅ Pas coder — Réfléchir stratégiquement
- ✅ Proposer options, laisser choix au développeur
- ✅ Specs claires pour MAINa et agents en aval
- ❌ Pas créer le Plan d'Action (rôle MAINa)
- ❌ Pas présupposer détails implémentation

---

### 🔵 [DEVon](./Devon.agent.md) — Implémentateur

**Quand** : "Implémente cette fonctionnalité", "Code selon architecture"

Rôle : Implémentation code production.

**Responsabilités** :
- Traduire exigences en code qualité production
- Respecter patterns architecturaux + conventions projet
- Assurer code propre, testé, maintenable
- Identifier et gérer cas limites

**Points clés** :
- ✅ Implémenter exactement ce qui demandé, pas plus
- ✅ Étudier patterns existants
- ✅ Code compile, s'exécute, s'intègre correctement
- ❌ Pas de dérive périmètre
- ❌ Pas concevoir architecture
- ❌ Pas écrire tests

---

### 🟢 [QALvin](./Qalvin.agent.md) — Expert QA

**Quand** : "Écris des tests", "Ajoute tests unitaires"

Rôle : Tests unitaires, couverture qualité.

**Responsabilités** :
- Écrire tests unitaires complets (composants, services)
- Exécuter + vérifier passage avec couverture ≥80%
- Identifier cas limites, conditions erreur, scénarios frontières
- Mocker dépendances externes

**Points clés** :
- ✅ Minimum 80% couverture code
- ✅ Tests maintenables, lisibles
- ✅ Cas limites + erreurs couverts
- ❌ Pas écrire code implémentation
- ❌ Pas documenter

---

### 🟣 [DOCly](./Docly.agent.md) — Gardien Documentation

**Quand** : "Mets à jour doc", "Garde docs en sync"

Rôle : Documentation après code + tests validés.

**Responsabilités** :
- Mettre à jour README.md, `docs/ARCHITECTURE.md`
- Créer/maintenir ADRs dans `docs/adr/`
- Assurer cohérence terminologie, structure, qualité
- Identifier + corriger infos obsolètes

**Hiérarchie priorité** :
1. README.md (plus visible)
2. `docs/ARCHITECTURE.md` (**obligatoire**)
3. `docs/adr/` (décisions archi)
4. `docs/` guides détaillés
5. Instructions agents

**Points clés** :
- ✅ Tous exemples code testés
- ✅ Liens valides, terminologie cohérente
- ✅ Aucune info obsolète
- ❌ Pas concevoir architecture
- ❌ Pas coder

---

## 📋 Workflow typique

```
👤 Développeur cadre besoin
    ↓
⚫ MAINa intake + clarification
    ↓
🟠 ARCos présente options → ✅ décision développeur (Gate #0)
    ↓
⚫ MAINa crée Plan d'Action → ✅ validation développeur (Gate #1)
    ↓
🔵 DEVon implémente → ✅ validation développeur (Gate #2)
    ↓
🟢 QALvin écrit tests → ✅ validation développeur (Gate #3)
    ↓
🟣 DOCly synchronise docs → ✅ validation développeur (Gate #4)
    ↓
✅ Clôture initiative
```

**Validation humaine obligatoire** à chaque étape avant progression.

---

## 🔐 Règles absolues

Tous agents respectent :
- ⛔ Ne JAMAIS supprimer fichiers/répertoires
- ⛔ Ne JAMAIS commandes SQL destructives
- ⛔ Ne JAMAIS `git clean`, `git reset --hard`
- ⛔ Ne JAMAIS modifier fichiers hors périmètre
- ⛔ Respect ABSOLU `.copilotignore`

En cas doute → demander confirmation développeur.

---

## 🚀 Démarrage

```bash
# Pour projet simple ou décision rapide
@ARCos "Conçois architecture pour..."
```

```bash
# Pour initiative complète : sélectionner l'agent MAINa dans le chat
@MAINa "Voici besoin : ..."
```

Chaque profil Copilot suit les instructions projet générées et charge explicitement les skills demandées ;
la sélection finale des skills reste déterminée par la pertinence de la CLI.
<!-- /copilot-only
