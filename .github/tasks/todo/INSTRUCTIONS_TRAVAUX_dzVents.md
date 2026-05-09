# Instructions de travail pour l'évolution de `dzVents`

## 1. Objet

Ce document traduit les constats de `RETROCONCEPTION_dzVents.md` et `PLAN_ACTIONS_dzVents.md` en instructions opérationnelles pour les prochains travaux sur les scripts `dzVents`.

Il sert de référence de démarrage pour :

- cadrer les interventions ;
- prioriser les correctifs ;
- éviter les régressions fonctionnelles ;
- préparer la planification détaillée des lots.

## 2. Documents de référence obligatoires

Avant toute modification sur `domoticz\scripts\dzVents`, lire dans cet ordre :

1. `RETROCONCEPTION_dzVents.md`
2. `PLAN_ACTIONS_dzVents.md`
3. le ou les scripts du domaine concerné
4. `global_data.lua`

Toute intervention doit être cohérente avec ces deux documents. En cas d'écart entre le code et la documentation, le code fait foi à court terme, mais l'écart doit être consigné et la documentation mise à jour.

## 3. Règles générales d'intervention

### 3.1 Principe de prudence

- ne pas refactorer plusieurs domaines à la fois ;
- intervenir par flux fonctionnel complet ;
- privilégier les changements petits, testables et réversibles ;
- ne pas mélanger correction de bug, refactoring structurel et évolution fonctionnelle dans le même lot sauf nécessité forte.

### 3.2 Principe de non-régression

Avant de modifier un script, identifier :

- son ou ses déclencheurs ;
- les événements qu'il émet ;
- les devices, groupes, scènes et variables qu'il lit ;
- les effets de bord attendus sur Domoticz, Freebox et Tydom.

Une modification n'est acceptable que si cette cartographie est explicitement vérifiée.

### 3.3 Principe de traçabilité

Tout nouveau flux ou correctif important doit :

- conserver ou améliorer la propagation de `uuid` ;
- produire des logs compréhensibles ;
- documenter les hypothèses de fonctionnement si elles ne sont pas évidentes.

## 4. Ordre de traitement recommandé

Les travaux doivent être menés dans l'ordre ci-dessous.

### Phase 1 - Stabilisation immédiate ✅ Couverte par le lot DEV-1

Les anomalies avérées ci-dessous ont été corrigées dans le lot DEV-1 :

- ~~remplacer `null` par `nil` dans `Tydom_heat_getTemp.lua`~~ → **corrigé** ;
- ~~corriger les variables globales implicites comme `suffixeMode`~~ → **corrigé** ;
- ~~corriger la gestion de `previousMode` dans `Device_Mode_Domicile.lua`~~ → **corrigé** ;
- ~~corriger le stockage et la comparaison d'état dans `Device_Presence_Domicile.lua`~~ → **corrigé** ;
- ~~uniformiser la gestion de `scenePhase`, notamment dans `Scene_4_Nuit_2.lua`~~ → **corrigé**.

Vigilances à maintenir pour éviter la réintroduction de ces défauts :

- ne jamais utiliser `null` dans un script Lua ; toujours utiliser `nil` ;
- déclarer systématiquement les variables temporaires avec `local`, dans `global_data.lua` et dans tous les scripts ;
- mettre à jour `previousMode` en fin de traitement dans `Device_Mode_Domicile.lua` et tout script de suivi d'état ;
- comparer et stocker une valeur simple (ex. `levelName`) dans `Device_Presence_Domicile.lua`, jamais un objet device ;
- toutes les scènes doivent émettre l'événement `Scene Phase` ; ne jamais écrire `globalData.scenePhase` directement.

Instruction :

- ne pas ouvrir de chantier d'optimisation avant la clôture de cette phase ;
- regrouper ces corrections dans un lot court centré sur la fiabilité.

### Phase 2 - Sécurisation de l'état métier ✅ Couverte par le lot DEV-2

Objectif : garantir qu'un redémarrage Domoticz ne laisse pas le système sans phase exploitable.

Livraisons :

- `Device_Label_Scene_Phase.lua` écoute désormais `systemStart` en plus de l'événement `Scene Phase`.
- Au boot, il lit le device texte `Phase` et restaure `scenePhase` si la valeur est reconnue dans la liste des phases valides.
- Si le device est absent, vide ou contient une valeur non reconnue, `scenePhase` est positionnée à `'Inconnue'` (fallback explicite et documenté).
- `getMomentJournee` dans `global_data.lua` journalise via `tostring(moment)` pour éviter tout crash quand la phase vaut `'Inconnue'`.

Vigilances à maintenir pour éviter la réintroduction de ces défauts :

- tout ajout de nouvelle phase dans les scripts `Scene_*` doit être accompagné de son insertion dans la table `validPhases` de `Device_Label_Scene_Phase.lua` ;
- la valeur `'Inconnue'` doit rester tolérée par tous les consommateurs de `scenePhase` (aucun consommateur ne doit supposer que `scenePhase` est toujours une phase métier valide) ;
- `getMomentJournee` retournant `nil` quand `scenePhase == 'Inconnue'` est un comportement attendu et non un bug ;
- ne jamais journaliser directement une variable pouvant être `nil` : utiliser `tostring()`.

Instruction :

- la phase 2 est terminée ; ne pas rouvrir ce chantier sans identifier un cas de régression précis.

### Phase 3 - Robustesse des intégrations HTTP ✅ Couverte par le lot DEV-3

Objectif : éviter les pannes silencieuses sur Freebox et Tydom.

Livraisons :

- `global_HTTP_response.lua` : journalisation enrichie corrélable via `corrId`, classification HTTP (`httpErrorClass`), compteur `consecutiveErrors` persistant, alerte `LOG_ERROR` dès 3 erreurs consécutives.
- `Freebox_login.lua` : helpers `shellEscape` et `validateShellInput` pour sécuriser la construction shell ; nil guards sur les champs JSON critiques (`challenge`, `session_token`, payload `freebox_endsession`) ; fonctions internes déclarées `local` (conformité DEV-1).
- Stratégie retry documentée : le handler `global_HTTP_response.lua` couvre les callbacks POST/PUT non idempotents sans retry ; le retry sur GET idempotents est à la charge de chaque script appelant.

Vigilances à maintenir pour éviter la réintroduction de ces défauts :

- **ne jamais accéder à `item.json.xxx` sans vérifier que `item.json` est non-nil** : utiliser un nil guard complet avant tout accès à un champ de réponse JSON ;
- **distinguer idempotent / non-idempotent avant d'ajouter un retry** : les appels POST/PUT ne doivent jamais être rejoués automatiquement ;
- **ne pas journaliser `app_token`** : le secret applicatif Freebox doit rester absent de tous les logs, même en `LOG_DEBUG` ;
- toute nouvelle commande shell construite avec des valeurs externes doit passer par `shellEscape` et `validateShellInput` ;
- tout nouveau callback HTTP doit propager le header `X-CorrId` pour la corrélation.

Instruction :

- la phase 3 est terminée ; ne pas rouvrir ce chantier sans identifier un cas de régression ou une nouvelle intégration HTTP.

### Phase 4 - Réduction du couplage ✅ Couverte par le lot DEV-4

Objectif : sortir progressivement les hypothèses de configuration du code métier.

Livraisons :

- table `TYDOM_DEVICES` centralisée dans `global_data.lua` (thermostat + volets) : source de vérité unique pour tous les identifiants Tydom.
- helper `getTydomHeatURI(domoticz)` dans `global_data.lua` pour construire l'URI REST du thermostat sans dupliquer les IDs.
- `Tydom_heat_getTemp.lua` et `Tydom_heat_setPoint.lua` : suppression des IDs Tydom câblés en dur, utilisation exclusive de `getTydomHeatURI`.
- `Config_check.lua` (nouveau) : contrôle des prérequis Domoticz (devices, groupes, scènes, variables) au `systemStart` ; erreurs purement informatives sans blocage.

Vigilances à maintenir pour éviter la réintroduction de ces défauts :

- **ne jamais écrire d'identifiant Tydom en dur dans un script métier** : utiliser exclusivement `domoticz.helpers.TYDOM_DEVICES` ;
- tout remplacement matériel Tydom doit se traiter **uniquement** dans la table `TYDOM_DEVICES` de `global_data.lua` ;
- **maintenir les listes de prérequis** dans `Config_check.lua` à jour : tout ajout d'un device, groupe, scène ou variable Domoticz critique au système doit s'accompagner d'une entrée dans ce script ;
- les erreurs de `Config_check.lua` sont informatives : elles ne bloquent pas l'exécution mais doivent être traitées avant mise en production.

Instruction :

- la phase 4 est terminée ; ne pas rouvrir ce chantier sans identifier un nouveau cas de couplage avéré.

### Phase 5 - Factorisation et observabilité ✅ Couverte par le lot DEV-5

Objectif : rendre le système plus lisible et plus simple à maintenir.

Livraisons :

- helper `verifyGroupeFromItem(groupe, items, uuid, domoticz)` centralisé dans `global_data.lua` : réalignement silencieux d'un groupe Domoticz à partir de ses items, utilisable indifféremment pour volets et lampes.
- `Groupes_Volets.lua`, `Tydom_volets_setPosition.lua`, `Devices_Lampes_Groupe.lua` : suppression du code de réalignement local, utilisation exclusive de `verifyGroupeFromItem`.
- `Health_check_dzVents.lua` (nouveau) : contrôle quotidien à 08:00 de quatre indicateurs de santé (`scenePhase`, fraîcheur des scènes, Freebox, Tydom) ; notification Signal en cas d'indicateur dégradé.
- Homogénéisation des logs sur le périmètre touché : marker entre crochets `[Domaine] `, format `[uuid] message`, niveaux cohérents.

Vigilances à maintenir pour éviter la réintroduction de ces défauts :

- **ne jamais ré-implémenter localement la logique de réalignement de groupe** : toujours utiliser `domoticz.helpers.verifyGroupeFromItem` ;
- tout nouveau groupe ou modification de hiérarchie de groupes doit s'accompagner de la mise à jour des appels à `verifyGroupeFromItem` dans les scripts concernés ;
- **maintenir les indicateurs de `Health_check_dzVents.lua` à jour** : tout ajout d'intégration critique ou changement de polling doit se traduire par un indicateur supplémentaire ou une révision des seuils ;
- les seuils actuels sont : scenePhase exploitable (avec distinction transitoire/panne via fraîcheur du device Phase), device `Phase` < 25 h, `Freebox` < 10 min, `Tydom Temperature` < 90 min ;
- respecter la convention de logs dans tout nouveau script ou modification : `marker = "[Domaine] "`, format `"[" .. uuid .. "] " .. message`, `LOG_DEBUG` pour le détail, `LOG_INFO` pour les résumés nominaux, `LOG_ERROR` pour les anomalies ;
- ne jamais journaliser directement une variable pouvant être `nil` : utiliser `tostring()`.

Instruction :

- la phase 5 est terminée ; ne pas rouvrir ce chantier sans identifier un nouveau cas de duplication ou d'observabilité manquante.

## 5. Consignes par type de chantier

### 5.1 Si le chantier concerne les scènes

- vérifier la cohérence avec `Device_Label_Scene_Phase.lua` ;
- garantir que la phase du jour reste traçable ;
- vérifier les effets croisés sur chauffage, présence, lampes et volets ;
- éviter toute divergence de comportement entre scènes homologues ;
- **si une nouvelle phase est créée**, l'ajouter obligatoirement dans la table `validPhases` de `Device_Label_Scene_Phase.lua` pour qu'elle soit reconnue lors du boot ;
- **ne jamais supposer que `scenePhase` contient une valeur métier valide** : au démarrage, elle peut valoir `'Inconnue'` jusqu'à ce qu'une scène s'exécute.

### 5.2 Si le chantier concerne la présence

- vérifier le flux complet `Freebox_LAN_statuts` -> `Devices_Telephones` -> `Device_Presence_Domicile` -> consommateurs ;
- distinguer clairement état détecté, état publié et état rejoué ;
- ne pas introduire de changement sans revalider le debounce et le rejeu de scène.

### 5.3 Si le chantier concerne Tydom

- identifier si le script lit l'état réel, écrit une commande ou fait les deux ;
- éviter les écarts entre vérité terrain Tydom et état Domoticz ;
- conserver une stratégie de corrélation des appels ;
- **ne jamais écrire d'identifiant Tydom (`deviceId`, `endpointId`) directement dans un script** : lire exclusivement `domoticz.helpers.TYDOM_DEVICES` ;
- tout ajout ou modification d'équipement Tydom doit être traité **uniquement** dans la table `TYDOM_DEVICES` de `global_data.lua` ;
- utiliser `getTydomHeatURI(domoticz)` pour le thermostat et `getTydomDeviceNumberFromDzItem` / `getDzItemFromTydomDeviceId` pour les volets.

### 5.4 Si le chantier concerne Freebox

- ne pas modifier la séquence d'authentification sans revue complète du flux ;
- isoler les manipulations shell ;
- traiter en priorité la robustesse et la sécurité avant toute optimisation ;
- vérifier les impacts sur le comptage des équipements personnels.

### 5.5 Si le chantier concerne les groupes

- vérifier les deux sens de synchronisation : groupe vers items et items vers groupe ;
- s'assurer qu'aucune correction ne casse les niveaux intermédiaires ;
- **toujours utiliser `domoticz.helpers.verifyGroupeFromItem` pour tout réalignement groupe <- items** ; ne pas ré-implémenter la logique localement ;
- si une hiérarchie de groupes change, mettre à jour tous les appels à `verifyGroupeFromItem` dans les scripts concernés (`Groupes_Volets.lua`, `Tydom_volets_setPosition.lua`, `Devices_Lampes_Groupe.lua`, etc.) ;
- ne factoriser qu'après stabilisation des comportements existants.

## 6. Définition de fini pour chaque lot

Un lot n'est considéré terminé que si :

- les scripts modifiés sont relus avec leur flux complet ;
- les hypothèses de configuration sont identifiées ;
- les logs utiles sont présents ;
- la documentation impactée est mise à jour ;
- les risques de bord sur les autres scripts ont été vérifiés ;
- les modifications restent limitées au périmètre annoncé ;
- tout nouvel objet Domoticz critique est référencé dans `Config_check.lua` ;
- tout nouvel identifiant Tydom est ajouté à `TYDOM_DEVICES` dans `global_data.lua` ;
- tout réalignement de groupe passe par `domoticz.helpers.verifyGroupeFromItem` ;
- les logs respectent la convention : marker `[Domaine] `, format `[uuid] message`, niveaux `LOG_DEBUG` / `LOG_INFO` / `LOG_ERROR`.

## 7. Interdictions pendant les travaux

- ne pas renommer des devices, groupes ou variables sans chantier explicite de migration ;
- ne pas introduire de nouvelle dépendance externe sans justification forte ;
- ne pas réécrire l'architecture complète en une seule fois ;
- ne pas fusionner correction de bug et nouvelle logique métier dans un même correctif sans nécessité ;
- ne pas supprimer les traces `uuid` existantes sans alternative équivalente.

## 8. Backlog d'ouverture recommandé

Le backlog initial doit être créé à partir des items suivants :

1. ~~correction des anomalies certaines sur `nil`, `local`, `previousMode` et `scenePhase`~~ → **corrigé dans le lot DEV-1** ;
2. ~~stratégie d'initialisation fiable de `scenePhase`~~ → **corrigé dans le lot DEV-2** ;
3. ~~gestion minimale des erreurs HTTP avec logs homogènes~~ → **livré dans le lot DEV-3** (`global_HTTP_response.lua`) ;
4. ~~cartographie de configuration Domoticz attendue~~ → **livré dans le lot DEV-4** (`Config_check.lua`) ;
5. ~~externalisation progressive des mappings Tydom~~ → **livré dans le lot DEV-4** (`TYDOM_DEVICES`) ;
6. ~~factorisation de la logique de groupes~~ → **livré dans le lot DEV-5** (`verifyGroupeFromItem`) ;
7. ~~health check et observabilité~~ → **livré dans le lot DEV-5** (`Health_check_dzVents.lua`).

## 9. Format conseillé pour les futures demandes de travaux

Chaque demande de mise en œuvre devrait préciser :

- le domaine concerné ;
- le problème constaté ;
- le script ou flux cible ;
- le comportement attendu ;
- le niveau de priorité ;
- les risques connus ;
- le besoin éventuel de mise à jour documentaire.

## 10. Instruction finale

Tant que la phase de stabilisation n'est pas terminée, toute nouvelle évolution fonctionnelle doit être considérée comme secondaire.

La priorité d'exécution reste :

1. fiabiliser l'état métier ;
2. corriger les bugs avérés ;
3. sécuriser les intégrations ;
4. seulement ensuite optimiser ou étendre le système.
