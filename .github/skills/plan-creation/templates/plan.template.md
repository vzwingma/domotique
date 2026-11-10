# Plan d'Action <NO> — <Titre explicite>

**Document :** `docs/plans/<NO>_<slug>.plan.md`
**Date de création :** AAAA-MM-JJ
**Statut :** ⏳ Planifié | 🔄 En cours | ✅ Complété | ❌ Bloqué
**Objectif Prioritaire :** HIGH | MEDIUM | LOW
**ADR associé :** `docs/adr/NNN-titre-court.md` — `Proposée` → `Acceptée` au Gate #1 (si décision majeure)

---

## 🎯 Objectif Global

[Problème ou besoin en 1-2 phrases.]
[Résultats attendus, mesurables.]

### Solution retenue (Gate #0)

[Option choisie par 👤 parmi l'analyse 🟠 ARCos + raison en une phrase.]

### Sources et non-régression (si dzVents)

- Lire `docs/Retroconception.md` avant toute évolution de comportement et `.github/tasks/todo/PLAN_ACTIONS_dzVents.md` avant roadmap/refactor.
- `global_data.lua` est la source de vérité pour `TYDOM_DEVICES`, helpers et état partagé; vérifier `Config_check.lua` pour les prérequis Domoticz.
- Préserver l'événement `Scene Phase`, l'état `Inconnue`, la corrélation `uuid`, les helpers HTTP centralisés et `verifyGroupeFromItem`.
- Aucun identifiant Tydom codé en dur; respecter la syntaxe timer dzVents documentée.

---

## 🛠️ Phases

### Phase 1 — <Titre> — ⏳ Planifié
**Contexte :** [situation actuelle, enjeux, dépendances]
**Critères de réussite :**
- ✅ [condition mesurable 1]
- ✅ [condition mesurable 2]

#### T1.1 - <Verbe d'action> <objet>
- **Agent :** 🔵 DEVon | 🟢 QALvin | 🟣 DOCly | 🟠 ARCos
- **Fichier(s) :** `chemin/exact`
- **Couvrir / Implémenter :**
  - [fonctionnalité]
  - [cas d'erreur / limites]
- **Acceptation :** [condition mesurable, ex. « ≥ 90 % couverture », « 5/5 tests verts »]

### Phase 2 — <Titre> — ⏳ Planifié
[...]

---

## 📊 Résumé par Agent

| Agent | Tâches | Livrable |
|---|---|---|
| 🔵 DEVon | T1.1 – T1.n | Code de production dans le périmètre validé |
| 🟢 QALvin | T2.1 – T2.n | Tests/contrôles nominaux, erreurs, limites et régression; couverture si mesurable |
| 🟣 DOCly | T3.1 – T3.n | Documentation synchronisée, ADR/plan/index si requis |

---

## 📍 Dépendances entre Phases

```
Phase 1 (code)    → Gate #2
    ↓ GO
Phase 2 (tests)   → Gate #3
    ↓ GO
Phase 3 (docs)    → Gate #4
```

---

## ✅ Critères de Succès Globaux

1. [mesure finale 1]
2. [mesure finale 2]

---

## 🚦 Journal des gates

| Gate | Date | Objet | Décision 👤 | Notes |
|---|---|---|---|---|
| #0 | AAAA-MM-JJ | Choix de solution | ✅ GO / 🔁 AJUSTER / ⛔ STOP | [...] |
| #1 | — | Validation plan | ⏳ En attente | — |
