# Phase 1 : Fusion des consignes et migration des plans

**Plan :** `docs/plans/008_harmonisation-templates-et-plans.plan.md`
**Responsable Agent :** 🟣 DOCly
**Date Début :** 2026-11-10
**Date Fin :** 2026-11-10
**Statut :** ✅ COMPLÉTÉE — Gate #2 GO

---

## Tâches

### T1.1 — Fusionner les consignes actives et corriger leurs références

**Statut :** ✅ DONE

**Fichiers créés / modifiés :**
- `.github/copilot-instructions.md` et `.github/instructions/*.instructions.md` — consignes projet fusionnées; règles dzVents conservées.
- `.github/agents/*.agent.md`, `.github/agents/README.md`, `.github/README.md`, `.github/PLANS.md`, skills et prompts — références alignées sur les consignes actives.
- Modèles de consignes projet `.template.md` supprimés après fusion.
- `docs/ARCHITECTURE.template.md` conservé comme modèle générique; le contexte Domoticz reste dans `docs/ARCHITECTURE.md`.

**Résultats (preuves) :**
- Les cinq rôles disposent d'instructions actives (`orchestrator`, `architect`, `dev`, `qa`, `doc`).
- Recherche `rg` des références aux anciens modèles : aucune référence opérationnelle restante; seules subsistent les mentions historiques, les critères du plan 008 et la détection de l'ancien chemin dans `init-harness`.

### T1.2 — Migrer le répertoire des plans vers `docs/plans/`

**Statut :** ✅ DONE

**Fichiers créés / modifiés :**
- Plans 001 à 007 et rapports 001 déplacés dans `docs/plans/`; rapport du plan 008 et index global créés.
- ADR 001–004, plans déplacés, modèles de planification, guide et procédures mis à jour.
- Ancien index `.github/plans/README.md` supprimé après fusion dans `docs/plans/README.md`.

**Résultats (preuves) :**
- `Get-ChildItem docs\\plans` confirme les plans 001 à 008 et leurs répertoires de rapports.
- Le contrôle complet des liens et chemins est réservé à la validation statique T2.1.

---

## Synthèse de Phase

**Tâches complétées :** 2/2
**Critères de réussite :** consignes fusionnées et migration documentaire effectuée; vérification statique des liens et contenus en phase 2.
**Bloqueurs :** aucun.
**Questions pour 👤 :** aucune.
**Prochaine phase :** Phase 2 lancée après Gate #2 GO.
