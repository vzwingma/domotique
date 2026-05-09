# Copilot instructions for domotique

Ces instructions s'appliquent en priorite quand vous travaillez dans domoticz/scripts/dzVents.

## Agents et orchestration

Le projet suit une orchestration multi-agents avec validation humaine a chaque etape:
- ARCos [v2.3]: planification et decisions architecturales
- DEVon [v2.1]: implementation
- QUALvin [v2.3]: verification qualite
- DOCly [v2.2]: documentation

Les fichiers de specificites projet sont:
- .github/instructions/architect.instructions.md
- .github/instructions/dev.instructions.md
- .github/instructions/qa.instructions.md
- .github/instructions/doc.instructions.md

## Sources de verite

- Lire .github/tasks/todo/RETROCONCEPTION_dzVents.md avant toute evolution de comportement.
- Lire .github/tasks/todo/PLAN_ACTIONS_dzVents.md avant toute proposition de refactoring/roadmap.
- Lire domoticz/scripts/dzVents/global_data.lua avant toute modification dzVents.
- TYDOM_DEVICES dans global_data.lua est l'unique source de verite des IDs Tydom.
- Config_check.lua est la liste de prerequis Domoticz (devices, groupes, scenes, variables).
- En cas d'ecart doc/code, le code fait foi puis la documentation est alignee dans le meme changement.

## Etat documentaire du depot

- Le depot ne contient pas de dossier docs/ a ce jour.
- docs/ARCHITECTURE.md est donc absent: en fin d'initiative, deleguer a DOCly la creation de ce document.
- Les references BEST_PRACTICES.md, CODING_STANDARDS.md, CONTRIBUTING.md, CHANGELOG.md et configuration ESLint ne sont pas presentes au niveau du repo (hors dependances node_modules).

## Architecture dzVents

Traiter dzVents comme un systeme evenementiel:
- global_*: constantes, helpers, wrappers HTTP, etat partage
- Device_* et Devices_*: logique metier reactant aux evenements
- Groupes_*: synchronisation groupe -> items et items -> groupe
- Scene_*: orchestration des phases quotidiennes
- Freebox_* et Tydom_*: integrations externes et callbacks HTTP

Regles de coherence:
- scenePhase doit etre maintenue via l'evenement custom Scene Phase.
- La restauration au boot est geree par Device_Label_Scene_Phase.lua.
- Preserver la propagation uuid et la correlaton des logs de bout en bout.

## Priorites de travail

Jusqu'a stabilisation:
1. corriger les bugs confirmes
2. securiser l'etat partage et scenePhase
3. renforcer la robustesse des integrations HTTP
4. reduire le couplage hard-code
5. ameliorer observabilite et duplication
6. ajouter de nouvelles fonctionnalites ensuite

## Non-regression dzVents

### DEV-1
- Tydom_heat_getTemp.lua: utiliser nil, jamais null.
- global_data.lua: declarer les variables temporaires en local.
- Device_Mode_Domicile.lua: mettre a jour previousMode en fin de traitement.
- Device_Presence_Domicile.lua: stocker/comparer une valeur simple (levelName), pas un objet device.
- Scene_4_Nuit_2.lua: ne jamais ecrire globalData.scenePhase directement, emettre Scene Phase.

### DEV-2 (boot scenePhase)
- Device_Label_Scene_Phase.lua doit ecouter system start et Scene Phase.
- Toute nouvelle phase Scene_* doit etre ajoutee dans validPhases.
- Fallback Inconnue est intentionnel et doit etre tolere par tous les consommateurs.
- getMomentJournee retourne nil quand scenePhase == Inconnue.
- Toujours logger les valeurs potentiellement nil via tostring().

### DEV-4 (Tydom + prerequis)
- Interdiction de hard-coder deviceId/endpointId Tydom.
- Utiliser getTydomHeatURI(domoticz) pour les scripts Tydom_heat_*.
- En cas de remplacement materiel, modifier TYDOM_DEVICES uniquement.
- Toute nouvelle dependance Domoticz critique doit etre ajoutee a Config_check.lua.

### DEV-5 (groupes + health check)
- Tout realignement groupe <- items passe par verifyGroupeFromItem(groupe, items, uuid, domoticz).
- Mettre a jour les appels dans Groupes_Volets.lua, Tydom_volets_setPosition.lua, Devices_Lampes_Groupe.lua si la hierarchie change.
- Health_check_dzVents.lua (08:00) controle:
  - scenePhase exploitable
  - device Phase recemment mis a jour (< 25h)
  - Freebox recente (< 10 min)
  - Tydom Temperature recente (< 90 min)

## Conventions de logs

Dans tous les scripts dzVents:
- marker au format [Domaine]
- message au format [uuid] message
- LOG_DEBUG pour details techniques
- LOG_INFO pour nominal et realignements
- LOG_ERROR pour anomalies
- tostring() obligatoire pour toute variable pouvant etre nil

## Regles d'edition dzVents

- Faire des changements chirurgicaux, flux par flux.
- Avant d'editer un script: identifier triggers, evenements emis, donnees lues, effets de bord Domoticz/Freebox/Tydom.
- Conserver les noms d'evenements existants sauf migration explicite.
- Ne pas renommer devices/groupes/scenes/variables Domoticz sans plan de migration valide.
- Ne pas casser la tracabilite uuid.

## Regles par domaine

### Scenes
- Garder la coherence avec Device_Label_Scene_Phase.lua.
- Verifier impacts chauffage, lumieres, volets, presence.
- Tolerer explicitement l'etat Inconnue.

### Presence
- Revalider la chaine Freebox_LAN_statuts -> Devices_Telephones -> Device_Presence_Domicile -> consommateurs.

### Tydom
- Distinguer ecriture et reconciliation.
- Eviter les incoherences entre etat Domoticz et etat reel Tydom.
- Utiliser domoticz.helpers.TYDOM_DEVICES + helpers de mapping dedies.

### Freebox
- Preserver la sequence d'authentification.
- Traiter la construction de commandes shell comme sensible.

### Groupes
- Verifier les deux sens (groupe -> items et items -> groupe).
- Preserver les realignements silencieux.

## Validation attendue

Pour toute modification dzVents, verifier au minimum:
- comportement direct du script
- flux cross-scripts impacte
- coherence scenePhase
- qualite des logs (marker, uuid, niveau)
- coherence des realignements de groupes
- seuils/indicateurs Health_check_dzVents.lua si polling modifie
- documentation impactee

## Point faible ouvert

Quand vous touchez le script concerne, renforcer la resilience de global_HTTP_response.lua (au-dela de la journalisation simple).

## A eviter

- Ne pas refondre toute l'architecture en un seul changement.
- Ne pas melanger bugfix, nouvelle feature et refacto large sans justification explicite.
- Ne pas introduire de dependance externe sans necessite claire.
- Ne pas supposer qu'un ID ou nom hard-code peut changer sans audit des dependances.
