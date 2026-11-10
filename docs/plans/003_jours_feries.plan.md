# Plan d'Action 003 — Jours fériés dans l'orchestration des scènes

**Statut :** COMPLÉTÉ  
**Date :** 2026-05-09

---

## Objectif Global

Les scènes Domoticz 0, 1 et 2a sont planifiées avec des horaires différents en semaine (7h, 7h45, 8h05) et le week-end (8h, 9h50, 10h). L'objectif est de traiter les jours fériés comme des jours de week-end : les scènes se déclenchent à l'heure semaine (Domoticz ne peut pas les ignorer), mais leurs **effets** ne s'exécutent qu'à l'heure tardive (weekend).

La solution repose sur :
1. Un nouveau script `JoursFeries_API.lua` qui charge les jours fériés depuis l'API officielle française et les met en cache dans `globalData`.
2. Un helper `isJourFerie(domoticz)` dans `global_data.lua` consulté par les scènes.
3. Des guards dans les scènes 0, 1, 2a pour ignorer ou exécuter selon le type de jour.
4. Un 3e déclenchement dans le planificateur Domoticz (modification manuelle) pour les scènes concernées.

---

## Scènes concernées

| Scène | Heure semaine | Heure week-end | Nouveau déclenchement lun-ven |
|---|---|---|---|
| Scene 0 — PreparationChauffage | 7h00 | 8h00 | 8h00 |
| Scene 1 — Reveil | 7h45 | 9h50 | 9h50 |
| Scene 2a — Journee | 8h05 | 10h00 | 10h00 |
| Scene 2b/2c/3/4 | — | — | **Non impactées** |

---

## Phase 1 — Intégration API jours fériés

### Contexte
Aucune notion de jour férié n'existe dans le système. Besoin d'un helper fiable et robuste.

### Critères de Réussite
- [ ] `globalData.joursFeries` est chargé automatiquement chaque année (et mensuellement en failsafe)
- [ ] Si la liste est vide (reboot), un rappel on-demand est déclenché via customEvent `JoursFeries Refresh`
- [ ] `isJourFerie(domoticz)` retourne `true` pour un jour férié connu, `false` sinon
- [ ] Comportement conservatif si la liste est vide : `isJourFerie` retourne `false` (pas d'exécution différée par défaut)
- [ ] Logs corrects (uuid, niveau, marker)

### Tâches

#### T1.1 — Créer JoursFeries_API.lua
- **Agent :** DEVon
- **Fichier :** `domoticz/scripts/dzVents/JoursFeries_API.lua`
- **Comportement :**
  - Timer annuel (`01:00` le 1er janvier) + mensuel (1er du mois, failsafe) + customEvent `JoursFeries Refresh`
  - Appel GET : `https://calendrier.api.gouv.fr/jours-feries/metropole/{annee}.json`
  - Callback : `jours_feries_response`
  - Sur réception HTTP : parser le JSON (clés = dates `YYYY-MM-DD`), stocker dans `domoticz.globalData.joursFeries`
  - Logs : marker `[JoursFeries]`, uuid, niveaux corrects

#### T1.2 — Modifier global_data.lua
- **Agent :** DEVon
- **Fichier :** `domoticz/scripts/dzVents/global_data.lua`
- **Modifications :**
  - Ajouter dans `data` : `joursFeries = { initial = {} }` (ou JSON string si tables non supportées)
  - Ajouter constante : `JOURS_FERIES_API_URL = 'https://calendrier.api.gouv.fr/jours-feries/metropole/'`
  - Ajouter helper `isJourFerie(domoticz)` :
    - Si `globalData.joursFeries` vide/nil → émettre customEvent `JoursFeries Refresh` + `return false`
    - Sinon → construire clé `YYYY-MM-DD` depuis `domoticz.time` → vérifier présence dans la table
  - Ajouter helper `callJoursFeriesAPI(domoticz, uuid)` : wraps `openURL` vers l'API

---

## Phase 2 — Guards dans les scènes matinales

### Contexte
Les scènes 0/1/2a sont déclenchées deux fois par jour en semaine (heure tôt + heure tardive ajoutée). Chaque déclenchement doit savoir s'il doit s'exécuter.

### Critères de Réussite
- [ ] Déclenchement tôt (7h/7h45/8h05) → ignoré si `isJourFerie`
- [ ] Déclenchement tardif (8h/9h50/10h lun-ven) → ignoré si ni week-end ni jour férié
- [ ] Déclenchement tardif (sam-dim ou jour férié) → exécuté normalement
- [ ] Comportement semaine normale inchangé
- [ ] `scenePhase` cohérente avec l'exécution réelle (non émise si on skip)
- [ ] Health check signale si `joursFeries` est vide depuis trop longtemps

### Tâches

#### T2.1 — Guards dans Scene_0, Scene_1, Scene_2a
- **Agent :** DEVon
- **Fichiers :** `Scene_0_PreparationChauffage.lua`, `Scene_1_Reveil.lua`, `Scene_2a_Journee.lua`
- **Modification :**
  - Identifier si le déclenchement est "tôt" ou "tardif" (via `domoticz.time.hour`)
  - Si tôt ET `isJourFerie(domoticz)` → log + `return` (skip complet, pas d'émission scenePhase)
  - Si tardif ET NOT (`isWeekEnd(domoticz)` OR `isJourFerie(domoticz)`) → log + `return`

#### T2.2 — Health_check_dzVents.lua
- **Agent :** DEVon
- **Fichier :** `Health_check_dzVents.lua`
- **Modification :** ajouter contrôle sur fraîcheur de `domoticz.globalData.joursFeries`

---

## Phase 3 — QA

- **Agent :** QUALvin
- **Dépend de :** Phase 1 + Phase 2

### Cas à couvrir
- Nominal jour férié : scène tôt ignorée, scène tardive exécutée
- Semaine non-férié : scène tôt exécutée, scène tardive ignorée
- Week-end : scène tardive exécutée (com avant)
- Liste vide (reboot) : rappel API déclenché, comportement conservatif
- Non-régression : Scènes 2b, 2c, 3, 4 inchangées
- Cohérence scenePhase : non émise si skip

---

## Phase 4 — Documentation

- **Agent :** DOCly
- **Dépend de :** Phase 1 + Phase 2 (peut être parallèle à Phase 3)

### Tâches

#### T4.1 — domoticz/README.md
Ajouter/mettre à jour : tableau de planification des scènes (semaine / week-end / jours fériés) + note sur la modification manuelle Domoticz requise.

#### T4.2 — docs/ARCHITECTURE.md
Créer si absent. Documenter : orchestration des scènes, nouveau composant `JoursFeries_API`, helpers `isJourFerie` / `isWeekEnd`.

#### T4.3 — docs/scenarios.puml
Créer le diagramme PlantUML de l'orchestration complète des scènes (acteurs : Domoticz scheduler, dzVents scripts, API jours fériés).

---

## Modification manuelle Domoticz requise

⚠️ **Action hors code — À réaliser manuellement dans l'interface Domoticz** :

Ajouter un déclenchement supplémentaire lun-ven pour chaque scène concernée :
- `PreparationChauffage` → ajouter déclenchement lun-ven à **08:00**
- `Reveil` → ajouter déclenchement lun-ven à **09:50**
- `Journee` → ajouter déclenchement lun-ven à **10:00**

---

## Risques et mitigations

| Risque | Mitigation |
|---|---|
| API indisponible au chargement | Comportement conservatif (`isJourFerie = false`) |
| Reboot pendant la journée → liste vide | Rappel on-demand déclenché à la prochaine scène |
| Persistance table Lua dans globalData | Si non supporté : encoder en JSON string dans variable Domoticz |
| Oubli modification manuelle Domoticz | Documenté en README + plan |
