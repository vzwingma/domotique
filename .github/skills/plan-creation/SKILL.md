---
name: plan-creation
description: "Procédure de création, validation et lancement d'un Plan d'Action (AP) multi-phases : fichier plan persisté, dossier de rapports, index, gates humains. Utilisée par ⚫ MAINa (préchargée) dès qu'une initiative mène à une modification de code."
---

# Skill : Création d'un Plan d'Action (AP)

> Réservé à ⚫ MAINa — responsable création et orchestration des Plans d'Action.
> Modèle de fichier : [`templates/plan.template.md`](templates/plan.template.md) · Guide : `.github/PLANS.md`

---

## Avant de créer un plan

1. **Clarifier problème / objectif** — besoin, critères de succès mesurables, contraintes.
2. **Gate #0 franchi** — solution choisie par 👤 parmi l'analyse 🟠 ARCos (≥ 2 options).
3. **Structurer** — phases logiques, dépendances, agent responsable de chaque tâche.

---

## Créer le fichier plan

1. Numéro : dernier plan de `docs/plans/` + 1 (3 chiffres).
2. Copier [`templates/plan.template.md`](templates/plan.template.md) en `docs/plans/<NO>_<slug>.plan.md`.
3. Remplir : en-tête, objectif global, solution retenue, 3-6 phases (contexte, critères, tâches),
   résumé par agent, dépendances, critères de succès globaux, **journal des gates** (Gate #0 déjà rempli).

Chaque tâche :
- **Numéro unique** `T<PHASE>.<NUM>` (ex. T1.1, T2.3)
- **Agent assigné** : 🔵 DEVon, 🟢 QALvin, 🟣 DOCly, 🟠 ARCos
- **Scope explicite** : fichiers à créer/modifier, quoi couvrir
- **Acceptation mesurable** : « ≥ 90 % couverture », « 5/5 tests verts »…

Ordre des phases aligné sur les gates : code → Gate #2 → tests → Gate #3 → docs → Gate #4.
Pas de parallélisation entre phases séparées par un gate.

## Règle de persistance obligatoire

Livrable = fichiers persistés dans le dépôt, dans le même changement :
- `docs/plans/<NO>_<slug>.plan.md`
- `docs/plans/<NO>_reports/`
- `docs/plans/README.md` mis à jour (plan + statut global)

Outils d'édition interdits ou consigne « ne modifier aucun fichier » → ne pas présenter un faux plan
« créé ». Demander au 👤 : autoriser la création des fichiers, ou recevoir un brouillon non formalisé.

---

## ADR (décision majeure)

Décision structurante (techno, pattern, sécurité — critères du skill `adr-writing`) : faire rédiger l'ADR
par 🟣 DOCly sur le contenu 🟠 ARCos **avant** Gate #1, statut `Proposée`, et le référencer dans l'en-tête
du plan.

## Présenter et valider le plan — Gate #1

Suivre le skill `gate-protocol` (preuves, question, journal) :

1. Soumettre le plan au 👤 (chemins créés + résumé phases/tâches + ADR `Proposée` éventuel).
2. Points de validation : phases séparées, dépendances sans cycle, tâches mesurables, agents appropriés.
3. Décision `GO` / `AJUSTER` / `STOP` consignée dans le journal des gates ; `GO` → ADR `Acceptée`.

---

## Lancer une phase

Quand le plan est validé et les dépendances satisfaites :

1. Vérifier que les phases précédentes sont ✅ et le gate précédent `GO`.
2. Identifier l'agent responsable.
3. Créer le rapport depuis le modèle du skill `plan-phase-execution` :
   `docs/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md`.
4. Déléguer avec un prompt structuré :

```
Exécute la Phase N du plan : docs/plans/<NO>_<slug>.plan.md
Tâches assignées : T<N>.1 à T<N>.M
Rapport à remplir : docs/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md
Critères de réussite :
- ✅ [Critère 1]
- ✅ [Critère 2]
Questions ou blocages : section « ❓ Questions pour 👤 » de ta réponse.
```

## Valider et progresser

Après phase signalée complétée :

1. Lire le rapport : critères ✅, preuves présentes, aucun bloqueur.
2. Conduire le gate de fin de phase selon le skill `gate-protocol` (preuves du bloc `handoff`, revue
   automatique avant Gate #2, questions relayées au 👤) et consigner la décision.
3. Mettre à jour le statut du plan ; démarrer la phase suivante seulement après `GO`.

---

## Règle obligatoire — Synchronisation de l'index des plans

- `docs/plans/README.md` contient **uniquement** la liste des plans + **statut global**.
- À chaque création de plan ou changement de statut global : mise à jour dans le **même changement**.

---

## Checklist d'un bon plan

- [ ] Titre explicite + objectif mesurable
- [ ] Solution retenue (Gate #0) rappelée
- [ ] 3-6 phases avec dépendances claires, alignées sur les gates
- [ ] Chaque tâche : numéro, agent, fichiers, scope, critère d'acceptation
- [ ] Critères de succès globaux (5-7 items)
- [ ] Journal des gates initialisé
