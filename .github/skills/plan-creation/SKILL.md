---
description: "Skill — Procédure de création et d'orchestration d'un Plan d'Action (AP). Utilisé par les agents orchestrateurs (ARCos et futurs agents de planification)."
applyTo: "**"
---

# Skill : Création d'un Plan d'Action (AP)

> Ce skill décrit la **procédure standard** pour créer, valider et lancer un Plan d'Action.
> Réservé aux agents ayant un rôle d'orchestration (ex: 🟠 ARCos).
> Référence complète du format AP : `.github/PLANS.md`

---

## Avant de créer un plan

1. **Clarifier le problème / l'objectif**
   - Quel est le besoin utilisateur ou technique ?
   - Quels sont les critères de succès mesurables ?
   - Y a-t-il des contraintes de temps, de ressources ou de technologie ?

2. **Structurer l'approche**
   - Quelles phases logiques sont nécessaires ?
   - Comment les phases dépendent-elles les unes des autres ?
   - Quel agent (DEVon, QUALvin, DOCly, ARCos) fera quoi ?

---

## Créer le fichier plan

Créer un fichier `.github/plans/<NO>_<nom>.plan.md` contenant :

1. **En-tête** : Titre, date, statut (`⏳ Planifié`), lien au document
2. **Objectif Global** : 1-2 paragraphes sur le problème et les outcomes attendus
3. **Phases** : 3-6 phases avec :
   - Contexte (situation actuelle, enjeux)
   - Critères de Réussite (3-5 conditions mesurables)
   - Tâches (T<N>.<M>) assignées à des agents
4. **Résumé par Agent** : Qui fait quoi, livrables, durée estimée
5. **Dépendances** : Diagramme montrant l'ordre d'exécution
6. **Critères de Succès Globaux** : Mesures finales du projet
7. **Plan d'Exécution** : Quand démarrer chaque phase, triggers

**Référence complète du format** : `.github/PLANS.md` (section "Format du Fichier Plan")

### Structurer les tâches

Chaque tâche doit avoir :
- **Numéro unique** : `T<PHASE>.<NUM>` (ex: T1.1, T2.3)
- **Agent assigné** : DEVon, QUALvin, DOCly, ARCos
- **Scope explicite** : Fichiers à créer/modifier, quoi couvrir
- **Critères mesurables** : "≥90% couverture", "5/5 tests passants", etc.

```markdown
#### T1.1 - <Verbe d'action> <objet>
- **Agent :** [QUALvin | DEVon | DOCly | ARCos]
- **Fichier(s) :** Chemin exact
- **Couvrir / Implémenter :**
  - Fonctionnalité 1
  - Cas d'erreur
- **Acceptation :** Condition mesurable (ex: ≥90% couverture)
```

---

## Créer le dossier reporting

```
.github/plans/<NO>_reports/
```

Ce dossier contiendra un rapport par phase :
- `PHASE_1_COMPLETION_REPORT.md`
- `PHASE_2_COMPLETION_REPORT.md`
- etc.

---

## Présenter et valider le plan

Avant de lancer les phases :

1. **Soumettre le plan** au 👤 Développeur humain pour validation
2. **Points de validation clés :**
   - Les phases sont-elles bien séparées logiquement ?
   - Les dépendances sont-elles correctes (pas de cycles) ?
   - Les tâches sont-elles claires et mesurables ?
   - Les agents assignés sont-ils appropriés ?
3. **Ajuster** en fonction du feedback

---

## Lancer une phase

Une fois le plan validé et les dépendances satisfaites :

1. **Vérifier les dépendances** : Toutes les phases précédentes sont ✅
2. **Identifier l'agent responsable** de cette phase
3. **Créer le rapport vide** : `.github/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md`
4. **Déléguer à l'agent** avec un prompt structuré incluant :
   - Lien vers le plan complet
   - Liste des tâches assignées (T<N>.X à T<N>.Y)
   - Lien vers le rapport à remplir
   - Critères de réussite et dépendances critiques

**Exemple de prompt de lancement :**
```
Exécute la Phase N du plan : .github/plans/<NO>_<nom>.plan.md

Tâches assignées : T<N>.1 à T<N>.M
Rapport à remplir : .github/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md

Critères de réussite :
- ✅ [Critère 1]
- ✅ [Critère 2]
```

---

## Valider et progresser

Après qu'une phase soit signalée comme complétée :

1. **Lire le rapport** : `.github/plans/<NO>_reports/PHASE_N_...md`
2. **Vérifier** : Tous les critères ✅, aucun bloqueur, livrables présents
3. **Décider** : La phase suivante peut-elle démarrer ?
4. **Mettre à jour** le statut du plan si changement global

---

## Règle obligatoire — Synchronisation de l'index des plans

- `.github/plans/README.md` doit contenir **uniquement** la liste des plans et leur **statut global**.
- À chaque création de plan ou changement de statut global, mettre à jour `.github/plans/README.md` dans le **même changement**.

---

## Checklist pour un bon plan

- [ ] Titre explicite et objectif mesurable
- [ ] 3-6 phases bien séparées avec dépendances claires
- [ ] Chaque tâche a : numéro, agent, fichiers, scope, critères d'acceptation
- [ ] Dépendances explicites (diagramme ou liste)
- [ ] Critères de succès globaux (5-7 items)
- [ ] Plan d'exécution avec triggers de démarrage

---

## Références

- 📋 Guide complet : `.github/PLANS.md`
- 📌 Index des plans : `.github/plans/README.md`
