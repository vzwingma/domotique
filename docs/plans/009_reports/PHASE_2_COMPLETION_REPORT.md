# Phase 2 : Revue factuelle et liens

**Plan :** `docs/plans/009_retrodoc_domoticzlinky.plan.md`
**Responsable Agent :** 🟢 QALvin
**Date Début :** 2026-11-25
**Date Fin :** 2026-11-25
**Statut :** ✅ COMPLÉTÉE — validation 👤 en attente (Gate #3)

---

## 📝 Tâches

### T2.1 - Vérifier les faits et les liens

**Statut :** ✅ DONE (revue en lecture seule ; aucun livrable ni code modifié par QALvin)

**Méthode :** initiative 100 % documentaire → pas de suite de tests ; revue factuelle par échantillonnage contre `plugin.py` (v2.6.1), `build-domoticz.yml`, `_docker/build_domoticz/Dockerfile`, `_docker/envs/*`, `domoticz/scripts/dzVents` ; vérification automatisée des liens (script Python local, non versionné). Les ~15 faits déjà couverts par la revue automatique (XML, proxy/endpoints, Mode3, marge 20 min, auth, 403/400/500, lots, planification, pickle/blake2s, types devices, D1-D6/D11/D12, CI/Dockerfile/compose) **ne sont pas recomptés** ci-dessous ; l'échantillon porte sur d'autres affirmations.

> ℹ️ **État des dépôts constaté pendant la revue (différent de l'énoncé « non commités »)** :
> - Fork `DomoticzLinky` : `docs/RETROCONCEPTION.md` + `readme.md` sont **commités et poussés** — commit `f3df258` (2026-11-25 10:18), `origin/master` = `f3df258` (`git ls-remote`), tag `v2.6.1` créé **pendant la revue** (10:23) sur `f3df258`. `plugin.py` est **identique** à `1ef6adf` (`git diff 1ef6adf HEAD -- plugin.py` vide) : la référence « v2.6.1 @ `1ef6adf` » reste exacte pour le code.
> - `domotique` : livrables commités en `1ae86c9` (2026-11-25 10:24, branche `feat/add_linky`, poussée) ; `origin/master` = `9de1334` (sans § 5.4).

#### Tableau des affirmations vérifiées (36)

| # | Fichier / section | Affirmation | Source (fonction / fichier) | Résultat | Commentaire |
|---|---|---|---|---|---|
| 1 | RETRO § 3 `Mode1` | Entier 0-7, défaut 7 ; erreur → 7 ; `0` désactive l'écriture horaire | `onStart()` ; `saveDataToDb()` (`iHistoryDaysForHoursView > 0`) ; XML `Mode1 default="7"` | ✅ | Bornage `<0→0`, `>7→7` exact |
| 2 | RETRO § 3 `Mode2` | 2-730, défaut 7 ; minimum relevé selon `Mode6` : cweek 7, lweek 14, cmonth 32, lmonth 63, year 366 | `onStart()` (`sConsumptionType1.endswith(...)`) | ✅ | |
| 3 | RETRO § 3 `Mode5`/`Mode6` | Mode5 = affichage principal (repli `peak_day`, fixe la durée des pics 1/7/14/32/63/366 j) ; Mode6 = secondaire (défaut `value_day`) ; variantes `lmonth`/`year` de Mode6 commentées dans le XML | `onStart()` (`sConsumptionType1 = Mode6`, `sConsumptionType2 = Mode5`, `iHistoryDaysForPeakDaysView`) ; XML `<params>` | ✅ | Correspondance Mode5↔CONS/PROD, Mode6↔U1/U2/R1/R2 confirmée par `updateDashboard()`/`updateDevice()` |
| 4 | RETRO § 3 `Port` | `Port == "1"` → HC d'abord ; inversion à l'écriture (`addToDevice`, `updateDevice`) | `onStart()` (`bOffPeakFirst = str(Parameters.get("Port","0")).strip() == "1"`) | ✅ | |
| 5 | RETRO § 3 « Effets de `Mode3` » | `>0` fichier log ; `>1` `Domoticz.Debugging(1)` ; `==3` `resetTokens()` ; `==4` `resetCache()` ; `≥10` sandbox ; 10-18 listes de 1 à 3 faux PRM ; **19 sans liste** → « Erreur à la lecture des points de livraison » | `onStart()` ; `handleConnection()` étape `start` ; `lFalseCustomer = []` (attribut de classe) | ✅ | 13 → 2 PRM, 17 → 3 PRM ; 19 : chaîne `if/elif` s'arrête à 18 |
| 6 | RETRO § 3 / § 7.5 `Mode4` (syntaxe HC) | PRM optionnel (chiffres), mot « production » = 1ᵉʳ mot commençant par `p`, jour FR/EN (`lu/mo`, `ma/tu`, `me/we`, `je/th`, `ve/fr`, `sa`, `di/su`), férié (`fe, fé, fè, jo, pu, ba, ho`), séparateurs `-_aà to`, `h`/`:` ; bornage 23/59 ; plage à cheval sur minuit scindée ; clés `dHc[PRM\|all][prod\|all][0-6\|7\|8]` | `parseHcParameter()` (regex + `startswith`) | ✅ | D14 (préfixe `p`) confirmé |
| 7 | RETRO § 7.5 test HC | Décalage −30 min ; borne `[début, fin[` ; priorité férié (clé 8) > jour > clé 7 ; PRM fusionné : 2ᵉ id en production ; jours fériés sans zone → Métropole | `isCost2()` ; `JoursFeries.is_bank_holiday(date, zone=None)` → `check_zone` (`zone or "Métropole"`) | ✅ | |
| 8 | RETRO § 7.6 agrégation 30 min → 1 h | Cumul des valeurs ≥ 0 avec `date`, stockage de `cumul / pas` quand `minute == 0` ; contrôle du `usage_point_id` ; « Données manquantes » | `exploreDataHours()`, `storeData()` | ✅ | Valeur = moyenne des points de l'heure ; commentaire « kWh par 30 min » bien signalé |
| 9 | RETRO § 7.8 calculs | Périodes `day` (veille), `cweek/lweek`, `cmonth/lmonth`, `year` ; `value_/max_/counter_/mean_` ; minuit = veille ; `peak_*` → `max_*` ; valeur < 0 → avertissement sans mise à jour | `doCalculation()`, `modifyCalculation()`, `resetDayAccumulate()`, `updateDashboard()` | ✅ | |
| 10 | RETRO § 7.9 + D3 fusion de PRM | PRM virtuel `"A / B"` pour conso-seule + prod-seule ; copie conso + superposition de la prod aux dates communes ; 2ᵉ boucle itère sur la conso (inopérante) ; `except:` nu → échec | `mergeCounters()` | ✅ | Boucle 2 : `sDate not in dData[new]` jamais vrai (copie profonde de la conso) |
| 11 | RETRO § 7.4 historique court/complet | Complet si `Mode2 > 35` et (modifié, `next_history_grab_date` atteinte ou dernière connexion + `Mode2` j dépassée) ; après succès `now + Mode2/2` j ; après échec `now + 1..7` j (µs) | `setHistoryDays()`, `savePreviousSuccessfulConnectionDate()` | ✅ | |
| 12 | RETRO § 7.7 + D4 cache | Seuil de complétude `len(h1)+len(h2) ≥ 23` ; en production `sTypeHour2 == production1_hours` → ≈ 12 h ; cache négatif sur `ADAM-ERR0069/0123` ; seul l'intervalle manquant est redemandé | `getDataHours()`, `getDataPeaks()`, `handleConnection()` | ✅ | |
| 13 | RETRO § 8 devices | Nom `Linky <PRM>`, description `Compteur Linky <PRM>`, `DeviceID` = PRM, unité libre 1-255, `Used=1` ; P1 `0xFA/0x01` + options `DisableLogAutoUpdate`/`AddDBLogEntry` ; Managed Counter `0xF3/0x21` sans options ; seuil 4.11774 | `getOrCreateDevice()`, `lType/lSubType/lOptions`, `onStart()` | ✅ | |
| 14 | RETRO § 8 `sValue` | P1 : `U1;U2;R1;R2;0;0;<date>` (log) / `U1;U2;R1;R2;CONS;PROD` (dashboard) ; Managed Counter : `-1.0;<U1+U2>;<date>` / `-1.0;<CONS+PROD>` | `addToDevice()`, `updateDevice()` (`fSecVal` = Mode5) | ✅ | |
| 15 | RETRO § 8 écriture en base | Entrées horaires cumulées (P1) / valeur d'heure (MC) ; totaux journaliers ≥ 12 h (dernier jour ≥ 1 h) ; jour courant exclu ; horaire limité à `Mode1` jours | `saveDataToDb()` | ✅ | |
| 16 | RETRO § 8 fraîcheur | Timeout = +1 j 12 h (global + par PRM) ; contrôle toutes les ≈ 50 s ; `TimedOut=1` sinon `Touch()` ; `Domoticz.Heartbeat()` jamais appelé | `setTimeout()`, `setRefreshTime()`, `onHeartbeat()` ; grep `Heartbeat(` → seulement les `def onHeartbeat` | ✅ | |
| 17 | RETRO § 10 planification/résilience | Fenêtre 8 h-22 h ; lendemain 8 h + 0-59 min (µs) ; échec → +1 h ; ≥ 5 s entre connexions ; 3 renvois ; 3 heartbeats « bloqués » puis `retry` ; `iInterval` = 5 s | `setNextConnection()`, `setNextConnectionForLater()`, `connectAndSend()`, `handleConnection()` (`retry`, `connecting/sending`), `onHeartbeat()` | ✅ | `setNextConnectionForLater()` force aussi `idle` hors fenêtre (ligne finale de la table) |
| 18 | RETRO § 10 / § 5.2 codes HTTP | 403 → `disablePlugin()` (heures **et** pics) ; 404/cache → `prod` ; 429/500 → `retry` (conso) ; prod : 400/500/`ADAM-ERR0123` = « pas de production » ; autre ≠ 200 → `prod` + `bHasAFail` ; pics : 404 silencieux (debug) | `handleConnection()` (`getdatahours`, `getdatapeakdays`) ; `showStatusError(False, Data, False, True)` | ✅ | |
| 19 | RETRO § 5.1 diagramme PlantUML | 16 états et leurs transitions (`idle → start/parseaccesstoken/parsedevicecode`, `parsedevicecode`, `parseaccesstoken` (done/pending/retry/error), `askagainaccesscode`, `start`, `nextcons`, `next`, `getdatahours`, `getdatapeakdays`, `prod`, `save`, `done`, `retry`, `connecting/sending`) ; `nothingtosend` signalé hors diagramme | `handleConnection()`, `reconnectAndResend()`, `connectAndSend()`, `onConnect()`, `onMessage()` | ✅ | Aucun état ni transition manquant ou inventé ; chaînage par `if` (non `elif`) après le premier bloc exact |
| 20 | RETRO § 5.2 table des transitions | Échantillon de 22 lignes (idle ×5, parsedevicecode ×2, parseaccesstoken ×4, askagain ×2, start ×2, nextcons, next, getdatahours ×6, getdatapeakdays ×4, prod ×2, save ×2, done, retry ×2, anti-rafale) | idem #19 | ✅ | Omission mineure (non erronée) : `nextcons` omet la propagation `bHasAFail → bGlobalHasAFail` ; `parseaccesstoken` « pending » + JSON invalide → `retry` non listé |
| 21 | RETRO § 6 enregistrement jetons | 4 champs requis (`refresh_token`, `access_token`, `token_type`, `expires_in`) sinon « Pas assez de données reçue » → `retry` ; `usage_points_id` séparé par virgules ; `interval` par défaut 5 | `parseAccessToken()` | ✅ | |
| 22 | RETRO § 9.2-9.3 clés et cache | 10 clés `Configuration` et leurs fonctions d'écriture ; `saveCache()` purge les clés hors `lUsagePointIndex` (PRM fusionnés non persistés) ; `loadCache()` « Cache incohérent » + `resetCache()` ; lecture en échec → `Domoticz.Configuration({})` ; `datetime` → `timestamp()` | `setConfigItem()`, `getConfigItemAndChecksum()`, `saveCache()`, `loadCache()`, `resetTokens()`, `resetCache()`, `onStart()` | ✅ | |
| 23 | RETRO § 9.4 + § 11 logs | Fichier `tempfile` préfixe `DomoticzLinky_AAAA_MM_JJ_HH_MM_SS_`, suffixe `.log`, `delete=False`, jamais fermé ; `flush()` seulement `onStop()`, `disablePlugin()`, échec de version ; `myDebug` → `Domoticz.Log` si `Mode3 > 1` ; préfixes `Status :`/`Erreur :`/`Debug :` ; `dumpDictToLog` 3 niveaux ; message « Log dans le fichier … » | `onStart()`, `myMessage()`, `myLog/myStatus/myError/myDebug()`, `dumpDictToLog()`, `showSimpleStepError()` | ✅ | |
| 24 | RETRO § 12 compatibilité | Minimum 4.11070 (sinon « trop ancienne », arrêt) ; ≥ 4.11774 pour P1/HP-HC, sinon Managed Counter + message ; `iVersion = maj×1 000 000 + min` ; stdlib seule ; `blake2s` testé dynamiquement ; incompatibilité Domoticz 2023.2 | `onStart()` ; imports ; `readme.md` l. 38 et 259 ; grep `4011070\|4011774` | ✅ | |
| 25 | RETRO § 13 S1/S2/S4 | `dumpDictToLog` écrit `Authorization`, `refresh_token`, réponses brutes ; `setConfigItem` journalise `str(Value)` ; `pickle.loads` **avant** comparaison du checksum | `getData()`, `refreshToken()`, `dumpDictToLog()`, `setConfigItem()`, `loadCache()` → `getConfigItemAndChecksum()` | ✅ | |
| 26 | RETRO § 14 D5/D6 | `iIndexUnit == 256` inaccessible, retour `None` sans message ; **14** `except:` nus | `getOrCreateDevice()` ; `Select-String '^\s*except\s*:'` → 14 | ✅ | « au moins 14 » exact |
| 27 | RETRO § 14 D7, D9, D10, D13, D14, D15, D16 | Monolithe sans test ; jetons non chiffrés ; proxy tiers ; Mode3=19 ; zone Métropole/préfixe `p` ; code mort (`API_ENDPOINT_DATA_DAILY_*`, `enedisDateToDatetime`, `bFirstMonths`, `dtDataInMemory`) ; fichier debug non purgé | fichier entier (2 726 lignes, 1 classe) ; dépôt sans test ni CI ; grep | ✅ | `dtDataInMemory` est écrit (l. 1506) mais jamais lu : « inutilisé » acceptable |
| 28 | RETRO § 16 glossaire | HP = compteur 1 (`U1/R1`), HC = compteur 2 (inversé si `Port=1`) ; P1 `0xFA/0x01`, Managed Counter `0xF3/0x21` ; sandbox `Mode3` 10-19 ; PRM à 14 chiffres | `addToDevice()`, `lType/lSubType`, `onStart()` | ✅ | « PRM 14 chiffres » = connaissance métier (cohérent avec les faux PRM du code), non vérifiable dans le code |
| 29 | RETRO § 1 identité | Clé `linky`, version 2.6.1, auteur `Barberousse` + copyrights 2016-2021, AGPL-3.0 (en-tête + `LICENSE`), `JoursFeries` MIT Etalab (l. 2534), `externallink` upstream, `.github/` = `FUNDING.yml` + `ISSUE_TEMPLATE.md` sans workflow | en-tête + XML `plugin.py` ; `LICENSE` ; arborescence du fork | ✅ | |
| 30 | RETRO § 1 « Commit analysé = HEAD = origin/master » et « aucun tag au-delà de 2.3.8 » | État du fork | `git rev-parse HEAD`, `git ls-remote`, `git tag` | ❌ mineur | **Obsolète** : HEAD = `origin/master` = `f3df258` (commit de la doc) ; tag `v2.6.1` → `f3df258` (créé 10:23, pendant la revue). `plugin.py` inchangé → SHA `1ef6adf` toujours valide pour le code. À reformuler en T3.1 |
| 31 | RETRO § 2.1 callbacks | « Les callbacks … (`onStart`, …, `onDisconnect`, …) délèguent **tous** à `_plugin` » | fonctions de module l. 2360-2414 | ❌ mineur | `onDeviceAdded/Modified/Removed` ne font que `global _plugin` (aucune délégation) ; `onCommand/onNotification` délèguent à des méthodes inexistantes (D1, correctement documenté) |
| 32 | ARCH § 5.4 chaîne CI → image | Jobs `download-linky`/`download-deconz`, artefacts `linky-plugin`/`deconz-plugin`, dépôts `guillaumezin/DomoticzLinky` & `Smanar/Domoticz-deCONZ`, `refs/heads/master` non épinglé ; `COPY linky/plugin.py`, `COPY deconz/*.py` ; `linux/arm/v7` (domoticz) vs `linux/arm64` (tydom) | `.github/workflows/build-domoticz.yml`, `build-tydom.yml` (`DOCKER_TARGET_PLATFORM`), `_docker/build_domoticz/Dockerfile` | ✅ | |
| 33 | ARCH § 1.2 + § 5.4 « aucun dzVents ne référence Linky » ; persistance | Aucune référence dans `Config_check.lua`/`Health_check_dzVents.lua` ; compose NAS ne monte que `domoticz.db` + `scripts/dzVents` ; deCONZ (ConBee III) défini dans `envs/pi` | `domoticz/scripts/dzVents/**` (grep `linky` insensible à la casse → 0) ; `_docker/envs/nas/domotique-compose.yml` ; `envs/pi/domotique-compose.yml` | ✅ | « stockage dans `domoticz.db` » = comportement du framework (réserve déjà posée en RETRO § 9) |
| 34 | README.md « Watchtower » + chemin de démarrage | Aucun service Watchtower dans les compose versionnés ; `cd _docker/envs/nas` (ou `envs/pi` pour deCONZ) | grep `watchtower` dans `_docker/envs/**` → 0 ; contenu des deux compose | ✅ | Le correctif Watchtower (accepté au Gate #2) est exact |
| 35 | `_docker/build_domoticz/README.md` | Plateforme CI `linux/arm/v7` ; plugins non versionnés, upstream `master` non épinglé ; `python3-dev`, `curl` ; manifests dans `_docker/envs/` et **pas** de `_docker/domotique-compose.yml` ; avertissement : monter tout `/opt/domoticz/userdata` masque `plugins/` | workflow ; Dockerfile (`COPY` → `/opt/domoticz/userdata/plugins/...`) ; arborescence `_docker/` ; exemple `docker run -v …/database:/opt/domoticz/userdata` | ✅ | Sémantique d'un bind-mount sur répertoire parent : l'avertissement est correct |
| 36 | `DomoticzLinky/readme.md` en-tête | Section « Fork vzwingma / notes techniques » (FR + phrase EN), lien relatif vers `docs/RETROCONCEPTION.md`, guide FR/EN inchangé | `git diff 1ef6adf HEAD -- readme.md` : seul le bandeau « non maintenu » (conservé comme retiré) est remplacé ; 0 ligne modifiée dans le guide | ✅ | Cosmétique : 3 lignes vides avant le titre (cf. écarts) |

**Bilan : 34 ✅ / 2 ❌ mineurs sur 36 affirmations (hors ~15 faits déjà couverts par la revue automatique).** 0 ❌ bloquant.

#### Liens

| Contrôle | Résultat |
|---|---|
| Liens relatifs des 5 livrables (RETROCONCEPTION, section en tête du readme fork, ARCHITECTURE, README, build README) | **52/52** cibles existantes (`os.path.exists`) |
| Ancres (33 liens avec `#…`) dont les 16 du sommaire + 13 renvois internes de RETROCONCEPTION, `#22-enedis-data-connect-et-proxy-dauthentification`, `#54-plugins-python-domoticz-linky-deconz` (×4 : ARCHITECTURE § 1.2, README ×2, build README) | **33/33** ancres résolues. Contrôle négatif : une ancre inexistante est bien signalée `MISSING` |
| Liens GitHub absolus propres aux livrables (4) : `vzwingma/DomoticzLinky`, `…/blob/master/docs/RETROCONCEPTION.md`, `vzwingma/domotique`, `…/blob/master/docs/ARCHITECTURE.md` (+ wiki, 3 URLs workflows/badges existants) | `curl -sL` → **HTTP 200 pour les 7 testés** |
| Réserve sur le lien `…/domotique/blob/master/docs/ARCHITECTURE.md` (readme du fork § « Usage », RETRO § 15) | URL en 200 **mais le § 5.4 n'existe pas encore sur `master`** (`raw.githubusercontent` : 0 occurrence de « 5.4 »/« Plugins Python ») : présent seulement sur la branche `feat/add_linky` → devient exact après merge. Non bloquant |

#### Sécurité / secrets

- Scan des 5 livrables (UUID, JWT `eyJ…`, `token|password|secret|api_key = valeur`, séquences de 14 chiffres, IPv4) : **aucun secret**. Les `client_id` codés en dur dans `plugin.py` ne sont **pas recopiés** dans la rétrodoc (S6 les décrit seulement) ; les « 12345678901234 » du `readme.md` sont les PRM fictifs du guide utilisateur existant (hors section modifiée). `stack.env` consulté pour les **noms** de variables uniquement (`HOST, MAC, PASSWD, PORT, AUTHAPI, PASSWDAPI`) — aucune valeur recopiée.

#### Aucune modification de code

- Fork : `git diff --stat 1ef6adf HEAD` → seulement `docs/RETROCONCEPTION.md` (+556) et `readme.md` (+5/−9) ; `plugin.py`, `LICENSE`, `assets/`, `.github/` inchangés ; `git status` propre.
- `domotique` : commit `1ae86c9` → 7 fichiers `.md` uniquement (README, build README, ARCHITECTURE, plan, 2 rapports, index) ; `git diff --cached --name-only` ne listait aucun fichier non `.md` ; workflows, Dockerfile, compose, dzVents : inchangés ; `git status` propre.

#### Écarts

| Id | Gravité | Fichier / section | Écart | Action (T3.1, DOCly) |
|---|---|---|---|---|
| E1 | **Mineur (connu)** | `_docker/build_domoticz/README.md` (note « Le volume `scripts/dzVents` est optionnel … En production, les scripts sont embarqués dans l'image (pas de volume) ») | **Confirmé.** Contradictoire avec `envs/nas/domotique-compose.yml` (monte `…/scripts/dzVents` → `generated_scripts`) et avec le nouvel avertissement du même fichier (« …et `scripts/dzVents` ») | Reformuler la note (la prod monte le volume) |
| E2 | **Mineur (connu)** | `README.md` § Déploiement rapide | **Confirmé.** « Éditer `domotique-compose.yml` et renseigner MAC, PASSWD, AUTHAPI, PASSWDAPI » : le compose NAS les lit via `env_file: stack.env` (noms présents dans `stack.env`, absents du compose) | Citer `stack.env` |
| E3 | Mineur (connu) → **à requalifier** | Liens GitHub « 404 avant push » | **Non confirmé tel quel** : 0 lien en 404, fork poussé. Résiduel : la cible « `docs/ARCHITECTURE.md` § 5.4 » n'est pas sur `master` avant merge de `feat/add_linky` | Aucune correction de texte ; vérifier après merge |
| E4 | **Mineur (nouveau)** | RETRO § 1 (lignes « Commit analysé » et « Tags ») | Obsolète (#30) : HEAD/`origin/master` = `f3df258`, tag `v2.6.1` existe | Reformuler : « code analysé = `1ef6adf` ; `plugin.py` identique à `f3df258` = tag `v2.6.1` » |
| E5 | **Mineur (nouveau)** | RETRO § 2.1 | « délèguent tous » inexact (#31) | « … délèguent à `_plugin` (sauf `onDeviceAdded/Modified/Removed`, vides) » |
| E6 | Info (nouveau) | `DomoticzLinky/readme.md` l. 1-4 ; commit `f3df258` | 3 lignes vides avant le titre ; message de commit « Refactor code structure… » ne décrit pas un commit documentaire (déjà poussé ; réécriture d'historique hors périmètre) | Supprimer les lignes vides (T3.1) ; message : à la discrétion de 👤 |
| E7 | Info (nouveau) | RETRO § 5.2 | Deux omissions non erronées (#20) | Optionnel |

**Écarts bloquants : 0.**

---

## 📊 Synthèse de Phase

**Tâches complétées :** 1/1
**Critères de réussite :**
- ✅ ≥ 15 affirmations vérifiées (36 hors faits déjà couverts), 0 écart bloquant (2 mineurs connus confirmés + 2 mineurs nouveaux + 2 infos)
- ✅ 100 % des liens relatifs vérifiés (52/52 cibles, 33/33 ancres) ; liens GitHub absolus : 7/7 en HTTP 200 (réserve § 5.4 non présent sur `master` avant merge)
- ✅ Aucun secret ; ✅ aucun fichier de code modifié (deux dépôts)

**Bloqueurs :** Aucun
**Prochaine phase :** Phase 3 (T3.1 🟣 DOCly — corriger E1, E2, E4, E5, E6 ; revérifier E3 après merge) après validation 👤 (Gate #3)
