---
name: maina-help
description: "Aide du système multi-agents : rôle de MAINa, 5 agents, workflow strict avec gates humains #0→#4, commandes et format d'entrée attendu. Usage : /maina-help."
---

# Skill : Aide Orchestration MAINa

Répondre à `/maina-help` avec les sections ci-dessous, sans lancer de travail.

## 1. Rôle de MAINa

- Point d'entrée principal du système multi-agents
- Orchestre le workflow strict de bout en bout et crée le Plan d'Action
- Impose une validation humaine 👤 entre chaque phase (gates #0 → #4)
- Ne code, ne teste et ne documente pas lui-même : il délègue

**Lancer MAINa** : sélectionner l'agent MAINa dans le chat, ou `/maina <besoin>`.

## 2. Les 5 agents

```
⚫ MAINa  — Maître orchestrateur : cadre, crée le Plan d'Action, délègue, tient les gates
🟠 ARCos  — Architecte (lecture seule) : ≥ 2 options comparées + recommandation
🔵 DEVon  — Développeur : implémente selon le plan validé
🟢 QALvin — QA & tests : nominal + erreurs + limites, couverture
🟣 DOCly  — Documentation : README, docs/, ADR en sync avec le code
```

Les sous-agents n'échangent pas directement avec 👤 : leurs questions arrivent dans une section
`❓ Questions pour 👤`, que MAINa pose au gate suivant.

## 3. Workflow strict

```
1. Intake MAINa      — besoin + critères d'acceptation
2. ARCos             — ≥ 2 options + recommandation     → 👤 Gate #0 (choix solution)
3. MAINa             — Plan d'Action persisté           → 👤 Gate #1 (validation plan)
4. DEVon             — implémentation + preuves         → 👤 Gate #2 (validation code)
5. QALvin            — tests + couverture               → 👤 Gate #3 (validation tests)
6. DOCly             — documentation                    → 👤 Gate #4 (clôture)
```

Chaque gate est consigné dans le « Journal des gates » du plan. Pas de parallélisation entre phases
séparées par un gate.

## 4. Commandes

| Commande | Effet |
|---|---|
| `/maina <besoin>` | Orchestration complète |
| `/arcos <problème>` | Analyse d'options (lecture seule) |
| `/devon <tâche>` | Implémentation |
| `/qalvin <cible>` | Tests |
| `/docly <changements>` | Documentation |
| `/maina-help` | Cette aide |

## 5. Format minimal d'entrée

- Besoin fonctionnel clair
- Critères d'acceptation explicites
- Périmètre (fichiers, modules)
- Contraintes non-fonctionnelles si pertinentes

## Cas d'escalade

MAINa s'arrête et demande clarification si : objectifs contradictoires · périmètre flou · demande qui
contourne un gate humain · dépendance externe bloquante.
