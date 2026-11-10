# 📋 Plans d'Action (AP) — Guide

**Document :** `.github/PLANS.md`
**Objectif :** créer, exécuter et tracer les initiatives multi-phases orchestrées par ⚫ MAINa.

---

## 🎯 Qu'est-ce qu'un Plan d'Action ?

Un **Plan d'Action (AP)** est un document persisté qui :
- décrit un **objectif global** mesurable et la **solution retenue** (Gate #0) ;
- se décompose en **phases** et **tâches** `T<N>.<M>` assignées à un agent
  (🟠 ARCos, 🔵 DEVon, 🟢 QALvin, 🟣 DOCly) ;
- définit **critères de réussite** et **dépendances** ;
- trace chaque **gate humain** dans un journal ;
- s'accompagne d'un **rapport par phase** (preuves d'exécution).

Obligatoire pour toute initiative menant à une modification de code (règle MAINa, `copilot-instructions.md`).

---

## 📂 Structure

```
docs/plans/
├── README.md                    # Index : plans + statut global uniquement
├── <NO>_<slug>.plan.md          # Plan d'Action
├── <NO>_reports/
│   └── PHASE_N_COMPLETION_REPORT.md
└── archive/                     # Plans historiques
```

- `<NO>` : numéro séquentiel sur 3 chiffres (dernier plan + 1)
- `<slug>` : kebab-case descriptif (ex. `005_claude-first`)

---

## 📝 Formats (modèles)

| Document | Modèle | Procédure |
|---|---|---|
| Plan d'Action | [`skills/plan-creation/templates/plan.template.md`](skills/plan-creation/templates/plan.template.md) | skill `plan-creation` (⚫ MAINa) |
| Rapport de phase | [`skills/plan-phase-execution/templates/phase-report.template.md`](skills/plan-phase-execution/templates/phase-report.template.md) | skill `plan-phase-execution` (agents) |
| Bloc handoff (fin de réponse agent) | [`skills/plan-phase-execution/templates/handoff.template.md`](skills/plan-phase-execution/templates/handoff.template.md) | skill `plan-phase-execution` (agents) |
| Gate | — | skill `gate-protocol` (⚫ MAINa) |

### Règles de rédaction

- **Critères mesurables** : « ≥ 80 % couverture », « 5/5 tests verts » — jamais « bien », « suffisant ».
- **3-5 critères par phase**, **5-7 critères globaux**.
- **Tâche** = verbe d'action + objet, fichiers exacts, scope, critère d'acceptation, agent assigné.
- **Phases alignées sur les gates** : code → Gate #2 → tests → Gate #3 → docs → Gate #4.
- **Preuves** dans les rapports : commande lancée + résultat obtenu.

---

## 🔄 Cycle de vie

```
Intake ⚫ MAINa
   ↓
Analyse 🟠 ARCos (≥ 2 options)          → 👤 Gate #0 — choix de la solution
   ↓
Plan ⚫ MAINa (fichier + rapports + index) → 👤 Gate #1 — validation du plan
   ↓
Phase(s) 🔵 DEVon                        → 👤 Gate #2 — validation du code
   ↓
Phase(s) 🟢 QALvin                       → 👤 Gate #3 — validation des tests
   ↓
Phase(s) 🟣 DOCly                        → 👤 Gate #4 — validation doc + clôture
```

- Chaque gate suit le skill `gate-protocol` : livrable + preuves (bloc `handoff` de l'agent) présentés au 👤,
  revue automatique avant Gate #2, décision `GO` / `AJUSTER` / `STOP` consignée dans le **journal des gates**.
- Décision majeure : ADR rédigé en `Proposée` avant Gate #1, `Acceptée` au `GO` du Gate #1.
- Pas de parallélisation à travers un gate ; parallélisation possible **au sein** d'une phase
  (skill `parallel-guide`).
- Les sous-agents ne s'adressent pas au 👤 : questions dans `❓ Questions pour 👤`, posées par MAINa au gate.

### Lancer une phase (prompt type)

```
Exécute la Phase N du plan : docs/plans/<NO>_<slug>.plan.md
Tâches assignées : T<N>.1 à T<N>.M
Rapport à remplir : docs/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md
Critères de réussite : [...]
Questions ou blocages : section « ❓ Questions pour 👤 ».
```

### Index des plans

`docs/plans/README.md` liste **uniquement** les plans et leur statut global. Toute création de plan ou
changement de statut global le met à jour **dans le même changement**.

---

## ✅ Checklist — bon plan

- [ ] Titre explicite, objectif mesurable, solution retenue (Gate #0)
- [ ] 3-6 phases alignées sur les gates, dépendances sans cycle
- [ ] Chaque tâche : numéro, agent, fichiers, scope, critère d'acceptation
- [ ] Critères de succès globaux (5-7)
- [ ] Journal des gates initialisé
- [ ] Index `docs/plans/README.md` mis à jour

## ✅ Checklist — bon rapport de phase

- [ ] En-tête complet (plan, agent, dates, statut)
- [ ] Chaque tâche : statut, fichiers, résultats **avec preuves**, notes
- [ ] Synthèse : tâches X/Y, critères, bloqueurs, `❓ Questions pour 👤`
- [ ] Statut final `✅ COMPLÉTÉE — validation 👤 en attente`

---

## 📚 Exemples réels

- **AP 004** — Analyse critique & remédiation infra agents : [`docs/plans/004_analyse-critique-infra-agents.plan.md`](../docs/plans/004_analyse-critique-infra-agents.plan.md) (✅ Complété)
- **AP 005** — Refonte « Copilot-first » : [`docs/plans/005_claude-first.plan.md`](../docs/plans/005_claude-first.plan.md) + [`docs/plans/005_reports/`](../docs/plans/005_reports/) (journal des gates, rapports avec preuves)
