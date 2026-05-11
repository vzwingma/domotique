---
description: "Skill — Guide de parallélisation avec /fleet pour tous les agents. Appliqué automatiquement."
applyTo: "**"
---

# Skill : Parallélisation avec /fleet

> `/fleet` est le mode d'exécution parallèle du CLI Copilot.
> Il dispatche plusieurs sous-agents simultanément, réduisant le temps total d'exécution.

---

## Quand utiliser /fleet

- **Tâches indépendantes du même agent** : Plusieurs composants / services / fichiers sans dépendance entre eux
- **Délégation multi-agents en parallèle** : Deux agents peuvent démarrer en même temps (ex: QUALvin + DOCly sur la même feature après DEVon)
- **Phases parallèles d'un Plan d'Action** : Quand deux phases peuvent s'exécuter simultanément

---

## Quand NE PAS utiliser /fleet

- Quand la tâche B **dépend du résultat** de la tâche A
- Quand deux sous-tâches **modifient le même fichier** (risque de conflit)
- Quand un fichier de setup commun doit être créé d'abord

---

## Comment indiquer l'usage de /fleet

Dans ton plan ou ta délégation, signaler explicitement les tâches parallélisables :

```
💡 Ces tâches sont indépendantes → lancer en /fleet :
- Tâche A (Agent X)
- Tâche B (Agent Y)
```

---

## Règle de décision

| Situation | Mode recommandé |
|---|---|
| Tâche B dépend de la tâche A | Séquentiel |
| Tâches A et B sans lien | `/fleet` |
| DEVon terminé → QUALvin + DOCly | `/fleet` pour QUALvin + DOCly |
| Plusieurs éléments indépendants à traiter | `/fleet` |
