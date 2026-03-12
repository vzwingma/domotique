# Rétroconception des scripts `dzVents`

## 1. Périmètre analysé

Cette rétroconception couvre les scripts présents dans `domoticz\scripts\dzVents`. Le répertoire implémente une automatisation domestique autour de quatre briques majeures :

- l'orchestration de la journée par scènes Domoticz ;
- la gestion du contexte d'occupation du domicile ;
- l'intégration des équipements externes Freebox et Tydom ;
- la supervision d'équipements physiques et de capteurs.

L'ensemble est écrit sous forme de scripts dzVents déclenchés par événements Domoticz, timers, réponses HTTP et événements personnalisés.

## 2. Vue d'ensemble de l'architecture

L'architecture est organisée implicitement par familles de scripts.

### 2.1 Couche de socle

- `global_data.lua`
  - centralise les constantes de nommage Domoticz ;
  - expose les helpers métier ;
  - encapsule les appels HTTP vers Tydom et Freebox ;
  - porte l'état global `scenePhase`.

- `global_HTTP_response.lua`
  - reçoit les réponses HTTP génériques ;
  - journalise les succès et erreurs ;
  - ne contient pas de stratégie de reprise ni d'escalade.

### 2.2 Couche d'intégration externe

- `Freebox_login.lua`
- `Freebox_statut.lua`
- `Freebox_LAN_statuts.lua`
- `Tydom_heat_getTemp.lua`
- `Tydom_heat_setPoint.lua`
- `Tydom_volets_getPosition.lua`
- `Tydom_volets_setPosition.lua`
- `Tydom_refresh_values.lua`

Cette couche traduit les objets Domoticz en appels HTTP et inversement.

### 2.3 Couche métier

- `Device_Mode_Domicile.lua`
- `Device_Presence_Domicile.lua`
- `Device_Label_Scene_Phase.lua`
- `Devices_Telephones.lua`
- `Devices_TempHumidity.lua`
- `Devices_Lampes.lua`
- `Devices_Lampes_Groupe.lua`
- `Devices_Ouvertures.lua`
- `Supervision_IoT_devices.lua`

Elle transforme les événements techniques en états métier : présence, phase de journée, température cible, supervision d'ouvertures, niveau d'éclairage, etc.

### 2.4 Couche de contrôle composite

- `Groupes_Lampes.lua`
- `Groupes_Volets.lua`

Ces scripts synchronisent les groupes Domoticz et les équipements unitaires.

### 2.5 Couche scénario

- `Scene_0_PreparationChauffage.lua`
- `Scene_1_Reveil.lua`
- `Scene_2a_Journee.lua`
- `Scene_2b_Journee_Ete.lua`
- `Scene_2c_Journee_Vacs.lua`
- `Scene_3_Soiree.lua`
- `Scene_4_Nuit.lua`
- `Scene_4_Nuit_2.lua`

Ces scripts jouent la partition temporelle de la maison et diffusent la phase courante.

## 3. Inventaire détaillé des scripts

| Script | Rôle principal | Déclencheurs principaux | Sorties principales |
|---|---|---|---|
| `global_data.lua` | Référentiel de constantes, helpers et wrappers HTTP | Chargement global | Fonctions partagées, `globalData.scenePhase` |
| `global_HTTP_response.lua` | Callback HTTP générique | `httpResponses` | Logs succès/erreur |
| `Freebox_login.lua` | Authentification Freebox et gestion de session | timer minute, custom events, callbacks HTTP/shell | Événement `freebox_session`, logout |
| `Freebox_statut.lua` | Supervision du WAN Freebox | custom event `freebox_session`, callback HTTP | mise à jour capteur Freebox |
| `Freebox_LAN_statuts.lua` | Supervision LAN et détection téléphones | custom event `freebox_session`, callback HTTP | statuts TV/NAS/Domotique, nb téléphones |
| `Tydom_heat_getTemp.lua` | Lecture température et consigne thermostat | timer horaire, device, callback HTTP | mise à jour température et setpoint Domoticz |
| `Tydom_heat_setPoint.lua` | Envoi de la consigne thermostat | device thermostat | requête PUT vers Tydom |
| `Tydom_volets_getPosition.lua` | Récupération périodique des positions réelles | timer 30 min, callbacks HTTP | réalignement niveaux des volets |
| `Tydom_volets_setPosition.lua` | Envoi de position volet et réalignement groupes | devices volets | requête PUT, réalignement groupes |
| `Tydom_refresh_values.lua` | Forçage de refresh Tydom | timer 12 min, device | POST `/refresh/all` |
| `Device_Mode_Domicile.lua` | Gestion du mode Normal/Vacances/Été | device `Mode` | notification, rejeu scène |
| `Device_Presence_Domicile.lua` | Conversion présence téléphones -> présence domicile | device `Présence`, event `Presence Domicile` | changement de présence, rejeu scène, thermostat |
| `Device_Label_Scene_Phase.lua` | Mise à jour de la phase courante | event `Scene Phase` | `globalData.scenePhase`, device texte `Phase` |
| `Devices_Telephones.lua` | Debounce du nombre de téléphones connectés | device `Equipements Personnels` | event `Presence Domicile` |
| `Devices_TempHumidity.lua` | Agrégation température/humidité | devices capteurs | mise à jour devices combinés |
| `Devices_Lampes.lua` | Gestion éclairage selon présence, nuit et lever du soleil | events + timer | extinction/allumage lampes |
| `Devices_Lampes_Groupe.lua` | Réalignement groupes de lampes | devices lampes | mise à jour groupes |
| `Devices_Ouvertures.lua` | Supervision ouverture prolongée | devices ouvertures, event différé | notifications, relance surveillance, init Freebox |
| `Groupes_Lampes.lua` | Cascade groupe -> lampes | groupes de lampes | commandes sur devices unitaires |
| `Groupes_Volets.lua` | Cascade groupe -> volets | groupes de volets | commandes sur devices unitaires |
| `Scene_0_PreparationChauffage.lua` | Préparation chauffage du matin | scène | phase + thermostat |
| `Scene_1_Reveil.lua` | Réveil et pré-ouverture ciblée | scène | phase + volet chambre |
| `Scene_2a_Journee.lua` | Journée mode normal | scène | phase + volets + thermostat |
| `Scene_2b_Journee_Ete.lua` | Journée été | scène | phase + volets adaptés été |
| `Scene_2c_Journee_Vacs.lua` | Journée vacances | scène | phase + volets adaptés vacances |
| `Scene_3_Soiree.lua` | Fermeture du soir et lumière salon | scène | phase + volets + lampes |
| `Scene_4_Nuit.lua` | Passage à la nuit | scène | phase + thermostat + event `Scenario Nuit` |
| `Scene_4_Nuit_2.lua` | Variante de nuit | scène | `globalData.scenePhase`, event `Scenario Nuit` |
| `Supervision_IoT_devices.lua` | Contrôle batterie et fraîcheur des équipements IoT | timer | notifications d'alerte |

## 4. Déclencheurs et mécanismes d'activation

## 4.1 Timers

- `Freebox_login.lua` : `every minute`
- `Tydom_heat_getTemp.lua` : `every hour`
- `Tydom_volets_getPosition.lua` : `every 30 minutes`
- `Tydom_refresh_values.lua` : `every 12 minutes`
- `Devices_Lampes.lua` : `30 minutes after sunrise`
- `Supervision_IoT_devices.lua` : contrôle quotidien

Le système mélange donc automation événementielle et polling régulier.

## 4.2 Devices

Les devices Domoticz jouent le rôle de points d'entrée métier :

- `Mode` pour le mode du domicile ;
- `Présence` pour l'état d'occupation ;
- `Equipements Personnels` pour le nombre de smartphones détectés ;
- `Tydom Thermostat` et `Tydom Temperature` pour le chauffage ;
- volets et groupes de volets ;
- lampes et groupes de lampes ;
- capteurs d'ouverture ;
- capteurs de température/humidité.

## 4.3 Scènes

Les scripts `Scene_*` sont le moteur principal du cycle journalier. Chaque scène pousse presque systématiquement un événement `Scene Phase` contenant un `uuid`, un index logique et le nom de scène.

## 4.4 Événements personnalisés

Les principaux événements internes sont :

- `Scene Phase`
- `Presence Domicile`
- `Scenario Nuit`
- `Supervision Ouverture`
- `freebox_initsession`
- `freebox_session`
- `freebox_endsession`

Ils constituent le bus d'intégration interne entre scripts.

## 4.5 Réponses HTTP et shell

- réponses HTTP Tydom et Freebox corrélées par callback ;
- calcul du mot de passe Freebox via réponse de commande shell `freebox_pwd`.

## 5. État partagé et configuration

## 5.1 État global

Le point central est `domoticz.globalData.scenePhase`, défini dans `global_data.lua` puis alimenté principalement par `Device_Label_Scene_Phase.lua`.

Cette donnée sert notamment à :

- rejouer la scène courante après un changement de présence ;
- déterminer le moment de journée via `getMomentJournee` ;
- savoir si les lampes doivent se rallumer en cas de retour de présence le soir.

## 5.2 État local par script

Chaque script utilise `data = { ... }` pour conserver un contexte local :

- `uuid` pour tracer les traitements ;
- compteurs de debounce et de supervision ;
- mode précédent ou état précédent ;
- session token Freebox dans le script LAN.

## 5.3 Variables utilisateurs

Le comportement métier dépend fortement des variables Domoticz :

- connectivité :
  - `tydom_bridge_host`
  - `tydom_bridge_auth`
  - `freebox_host`
  - `freebox_apptoken`
  - `livebox_devices`

- paramètres métier :
  - `param_temp_matin`, `param_temp_soir`
  - `param_volet_reveil`, `param_volet_matin`, `param_volet_soir`
  - `param_lampe_salon_soir`

Ces variables sont suffixées selon le contexte :

- `_abs` pour l'absence ;
- `_vacs` pour le mode vacances ;
- `_ete` pour le mode été.

## 6. Flux fonctionnels reconstitués

## 6.1 Flux de présence

1. `Freebox_LAN_statuts.lua` compte les smartphones connectés.
2. Le nombre est poussé dans `Equipements Personnels`.
3. `Devices_Telephones.lua` applique un léger debounce et émet `Presence Domicile`.
4. `Device_Presence_Domicile.lua` met à jour le device `Présence`.
5. Le même script rejoue la scène courante et recalcule la consigne thermostat.
6. `Devices_Lampes.lua` réagit aussi à `Presence Domicile` pour éteindre ou rallumer selon la phase.

Ce flux montre que la présence n'est pas un simple état technique : elle réinjecte du métier dans les scènes.

## 6.2 Flux de phase de journée

1. Une scène `Scene_*` s'exécute.
2. Elle émet `Scene Phase`.
3. `Device_Label_Scene_Phase.lua` met à jour :
   - `domoticz.globalData.scenePhase`
   - le device texte `Phase`
4. D'autres scripts consomment cette phase pour adapter chauffage, lumière et rejeu.

Il s'agit d'une machine d'état implicite, mais non formalisée.

## 6.3 Flux chauffage Tydom

1. Une scène ou un changement de présence décide d'une consigne.
2. Le setpoint est appliqué au device Domoticz `Tydom Thermostat`.
3. `Tydom_heat_setPoint.lua` envoie un PUT au bridge Tydom.
4. `Tydom_heat_getTemp.lua` relit périodiquement température et setpoint réels.
5. En cas d'écart, Domoticz se réaligne sur l'état réel Tydom.

Le flux est bidirectionnel, avec Domoticz comme interface opérateur et Tydom comme vérité terrain.

## 6.4 Flux volets Tydom

1. Une scène ou un groupe agit sur un ou plusieurs volets.
2. `Tydom_volets_setPosition.lua` traduit le niveau Domoticz en position Tydom.
3. Le script réaligne ensuite les groupes en fonction des niveaux individuels.
4. `Tydom_volets_getPosition.lua` relit périodiquement la position réelle et recale les niveaux Domoticz.

Les groupes de volets forment une hiérarchie logique :

- `[Grp] Volets Salon`
- `[Grp] Volets Chambres`
- `[Grp] Tous Volets`

## 6.5 Flux Freebox

1. `Freebox_login.lua` démarre sur timer ou événement `freebox_initsession`.
2. Le script appelle `/login`, récupère le challenge, puis calcule le mot de passe HMAC via `openssl`.
3. Le token de session est obtenu par `/login/session`.
4. `Freebox_statut.lua` et `Freebox_LAN_statuts.lua` écoutent `freebox_session`.
5. Les statuts WAN/LAN sont lus puis reportés dans Domoticz.
6. `Freebox_LAN_statuts.lua` clôt ensuite la session via l'événement `freebox_endsession`.

Le flux d'authentification est correctement séquencé mais très couplé aux callbacks et au shell local.

## 6.6 Flux de supervision d'ouvertures

1. `Devices_Ouvertures.lua` réagit à l'ouverture d'une porte/fenêtre.
2. Pour la porte, il lance une surveillance différée avec compteur croissant.
3. À expiration, un événement `Supervision Ouverture` vérifie si l'ouverture persiste.
4. En cas de persistance, une notification SMS est envoyée puis la surveillance est relancée.
5. À la fermeture de la porte, une initialisation Freebox est relancée après 20 secondes.

Ce flux illustre une logique de supervision à délais croissants, simple mais efficace.

## 7. Couplages et dépendances transverses

## 7.1 Dépendances structurelles

- quasiment tous les scripts dépendent de `global_data.lua` ;
- le moteur de phase dépend de la cohérence entre scènes et `Device_Label_Scene_Phase.lua` ;
- la présence dépend indirectement du bon fonctionnement Freebox ;
- les volets et le thermostat dépendent d'identifiants Tydom câblés en dur.

## 7.2 Dépendances métiers

- la température cible dépend simultanément de la phase, du mode et de la présence ;
- les lumières dépendent de la présence et du moment de journée ;
- le retour au mode `Normal` déclenche un rejeu de la scène courante ;
- la fermeture de la porte relance le cycle Freebox.

## 7.3 Dépendances d'infrastructure

- présence d'`openssl` et d'outils shell compatibles pour Freebox ;
- disponibilité réseau locale du bridge Tydom ;
- disponibilité de l'API Freebox ;
- cohérence des noms des devices Domoticz.

## 8. Conventions observées

Les conventions de nommage sont homogènes :

- `Device_*` : logique orientée sur un device métier ;
- `Devices_*` : logique transverse sur une famille ;
- `Groupes_*` : synchronisation de groupes ;
- `Scene_<ordre>_*` : séquence chronologique de la journée ;
- `Freebox_*` et `Tydom_*` : intégrations externes ;
- `global_*` : socle partagé.

Les scripts utilisent aussi une convention de traçabilité par `uuid`, propagée dans les événements et headers HTTP.

## 9. Cartographie des principaux points de configuration

## 9.1 Identifiants Domoticz critiques

Les noms des devices sont codés dans `global_data.lua`. Le système repose donc sur la stabilité exacte des libellés Domoticz.

## 9.2 Identifiants Tydom critiques

La fonction `getTydomDeviceNumberFromDzItem` de `global_data.lua` contient des couples `deviceId` / `endpointId` codés en dur pour les volets, et `Tydom_heat_getTemp.lua` cible directement l'endpoint du thermostat.

## 9.3 Paramètres métier

Les variables suffixées constituent la couche de configuration fonctionnelle. Elles permettent de modifier le comportement sans éditer le code, à condition que les noms restent cohérents.

## 10. Observations de rétroconception

## 10.1 Points forts de conception

- séparation logique correcte entre scènes, devices, groupes et intégrations ;
- usage cohérent des événements personnalisés ;
- existence d'un état global minimal pour la phase de journée ;
- réalignement périodique entre Domoticz et la vérité terrain Tydom ;
- traçabilité par `uuid` sur une grande partie des flux.

## 10.2 Limites structurelles

- absence de modélisation explicite des transitions d'état ;
- très fort couplage par noms de devices, variables et IDs externes ;
- logique transversale dispersée entre scènes et scripts métier ;
- faible mutualisation de certaines logiques de groupe ;
- gestion d'erreur limitée au logging.

## 11. Conclusion

Le répertoire `dzVents` implémente une architecture événementielle pragmatique, riche en automatisations et déjà structurée par domaines. Sa conception repose toutefois sur plusieurs hypothèses fragiles : noms exacts des objets Domoticz, IDs Tydom stables, disponibilité réseau, et bon enchaînement des callbacks.

La rétroconception montre un socle fonctionnel solide pour un usage domestique, mais aussi une base qui gagnerait à être industrialisée sur quatre axes : fiabilisation des flux externes, réduction du couplage, explicitation de l'état métier, et amélioration de l'observabilité.
