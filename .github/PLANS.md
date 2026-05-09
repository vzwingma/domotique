# 📋 Guide de référence — Plans d'Action (AP)

Ce document définit le cadre standard pour créer, exécuter et suivre les Plans d'Action du repo.

---

## 1) But des Plans d'Action et artefacts

Un Plan d'Action (AP) sert à piloter une initiative multi-phases avec responsabilités explicites par agent.

### Artefacts obligatoires

- **Plan** : `.github/plans/<NO>_<slug>.plan.md`
- **Rapports de phase** : `.github/plans/<NO>_reports/PHASE_<N>_COMPLETION_REPORT.md`
- **Index global** : `.github/plans/README.md` (liste des plans + statut global uniquement)

---

## 2) Convention de nommage

### Fichier plan

`<NO>_<slug>.plan.md`

- `<NO>` : numéro séquentiel sur 3 chiffres (`001`, `002`, `003`, ...)
- `<slug>` : nom court en minuscules, séparé par `_` (ex: `modernisation_complete`)

### Dossier rapports

`<NO>_reports/`

### Rapport de phase

`PHASE_<N>_COMPLETION_REPORT.md` (ex: `PHASE_1_COMPLETION_REPORT.md`)

---

## 3) Format standard d’un fichier plan (`*.plan.md`)

## 3.1 Métadonnées

- Titre du plan
- Date
- Statut global (`PLANIFIÉ`, `EN_COURS`, `BLOQUÉ`, `COMPLÉTÉ`)
- Auteur / validateur

## 3.2 Objectif global

- Problème à résoudre
- Résultat attendu (outcome)

## 3.3 Périmètre

- **In scope**
- **Out of scope**

## 3.4 Phases (3 à 6 en général)

Pour chaque phase :
- Contexte
- Critères de réussite mesurables
- Tâches

## 3.5 Tâches `T<N>.<M>`

Chaque tâche doit contenir :
- **Agent assigné** (`ARCos`, `DEVon`, `QALvin`, `DOCly`)
- **Fichiers ciblés** (paths explicites)
- **Contenu attendu** (quoi faire)
- **Critères d’acceptation** mesurables

## 3.6 Dépendances explicites

- Dépendances entre phases
- Dépendances entre tâches critiques
- Aucun cycle

## 3.7 Critères de succès globaux

- 5 à 8 critères finaux vérifiables

## 3.8 Risques et mitigations

- Risque
- Impact
- Mitigation

## 3.9 Plan d’exécution

- Ordre de lancement des phases
- Triggers de passage à la phase suivante
- Conditions de blocage / reprise

---

## 4) Format standard des rapports de phase (`PHASE_N_COMPLETION_REPORT.md`)

Structure minimale recommandée :

```markdown
# PHASE <N> — COMPLETION REPORT

## Contexte
- Plan : `.github/plans/<NO>_<slug>.plan.md`
- Phase : <N>
- Agent(s) : ...

## Tâches
### T<N>.<M> - <Titre>
**Statut :** ✅ DONE | 🔄 IN_PROGRESS | ❌ BLOCKED

**Fichiers touchés :**
- `path/...` — description courte

**Résultats / vérifications :**
- Critère 1 : ✅/❌
- Critère 2 : ✅/❌

**Notes :**
- Décisions, limites, points de vigilance

## Synthèse de phase
- Tâches complétées : X/Y
- Critères atteints : ...
- Bloqueurs : ...
- Recommandation : phase suivante possible (oui/non)
```

---

## 5) Règles de gouvernance

- `.github/plans/README.md` **ne doit pas détailler les phases**.
- `.github/plans/README.md` = **plans + statut global uniquement**.
- Toute création de plan ou changement de statut global d’un plan impose la **synchronisation immédiate** de `.github/plans/README.md` dans le même changement.

---

## 6) Workflow agents

Chaîne nominale :

1. `ARCos` : conçoit et structure le plan
2. `DEVon` : implémente
3. `QALvin` : teste et valide
4. `DOCly` : met à jour la documentation

Validation humaine attendue entre étapes critiques.

---

## 7) Checklist qualité (synthétique)

- [ ] Objectif global clair
- [ ] Périmètre in/out explicite
- [ ] 3 à 6 phases cohérentes
- [ ] Tâches `T<N>.<M>` avec agent, fichiers, acceptation
- [ ] Dépendances explicites sans cycle
- [ ] Critères de succès globaux mesurables
- [ ] Risques + mitigations documentés
- [ ] Plan d’exécution clair
- [ ] Dossier de rapports prévu
- [ ] Index `.github/plans/README.md` synchronisé (statut global)

---

## 8) Exemple minimal — squelette de plan

```markdown
# Plan d'Action — <Titre>

## Métadonnées
- ID : <NO>
- Fichier : `.github/plans/<NO>_<slug>.plan.md`
- Statut global : PLANIFIÉ
- Date : YYYY-MM-DD

## Objectif global
<1-2 paragraphes>

## Périmètre
### In scope
- ...
### Out of scope
- ...

## Phases
### Phase 1 — <Titre>
**Contexte :** ...
**Critères de réussite :**
- ...

#### T1.1 - <Titre tâche>
- **Agent :** DEVon
- **Fichiers :** `path/a`, `path/b`
- **À faire :** ...
- **Acceptation :** ...

### Phase 2 — <Titre>
...

## Dépendances
- Phase 2 dépend de Phase 1

## Critères de succès globaux
- ...

## Risques / mitigations
- Risque : ...
  - Mitigation : ...

## Plan d'exécution
1. Lancer Phase 1
2. Vérifier rapport `PHASE_1_COMPLETION_REPORT.md`
3. Lancer Phase 2
```

