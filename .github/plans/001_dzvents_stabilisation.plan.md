# Plan d'Action 001 — Stabilisation dzVents (rétro-documenté)

## 1) Objectif global et périmètre

**Objectif global :** consolider le socle dzVents de `domoticz/scripts/dzVents` en capitalisant sur les lots déjà livrés (DEV-1, DEV-2, DEV-4, DEV-5), puis terminer les travaux restants de robustesse HTTP/Freebox (DEV-3) avec traçabilité QA et documentation.

**Périmètre inclus :**
- scripts dzVents métier, scènes, groupes et intégrations Freebox/Tydom ;
- socle partagé (`global_data.lua`, `global_HTTP_response.lua`) ;
- documentation opérationnelle liée aux lots.

**Périmètre exclu :**
- réécriture complète de l’architecture ;
- ajout de fonctionnalités métier non liées à la stabilisation.

**Sources consolidées :**
- `.github/tasks/todo/PLAN_ACTIONS_dzVents.md`
- `.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md`
- `.github/tasks/todo/ORCHESTRATION_dzVents.md`
- `.github/tasks/todo/RETROCONCEPTION_dzVents.md` *(référence demandée, fichier non présent dans le dépôt au moment de la rétro-doc)*
- `.github/instructions/doc.instructions.md`

---

## 2) État historique et statut global

Statut global du plan : **Complété (tous les lots clos, documentation finalisée)**.

| Lot | Intitulé | Statut |
|---|---|---|
| DEV-1 | Stabilisation immédiate (bugs avérés) | ✅ Complété |
| DEV-2 | Initialisation fiable de `scenePhase` | ✅ Complété |
| DEV-3 | Robustesse HTTP + sécurisation Freebox | ✅ Complété |
| DEV-4 | Réduction du couplage de configuration | ✅ Complété |
| DEV-5 | Factorisation + observabilité | ✅ Complété |

---

## 3) Phases et tâches opérationnelles

## Phase 1 — Historique DEV-1 (complétée)
**Objectif :** corriger les anomalies bloquantes immédiates.
**Statut :** ✅ Complétée

### T1.1
- **Agent :** DEVon
- **Action :** corriger `null` -> `nil` + variables implicites + gestion états précédents + émission `Scene Phase`
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/scripts/Tydom_heat_getTemp.lua`
  - `domoticz/scripts/dzVents/runtime/global_data.lua`
  - `domoticz/scripts/dzVents/scripts/Device_Mode_Domicile.lua`
  - `domoticz/scripts/dzVents/scripts/Device_Presence_Domicile.lua`
  - `domoticz/scripts/dzVents/scripts/Scene_4_Nuit_2.lua`
- **Critères d’acceptation :**
  - aucun usage de `null` ;
  - pas de variable globale implicite `suffixeMode` ;
  - rejet d’événements seulement sur vrai changement ;
  - `Scene_4_Nuit_2.lua` passe par l’événement `Scene Phase`.

### T1.2
- **Agent :** QALvin
- **Action :** valider non-régression des flux mode/présence/scènes
- **Fichiers ciblés :** scripts du lot T1.1
- **Critères d’acceptation :**
  - scénarios nominaux + limites validés ;
  - aucun rejeu intempestif détecté.

### T1.3
- **Agent :** DOCly
- **Action :** documenter corrections et règles de vigilance DEV-1
- **Fichiers ciblés :**
  - `.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md`
  - `.github/tasks/todo/ORCHESTRATION_dzVents.md`
- **Critères d’acceptation :**
  - règles anti-réintroduction explicites ;
  - cohérence doc/code.

## Phase 2 — Historique DEV-2 (complétée)
**Objectif :** fiabiliser `scenePhase` au démarrage.
**Statut :** ✅ Complétée

### T2.1
- **Agent :** DEVon
- **Action :** restaurer `scenePhase` au boot avec fallback `'Inconnue'`
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/scripts/Device_Label_Scene_Phase.lua`
  - `domoticz/scripts/dzVents/runtime/global_data.lua`
- **Critères d’acceptation :**
  - prise en charge `systemStart` ;
  - fallback explicite si phase absente/invalide ;
  - `getMomentJournee` robuste avec `tostring`.

### T2.2
- **Agent :** QALvin
- **Action :** valider restauration et fallback de phase
- **Fichiers ciblés :** scripts du lot T2.1
- **Critères d’acceptation :**
  - restauration nominale validée ;
  - valeur invalide correctement traitée ;
  - écrasement correct après exécution d’une scène.

### T2.3
- **Agent :** DOCly
- **Action :** consigner machine d’état implicite de `scenePhase`
- **Fichiers ciblés :**
  - `.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md`
- **Critères d’acceptation :**
  - phases valides et fallback documentés ;
  - vigilance sur `'Inconnue'` explicite.

## Phase 3 — DEV-3 restant (à exécuter/valider)
**Objectif :** terminer la robustesse des intégrations HTTP et durcir Freebox.
**Statut :** ✅ Complétée

### T3.1
- **Agent :** ARCos
- **Action :** valider le cadrage final DEV-3 (idempotence, retry, backoff, sécurité shell)
- **Fichiers ciblés :**
  - `.github/tasks/todo/PLAN_ACTIONS_dzVents.md`
  - `.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md`
- **Critères d’acceptation :**
  - stratégie retry bornée ;
  - distinction explicite idempotent/non-idempotent ;
  - exigences de sécurité Freebox formalisées.

### T3.2
- **Agent :** DEVon
- **Action :** implémenter robustesse HTTP commune
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/runtime/global_HTTP_response.lua`
  - `domoticz/scripts/dzVents/runtime/global_data.lua` (wrappers HTTP)
- **Critères d’acceptation :**
  - journalisation enrichie et corrélable ;
  - compteur d’échecs consécutifs ;
  - retry/backoff bornés sur appels idempotents uniquement.

### T3.3
- **Agent :** DEVon
- **Action :** sécuriser la construction shell Freebox
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/scripts/Freebox_login.lua`
- **Critères d’acceptation :**
  - interpolation contrôlée/échappée ;
  - réduction du risque d’injection ;
  - comportement d’authentification inchangé côté métier.

### T3.4
- **Agent :** QALvin
- **Action :** valider robustesse HTTP + flux Freebox
- **Fichiers ciblés :** scripts des lots T3.2 et T3.3
- **Critères d’acceptation :**
  - erreurs HTTP visibles avec contexte ;
  - retries non agressifs ;
  - pas de retry sur actions non idempotentes ;
  - tests de non-régression Freebox passants.

### T3.5
- **Agent :** DOCly
- **Action :** finaliser la documentation post DEV-3
- **Fichiers ciblés :**
  - `.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md`
  - `.github/tasks/todo/ORCHESTRATION_dzVents.md`
  - `README.md` (si impacts d’exploitation visibles utilisateur/dev)
- **Critères d’acceptation :**
  - conventions HTTP et erreurs documentées ;
  - limites et vigilance d’exploitation explicites ;
  - doc alignée sur le comportement réel.

## Phase 4 — Historique DEV-4 (complétée)
**Objectif :** réduire le couplage de configuration.
**Statut :** ✅ Complétée

### T4.1
- **Agent :** DEVon
- **Action :** centraliser les IDs Tydom et helpers associés
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/runtime/global_data.lua`
  - `domoticz/scripts/dzVents/scripts/Tydom_heat_getTemp.lua`
  - `domoticz/scripts/dzVents/scripts/Tydom_heat_setPoint.lua`
- **Critères d’acceptation :**
  - aucune duplication d’IDs Tydom critiques ;
  - usage des helpers centralisés uniquement.

### T4.2
- **Agent :** DEVon
- **Action :** introduire contrôle de prérequis Domoticz
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/scripts/Config_check.lua`
- **Critères d’acceptation :**
  - contrôle au démarrage ;
  - signalement des manquants ;
  - impact fonctionnel maîtrisé.

### T4.3
- **Agent :** QALvin
- **Action :** valider couplage réduit + contrôle prérequis
- **Fichiers ciblés :** scripts du lot DEV-4
- **Critères d’acceptation :**
  - détection cohérente des prérequis ;
  - pas de régression des flux Tydom.

### T4.4
- **Agent :** DOCly
- **Action :** documenter configuration centralisée et procédure matérielle
- **Fichiers ciblés :**
  - `.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md`
- **Critères d’acceptation :**
  - procédure de remplacement équipement tracée ;
  - règle “pas d’ID en dur” explicite.

## Phase 5 — Historique DEV-5 (complétée)
**Objectif :** factoriser et renforcer l’observabilité.
**Statut :** ✅ Complétée

### T5.1
- **Agent :** DEVon
- **Action :** centraliser réalignement groupe/items
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/runtime/global_data.lua`
  - `domoticz/scripts/dzVents/scripts/Groupes_Volets.lua`
  - `domoticz/scripts/dzVents/scripts/Tydom_volets_setPosition.lua`
  - `domoticz/scripts/dzVents/scripts/Devices_Lampes_Groupe.lua`
- **Critères d’acceptation :**
  - usage exclusif de `verifyGroupeFromItem` ;
  - pas de ré-implémentation locale.

### T5.2
- **Agent :** DEVon
- **Action :** introduire health check dzVents
- **Fichiers ciblés :**
  - `domoticz/scripts/dzVents/scripts/Health_check_dzVents.lua`
- **Critères d’acceptation :**
  - indicateurs scène/Freebox/Tydom monitorés ;
  - notification sur état dégradé.

### T5.3
- **Agent :** QALvin
- **Action :** valider factorisation + observabilité
- **Fichiers ciblés :** scripts du lot DEV-5
- **Critères d’acceptation :**
  - synchronisation groupes cohérente ;
  - logs homogènes ;
  - health check pertinent.

### T5.4
- **Agent :** DOCly
- **Action :** documenter convention de logs et supervision
- **Fichiers ciblés :**
  - `.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md`
  - `.github/tasks/todo/ORCHESTRATION_dzVents.md`
- **Critères d’acceptation :**
  - format logs normalisé décrit ;
  - règles de maintenance health check précisées.

---

## 4) Dépendances entre phases et tâches

- **Phase 1 -> Phase 2 -> Phase 3** (socle de stabilité avant robustesse HTTP finale).
- **Phase 1 -> Phase 4 -> Phase 5** (réduction couplage avant factorisation avancée).
- **Phase 3.5** dépend de **T3.2 + T3.3 + T3.4**.
- Clôture globale dépend de la complétion de toutes les tâches Phase 3.

### Graphe simplifié
`P1 -> P2 -> P3 -> Clôture`  
`P1 -> P4 -> P5 -> Clôture`

---

## 5) Critères de succès globaux

1. Plus de rejeux intempestifs sur transitions identiques.
2. `scenePhase` exploitable après redémarrage.
3. Erreurs HTTP visibles, contextualisées et corrélables.
4. Retry/backoff maîtrisés sur appels idempotents uniquement.
5. Chaîne Freebox durcie sans régression métier.
6. Couplage de configuration Tydom/Domoticz réduit et maintenable.
7. Logs et supervision dzVents homogènes, doc alignée sur le réel.

---

## 6) Risques et mitigations

| Risque | Impact | Mitigation |
|---|---|---|
| Régression sur `global_data.lua` | Large surface impactée | Changements atomiques + QA ciblée par flux |
| Retry mal calibré | Tempêtes d’appels externes | Bornes strictes + tests de charge légère |
| Durcissement Freebox insuffisant | Risque sécurité | Revue ARCos + tests QA dédiés |
| Désalignement code/doc | Exploitation confuse | DOCly systématique en fin de lot |
| Prérequis Domoticz incomplets | Pannes silencieuses | Maintien actif de `Config_check.lua` |

---

## 7) Protocole de reporting (rapports de phase)

Pour chaque phase exécutée, renseigner :
- `.github/plans/001_reports/PHASE_<N>_COMPLETION_REPORT.md`

**Format minimal attendu :**
- tâches T<N>.<M> avec statut (`✅ DONE`, `🔄 IN_PROGRESS`, `❌ BLOCKED`) ;
- fichiers réellement modifiés ;
- critères d’acceptation validés/non validés ;
- incidents, décisions, actions de mitigation ;
- décision de passage phase suivante.

**Règles :**
- un rapport par phase ;
- pas de clôture globale sans rapport de phase à jour ;
- en cas de blocage, documenter cause + prérequis de déblocage.

---

## 8) Plan d’exécution restant

1. Exécuter/valider **Phase 3 (T3.1 -> T3.5)**.
2. Produire les rapports manquants dans `001_reports/`.
3. Basculer le statut global du plan en **Complété** dans `.github/plans/README.md` une fois toutes les tâches closes.

