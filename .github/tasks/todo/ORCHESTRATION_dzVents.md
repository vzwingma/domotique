# Orchestration dzVents

## 1. Vue d'ensemble de l'architecture

Le répertoire `domoticz\scripts\dzVents` implémente une architecture événementielle en couches pour l'automatisation domestique.

```text
COUCHE SCENARIO
  Scene_0..Scene_4_Nuit_2 -> emettent "Scene Phase"

COUCHE METIER
  Device_Mode_Domicile
  Device_Presence_Domicile
  Device_Label_Scene_Phase
  Devices_Telephones
  Devices_Lampes
  Devices_Ouvertures
  Devices_TempHumidity

COUCHE CONTROLE COMPOSITE
  Groupes_Lampes
  Groupes_Volets

COUCHE INTEGRATION EXTERNE
  Freebox_login / Freebox_statut / Freebox_LAN_statuts
  Tydom_heat_* / Tydom_volets_* / Tydom_refresh_values

COUCHE SOCLE
  global_data.lua
  global_HTTP_response.lua
```

Bus d'intégration interne :

- `Scene Phase`
- `Presence Domicile`
- `Scenario Nuit`
- `Supervision Ouverture`
- `freebox_initsession`
- `freebox_session`
- `freebox_endsession`

Etat partagé critique :

- `domoticz.globalData.scenePhase`

Point structurant :

- `global_data.lua` est une dépendance centrale et tout changement sur ce fichier doit être isolé et validé avec précaution.

## 2. Décisions de conception

- Pas de réécriture globale du système.
- Priorité absolue à la stabilisation avant tout refactoring ou ajout fonctionnel.
- Corrections effectuées par flux métier complet et non par script pris isolément.
- Tests pensés en non-régression de flux inter-scripts.
- Documentation maintenue au fil de l'eau, en parallèle des corrections.
- Réduction du couplage de configuration avant factorisation avancée.

## 3. Découpage du travail

| ID | Titre | Complexité | Dépendances | Agent principal | Agents contributeurs | Parallélisable |
|---|---|---|---|---|---|---|
| `T-A1a` | Corriger `null` -> `nil` dans `Tydom_heat_getTemp.lua` | Faible | Aucune | Dev | QA | Oui |
| `T-A1b` | Rendre `suffixeMode` local dans `global_data.lua` | Faible | Aucune | Dev | QA | Oui |
| `T-A1c` | Corriger `previousMode` dans `Device_Mode_Domicile.lua` | Faible | Aucune | Dev | QA | Oui |
| `T-A1d` | Corriger stockage/comparaison d'état dans `Device_Presence_Domicile.lua` | Moyenne | Aucune | Dev | QA | Oui |
| `T-A1e` | Uniformiser `scenePhase` dans `Scene_4_Nuit_2.lua` | Faible | Aucune | Dev | QA | Oui |
| `T-A2` | Initialisation fiable de `scenePhase` au démarrage | Moyenne | `T-A1b`, `T-A1e` | Dev | QA, Doc | Non |
| `T-B1` | Enrichir gestion d'erreurs HTTP | Moyenne | `T-A1b` | Dev | QA, Doc | Non |
| `T-B2` | Ajouter retry borné et backoff sur appels idempotents | Moyenne | `T-B1` | Dev | QA | Non |
| `T-B3` | Sécuriser la construction shell Freebox | Moyenne | `T-B1` | Dev | QA, Doc | Non |
| `T-C1` | Centraliser les mappings Tydom | Moyenne | `T-A1b` | Dev | Doc | Oui |
| `T-C2` | Vérifier les prérequis Domoticz | Moyenne | `T-A1b` | Dev | Doc | Oui |
| `T-D1` | Mutualiser la logique de groupes | Forte | `T-B1`, `T-C1` | Dev | QA | Non |
| `T-D2` | Normaliser le style et l'usage de `local` | Moyenne | `T-E1` | Dev | - | Oui |
| `T-E1` | Standardiser la journalisation | Moyenne | `T-B1` | Dev | Doc | Non |
| `T-E2` | Ajouter un health check dzVents | Moyenne | `T-B2`, `T-E1` | Dev | QA, Doc | Non |

## 4. Tâches de l'agent Dev

### DEV-1 - Corrections de bugs avérés

Perimetre :

- `Tydom_heat_getTemp.lua`
- `global_data.lua`
- `Device_Mode_Domicile.lua`
- `Device_Presence_Domicile.lua`
- `Scene_4_Nuit_2.lua`

Livrables :

- corriger `nil` vs `null`
- supprimer la variable globale implicite `suffixeMode`
- corriger le suivi du mode précédent
- corriger le suivi de la présence précédente
- uniformiser la mise à jour de `scenePhase` par événement

Definition de termine :

- changements minimaux et ciblés
- pas de régression sur les flux présence/scènes
- revue QA-1 validée

### DEV-2 - Initialisation fiable de `scenePhase`

Perimetre :

- `global_data.lua`
- `Device_Label_Scene_Phase.lua`

Livrables :

- stratégie d'initialisation au boot
- valeur de repli explicite
- restauration depuis le device `Phase` ou fallback documenté

Definition de termine :

- `getMomentJournee` retourne une valeur cohérente après redémarrage simulé
- revue QA-2 validée

### DEV-3 - Robustesse HTTP et sécurisation Freebox

Perimetre :

- `global_HTTP_response.lua`
- wrappers HTTP dans `global_data.lua`
- `Freebox_login.lua`

Livrables :

- journalisation enrichie
- compteur d'erreurs consécutives
- retry borné sur appels idempotents
- pas de retry sur les appels non idempotents
- sécurisation et isolement de la commande shell Freebox

Definition de termine :

- erreurs HTTP visibles et corrélées
- retries bornés
- revue QA-3 validée

### DEV-4 - Réduction du couplage de configuration

Perimetre :

- `global_data.lua`
- scripts Tydom concernés
- nouveau contrôle de configuration Domoticz

Livrables :

- table centralisée des IDs Tydom
- contrôle des prérequis devices, groupes, scènes et variables
- blocage limité aux flux critiques si prérequis manquant

Definition de termine :

- aucun identifiant Tydom dispersé
- revue QA-4 validée
- documentation Doc-3 produite

### DEV-5 - Factorisation et observabilité

Perimetre :

- `Groupes_Lampes.lua`
- `Groupes_Volets.lua`
- `Devices_Lampes_Groupe.lua`
- scripts modifiés des vagues précédentes

Livrables :

- logique groupe centralisée
- format de log homogène
- script de health check quotidien

Definition de termine :

- revue QA-5 validée
- documentation Doc-4 produite

## 5. Tâches de l'agent Qa

### QA-1

Valider les cinq corrections de bugs du lot DEV-1, en couvrant le cas nominal et le cas limite pour :

- `nil` / `null`
- `suffixeMode`
- `previousMode`
- état précédent de présence
- émission correcte de `Scene Phase` dans `Scene_4_Nuit_2.lua`

### QA-2

Valider l'initialisation de `scenePhase` :

- restauration nominale
- fallback si `Phase` est absente ou vide
- écrasement correct par une scène ultérieure

### QA-3

Valider :

- classification des erreurs HTTP
- retry/backoff bornés
- absence de retry sur les commandes non idempotentes
- robustesse de la construction shell Freebox

### QA-4

Valider :

- exhaustivité de la table Tydom centralisée
- détection des prérequis manquants
- blocage des seuls flux critiques

### QA-5

Valider :

- synchronisation groupe -> items et items -> groupe
- format de logs attendu
- détection d'indicateurs dégradés par le health check

## 6. Tâches de l'agent Doc

### DOC-1

Mettre à jour la rétroconception, les instructions de travail et les instructions Copilot après les corrections du lot DEV-1.

### DOC-2

Documenter la stratégie de boot et la machine d'état implicite de `scenePhase`.

### DOC-3

Documenter :

- la table centralisée Tydom
- la procédure de remplacement d'équipement
- la liste des prérequis Domoticz

### DOC-4

Documenter :

- la convention de logs
- le health check
- les nouveaux points de validation attendus

## 7. Critères de succès

- plus de rejeu intempestif sur transitions identiques
- `getMomentJournee` non `nil` au démarrage
- erreurs HTTP visibles avec contexte et `uuid`
- coupures courtes Tydom/Freebox absorbées sans rupture durable
- construction shell Freebox durcie
- IDs Tydom centralisés
- prérequis Domoticz détectés avant effets de bord
- logique de groupes centralisée
- logs homogènes sur les scripts modifiés
- cohérence entre code et documentation

## 8. Risques et mitigations

| Risque | Mitigation |
|---|---|
| Régression sur `global_data.lua` | Traiter isolément et valider systématiquement avec QA |
| Confusion entre états précédents mode / présence | Documenter le champ exact stocké avant correction |
| Effet de bord sur `Scene_4_Nuit_2.lua` | Vérifier que `Scenario Nuit` reste déclenché |
| Retry trop agressif | Limiter strictement le nombre de tentatives |
| Injection shell Freebox | Isoler et valider les entrées de la commande |
| Perte de traçabilité `uuid` | Contrôle obligatoire sur tous les helpers refactorés |
| Désynchronisation code / doc | Déclencher Doc en parallèle de chaque lot Dev |
| Tests surtout manuels | Formaliser les scénarios QA comme base de régression |

## Vagues d'exécution

### Vague 1 - Stabilisation

- DEV-1
- QA-1
- DEV-2
- QA-2
- DOC-1
- DOC-2

Sortie attendue :

- bugs certains corrigés
- `scenePhase` fiable au démarrage

### Vague 2 - Robustesse et découplage

- DEV-3
- QA-3
- DEV-4
- QA-4
- DOC-3

Sortie attendue :

- intégrations HTTP plus robustes
- configuration Tydom et Domoticz mieux maîtrisée

### Vague 3 - Factorisation et observabilité

- DEV-5
- QA-5
- DOC-4

Sortie attendue :

- logique de groupes factorisée
- logs homogènes
- health check opérationnel
