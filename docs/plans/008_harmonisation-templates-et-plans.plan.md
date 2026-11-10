# Plan d'Action 008 — Harmonisation des consignes et migration des plans

**Document :** `docs/plans/008_harmonisation-templates-et-plans.plan.md`
**Date de création :** 2026-11-10
**Statut :** ✅ Complété
**Priorité :** HIGH
**ADR associé :** `docs/adr/005-plans-docs-et-instructions-projet.md` — Acceptée

---

## Objectif global

Supprimer les divergences entre les consignes projet actives et leurs modèles, puis établir `docs/plans/` comme emplacement unique des Plans d'Action, rapports et index. Préserver les consignes domotique existantes et les modèles génériques réutilisables.

### Solution retenue (Gate #0)

Option B recommandée par ARCos et approuvée par 👤 le 2026-11-10 : fusionner les modèles de consignes projet dans les fichiers actifs `.md` plutôt que les écraser, créer le fichier actif d'orchestration, puis migrer les plans et toutes leurs références vers `docs/plans/`.

### Exception de séquencement proposée

Cette initiative est documentaire, sans code de production. L'ordre normal DEVon → Gate #2 → QALvin → Gate #3 → DOCly n'est pas directement applicable : DOCly doit réaliser la migration documentaire avant que QALvin puisse la vérifier. L'ordre proposé est DOCly → Gate #2 → QALvin → Gate #3 → DOCly (corrections de clôture) → Gate #4. Cette exception et l'absence de phase DEVon sont soumises à l'approbation explicite du Gate #1.

---

## Phases

### Phase 1 — Fusion des consignes et migration des plans — ✅ Complétée

**Contexte :** les modèles projet `.template.md` divergent des consignes `.md` actives; les agents chargent les fichiers actifs. Les plans sont actuellement sous `.github/plans/`, alors que la destination retenue est `docs/plans/`.

**Critères de réussite :**
- Chaque fichier actif de consignes contient les règles utiles du modèle correspondant et les règles projet encore valides; aucun contenu critique dzVents n'est perdu.
- `orchestrator.instructions.md` existe et le profil MAINa ainsi que la documentation des agents pointent vers les fichiers actifs `.instructions.md`.
- Les plans 001 à 008, leurs rapports, et l'index sont sous `docs/plans/`; aucun plan ne reste dans `.github/plans/`.
- Les références opérationnelles aux plans, rapports et index ciblent `docs/plans/`; les liens relatifs déplacés sont valides.

#### T1.1 — Fusionner les consignes actives et corriger leurs références
- **Agent :** 🟣 DOCly
- **Fichiers :** `.github/copilot-instructions.md`, `.github/instructions/{architect,dev,doc,qa}.instructions.md`, créer `.github/instructions/orchestrator.instructions.md`, profils `.github/agents/*.agent.md`, `.github/README.md`, `.github/agents/README.md`.
- **Couvrir :**
  - Fusionner les contenus projet des modèles dans les fichiers actifs sans remplacer le contenu métier valide.
  - Préserver les règles de non-régression dzVents, les sources de vérité, les conventions de logs et les limites QA; corriger seulement les références avérées obsolètes dans le périmètre.
  - Pointer les profils d'agents vers les fichiers actifs; conserver les modèles génériques réutilisables (plan, rapport de phase, handoff, ADR et architecture).
- **Acceptation :** les cinq rôles disposent d'un fichier actif; aucun rôle ne demande de lire son template générique au lieu des consignes projet; aucune règle projet active n'est perdue.

#### T1.2 — Migrer le répertoire des plans vers `docs/plans/`
- **Agent :** 🟣 DOCly
- **Fichiers :** déplacer `.github/plans/` vers `docs/plans/`; mettre à jour `.github/PLANS.md`, skills de planification et de gate, ADR 001–004, modèles concernés, prompts et références dans les plans.
- **Couvrir :**
  - Préserver les noms, contenus, statuts et rapports existants.
  - Corriger les liens relatifs qui changent de profondeur et l'index global.
  - Faire de `docs/plans/README.md` l'unique index des plans et de leur statut global.
- **Acceptation :** tous les plans 001–008 et rapports existants résident sous `docs/plans/`; aucune référence opérationnelle ne dirige vers `.github/plans/`; les références historiques du changelog ne sont pas réécrites.

### Phase 2 — Vérification statique des références et contenus — ✅ Complétée

**Contexte :** vérifier la migration avant corrections de clôture; aucune exécution du système Domoticz n'est nécessaire.

**Critères de réussite :**
- Tous les liens relatifs des fichiers déplacés et des instructions concernées sont résolus.
- Aucune référence active à `.github/plans/` ou à un fichier de consignes projet `.template.md` ne subsiste.
- Les règles métier dzVents des contrôles DEV-1, DEV-2, DEV-4, DEV-5 et les règles de timer sont toujours présentes.

#### T2.1 — Vérifier les liens, chemins et règles préservées
- **Agent :** 🟢 QALvin
- **Fichiers :** documentation et instructions modifiées en Phase 1.
- **Couvrir :** liens Markdown relatifs, chemins de plans, existence des cibles, références restantes, conservation des règles dzVents et cohérence de l'index.
- **Acceptation :** rapport listant les commandes de recherche/vérification et leurs résultats; zéro lien cassé et zéro référence opérationnelle à l'ancien répertoire.

### Phase 3 — Corrections documentaires et clôture — ✅ Complétée

**Contexte :** appliquer les corrections issues de la vérification QA, puis confirmer l'alignement final de l'ADR, des plans et des index.

**Critères de réussite :**
- Tous les constats QA bloquants sont corrigés et revérifiés.
- L'ADR 005 reflète la décision finalement validée au Gate #1.
- Le statut global du plan et l'index sont cohérents.

#### T3.1 — Corriger les constats QA et synchroniser la clôture
- **Agent :** 🟣 DOCly
- **Fichiers :** fichiers signalés par T2.1, ADR 005, `docs/plans/README.md`.
- **Couvrir :** corrections ciblées, liens, statut ADR et statut global du plan.
- **Acceptation :** aucun constat QA bloquant ouvert; index des plans et statut ADR conformes aux décisions humaines.

---

## Résumé par agent

| Agent | Tâches | Livrable |
|---|---|---|
| 🟣 DOCly | T1.1, T1.2, T3.1 | Instructions fusionnées, migration des plans et corrections documentaires |
| 🟢 QALvin | T2.1 | Vérification statique des liens, chemins et règles préservées |

---

## Dépendances entre phases

```text
Phase 1 — DOCly : fusion et migration
    ↓ Gate #2 — revue du diff documentaire
Phase 2 — QALvin : vérifications statiques
    ↓ Gate #3
Phase 3 — DOCly : corrections et synchronisation
    ↓ Gate #4 — clôture
```

Cette séquence documentaire déroge à l'ordre générique et nécessite le GO explicite du Gate #1.

---

## Critères de succès globaux

1. `docs/plans/` contient tous les plans existants, les rapports associés et l'index global.
2. Aucun répertoire `.github/plans/` ni référence opérationnelle à celui-ci ne subsiste.
3. Les consignes actives des cinq rôles sont cohérentes avec leurs descriptions et règles projet.
4. Les règles dzVents DEV-1, DEV-2, DEV-4, DEV-5 et la syntaxe timer restent présentes.
5. Tous les liens locaux touchés sont valides et `git diff --check` ne rapporte aucune erreur.
6. Les vrais modèles génériques réutilisables restent disponibles avec des noms explicites de template.

---

## Journal des gates

| Gate | Date | Objet | Décision 👤 | Notes |
|---|---|---|---|---|
| #0 | 2026-11-10 | Choix de solution | ✅ GO | Option B ARCos : fusion sans perte, consignes actives uniques et migration finale vers `docs/plans/`. |
| #1 | 2026-11-10 | Validation du plan et de l'exception DOCly → QALvin | ✅ GO | Plan accepté; exception d'ordre documentaire approuvée. ADR 005 accepté. |
| #2 | 2026-11-10 | Validation de la migration documentaire | ✅ GO | 👤 GO à 15:47; revue automatique : le modèle d'architecture projet-spécifique a été remplacé par un modèle générique; 58 fichiers Markdown contrôlés, 0 lien local cassé, `git diff --check` sans erreur. |
| #3 | 2026-11-10 | Validation QA statique | ✅ GO | 👤 GO à 15:50; QA-1 (doublon du plan 008 dans l'index) transmis à DOCly pour correction T3.1. |
| #4 | 2026-11-10 | Documentation et clôture | ✅ GO | 👤 GO à 15:51; index sans doublon, rapports et ADR 005 cohérents, initiative clôturée. |
