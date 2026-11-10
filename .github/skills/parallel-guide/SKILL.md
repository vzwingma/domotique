---
name: parallel-guide
description: "Quand et comment paralléliser le travail des agents au sein d'une phase de Plan d'Action (tâches indépendantes) sans jamais franchir un gate humain. À consulter avant de lancer plusieurs sous-agents ou tâches simultanément."
---

# Skill : Parallélisation des tâches

> Règle d'or : on parallélise **à l'intérieur** d'une phase, **jamais à travers un gate humain**
> (DOCly attend Gate #3, QALvin attend Gate #2).

---

## Quand paralléliser

- **Tâches indépendantes d'un même agent** dans une phase : composants, services ou fichiers sans dépendance
- **Phases d'un Plan d'Action sans gate entre elles** et sans dépendance

## Quand NE PAS paralléliser

- Tâche B **dépend du résultat** de tâche A
- Deux tâches **modifient le même fichier** (conflit)
- Un fichier commun (setup, types partagés) doit être créé d'abord
- Les tâches sont séparées par un **gate humain**

---

## Comment

- Utiliser `/fleet` pour dispatcher plusieurs sous-agents simultanément.

Signaler explicitement dans le plan ou la délégation :

```
💡 Tâches indépendantes (même phase) → en parallèle :
- T2.1 Implémenter `ComponentA` (🔵 DEVon)
- T2.2 Implémenter `ServiceB` (🔵 DEVon)
```

---

## Règle de décision

| Situation | Mode |
|---|---|
| Tâche B dépend de tâche A | Séquentiel |
| Tâches A et B sans lien, même phase | Parallèle |
| DEVon terminé → QALvin puis DOCly | Séquentiel (Gate #2 puis Gate #3) |
| Plusieurs éléments indépendants, même fichier | Séquentiel |
| Plusieurs éléments indépendants, fichiers distincts | Parallèle |
