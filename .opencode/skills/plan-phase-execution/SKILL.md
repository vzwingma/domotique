---
name: "plan-phase-execution"
description: "Skill — Procédure d'exécution de phase d'un Plan d'Action (AP). Appliqué automatiquement à tous les agents."
---

# Skill : Exécution de Phase d'un Plan d'Action (AP)

> Skill décrit **procédure standard** pour agent exécute phase Plan Action.
> Chaque agent connaît propre identifiant et cibles délégation (voir instructions).
> Référence complète format AP : `.opencode/PLANS.md`

---

## Avant de démarrer

1. **Lire plan complet** : `.opencode/plans/<NO>_<nom>.plan.md`
2. **Identifier tes tâches** : Chercher ton identifiant agent dans phase (ex: `🔵 DEVon`, `🟢 QALvin`, etc.)
3. **Lister tâches** assignées (T<N>.X, T<N>.Y, etc.) et séquence
4. **Comprendre dépendances** : Quelle(s) phase(s) doit-on compléter avant tienne
5. **Identifier rapport à remplir** : `.opencode/plans/<NO>_reports/PHASE_N_COMPLETION_REPORT.md`

---

## Pendant l'exécution

Pour chaque tâche T<N>.<M> :

1. **Lire tâche en détail** dans plan
   - Quel(s) fichier(s) toucher / tester / documenter
   - Quoi couvrir / implémenter
   - Critères acceptation mesurables

2. **Exécuter tâche** selon ton rôle

3. **Documenter dans rapport phase** en temps réel

**Format documentation par tâche :**
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

- ✅ Mettre à jour statut dans rapport (🔄 → ✅ ou ❌)
- ✅ Vérifier que tâche suivante peut démarrer (dépendances internes)

---

## ⚡ Compact avant phase suivante (recommandé)

Avant de déclencher la phase suivante, recommander `/compact` pour éviter l'accumulation de skill blobs en contexte :

```
/compact
Instruction : Résume en 200 mots max — phase courante, numéro, tâches restantes (T<N>.X), décisions clés prises.
Supprime : blobs skill des phases précédentes, historique détaillé résolu, confirmations ("oui", "go", etc.).
```

> 💡 Sans compact entre phases, chaque skill injecté (~4-8KB) reste en contexte pour tous les tours suivants. Sur 4 phases, cela représente ~20-30KB de contexte inutile accumulé.

---

## À la fin de la phase

Remplir **Synthèse Phase** dans rapport :

```markdown
## 📊 Synthèse de Phase

**Tâches Complétées :** X/Y ✅
**Critères de Réussite Atteints :**
- ✅ Critère 1
- ✅ Critère 2

**Bloqueurs :** Aucun ❌
**Prochaine Phase :** Phase X peut démarrer (toutes les dépendances ✅)
```

Puis **signaler à agent suivant** selon tes instructions délégation.

---

## Règle obligatoire — Synchronisation de l'index des plans

- `.opencode/plans/README.md` est index **plans + statut global uniquement** (jamais détails phases).
- Si tes mises à jour entraînent changement **statut global** plan, mets à jour `.opencode/plans/README.md` dans **même changement**.

---

## Références

- 📋 Guide complet : `.opencode/PLANS.md`
- 📋 Plan courant : `.opencode/plans/<NO>_<nom>.plan.md`
- 📊 Rapports existants : `.opencode/plans/<NO>_reports/`
- 📌 Index plans (synthétique) : `.opencode/plans/README.md`