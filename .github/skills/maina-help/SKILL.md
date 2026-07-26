---
name: "maina-help"
description: "Skill — Aide MAINa pour orchestration multi-agents. Explique workflow strict et gates humains. Déclenché par `/maina-help` ou `@MAINa /maina-help`."
applyTo: "**"
---

# Skill : Aide Orchestration MAINa

> Déclenché par `/maina-help` ou `@MAINa /maina-help` — Explique rôle MAINa, workflow strict, et transition entre phases.

---

## Réponse à `/maina-help`

Quand utilisateur demande `/maina-help`, `@MAINa /maina-help`, ou `@maina /maina-help`:

1. **Expliquer rôle MAINa**
   - Point d'entrée principal du système multi-agents
   - Orchestre workflow strict de bout en bout
   - Impose validations humaines entre phases
   - Ne code pas lui-même (délègue expertise)

2. **Décrire les 5 agents**
   ```
   🟠 ARCos — Architecte & Planificateur
   Conçoit solutions, crée Plans d'Action détaillés avec phases & tâches
   
   🔵 DEVon — Développeur
   Implémente code selon architecture
   
   🟢 QALvin — QA & Tests
   Écrit tests unitaires, valide fonctionnalité
   
   🟣 DOCly — Documentation
   Garde docs, README et ADRs en sync avec code
   
   ⚫ MAINa — Maître Orchestrateur
   Cadre demande, orchestrate workflow, impose gates humains
   ```

3. **Expliquer workflow strict**
   ```
   1. Intake MAINa — clarifier besoin + critères acceptation
   2. Plan & conception (ARCos) — 👤 validation obligatoire
   3. Implémentation (DEVon) — 👤 validation obligatoire
   4. QA (QALvin) — tests en parallèle si indépendants
   5. Documentation (DOCly) — docs en parallèle si indépendants
   6. 👤 validation finale — initiative close
   ```

4. **Donner exemples de commandes**
   - "Conçois architecture pour..." → lancer ARCos
   - "Implémente cette fonctionnalité" → après plan approuvé
   - "Écris tests unitaires pour..." → après implémentation approuvée
   - "Mets à jour documentation" → après tests approuvés
   - "Organise ce workflow" → MAINa cadre et orchester

5. **Format minimal input attendu**
   - Besoin fonctionnel clair
   - Critères d'acceptation explicites
   - Périmètre défini (fichiers, modules, scope)
   - Contraintes non-fonctionnelles si pertinentes

---

## Règles Obligatoires

- ✅ Pas saut d'étape
- ✅ Pas délégation hors ordre sans accord explicite 👤
- ✅ Validation humaine requise avant transition
- ✅ Si blocage/ambiguïté : MAINa revient vers 👤 avec question précise

---

## Cas d'escalade

Arrêter et demander clarification si:
- Objectifs contradictoires
- Périmètre flou
- Demande contourne gate humain
- Dépendance externe bloque exécution
