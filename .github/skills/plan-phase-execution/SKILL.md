---
name: plan-phase-execution
description: "Procédure standard d'exécution d'une phase de Plan d'Action (AP) : lecture du plan, exécution des tâches T<N>.<M> assignées, rapport de phase avec preuves, relais. Préchargée par ARCos, DEVon, QALvin et DOCly."
---

# Skill : Exécution de Phase d'un Plan d'Action (AP)

> Procédure commune à tous les agents exécutants. Chaque agent connaît son identifiant et ses relais.
> Modèles : rapport [`templates/phase-report.template.md`](templates/phase-report.template.md) · handoff [`templates/handoff.template.md`](templates/handoff.template.md) · Guide : `.github/PLANS.md`

---

## Avant de démarrer

1. **Lire le plan complet** : `docs/plans/<NO>_<slug>.plan.md`
2. **Identifier tes tâches** : ton identifiant agent dans la phase (`🔵 DEVon`, `🟢 QALvin`…)
3. **Lister tes tâches** (T<N>.X, T<N>.Y…) et leur séquence
4. **Vérifier les dépendances** : phases précédentes ✅ et gate précédent `GO` dans le journal des gates
5. **Rapport** : `docs/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md` (créer depuis le modèle si absent)

Agent en lecture seule (🟠 ARCos) : ne pas écrire le rapport — rendre son contenu dans la réponse,
⚫ MAINa l'écrit.

---

## Pendant l'exécution

Pour chaque tâche T<N>.<M> :

1. **Lire la tâche** : fichiers à toucher / tester / documenter, scope, critère d'acceptation.
2. **Exécuter** selon ton rôle, sans élargir le périmètre.
3. **Documenter dans le rapport** au fil de l'eau (statut, fichiers, résultats, notes).

Chaque résultat cite sa **preuve** : commande lancée et résultat obtenu (tests, lint, build, couverture).

---

## Après chaque tâche

- Mettre à jour le statut dans le rapport (🔄 → ✅ ou ❌)
- Vérifier que la tâche suivante peut démarrer (dépendances internes)

---

## À la fin de la phase

1. Remplir la **Synthèse de Phase** du rapport (tâches X/Y, critères, bloqueurs, questions).
2. Statut du rapport : `✅ COMPLÉTÉE — validation 👤 en attente`.
3. Rendre la main à ⚫ MAINa pour le gate : résumé court, puis **bloc `handoff`** (YAML, modèle
   [`templates/handoff.template.md`](templates/handoff.template.md)) en toute fin de réponse —
   fichiers, critères avec preuve, commandes + résultats, risques, questions, suite.
   Relais vers l'agent suivant **seulement après** validation du gate.

> 💡 Session longue : avant la phase suivante, `/compact` (instructions de compaction : `copilot-instructions.md`).

---

## Règle obligatoire — Synchronisation de l'index des plans

- `docs/plans/README.md` = index **plans + statut global uniquement** (jamais de détail de phase).
- Mise à jour entraînant un changement de **statut global** → mettre à jour l'index dans le **même changement**.

---

## Références

- 📋 Guide complet : `.github/PLANS.md`
- 📊 Rapports : `docs/plans/<NO>_reports/`
- 📌 Index : `docs/plans/README.md`
