# Analyse critique et plan d'actions `dzVents`

## 1. Synthèse critique

Le système dzVents est globalement bien pensé pour une installation domestique évolutive : les responsabilités sont lisibles, les scènes structurent la journée, et les intégrations Tydom/Freebox sont raccordées au métier par événements. En revanche, le niveau d'industrialisation reste hétérogène. Plusieurs scripts fonctionnent comme une chaîne très couplée où la moindre dérive de configuration peut casser un flux complet.

Les points forts principaux sont :

- architecture par domaines facilement compréhensible ;
- bonne utilisation des événements personnalisés ;
- effort réel de corrélation via `uuid` ;
- séparation pratique entre orchestration de scènes et pilotage d'équipements ;
- stratégie de réalignement périodique avec Tydom.

Les faiblesses principales sont :

- couplage fort aux noms Domoticz et aux IDs Tydom ;
- faible robustesse des appels HTTP ;
- persistance et cohérence d'état perfectibles ;
- duplication de logique ;
- plusieurs anomalies de code directement visibles dans les scripts.

## 2. Constats techniques prioritaires

## 2.1 Couplage fort et configuration fragile

Le cœur du système repose sur `global_data.lua`, qui centralise les noms Domoticz et les mappings Tydom. C'est pratique, mais aussi très fragile :

- les volets Tydom sont adressés par IDs codés en dur ;
- les devices Domoticz sont référencés par libellés ;
- les variables utilisateur sont construites dynamiquement par concaténation.

Conséquence : un renommage, un remplacement d'équipement ou une dérive de paramétrage peut provoquer des pannes silencieuses ou des comportements incohérents.

## 2.2 Résilience réseau limitée

`global_HTTP_response.lua` se limite à logger l'erreur. Aucun mécanisme n'apparaît pour :

- rejouer une requête ;
- temporiser ou faire un backoff ;
- ouvrir un circuit breaker ;
- remonter une alerte d'exploitation.

Cela expose fortement les flux Freebox et Tydom aux indisponibilités transitoires.

## 2.3 État métier implicite et parfois incohérent

Le système s'appuie sur `domoticz.globalData.scenePhase`, mais sans machine d'état explicite. Quelques observations concrètes méritent une correction rapide :

- `global_data.lua` initialise `scenePhase` à `nil`, ce qui peut rendre `getMomentJournee` indéterminé tant qu'aucune scène n'a tourné ;
- `Scene_4_Nuit_2.lua` met directement `globalData.scenePhase`, alors que les autres scènes utilisent plutôt l'événement `Scene Phase` ;
- `Device_Mode_Domicile.lua` compare `modeDomicile` à `previousMode`, mais ne remet jamais `previousMode` à jour ;
- `Device_Presence_Domicile.lua` stocke ensuite `presenceDomDevice` dans `previousMode`, alors que la comparaison est faite avec l'objet device et non avec une valeur simple.

Ces incohérences créent un risque élevé de rejeux intempestifs ou de non-détection de changement réel.

## 2.4 Anomalies de code avérées

Plusieurs défauts sont visibles sans hypothèse forte :

- `Tydom_heat_getTemp.lua` teste `commandeTyd == null` alors qu'en Lua la valeur attendue est `nil` ;
- `global_data.lua` utilise `suffixeMode` sans `local` dans `getModeDomicile`, ce qui crée une variable globale implicite ;
- `Freebox_login.lua` construit une commande shell avec interpolation directe du challenge et du token ;
- la logique d'alignement de groupes est dupliquée entre familles d'équipements.

Ces points sont de bons candidats pour un premier lot court et à fort retour sur investissement.

## 2.5 Observabilité partielle

Les logs sont nombreux mais peu homogènes :

- les niveaux ne sont pas toujours cohérents ;
- il n'existe pas de journal d'audit fonctionnel ;
- les erreurs d'intégration ne remontent pas en alerte d'exploitation.

En exploitation, cela rend le diagnostic plus long qu'il ne devrait l'être.

## 3. Vision cible

La cible recommandée n'est pas une réécriture complète. Le système paraît suffisamment structuré pour être consolidé par incréments.

La trajectoire proposée est :

1. sécuriser l'existant ;
2. corriger les anomalies avérées ;
3. fiabiliser les intégrations externes ;
4. réduire le couplage et dédupliquer ;
5. améliorer l'observabilité ;
6. seulement ensuite envisager des évolutions plus ambitieuses.

## 4. Plan d'actions priorisé

Le plan ci-dessous est pensé comme point d'entrée de planification. Chaque chantier peut devenir une Epic ou un lot de sprint.

### Lot A - Stabilisation immédiate

Objectif : corriger les défauts certains et réduire les comportements imprévisibles sans changer l'architecture.

#### A1. Corriger les anomalies de base

Actions :

- remplacer `null` par `nil` dans `Tydom_heat_getTemp.lua` ;
- rendre `suffixeMode` local dans `global_data.lua` ;
- corriger la gestion de `previousMode` dans `Device_Mode_Domicile.lua` ;
- corriger la comparaison et le stockage d'état dans `Device_Presence_Domicile.lua` ;
- homogénéiser la mise à jour de `scenePhase` entre `Scene_4_Nuit_2.lua` et les autres scènes.

Valeur :

- baisse du risque de faux positifs ;
- meilleure cohérence des rejeux de scènes ;
- suppression de bugs visibles à faible coût.

Critère de sortie :

- les transitions mode/présence ne rejouent qu'en cas de vrai changement ;
- la phase de journée reste cohérente quel que soit le scénario exécuté.

#### A2. Initialiser proprement l'état métier

Actions :

- définir une stratégie d'initialisation de `scenePhase` au démarrage ;
- restaurer la phase depuis le device `Phase` ou une valeur persistée ;
- prévoir un comportement par défaut si aucune phase n'est connue.

Valeur :

- suppression des cas où chauffage et lumières ne savent pas à quel moment de journée se référer.

Critère de sortie :

- après redémarrage Domoticz, les scripts disposent toujours d'une phase exploitable.

### Lot B - Fiabilisation des intégrations

Objectif : rendre les chaînes Freebox et Tydom plus robustes aux incidents réels.

#### B1. Enrichir le client HTTP commun

Actions :

- enrichir `global_HTTP_response.lua` et/ou les wrappers de `global_data.lua` ;
- standardiser la journalisation des erreurs par type d'appel ;
- ajouter un compteur d'échecs consécutifs ;
- prévoir une notification d'administration sur échecs répétés.

Valeur :

- visibilité opérationnelle accrue ;
- réduction des pannes silencieuses.

Critère de sortie :

- tout échec HTTP significatif est au moins visible, corrélé, et classable.

#### B2. Introduire retry contrôlé et backoff

Actions :

- ajouter un retry borné sur les appels non critiques ;
- introduire un backoff pour éviter les boucles agressives ;
- distinguer les appels idempotents et non idempotents.

Valeur :

- meilleure résilience réseau locale ;
- limitation des tempêtes d'appels sur Freebox/Tydom.

Critère de sortie :

- une indisponibilité courte n'entraîne plus une rupture durable de service.

#### B3. Sécuriser la chaîne Freebox

Actions :

- isoler la construction de la commande shell ;
- valider et échapper proprement les valeurs interpolées ;
- documenter la dépendance à `openssl` ;
- si possible à terme, remplacer le shell par une implémentation Lua dédiée.

Valeur :

- baisse du risque technique et sécuritaire ;
- meilleur contrôle du flux d'authentification.

Critère de sortie :

- la chaîne Freebox n'exécute plus de commande shell construite de façon fragile.

### Lot C - Réduction du couplage

Objectif : rendre le système moins dépendant des détails de configuration.

#### C1. Externaliser les mappings Tydom

Actions :

- sortir les IDs Tydom du code métier ;
- prévoir un fichier ou une table de configuration dédiée ;
- documenter la procédure de réconciliation en cas de remplacement d'équipement.

Valeur :

- maintenance simplifiée ;
- diminution du risque de casse lors d'un changement matériel.

Critère de sortie :

- aucun identifiant Tydom critique n'est dispersé dans plusieurs scripts.

#### C2. Cartographier et valider les prérequis Domoticz

Actions :

- lister les devices, groupes, scènes et variables attendus ;
- ajouter un script de contrôle de cohérence de configuration ;
- faire échouer explicitement les flux critiques quand un prérequis manque.

Valeur :

- mise en service et diagnostic largement simplifiés.

Critère de sortie :

- un environnement incomplet est détecté avant de produire des effets de bord métier.

### Lot D - Factorisation et lisibilité

Objectif : réduire la dette technique sans changer le comportement fonctionnel.

#### D1. Mutualiser la logique de groupe

Actions :

- extraire les algorithmes communs d'alignement de groupes ;
- éviter la duplication entre volets et lampes ;
- centraliser les helpers d'évaluation de niveau et d'état.

Valeur :

- moins de code à maintenir ;
- correction d'un bug potentiellement propagée une seule fois.

Critère de sortie :

- la logique groupe -> items et items -> groupe est centralisée.

#### D2. Normaliser le style de code

Actions :

- utiliser systématiquement `local` pour les variables temporaires ;
- homogénéiser les fonctions internes ;
- standardiser les messages de log ;
- clarifier les responsabilités des scènes.

Valeur :

- lecture plus simple ;
- baisse du risque de variables globales implicites.

Critère de sortie :

- les scripts clés suivent une convention de structure homogène.

### Lot E - Observabilité et exploitation

Objectif : rendre le système pilotable et diagnostiquer plus vite.

#### E1. Standardiser la journalisation

Actions :

- imposer un format de log commun ;
- distinguer clairement DEBUG, INFO, WARN et ERROR ;
- s'appuyer sur l'`uuid` pour tous les flux majeurs.

Valeur :

- analyse d'incident plus rapide ;
- meilleure lecture des enchaînements inter-scripts.

#### E2. Ajouter un contrôle de santé

Actions :

- vérifier périodiquement les prérequis critiques ;
- surveiller la fraîcheur des statuts Freebox et Tydom ;
- remonter une alerte si un flux n'a pas produit d'événement attendu.

Valeur :

- détection proactive des régressions silencieuses.

## 5. Proposition de backlog initial

Voici un backlog conseillé pour ouvrir la planification.

| Priorité | Chantier | Type | Effort relatif | Dépendances |
|---|---|---|---|---|
| P1 | Corrections de bugs avérés (`nil`, `local`, états précédents, phase) | Correctif | Faible | Aucune |
| P1 | Initialisation fiable de `scenePhase` | Correctif | Faible à moyen | Aucune |
| P1 | Journalisation et gestion d'erreurs HTTP minimales | Fiabilisation | Moyen | Aucune |
| P2 | Retry/backoff sur intégrations externes | Fiabilisation | Moyen | Gestion d'erreurs HTTP |
| P2 | Externalisation des IDs Tydom | Refactoring | Moyen | Cartographie équipements |
| P2 | Contrôle de cohérence de configuration Domoticz | Outillage | Moyen | Cartographie équipements |
| P3 | Mutualisation logique de groupes | Refactoring | Moyen | Stabilisation préalable |
| P3 | Standardisation logs + health check | Observabilité | Moyen | Gestion d'erreurs HTTP |
| P4 | Remplacement du shell Freebox par solution Lua | Durcissement | Moyen à fort | Stabilisation chaîne Freebox |

## 6. Recommandation de démarrage

Le meilleur point d'entrée pour les travaux est un premier lot court centré sur la stabilisation.

Je recommande de commencer par :

1. corriger les anomalies certaines ;
2. fiabiliser `scenePhase` ;
3. améliorer le minimum vital de gestion d'erreur HTTP ;
4. produire ensuite une cartographie de configuration exécutable.

Ce séquencement donnera rapidement une base plus saine pour les lots suivants, sans risquer une régression globale.

## 7. Découpage proposé en Epics de planification

- **Epic 1 - Stabilisation des scripts dzVents**
- **Epic 2 - Robustesse des intégrations Freebox et Tydom**
- **Epic 3 - Réduction du couplage de configuration**
- **Epic 4 - Refactoring des logiques communes**
- **Epic 5 - Observabilité et exploitation**

Ces cinq Epics peuvent servir directement de squelette de roadmap ou de board de travaux.
