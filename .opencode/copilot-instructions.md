# OpenCode instructions — domotique

Instructions globales projet, lues par tous les agents OpenCode au démarrage. Contient conventions dzVents, règles de non-régression, architecture et validation.

## Agents et orchestration

Le projet suit une orchestration multi-agents avec validation humaine à chaque étape :
- 🟠 **ARCos** : planification et décisions architecturales
- 🔵 **DEVon** : implémentation
- 🟢 **QALvin** : vérification qualité
- 🟣 **DOCly** : documentation

Les fichiers d'instructions projet sont dans `.opencode/instructions/` :
- `.opencode/instructions/architect.instructions.md`
- `.opencode/instructions/dev.instructions.md`
- `.opencode/instructions/qa.instructions.md`
- `.opencode/instructions/doc.instructions.md`

Vue transverse agents + workflow : `.opencode/README.md`

### Règle obligatoire ARCos — plan + ADR

Toute initiative architecturale ou infrastructure doit produire **avant** de marquer la tâche terminée :
1. Un fichier Plan d'Action dans `.opencode/plans/NNN_nom.plan.md`
2. Un ADR dans `docs/adr/NNN-titre-court.md` si décision architecturale majeure
3. Une mise à jour de l'index `.opencode/plans/README.md`

## Sources de vérité

- Lire `docs/RETROCONCEPTION_dzVents.md` avant toute évolution de comportement
- Lire `domoticz/scripts/dzVents/global_data.lua` avant toute modification dzVents
- `TYDOM_DEVICES` dans `global_data.lua` est l'unique source de vérité des IDs Tydom
- `Config_check.lua` est la liste des prérequis Domoticz (devices, groupes, scènes, variables)
- En cas d'écart doc/code, le code fait foi puis la documentation est alignée dans le même changement

## État documentaire du dépôt

- Lire `docs/adr/` pour les ADRs existants
- Lire `.opencode/plans/README.md` pour les plans d'action et leur statut global
- En cas d'écart doc/code, corriger la doc dans le même changement que le code

## Architecture dzVents

Traiter dzVents comme un système événementiel :
- `global_*` : constantes, helpers, wrappers HTTP, état partagé
- `Device_*` et `Devices_*` : logique métier réagissant aux événements
- `Groupes_*` : synchronisation groupe → items et items → groupe
- `Scene_*` : orchestration des phases quotidiennes
- `Freebox_*` et `Tydom_*` : intégrations externes et callbacks HTTP

Règles de cohérence :
- `scenePhase` maintenue via l'événement custom `Scene Phase` uniquement
- Restauration au boot gérée par `Device_Label_Scene_Phase.lua`
- Propagation `uuid` et corrélation des logs de bout en bout

## Non-régression dzVents

### DEV-1
- `Tydom_heat_getTemp.lua` : utiliser `nil`, jamais `null`
- `global_data.lua` : déclarer les variables temporaires en `local`
- `Device_Mode_Domicile.lua` : mettre à jour `previousMode` en fin de traitement
- `Device_Presence_Domicile.lua` : stocker/comparer une valeur simple (`levelName`), pas un objet device
- `Scene_4_Nuit_2.lua` : ne jamais écrire `globalData.scenePhase` directement, émettre `Scene Phase`

### DEV-2 (boot scenePhase)
- `Device_Label_Scene_Phase.lua` doit écouter `system start` et `Scene Phase`
- Toute nouvelle phase `Scene_*` doit être ajoutée dans `validPhases`
- Fallback `Inconnue` est intentionnel et doit être toléré par tous les consommateurs
- `getMomentJournee` retourne `nil` quand `scenePhase == Inconnue`
- Toujours logger les valeurs potentiellement `nil` via `tostring()`

### DEV-4 (Tydom + prérequis)
- Interdiction de hard-coder `deviceId`/`endpointId` Tydom
- Utiliser `getTydomHeatURI(domoticz)` pour les scripts `Tydom_heat_*`
- En cas de remplacement matériel, modifier `TYDOM_DEVICES` uniquement
- Toute nouvelle dépendance Domoticz critique doit être ajoutée à `Config_check.lua`

### DEV-5 (groupes + health check)
- Tout réalignement groupe ↔ items passe par `verifyGroupeFromItem(groupe, items, uuid, domoticz)`
- Mettre à jour les appels dans `Groupes_Volets.lua`, `Tydom_volets_setPosition.lua`, `Devices_Lampes_Groupe.lua` si la hiérarchie change
- `Health_check_dzVents.lua` (08:00) contrôle 5 indicateurs :
  - `scenePhase` exploitable
  - device `Phase` récemment mis à jour (< 25h)
  - `Freebox` récente (< 10 min)
  - `Tydom Temperature` récente (< 90 min)
  - `globalData.joursFeries` non vide (émet `JoursFeries Refresh` si vide)

## Conventions de logs

Dans tous les scripts dzVents :
- marker au format `[Domaine]`
- message au format `[uuid] message`
- `LOG_DEBUG` pour détails techniques
- `LOG_INFO` pour nominal et réalignements
- `LOG_ERROR` pour anomalies
- `tostring()` obligatoire pour toute variable pouvant être `nil`

## Règles d'édition dzVents

- Changements chirurgicaux, flux par flux
- Avant d'éditer un script : identifier triggers, événements émis, données lues, effets de bord Domoticz/Freebox/Tydom
- Conserver les noms d'événements existants sauf migration explicite
- Ne pas renommer devices/groupes/scènes/variables Domoticz sans plan de migration validé
- Ne pas casser la traçabilité `uuid`

### Syntaxe timer dzVents (règles critiques)

Formats valides pour le champ `timer` :
- `'at HH:MM'` — quotidien à l'heure donnée
- `'at HH:MM on weekdays'` / `'at HH:MM on weekends'`
- `'at HH:MM on mon,tue,wed,thu,fri'`

Formats INVALIDES (causent un crash au chargement du module) :
- `'at HH:MM on N/M'`
- `'at HH:MM on N'` (N = jour du mois)

Pour un déclenchement le 1er de chaque mois ou le 1er janvier : utiliser `'at HH:MM'` (quotidien) et filtrer dans `execute()` :
```lua
if item.isTimer and domoticz.time.day ~= 1 then return end
```

## Règles par domaine

### Scènes
- Garder la cohérence avec `Device_Label_Scene_Phase.lua`
- Vérifier impacts chauffage, lumières, volets, présence
- Tolérer explicitement l'état `Inconnue`

### Présence
- Revalider la chaîne `Freebox_LAN_statuts` → `Devices_Telephones` → `Device_Presence_Domicile` → consommateurs

### Tydom
- Distinguer écriture et réconciliation
- Éviter les incohérences entre état Domoticz et état réel Tydom
- Utiliser `domoticz.helpers.TYDOM_DEVICES` + helpers de mapping dédiés

### Freebox
- Préserver la séquence d'authentification
- Traiter la construction de commandes shell comme sensible

### Groupes
- Vérifier les deux sens (groupe → items et items → groupe)
- Préserver les réalignements silencieux

## Validation attendue

Pour toute modification dzVents, vérifier au minimum :
- comportement direct du script
- flux cross-scripts impacté
- cohérence `scenePhase`
- qualité des logs (marker, uuid, niveau)
- cohérence des réalignements de groupes
- seuils/indicateurs `Health_check_dzVents.lua` si polling modifié
- documentation impactée : `domoticz/README.md`, `docs/ARCHITECTURE.md`, `docs/scenarios.puml`, `docs/adr/` si décision architecturale majeure

## Point faible ouvert

Quand vous touchez le script concerné, renforcer la résilience de `global_HTTP_response.lua` (au-delà de la journalisation simple).

## À éviter

- Ne pas refondre toute l'architecture en un seul changement
- Ne pas mélanger bugfix, nouvelle feature et refacto large sans justification explicite
- Ne pas introduire de dépendance externe sans nécessité claire
- Ne pas supposer qu'un ID ou nom hard-code peut changer sans audit des dépendances

## Architecture infrastructure (_docker/)

Déploiement sur **Raspberry Pi** via Docker Compose (`_docker/domotique-compose.yml`).

| Composant | Image | Ports | Rôle |
|---|---|---|---|
| `httpd-proxy` | `vzwingmadomatic/httpd` (Apache 2.4) | 8243, 8280 | Proxy frontal TLS, point d'entrée externe |
| `domoticz` | `vzwingmadomatic/domoticz` | 8080, 8443 | Moteur domotique central |
| `tydom-bridge` | `vzwingmadomatic/domoticz-tydom` | 9101 | Bridge HTTP ↔ protocole Tydom Delta Dore |
| `deconz` | `deconzcommunity/deconz` | 9102, 9143 | Passerelle Zigbee |
| `watchtower` | `containrrr/watchtower` | — | Auto-update des images Docker |

**Accès externe :** `https://domatique.freeboxos.fr:38243/` — NAT Freebox 38243→8243 (HTTPS)

**Certificat TLS :** Let's Encrypt (webroot HTTP-01), monté en volume depuis `/home/pi/appli/letsencrypt/`.

**Configuration :** `_docker/build_httpd/httpd.conf` source de vérité Apache. Placeholder `__SERVER_NAME__` substitué par secret GitHub `SERVER_NAME` au build CI/CD.
