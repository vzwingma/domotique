---
name: gate-protocol
description: "Protocole des gates humains #0→#4 du workflow strict : livrable et preuves exigés par gate, revue automatique avant Gate #2, question GO / AJUSTER / STOP, consignation dans le journal des gates, cycle de vie de l'ADR. Préchargé par ⚫ MAINa."
---

# Skill : Protocole de gate

> Un gate est un **arrêt obligatoire** : ⚫ MAINa présente le livrable et ses preuves au 👤, obtient une
> décision explicite, la consigne, et n'avance que sur `GO`. Aucun gate n'est sauté, fusionné ou présumé.

---

## Déroulé (chaque gate)

1. **Collecter** le livrable et le **bloc `handoff`** de l'agent (skill `plan-phase-execution`).
2. **Contrôler les preuves** exigées (table ci-dessous). Preuve manquante ou `status: blocked` non expliqué →
   relancer l'agent **avant** de solliciter le 👤 (pas de gate sur un livrable incomplet).
3. **Présenter** au 👤 en ≤ 15 lignes : livrable (chemins), preuves (commandes + résultats), écarts au plan,
   risques, questions `❓` remontées par les agents.
4. **Demander la décision** :
demander explicitement « Gate #N — <objet> : GO / AJUSTER / STOP ? » et attendre la réponse 👤.
5. **Consigner** une ligne dans la section « 🚦 Journal des gates » du plan (date, objet, décision, notes).
6. **Agir** :
   - `GO` → phase suivante (relais prévu dans le handoff) ;
   - `AJUSTER` → relancer le **même** agent avec les retours, puis refaire le gate ;
   - `STOP` → statut du plan `❌ Bloqué` (raison en notes), index `docs/plans/README.md` mis à jour, ADR en `Rejetée`.

---

## Preuves exigées par gate

| Gate | Livrable | Preuves exigées avant de solliciter le 👤 |
|---|---|---|
| **#0** — choix solution | Analyse 🟠 ARCos | ≥ 2 options comparées (avantages / inconvénients / risques / effort), recommandation motivée |
| **#1** — validation plan | Plan d'Action + ADR (si décision majeure) | Chemins créés : plan, `<NO>_reports/`, index mis à jour ; ADR en statut `Proposée` |
| **#2** — validation code | Code 🔵 DEVon | Handoff : fichiers modifiés, build + lint + tests existants **verts** (commandes + résultats) ; `git diff --stat` de la phase ; **revue automatique** (ci-dessous) |
| **#3** — validation tests | Tests 🟢 QALvin | Tests créés/modifiés, résultats, couverture vs seuil (`conventions-qa`), preuve de détection de régression |
| **#4** — clôture | Docs 🟣 DOCly | Fichiers de doc modifiés, liens vérifiés, ADR `Acceptée`, statut du plan et index à jour |

---

## Revue automatique avant Gate #2

Lancer une revue de code Copilot sur le diff de la phase si disponible et joindre la synthèse (findings bloquants / non bloquants).

---

## Cycle de vie de l'ADR

| Moment | Statut | Qui |
|---|---|---|
| Après Gate #0 (décision majeure) | Rédigé en `Proposée` | 🟠 ARCos prépare, 🟣 DOCly écrit (skill `adr-writing`) |
| Gate #1 `GO` | `Acceptée` | ⚫ MAINa met à jour le statut |
| `STOP` | `Rejetée` | ⚫ MAINa |
| Décision remplacée plus tard | `Remplacée par ADR-NNN` | 🟣 DOCly |

---

## Ligne de journal

```markdown
| #2 | 2026-10-12 | Validation code phase 1 | ✅ GO | build/lint/tests ✅ ; code-review : 0 bloquant, 2 mineurs (suivis T2.4) |
```

Décisions : `✅ GO` · `🔁 AJUSTER` (+ retours résumés) · `⛔ STOP` (+ raison).
