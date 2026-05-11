---
description: "Skill — Procédure d'exécution de phase d'un Plan d'Action (AP). Appliqué automatiquement à tous les agents."
applyTo: "**"
---

# Skill : Exécution de Phase d'un Plan d'Action (AP)

> Ce skill décrit la **procédure standard** pour qu'un agent exécute une phase d'un Plan d'Action.
> Chaque agent connaît son propre identifiant et ses cibles de délégation (voir ses instructions).
> Référence complète du format AP : `.github/PLANS.md`

---

## Avant de démarrer

1. **Lire le plan complet** : `.github/plans/<NO>_<nom>.plan.md`
2. **Identifier tes tâches** : Chercher ton identifiant d'agent dans la phase (ex: `🔵 DEVon`, `🟢 QUALvin`, etc.)
3. **Lister les tâches** assignées (T<N>.X, T<N>.Y, etc.) et leur séquence
4. **Comprendre les dépendances** : Quelle(s) phase(s) doit-on compléter avant la tienne
5. **Identifier le rapport à remplir** : `.github/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md`

---

## Pendant l'exécution

Pour chaque tâche T<N>.<M> :

1. **Lire la tâche en détail** dans le plan
   - Quel(s) fichier(s) toucher / tester / documenter
   - Quoi couvrir / implémenter
   - Critères d'acceptation mesurables

2. **Exécuter la tâche** selon ton rôle

3. **Documenter dans le rapport de phase** en temps réel

**Format de documentation par tâche :**
```markdown
### T<N>.<M> - [Titre de la tâche]

**Statut :** ✅ DONE (ou 🔄 IN_PROGRESS, ❌ BLOCKED)

**Fichiers Créés / Modifiés :**
- `path/to/file1.ts` — [Brève description]
- `path/to/file2.tsx` — [Brève description]

**Résultats :**
- Critère 1 : ✅ Atteint (ex: "Coverage 92% ≥90%")
- Critère 2 : ✅ Atteint

**Notes :**
[Décisions, problèmes rencontrés, hypothèses]
```

---

## Après chaque tâche

- ✅ Mettre à jour le statut dans le rapport (🔄 → ✅ ou ❌)
- ✅ Vérifier que la tâche suivante peut démarrer (dépendances internes)

---

## À la fin de la phase

Remplir la **Synthèse de Phase** dans le rapport :

```markdown
## 📊 Synthèse de Phase

**Tâches Complétées :** X/Y ✅
**Critères de Réussite Atteints :**
- ✅ Critère 1
- ✅ Critère 2

**Bloqueurs :** Aucun ❌
**Prochaine Phase :** Phase X peut démarrer (toutes les dépendances ✅)
```

Puis **signaler à l'agent suivant** selon tes instructions de délégation.

---

## Règle obligatoire — Synchronisation de l'index des plans

- `.github/plans/README.md` est un index **plans + statut global uniquement** (jamais de détails de phases).
- Si tes mises à jour entraînent un changement de **statut global** du plan, mets à jour `.github/plans/README.md` dans le **même changement**.

---

## Références

- 📋 Guide complet : `.github/PLANS.md`
- 📋 Plan courant : `.github/plans/<NO>_<nom>.plan.md`
- 📊 Rapports existants : `.github/plans/<NO>_reports/`
- 📌 Index des plans (synthétique) : `.github/plans/README.md`
