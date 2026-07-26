# 📋 Plans d'Action (AP) — Documentation Centralisée

**Document :** `.opencode/PLANS.md`  
**Objectif :** Guide centralisé pour créer, exécuter et tracker les plans d'action multi-phases.

---

## 🎯 Qu'est-ce qu'un Plan d'Action (AP) ?

Un **Plan d'Action (AP)** est un document structuré qui :
- Décrit un **objectif global** (ex: modernisation, nouvelle feature, refactoring majeur)
- Se décompose en **phases logiques** et **tâches détaillées**
- Assigne les tâches à des **agents spécifiques** (MAINa/⚫ orchestration, ARCos/🟠 ARC architecture, DEVon/🔵 DEV, QALvin/🟢 QUAL, DOCly/🟣 DOC)
- Définit les **critères de réussite** et les **dépendances** entre phases
- Génère des **rapports de phase** documentant l'exécution et les résultats

**Cas d'usage :**
- Moderniser l'infrastructure et les tests (AP-001 : Modernisation Complète)
- Implémenter une grande fonctionnalité cross-team
- Refactoriser un domaine métier complexe
- Coordonner des mises à jour dépendantes

---

## 📂 Structure des Répertoires

```
.opencode/
├── PLANS.md                              # Ce document (guide centralisé)
├── plans/
│   ├── 001_feature_1.plan.md    # Fichier plan principal
│   ├── 001_reports/                          # Dossier de reporting
│   │   ├── PHASE_1_COMPLETION_REPORT.md
│   │   ├── PHASE_2_COMPLETION_REPORT.md
│   │   └── PHASE_N_FINAL_REVIEW.md
│   ├── 002_nouvelle_feature.plan.md          # Autre plan
│   ├── 002_reports/
│   │   └── PHASE_1_...
│   └── README.md                        # Index des plans actifs/archivés
└── ...
```

**Conventions de nommage :**
- Fichier plan : `.opencode/plans/<NO>_<nom_descriptif>.plan.md`
  - `<NO>` : Numéro séquentiel (001, 002, 003...)
  - `<nom_descriptif>` : Slug lisible en français ou anglais
  - Exemple : `001_modernisation_complète.plan.md`
- Dossier reporting : `.opencode/plans/<NO>_reports/`
  - Contient les rapports de phase (`PHASE_1_...`, `PHASE_2_...`, etc.)
  - Un rapport par phase complétée

---

## 📝 Format du Fichier Plan (`.plan.md`)

### 1. En-tête (Métadonnées)

```markdown
# Plan d'Action : <Titre Explicite>

**Document :** `.opencode/plans/<NO>_<nom>.plan.md`  
**Date de création :** YYYY-MM-DD  
**Statut :** ✅ Complété | 🔄 En cours | ⏳ Planifié | ❌ Bloqué  
**Objectif Prioritaire :** [HIGH | MEDIUM | LOW]

---
```

### 2. Objectif Global (1-2 paragraphes)

```markdown
## 🎯 Objectif Global

[Décrire le problème ou le besoin en 1-2 phrases]
[Lister les domaines d'amélioration ou les outcomes attendus]

Exemple :
"Moderniser l'application domoticz-mobile en améliorant la couverture de test, 
les dépendances à jour, l'architecture du code et la performance. 
Objectifs : couverture ≥80%, 0 dépendances dépréciées, 0 breaking changes, 
documentation exhaustive."
```

### 3. Phases (Une par section)

Chaque phase doit contenir :

#### A. Contexte
```markdown
### Contexte
- [Situation actuelle / problèmes identifiés]
- [Dépendances avec d'autres phases]
- [Ressources/outils disponibles]
```

#### B. Critères de Réussite
```markdown
### Critères de Réussite
✅ [Condition testable 1]  
✅ [Condition testable 2]  
✅ [Condition testable 3]  
```

**Bonnes pratiques :**
- Utiliser "≥X%" plutôt que "bien", "suffisant"
- Mesurable et vérifiable
- Lister 3-5 critères max par phase

#### C. Tâches
```markdown
### Tâches (Agent: [MAINa (⚫) | ARCos (🟠 ARC) | DEVon (🔵 DEV) | QALvin (🟢 QUAL) | DOCly (🟣 DOC)])

#### T<N>.<M> - <Titre de la Tâche>
- **Fichier :** `path/to/file.ts` (ou liste si multiple)
- **Couvrir/Implémenter :**
  - Point 1
  - Point 2
- **Acceptation :** Condition mesurable

#### T<N>.<M+1> - <Autre Tâche>
- ...
```

**Numérotation :**
- `T<PHASE>.<NUMERO>` : T1.1, T1.2, T2.1, T3.3, etc.
- Unique par phase
- Ordre d'exécution recommandé

**Template de tâche :**
```markdown
#### T<N>.<M> - <Verbe d'action> <objet> (<scope optionnel>)

- **Fichier(s) :** Chemin exact des fichiers à créer/modifier
- **Couvrir / Implémenter :**
  - Fonctionnalité 1 (avec détails)
  - Fonctionnalité 2
  - Cas d'erreur ou edge cases
- **Acceptation :** Condition mesurable et testable
  - ✓ ≥90% couverture (si tests)
  - ✓ Tous les cas couverts (si logique)
  - ✓ Performance < 1s (si perf)
```

### 4. Résumé des Tâches par Agent

```markdown
## 📊 Résumé des Tâches par Agent

### Devon (🔵 DEV) Agent
- T2.1 à T2.8 : Mise à jour des dépendances
- T3.1 à T3.5 : Refactorisation architecture
- **Livrable :** Dépendances à jour, code refactorisé, tests passant
- **Durée estimée :** 2-3 semaines

### Qalvin (🟢 QUAL) Agent
- T1.1 à T1.7 : Tests unitaires + rapport de couverture
- **Livrable :** Tests ≥80% couverture
- **Durée estimée :** 1-2 semaines
```

### 5. Dépendances entre Phases

```markdown
## 📍 Dépendances entre Phases

```
Phase 1 (Tests)
    ↓
Phase 2 (Dépendances) ← [Phase 1 doit être ✅]
    ↓
Phase 3 (Architecture) ← [Phase 2 doit être ✅]
    ↓
Phase 4 (Performance) ← [Phase 3 doit être ✅]
    ↓
Phase 5 (CI/CD) ← [Phases 1, 2, 3 doivent être ✅]
    ↓
Phase 6 (Docs) ← [Phases 1-5 doivent être ✅]
```

**Règles :**
- Phase X peut démarrer si toutes ses dépendances sont ✅
- Indiquer explicitement les "dépend de" avec `←`
- Phases sans dépendances = peuvent démarrer en parallèle
```

### 6. Critères de Succès Globaux

```markdown
## ✅ Critères de Succès Globaux

1. **Couverture de test ≥80%** (Phase 1)
2. **0 dépendances dépréciées** (Phase 2)
3. **0 `any` non-justifiés** (Phase 3)
4. **Bundle size stable ou ↓** (Phase 4)
5. **CI/CD 100% passing** (Phase 5)
6. **Documentation à jour** (Phase 6)
```

### 7. Plan d'Exécution

```markdown
## 🚀 Plan d'Exécution

1. **Semaine 1-2 :** Lancer Phase 1 (Qalvin (🟢 QUAL) agent)
2. **Semaine 2-3 :** Lancer Phase 2 (Devon (🔵 DEV) agent, après Phase 1 ✅)
3. **Semaine 3-4 :** Lancer Phases 3-4 en parallèle (Devon (🔵 DEV) agent)
4. **Semaine 4-5 :** Lancer Phase 5 (Arkos (🟠 ARC), après Phase 3 ✅)
5. **Semaine 5-6 :** Lancer Phase 6 en parallèle (Docly (🟣 DOC))

**Triggers pour démarrer une phase :**
- Tous les rapports de la phase précédente ✅ COMPLÉTÉE
- Tous les critères de réussite atteints
- Pas de bloqueurs signalés
```

---

## 📈 Rapports de Phase (Execution Tracking)

### Structure du Reporting

Pour chaque plan, créer un dossier `.opencode/plans/<NO>_reports/` avec un rapport par phase :

```
.opencode/plans/001_reports/
├── PHASE_1_COMPLETION_REPORT.md
├── PHASE_2_COMPLETION_REPORT.md
├── PHASE_3_COMPLETION_REPORT.md
└── PHASE_6_FINAL_REVIEW.md
```

### Format d'un Rapport de Phase

```markdown
# Phase N : <Titre de la Phase>

**Responsable Agent :** [Devon (🔵 DEV) | Qalvin (🟢 QUAL) | Arkos (🟠 ARC) | Docly (🟣 DOC)]  
**Date Début :** YYYY-MM-DD  
**Date Fin :** YYYY-MM-DD (ou TBD si en cours)  
**Statut :** ✅ COMPLÉTÉE | 🔄 EN_COURS | ⏳ PLANIFIÉE | ❌ BLOQUÉE

---

## 📝 Tâches

### T<N>.<M> - <Titre Tâche>

**Statut :** ✅ DONE | 🔄 IN_PROGRESS | ⏳ PENDING | ❌ BLOCKED  
**Date Fin :** YYYY-MM-DD (ou en cours si 🔄)

**Fichiers Modifiés / Créés :**
- `path/to/file1.ts` — [Brève description des changements]
- `path/to/file2.tsx` — [Ajout du composant X, refactorisation de Y]

**Résultats Quantifiés :**
- Coverage : 92% (critère : ≥90% ✅)
- Tests : 25/25 passants ✅
- Build time : 4min45s (vs. 5min avant) ✅

**Notes / Décisions :**
- [Problème rencontré et comment il a été résolu]
- [Hypothèses faites]
- [Améliorations futures identifiées (non implémentées)]

---

### T<N>.<M+1> - ...

[Répéter pour chaque tâche]

---

## 📊 Synthèse de Phase

**Tâches Complétées :** 7/7 ✅  
**Critères de Réussite Atteints :**
- ✅ Couverture ≥80%
- ✅ Tous les services testés
- ✅ Tous les controllers testés
- ✅ Composants critiques testés
- ✅ Aucun regression

**Bloqueurs :** Aucun ❌  
**Améliorations Futures :**
- [ ] Ajouter tests E2E pour les workflows critiques
- [ ] Augmenter couverture à ≥90%

---

## 📦 Livrables

✅ Tous les tests unitaires écrits et passants  
✅ Rapport de couverture dans `coverage/`  
✅ Aucune regression (tous les tests existants passent)  

---

**Rapport approuvé par :** [Utilisateur/Lead]  
**Date d'approbation :** YYYY-MM-DD  

Fin du rapport Phase N
```

---

## 🔄 Workflow de Suivi

### 1. Créer le Plan (Utilisateur / MAINa (⚫) / ARCos (🟠 ARC))

```bash
# Créer le fichier plan
touch .opencode/plans/00X_<nom>.plan.md

# Remplir :
# - Objectif global
# - Phases avec contexte, critères, tâches
# - Dépendances
# - Critères de succès
# - Plan d'exécution
```

**Validation :**
- [ ] Phases bien séparées avec dépendances claires
- [ ] Chaque tâche a un scope explicite et des critères mesurables
- [ ] Agents assignés sont cohérents avec les tâches
- [ ] Plan de dépendances est acyclique

### 2. Démarrer une Phase (Agent Responsable)

```bash
# 1. Lire le plan complet
cat .opencode/plans/<NO>_<nom>.plan.md

# 2. Identifier les tâches assignées
# Exemple : Agent Qalvin (🟢 QUAL) cherche "T<N>.<M>" où l'agent est "Qalvin (🟢 QUAL)"

# 3. Créer le rapport de phase
mkdir -p .opencode/plans/<NO>_reports/
touch .opencode/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md

# 4. Exécuter les tâches T<N>.1, T<N>.2, etc.
# 5. Documenter en temps réel dans le rapport
```

### 3. Documenter Pendant l'Exécution

Pour chaque tâche complétée :
```markdown
### T<N>.<M> - [Titre]

**Statut :** ✅ DONE (mise à jour depuis 🔄 IN_PROGRESS)
**Date Fin :** YYYY-MM-DD

**Fichiers Modifiés :**
- `app/services/__tests__/ClientHTTP.service.test.ts` — Ajout 50 tests
- `app/services/ClientHTTP.service.ts` — Nettoyage lint

**Résultats :**
- Coverage : 92% (critère ≥90% ✅)
- Tests : 50/50 passing

**Notes :**
- Découvert et fixé [bug X] qui bloquait les tests de mock API
```

### 4. Compléter le Reporting (Après la Phase)

Remplir la **synthèse de phase** :
```markdown
## 📊 Synthèse de Phase

**Tâches Complétées :** 7/7 ✅
**Critères de Réussite Atteints :**
- ✅ Critère 1
- ✅ Critère 2
- ✅ Critère 3

**Bloqueurs :** Aucun
**Prochaine Phase :** Phase X peut démarrer (toutes les dépendances ✅)
```

### 5. Valider et Archiver (Utilisateur / Lead)

```bash
# Approuver le rapport
# Lister dans README si archivé
# Créer issue GitHub pour tracking si souhaité
```

---

## 🎯 Intégration avec les Agents

Chaque agent doit recevoir un **prompt structuré** qui :
1. **Pointe vers le plan** (`.opencode/plans/<NO>_<nom>.plan.md`)
2. **Identifie ses tâches** (T<N>.X où agent = [son rôle])
3. **Spécifie le rapport à remplir** (`.opencode/plans/<NO>_reports/PHASE_N_...`)

**Exemple de prompt pour Qalvin (🟢 QUAL) :**
```
Exécute la Phase 1 du plan : .opencode/plans/001_modernisation_complète.plan.md

**Tâches assignées :**
- T1.1 : Tests ClientHTTP.service
- T1.2 : Tests DataUtils.service
- ... (T1.1 à T1.7)

**Rapport à remplir :**
- `.opencode/plans/001_reports/PHASE_1_COMPLETION_REPORT.md`

**Pour chaque tâche, documenter :**
- Fichiers créés/modifiés
- Résultats (coverage %, test count, etc.)
- Notes et décisions
- Statut final (✅ DONE ou ❌ BLOCKED + raison)

**À la fin :**
- Remplir la synthèse de phase
- Confirmer critères de réussite atteints
- Signaler tout bloqueur pour la phase suivante
```

**Chaîne de délégation entre agents :**
```
MAINa (⚫) (orchestration + gates humains)
    ↓
ARCos (🟠 ARC) (plan)
    ↓
Devon (🔵 DEV) (T2.1-T3.5)
    ├→ Qalvin (🟢 QUAL) (valider + écrire tests)
    └→ Docly (🟣 DOC) (documenter changements)
```

---

## ✅ Checklist pour un Bon Plan

- [ ] **Titre explicite** (ex: "Modernisation Complète", pas "AP-001")
- [ ] **Objectif clair** (1-2 phrases, mesurable)
- [ ] **Phases bien séparées** (3-6 phases généralement)
- [ ] **Chaque phase a :**
  - [ ] Contexte (situation actuelle)
  - [ ] Critères de réussite (3-5, mesurables)
  - [ ] Tâches numérotées (T<N>.<M>)
  - [ ] Agent responsable identifié
- [ ] **Chaque tâche a :**
  - [ ] Titre avec verbe d'action
  - [ ] Fichiers précis
  - [ ] Scope explicite (quoi couvrir / implémenter)
  - [ ] Critères d'acceptation testables
- [ ] **Dépendances explicites** (diagramme ou liste)
- [ ] **Critères de succès globaux** (5-7 items)
- [ ] **Plan d'exécution** (quand démarrer chaque phase, triggers)

---

## ✅ Checklist pour un Bon Rapport de Phase

- [ ] **En-tête complet** (Agent, dates, statut)
- [ ] **Chaque tâche documente :**
  - [ ] Statut final (✅ DONE, ❌ BLOCKED, etc.)
  - [ ] Fichiers modifiés/créés (paths précis)
  - [ ] Résultats mesurés (coverage %, count, etc.)
  - [ ] Notes pertinentes
- [ ] **Synthèse de phase :**
  - [ ] Tâches complétées (X/Y)
  - [ ] Critères de réussite atteints (checklist)
  - [ ] Bloqueurs identifiés (le cas échéant)
  - [ ] Améliorations futures (optional)
- [ ] **Livrables clairs** (liste de ce qui a été produit)

---

## 📚 Exemples Existants

- **AP-001 :** Modernisation Complète
  - Plan : `.opencode/plans/001_modernisation_complète.plan.md`
  - Rapports : `.opencode/plans/001_reports/PHASE_*_*.md`
  - Phases : 1 (Tests), 2 (Dépendances), 3 (Architecture), 4 (Performance), 5 (CI/CD), 6 (Docs)
  - Statut : 🔄 Phase 1 en cours

---

## 🚀 Lancer un Nouveau Plan

1. **Créer le fichier** `.opencode/plans/<NO>_<nom>.plan.md`
2. **Remplir** objectif global, phases, tâches, dépendances
3. **Valider** que les tâches sont mesurables et les agents assignés
4. **Créer le dossier** `.opencode/plans/<NO>_reports/`
5. **Lancer la Phase 1** avec l'agent responsable
6. **Suivre** via les rapports de phase

---

**Fin de la documentation sur les Plans d'Action**


