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

### Phase 1 - Stabilisation immédiate

Traiter en priorité les anomalies avérées :

- remplacer `null` par `nil` dans `Tydom_heat_getTemp.lua` ;
- corriger les variables globales implicites comme `suffixeMode` ;
- corriger la gestion de `previousMode` dans `Device_Mode_Domicile.lua` ;
- corriger le stockage et la comparaison d'état dans `Device_Presence_Domicile.lua` ;
- uniformiser la gestion de `scenePhase`, notamment dans `Scene_4_Nuit_2.lua`.

Instruction :

- ne pas ouvrir de chantier d'optimisation avant la clôture de cette phase ;
- regrouper ces corrections dans un lot court centré sur la fiabilité.

### Phase 2 - Sécurisation de l'état métier

Objectif : garantir qu'un redémarrage Domoticz ne laisse pas le système sans phase exploitable.

Instruction :

- définir une source de vérité d'initialisation pour `scenePhase` ;
- si nécessaire, utiliser le device `Phase` comme point de restauration ;
- documenter précisément le comportement attendu au boot.

### Phase 3 - Robustesse des intégrations HTTP

Objectif : éviter les pannes silencieuses sur Freebox et Tydom.

Instruction :

- enrichir d'abord la gestion d'erreur commune ;
- ne pas ajouter de retry sans distinguer appels idempotents et non idempotents ;
- journaliser toute erreur critique avec le contexte fonctionnel ;
- prévoir une alerte opérateur sur erreurs répétées.

### Phase 4 - Réduction du couplage

Objectif : sortir progressivement les hypothèses de configuration du code métier.

Instruction :

- centraliser les mappings Tydom ;
- produire une cartographie des prérequis Domoticz ;
- vérifier explicitement l'existence des objets indispensables avant exécution d'un flux critique.

### Phase 5 - Factorisation et observabilité

Objectif : rendre le système plus lisible et plus simple à maintenir.

Instruction :

- mutualiser les logiques d'alignement de groupes ;
- normaliser les messages et niveaux de log ;
- ajouter un contrôle de santé une fois la base stabilisée.

## 5. Consignes par type de chantier

### 5.1 Si le chantier concerne les scènes

- vérifier la cohérence avec `Device_Label_Scene_Phase.lua` ;
- garantir que la phase du jour reste traçable ;
- vérifier les effets croisés sur chauffage, présence, lampes et volets ;
- éviter toute divergence de comportement entre scènes homologues.

### 5.2 Si le chantier concerne la présence

- vérifier le flux complet `Freebox_LAN_statuts` -> `Devices_Telephones` -> `Device_Presence_Domicile` -> consommateurs ;
- distinguer clairement état détecté, état publié et état rejoué ;
- ne pas introduire de changement sans revalider le debounce et le rejeu de scène.

### 5.3 Si le chantier concerne Tydom

- identifier si le script lit l'état réel, écrit une commande ou fait les deux ;
- éviter les écarts entre vérité terrain Tydom et état Domoticz ;
- conserver une stratégie de corrélation des appels ;
- documenter tout identifiant externe utilisé.

### 5.4 Si le chantier concerne Freebox

- ne pas modifier la séquence d'authentification sans revue complète du flux ;
- isoler les manipulations shell ;
- traiter en priorité la robustesse et la sécurité avant toute optimisation ;
- vérifier les impacts sur le comptage des équipements personnels.

### 5.5 Si le chantier concerne les groupes

- vérifier les deux sens de synchronisation : groupe vers items et items vers groupe ;
- s'assurer qu'aucune correction ne casse les niveaux intermédiaires ;
- ne factoriser qu'après stabilisation des comportements existants.

## 6. Définition de fini pour chaque lot

Un lot n'est considéré terminé que si :

- les scripts modifiés sont relus avec leur flux complet ;
- les hypothèses de configuration sont identifiées ;
- les logs utiles sont présents ;
- la documentation impactée est mise à jour ;
- les risques de bord sur les autres scripts ont été vérifiés ;
- les modifications restent limitées au périmètre annoncé.

## 7. Interdictions pendant les travaux

- ne pas renommer des devices, groupes ou variables sans chantier explicite de migration ;
- ne pas introduire de nouvelle dépendance externe sans justification forte ;
- ne pas réécrire l'architecture complète en une seule fois ;
- ne pas fusionner correction de bug et nouvelle logique métier dans un même correctif sans nécessité ;
- ne pas supprimer les traces `uuid` existantes sans alternative équivalente.

## 8. Backlog d'ouverture recommandé

Le backlog initial doit être créé à partir des items suivants :

1. correction des anomalies certaines sur `nil`, `local`, `previousMode` et `scenePhase` ;
2. stratégie d'initialisation fiable de `scenePhase` ;
3. gestion minimale des erreurs HTTP avec logs homogènes ;
4. cartographie de configuration Domoticz attendue ;
5. externalisation progressive des mappings Tydom ;
6. factorisation de la logique de groupes ;
7. health check et observabilité.

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
