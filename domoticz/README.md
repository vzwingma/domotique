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
  - porte l'état global `scenePhase` ;
  - contient la table `TYDOM_DEVICES`, **source de vérité unique** pour tous les identifiants Tydom (thermostat et volets).

- `global_HTTP_response.lua`
  - reçoit les réponses HTTP génériques ;
  - journalise les succès et erreurs ;
  - ne contient pas de stratégie de reprise ni d'escalade.

- `Config_check.lua`
  - déclenché une fois au boot (`systemStart`) ;
  - vérifie la présence de tous les devices, groupes, scènes Domoticz et variables utilisateur critiques ;
  - émet un `LOG_ERROR` pour chaque prérequis absent, puis un résumé global ;
  - n'interrompt aucun flux : les erreurs sont purement informatives.

| `Health_check_dzVents.lua` décrit ci-dessus, 5 indicateurs sont contrôlés quotidiennement (à 08:00) :
1. `scenePhase` : valeur exploitable (pas `nil` ni `'Inconnue'`) ;
   si `'Inconnue'` mais device `Phase` < 25h → état transitoire probable après redémarrage (LOG_INFO) ;
   si `'Inconnue'` et device `Phase` >= 25h → panne avérée (LOG_ERROR) ;
2. device `Phase` : dernière mise à jour < 25 heures (preuve qu'une scène a tourné) ;
3. device `Freebox` : dernière mise à jour < 10 minutes (polling Freebox ~1 min) ;
   seuil relevé de 5 à 10 min pour absorber les délais de polling après redémarrage nocturne ;
4. device `Tydom Temperature` : dernière mise à jour < 90 minutes (polling Tydom ~60 min) ;
5. `globalData.joursFeries` : liste non vide ; si vide, émission de l'événement `JoursFeries Refresh` pour forcer le rechargement.

Chaque indicateur dégradé produit un `LOG_ERROR` corrélé à un `uuid` et déclenche une notification Signal.

### 2.2 Couche d'intégration externe

- `Freebox_login.lua`
- `Freebox_statut.lua`
- `Freebox_LAN_statuts.lua`
- `Tydom_heat_getTemp.lua`
- `Tydom_heat_setPoint.lua`
- `Tydom_volets_getPosition.lua`
- `Tydom_volets_setPosition.lua`
- `Tydom_refresh_values.lua`
- `JoursFeries_API.lua`
  - charge les jours fériés français depuis l'API officielle `calendrier.api.gouv.fr` ;
  - persiste la table de lookup `{ ['YYYY-MM-DD'] = true }` dans `domoticz.globalData.joursFeries` ;
  - déclenché annuellement (1er janvier 00:05), mensuellement en failsafe (1er du mois 00:10) et à la demande via l'événement `JoursFeries Refresh`.

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
| `global_data.lua` | Référentiel de constantes, helpers, table `TYDOM_DEVICES` et wrappers HTTP | Chargement global | Fonctions partagées, `globalData.scenePhase`, IDs Tydom centralisés |
| `global_HTTP_response.lua` | Callback HTTP générique | `httpResponses` | Logs succès/erreur |
| `Config_check.lua` | Contrôle de prérequis Domoticz au démarrage | `systemStart` | `LOG_ERROR` par prérequis absent, résumé global |
| `Health_check_dzVents.lua` | Contrôle quotidien de santé des automatismes (scenePhase, scènes, Freebox, Tydom, jours fériés) — 5 indicateurs | timer `at 08:00` | `LOG_ERROR` + notification Signal si indicateur dégradé ; `LOG_INFO` résumé si tout est nominal |
| `JoursFeries_API.lua` | Chargement des jours fériés français depuis l'API officielle `calendrier.api.gouv.fr` | timer annuel (1/1 00:05), timer mensuel (1er du mois 00:10), customEvent `JoursFeries Refresh` | `globalData.joursFeries` = table de lookup `{ ['YYYY-MM-DD'] = true }` |
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
| `Device_Label_Scene_Phase.lua` | Mise à jour de la phase courante et restauration au démarrage | event `Scene Phase`, `systemStart` | `globalData.scenePhase`, device texte `Phase` |
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
| `Scene_4_Nuit_2.lua` | Variante de nuit | scène | event `Scene Phase`, event `Scenario Nuit` |
| `Supervision_IoT_devices.lua` | Contrôle batterie et fraîcheur des équipements IoT | timer | notifications d'alerte |

## 4. Déclencheurs et mécanismes d'activation

## 4.1 Timers

- `Freebox_login.lua` : `every minute`
- `Tydom_heat_getTemp.lua` : `every hour`
- `Tydom_volets_getPosition.lua` : `every 30 minutes`
- `Tydom_refresh_values.lua` : `every 12 minutes`
- `Devices_Lampes.lua` : `30 minutes after sunrise`
- `Supervision_IoT_devices.lua` : contrôle quotidien
- `Health_check_dzVents.lua` : `at 08:00` (contrôle quotidien de santé des automatismes)
- `JoursFeries_API.lua` : `at 00:05 on 1/1` (chargement annuel) + `at 00:10 on 1` (failsafe mensuel)

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
- `JoursFeries Refresh`

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

### Cycle de vie de `scenePhase`

`scenePhase` suit le cycle de vie suivant :

1. **Valeur initiale** : `nil` à la définition dans `global_data.lua` (`data = { scenePhase = { initial = nil } }`).
2. **Restauration au boot** (`systemStart`) : `Device_Label_Scene_Phase.lua` lit le device texte `Phase` et restaure `scenePhase` si la valeur lue est reconnue dans la table des phases valides :
   `PreparationChauffage`, `Reveil`, `Journee`, `Journee Ete`, `Journee Vacs`, `Soiree`, `Nuit`, `Nuit 2`.
3. **Fallback explicite** : si le device `Phase` est absent, vide, ou contient une valeur non reconnue, `scenePhase` est initialisée à `'Inconnue'`. Cette valeur est intentionnelle et signifie que le moment de journée n'est pas encore déterminable. `getMomentJournee` retournera alors `nil` (comportement attendu).
4. **Mise à jour nominale** : à chaque événement `Scene Phase`, `scenePhase` est écrasée par la nouvelle valeur et le device texte `Phase` est mis à jour en conséquence.

La valeur `'Inconnue'` ne doit jamais déclencher de comportement incorrect : `getMomentJournee` utilise `tostring(moment)` pour journaliser sans crash même si `moment` est `nil`.

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

### Flux nominal (runtime)

1. Une scène `Scene_*` s'exécute.
2. Elle émet `Scene Phase`.
3. `Device_Label_Scene_Phase.lua` met à jour :
   - `domoticz.globalData.scenePhase`
   - le device texte `Phase`
4. D'autres scripts consomment cette phase pour adapter chauffage, lumière et rejeu.

### Flux de boot (restauration)

1. Au `systemStart`, `Device_Label_Scene_Phase.lua` est déclenché en dehors du circuit événementiel.
2. Il lit le device texte `Phase`.
3. Si la valeur est dans la liste des phases valides, `scenePhase` est restaurée depuis ce device.
4. Sinon, `scenePhase` est positionnée à `'Inconnue'` (fallback explicite).
5. Dans les deux cas, un log `[boot]` est émis au niveau `INFO` pour traçabilité.

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
- les volets et le thermostat dépendent des identifiants Tydom centralisés dans `TYDOM_DEVICES` de `global_data.lua`.

## 7.2 Dépendances métiers

- la température cible dépend simultanément de la phase, du mode et de la présence ;
- les lumières dépendent de la présence et du moment de journée ;
- le retour au mode `Normal` déclenche un rejeu de la scène courante ;
- la fermeture de la porte relance le cycle Freebox.

## 7.3 Dépendances d'infrastructure

- présence d'`openssl` et d'outils shell compatibles pour Freebox ;
- disponibilité réseau locale du bridge Tydom ;
- disponibilité de l'API Freebox ;
- cohérence des noms des devices Domoticz (vérifiée au boot par `Config_check.lua`).

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

Les noms des devices sont codés dans `global_data.lua`. Le système repose donc sur la stabilité exacte des libellés Domoticz. Leur présence est vérifiée au démarrage par `Config_check.lua`, qui émet une erreur pour chaque élément absent.

## 9.2 Identifiants Tydom critiques

Depuis le lot DEV-4, **tous les identifiants Tydom sont centralisés dans la table `TYDOM_DEVICES` de `global_data.lua`**. Cette table est la seule source de vérité pour les `deviceId` et `endpointId` Tydom. Aucun script métier ne doit contenir d'ID Tydom en dur.

Structure de la table :

- `TYDOM_DEVICES.thermostat` → identifiants du thermostat, utilisés par `Tydom_heat_getTemp.lua` et `Tydom_heat_setPoint.lua` via le helper `getTydomHeatURI`.
- `TYDOM_DEVICES.volets[nom_device_domoticz]` → identifiants de chaque volet, utilisés par `getTydomDeviceNumberFromDzItem` et `getDzItemFromTydomDeviceId`.

En cas de remplacement matériel, **seule cette table est à modifier**.

## 9.3 Paramètres métier

Les variables suffixées constituent la couche de configuration fonctionnelle. Elles permettent de modifier le comportement sans éditer le code, à condition que les noms restent cohérents.

---

## 10. Conventions et pièges dzVents

Cette section recense les comportements contre-intuitifs et les conventions à respecter impérativement lors de la modification ou de l'ajout de scripts dzVents.

### 10.1 Portée de l'objet `domoticz`

L'objet `domoticz` n'est **disponible que dans la fonction `execute`**. Il ne doit jamais être utilisé au niveau module (hors de la fonction), sous peine d'erreur à l'exécution.

```lua
-- ✅ Correct
return {
    execute = function(domoticz, item)
        domoticz.log('OK')
    end
}

-- ❌ Incorrect — domoticz non disponible ici
local x = domoticz.devices('MonDevice') -- crash
return { ... }
```

### 10.2 Constantes de logging

Les niveaux de log dzVents doivent être des **valeurs numériques**, pas des constantes symboliques :

| Constante | Valeur numérique |
|---|---|
| `LOG_DEBUG` | `1` |
| `LOG_INFO` | `3` |
| `LOG_ERROR` | `5` |

```lua
domoticz.log('message', 1)  -- DEBUG
domoticz.log('message', 3)  -- INFO
domoticz.log('message', 5)  -- ERROR
```

### 10.3 Syntaxe de démarrage système

Pour déclencher un script au démarrage de Domoticz, utiliser la syntaxe tableau :

```lua
-- ✅ Correct
on = {
    system = { 'start' }
}

-- ❌ Incorrect (ne fonctionne pas en dzVents)
-- systemStart = true
```

### 10.4 Switches On/Off non-dimmer

Les switches simples (non-dimmer) n'ont pas de propriété `level`. Il faut tester `device.state` :

```lua
-- device.level == nil pour un switch On/Off non-dimmer
-- ✅ Correct
if device.state == 'On' then ... end

-- Pour les dimmers, device.level retourne 0-100
```

### 10.5 Accès sécurisé aux devices

`domoticz.devices(name)` **lève une exception** si le device n'existe pas. Utiliser `pcall` pour un accès sécurisé :

```lua
local ok, device = pcall(function()
    return domoticz.devices('NomDuDevice')
end)
if ok and device then
    -- utiliser device
end
```

---

## 11. Helpers disponibles (`global_data.lua`)

Tous les helpers sont accessibles via `domoticz.helpers.*` dans n'importe quel script.

| Helper | Signature | Description |
|---|---|---|
| `uuid` | `uuid()` | Génère un UUID v4 utilisé comme identifiant de corrélation dans les logs et headers HTTP |
| `getLevelFromState` | `getLevelFromState(item)` | Retourne le niveau d'un device : `item.level` si dimmer, `100` si state == `'On'`, `0` sinon |
| `verifyGroupeFromItem` | `verifyGroupeFromItem(groupe, items, uuid, domoticz)` | Réaligne l'état d'un groupe Domoticz en fonction des niveaux individuels de ses items |
| `callTydomBridgeGET` | `callTydomBridgeGET(path, uuid, domoticz)` | Effectue un GET authentifié vers le bridge Tydom (`/path`) avec propagation du `X-CorrId` |
| `callTydomBridgePUT` | `callTydomBridgePUT(path, data, uuid, cb, domoticz)` | Effectue un PUT authentifié vers le bridge Tydom avec body JSON et callback de résultat |
| `getTydomDeviceNumberFromDzItem` | `getTydomDeviceNumberFromDzItem(name, domoticz)` | Retourne `{ deviceId, endpointId }` Tydom à partir du nom du device Domoticz (depuis `TYDOM_DEVICES`) |
| `isJourFerie` | `isJourFerie(domoticz)` | Retourne `true` si la date du jour est un jour férié français (lookup dans `globalData.joursFeries`) ; déclenche `JoursFeries Refresh` si la liste est vide |
| `JOURS_FERIES_API_URL` | constante | URL de base de l'API officielle des jours fériés : `https://calendrier.api.gouv.fr/jours-feries/metropole/` |

> **Note :** Les helpers `callTydomBridge*` lisent `tydom_bridge_host` et `tydom_bridge_auth` depuis les variables utilisateur Domoticz pour construire l'URL et l'en-tête `Authorization`.

---

## 12. Planification des scènes

### 12.1 Horaires et comportement jour férié

Les scènes dzVents s'exécutent selon deux horaires : un slot **semaine** (tôt) et un slot **week-end / jour férié** (tardif).

| Scène | Script dzVents | Heure semaine | Heure week-end / férié | Comportement jour férié |
|---|---|---|---|---|
| Scene 0 | `Scene_0_PreparationChauffage.lua` | 7h00 | 8h00 | Slot 7h ignoré → slot 8h exécuté |
| Scene 1 | `Scene_1_Reveil.lua` | 7h45 | 9h50 | Slot 7h45 ignoré → slot 9h50 exécuté |
| Scene 2a | `Scene_2a_Journee.lua` | 8h05 | 10h00 | Slot 8h05 ignoré → slot 10h exécuté |
| Scene 2b | `Scene_2b_Journee_Ete.lua` | 10h00 | 10h00 | Non impactée |
| Scene 2c | `Scene_2c_Journee_Vacs.lua` | 10h00 | 10h00 | Non impactée |
| Scene 3 | `Scene_3_Soiree.lua` | Coucher du soleil | Coucher du soleil | Non impactée |
| Scene 4 | `Scene_4_Nuit.lua` / `Scene_4_Nuit_2.lua` | 1h00 | 1h00 / 3h00 | Non impactée |

### 12.2 Logique guards dans les scripts

Les scènes 0, 1 et 2a appliquent la logique suivante :

```lua
local isWeekEnd   = domoticz.time.matchesRule('at xx:xx on sat,sun')
local isJourFerie = domoticz.helpers.isJourFerie(domoticz)

-- Slot tôt : ignoré si week-end ou jour férié
if not isWeekEnd and not isJourFerie then
    -- exécution slot semaine (7h00 / 7h45 / 8h05)
end

-- Slot tardif : exécuté si week-end OU jour férié
if isWeekEnd or isJourFerie then
    -- exécution slot tardif (8h00 / 9h50 / 10h00)
end
```

### 12.3 Composants de la feature jours fériés

- **`JoursFeries_API.lua`** : script dzVents qui charge les jours fériés depuis l'API officielle française `calendrier.api.gouv.fr` et persiste le résultat dans `domoticz.globalData.joursFeries`. Déclencheurs : timer annuel (1er janvier 00:05), timer mensuel failsafe (1er du mois 00:10), customEvent `JoursFeries Refresh` (on-demand si liste vide).

- **`isJourFerie(domoticz)`** : helper défini dans `global_data.lua`, accessible via `domoticz.helpers.isJourFerie(domoticz)`. Effectue un lookup dans `globalData.joursFeries` pour la date courante. Si la liste est vide ou absente, déclenche automatiquement un rechargement via `emitEvent('JoursFeries Refresh')`.

### 12.4 Action manuelle requise dans Domoticz

> ⚠️ **Cette étape ne peut pas être automatisée par code.** Elle doit être réalisée dans l'interface du planificateur Domoticz.

Pour que les jours fériés tombant un jour de semaine déclenchent bien la version "tardive" des scènes, il faut ajouter un **3e déclenchement lun-ven** (à l'heure tardive) dans le planificateur Domoticz :

| Scène Domoticz | Déclenchement à ajouter |
|---|---|
| PreparationChauffage | lun-ven à 08:00 |
| Reveil | lun-ven à 09:50 |
| Journee | lun-ven à 10:00 |

Sans ce 3e slot, un jour férié en semaine ne déclenchera pas le slot tardif, car le planificateur ne l'a pas programmé pour ce créneau en semaine.
