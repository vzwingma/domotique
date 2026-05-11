# ADR 001 — Intégration API officielle jours fériés (calendrier.api.gouv.fr)

---

**Date :** 2026-05-09  
**Statut :** Acceptée  
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Les scènes matinales de Domoticz (Scene_0, Scene_1, Scene_2a) fonctionnaient selon deux grilles horaires : semaine (7h00, 7h45, 8h05) et week-end (8h00, 9h50, 10h00). Les jours fériés tombant en semaine déclenchaient les horaires tôt, sans mécanisme permettant d'appliquer la grille tardive (week-end). Il fallait une source de vérité des jours fériés, un stockage accessible depuis tous les scripts dzVents, et une logique de guard dans les scènes concernées.

---

## Décision

**Nous avons décidé d'** intégrer l'API officielle française `calendrier.api.gouv.fr` via un script dédié `JoursFeries_API.lua`, de stocker les jours fériés dans `globalData.joursFeries` (table de lookup Lua), et d'exposer le helper centralisé `isJourFerie(domoticz)` dans `global_data.lua` — consulté par les scènes via un pattern double-slot dans le planificateur Domoticz.

---

## Alternatives Considérées

### Option 1 : API officielle + cache globalData + double-slot Domoticz ✅ Retenue

- **Avantages** :
  - Liste toujours à jour sans maintenance manuelle
  - API publique, gratuite, officielle (data.gouv.fr)
  - `globalData` est le mécanisme dzVents standard d'état partagé inter-scripts
  - Guard centralisé via helper réutilisable par n'importe quel script futur
  - Comportement conservatif sûr : si liste vide → `false` (les scènes s'exécutent à l'heure semaine)
  - Self-healing : `JoursFeries Refresh` auto-déclenché si liste vide + health check quotidien
- **Inconvénients** :
  - Dépendance réseau externe (HTTPS)
  - Nécessite un 3e slot horaire ajouté manuellement dans le planificateur Domoticz pour chaque scène concernée

### Option 2 : Liste statique hard-codée dans `global_data.lua`

- **Avantages** : Aucune dépendance externe, entièrement offline
- **Inconvénients** : Mise à jour manuelle annuelle obligatoire, risque d'oubli
- **Raison du rejet** : Charge de maintenance, source d'erreur humaine annuelle

### Option 3 : Variable Domoticz booléenne mise à jour manuellement

- **Avantages** : Simple à implémenter, pas de dépendance externe
- **Inconvénients** : Entièrement manuelle, ne couvre pas les jours fériés futurs, fragile
- **Raison du rejet** : Ne répond pas à l'objectif d'automatisation ; trop contraignant à opérer

---

## Conséquences

### Positives
- Jours fériés gérés automatiquement chaque année sans intervention
- Pattern guard réutilisable (`isJourFerie`, `isWeekEnd`) extensible à de futurs scripts
- Health check quotidien (indicateur #5) surveille la fraîcheur de la liste
- Auto-rechargement on-demand via customEvent `JoursFeries Refresh`

### Négatives / Compromis
- Action manuelle irréductible : ajout d'un 3e déclenchement lun-ven dans l'interface Domoticz pour chaque scène concernée (hors portée dzVents)
- Fenêtre de risque au reboot : `globalData.joursFeries` vide jusqu'au prochain appel API (mitigation : comportement conservatif + refresh on-demand à la première consultation)
- Dépendance à la disponibilité de `calendrier.api.gouv.fr`

### Neutres
- `docs/ARCHITECTURE.md` mis à jour (sections 2.5, 3.2, 4.2, 5.3, 6.2, 7)
- `Health_check_dzVents.lua` étendu avec un 5e indicateur de santé

---

## Mise en œuvre

- **Fichiers créés :** `domoticz/scripts/dzVents/JoursFeries_API.lua`
- **Fichiers modifiés :**
  - `global_data.lua` — ajout `JOURS_FERIES_API_URL`, `isJourFerie()`, `isWeekEnd()`, `data.joursFeries`
  - `Scene_0_PreparationChauffage.lua`, `Scene_1_Reveil.lua`, `Scene_2a_Journee.lua` — guards double-slot
  - `Health_check_dzVents.lua` — indicateur #5 jours fériés
  - `docs/ARCHITECTURE.md` — documentation de l'intégration
- **Action manuelle Domoticz :** ajouter déclenchement lun-ven 08:00 / 09:50 / 10:00 pour les 3 scènes
- **Date d'effet :** 2026-05-09 (plan 003 COMPLÉTÉ)

---

## Références

- [API Jours Fériés — calendrier.api.gouv.fr](https://calendrier.api.gouv.fr/)
- [Plan d'Action associé : `.github/plans/003_jours_feries.plan.md`]
