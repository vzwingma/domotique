# Phase 2 : S4 — supervision Linky dzVents (branche `feat/health_linky`)

**Plan :** `docs/plans/010_linky_suites.plan.md`
**Responsable Agent :** 🔵 DEVon (T2.1) — T2.2 : 🟢 QALvin, T2.3 : 🟣 DOCly, après gates
**Date Début :** 2026-11-25
**Date Fin :** TBD (section DEVon terminée le 2026-11-25 ; Gate P2-#2 en attente)
**Statut :** 🔄 EN_COURS — code DEVon livré, Gate P2-#2 en attente (pas de commit ni de push)

---

## 📝 Tâches

> Sections par agent : 🔵 DEVon (T2.1), 🟢 QALvin (T2.2), 🟣 DOCly (T2.3) — à compléter après gates.

### T2.1 - Implémenter l'indicateur Linky

**Statut :** ✅ DONE

**Fichiers modifiés (3, rien d'autre) :**
- `domoticz/scripts/dzVents/global_data.lua` — constante `DEVICE_LINKY_PREFIX = 'Linky'` (sans espace, après `DEVICE_STATUT_PHASE`) ; helper `helpers.getLinkyDevices(domoticz)` (après `getLevelFromState`) : `domoticz.devices().forEach` (style de `Supervision_IoT_devices.lua`), filtre `string.sub(tostring(d.name), 1, #prefix) == prefix`, retourne une table (éventuellement vide).
- `domoticz/scripts/dzVents/Health_check_dzVents.lua` — bloc **6** entre le bloc 5 (jours fériés) et `-- Résumé`, dans un `pcall` : 0 device → `warn` ; par device : `lastUpdate.minutesAgo > 36*60` → `warn` « plugin inactif » ; `elseif d.timedOut` → `warn` « aucune donnée Enedis depuis plus de 1,5 j » ; sinon `LOG_DEBUG`. `pcall` en échec → `warn('Linky inaccessible : …')` (= `LOG_ERROR` + incrément du compteur existant `nbWarnings`). Messages avec `tostring(d.idx)`, jamais le nom/ID/description du device (le PRM y figure) ; le message « 0 device » n'affiche que le préfixe constant `Linky*`.
- `domoticz/scripts/dzVents/Config_check.lua` — contrôle « 1bis » (entre sections 1 et 2) : aucun device préfixé → `PREREQUIS MANQUANT [Device] : Linky*` (`LOG_ERROR`) + `nbErrors + 1`, même format que `checkExists`. L'appel à `getLinkyDevices` est protégé par `pcall` (échec = prérequis manquant, cohérent avec `checkExists`).

**Inchangés (conformité) :** trigger `timer 'at 08:00'` / `system start`, markers `[HEALTH CHECK] ` / `[CONFIG CHECK] `, événements émis, notification existante `domoticz.helpers.notify`, format `[uuid] message`. Aucun « 5 indicateurs » dans ces scripts (le résumé dit « indicateur(s) dégradé(s) » / « tous les indicateurs ») → rien à mettre à jour ; les mentions « 5 → 6 indicateurs » sont en documentation (T2.3).

**Résultats (preuves) — contrôle statique (aucune exécution Domoticz ici ; runtime = T2.2 après synchronisation NAS) :**
- Acceptation « 3 fichiers » : ✅ `rg -n "DEVICE_LINKY_PREFIX|getLinkyDevices" domoticz/scripts/dzVents` → 3 fichiers : `Config_check.lua` (l. 96, 99), `global_data.lua` (l. 55, 215, 218, 219), `Health_check_dzVents.lua` (l. 107, 109).
- `git --no-pager diff --stat` : ✅ 3 fichiers, 52 insertions(+) : `Config_check.lua` 12, `Health_check_dzVents.lua` 24, `global_data.lua` 16 (aucune suppression).
- Aucun PRM : ✅ `git --no-pager diff | rg -n "[0-9]{14}"` → 0 résultat (exit 1).
- Syntaxe Lua : `lua` / `luac` / `luac5.x` / `luajit` **absents** du poste (`lua -v`, `luac -v` : commande non reconnue) → `luac -p` **non exécuté**. Substitut : analyseur `luaparse` 0.3.1 (npm, installé temporairement puis supprimé) en `luaVersion: 5.3` → ✅ `OK` sur les 3 fichiers. Ce n'est **pas** un `luac -p` (pas de vérification sémantique du compilateur).
- Fins de ligne : ✅ fichiers en CRLF sur toute leur longueur avant/après (global_data 428/428, Health_check 136/136, Config_check 183/183 CRLF/LF) — pas de mélange introduit.

**Notes :**
- **Écart annexe § 4.3 (voulu par le plan/Gate #1) :** préfixe `'Linky'` sans espace (device de production nommé exactement `Linky`, idx 90) ; message « aucun device » en `Linky*` au lieu de `<PRM>`.
- **Ajouts défensifs mineurs :** `tostring()` sur `d.name` (helper) et sur `d.lastUpdate.minutesAgo` (messages) ; `pcall` autour de l'appel dans Config_check.
- **Portée du filtre :** le préfixe `'Linky'` capte tout device dont le nom commence par ces 5 lettres (ex. « LinkyXYZ ») — acceptable (Q1 : aucun autre device « Linky… »).
- **Limite connue (annexe § 4.2) :** après redémarrage de Domoticz, `timedOut` reste faux ≤ 1,5 j (réarmement du délai par le plugin) ; la règle `lastUpdate` > 36 h reste valide (U1 ✅).
- Incident d'outillage : un `npm install luaparse` lancé par erreur à la racine du dépôt a créé `package.json`, `package-lock.json`, `node_modules/` ; **supprimés immédiatement** (`git status --short` → seuls les 3 fichiers Lua modifiés).

### T2.2 - Valider S4 (🟢 QALvin) — partie STATIQUE

**Statut :** ✅ DONE (revue statique + simulation) — ⏳ **runtime : en attente 👤** (copie manuelle des 3 scripts sur le NAS)

**Périmètre / méthode :** branche `feat/health_linky`, HEAD `0978ff5` (Gate P2-#2 GO). Aucun script de production modifié, aucun commit/push. Note : `git show 0978ff5 -- domoticz` est vide (0978ff5 ne touche que `docs/plans/…plan.md` : +1 ligne) ; le diff des 3 scripts est celui de `cfc638a` (= `git diff cfc638a~1 0978ff5 -- domoticz`, 3 fichiers, 52 insertions, **0 suppression**, 4 hunks purement additifs : Config_check 93, Health_check 101, global_data 54 et 214).

#### Tableau contrôle → preuve

| # | Contrôle | Résultat | Preuve (fichier:ligne / commande) |
|---|---|---|---|
| 1 | Trigger Health check inchangé (`timer 'at 08:00'`) | ✅ | `Health_check_dzVents.lua:3` ; aucun hunk du diff ne touche l. 1-10 (hunk unique en l. 101+) |
| 2 | Trigger Config_check inchangé (`system start`) | ✅ | `Config_check.lua:28` ; hunk unique l. 93+ |
| 3 | Marker inchangé | ✅ | `Health_check_dzVents.lua:6` `[HEALTH CHECK] ` ; `Config_check.lua:32` `[CONFIG CHECK] ` |
| 4 | `pcall` présent et correct | ✅ | Health : `l.106` (`local okLinky, errLinky = pcall(function() … end)`), échec → `l.121-123` `warn('Linky inaccessible : ' .. tostring(errLinky))` ; Config : `l.96` `pcall(domoticz.helpers.getLinkyDevices, domoticz)` (court-circuit `not okLinky or …` l.97 : `linkyDevices` n'est lu que si `okLinky`) |
| 5 | `tostring` sur toute valeur potentiellement nil | ✅ | `d.idx`, `d.lastUpdate.minutesAgo`, `errLinky` : `Health l.113, 115, 117, 122` ; `d.name` : `global_data.lua:222`. `d.lastUpdate` nil / `minutesAgo` nil → erreur comparaison **interceptée par le pcall** (simul. E). Le préfixe est une constante non nil. (Les blocs 2-4 préexistants concatènent `minutesAgo` sans `tostring` : hors périmètre, inchangés) |
| 6 | uuid dans les messages Health_check ; `warn` préfixe `[uuid]` + incrémente | ✅ | `warn` l.14-17 : `domoticz.log('[' .. uuid .. '] ' .. msg, LOG_ERROR)` + `nbWarnings = nbWarnings + 1` ; ligne nominale DEBUG l.117 `'[' .. uuid .. '] Linky …'`. Config_check : pas d'uuid (convention préexistante du script, inchangée) |
| 7 | Notification / résumé existant prend en compte Linky | ✅ | `nbWarnings` unique partagé (closure `warn`) → `l.128-134` : `nbWarnings == 0` → `Santé dzVents OK` ; sinon `Health check dzVents : N indicateur(s) dégradé(s)` + `domoticz.helpers.notify(msg, uuid, domoticz)` (message générique, sans nom). Simul. B/C/D/E/F : 1 anomalie ⇒ compteur = 1 ⇒ 1 notification |
| 8 | if/elseif sans double comptage | ✅ | `Health l.112-119` : `if >36h` / `elseif timedOut` / `else DEBUG` — un seul `warn` par device ; 0 device (l.108-110) = 1 `warn`, boucle vide. Simul. C : device >36 h **et** timedOut ⇒ 1 seul warn ; mutation `elseif`→`if` ⇒ test en échec |
| 9 | Branche 0 device | ✅ statique + simul. | `Health l.108-110` ; simul. B, B2 (devices à `name` nil / autre nom exclus) |
| 10 | Branche > 36 h | ✅ statique + simul. | `Health l.112-113` (`> 36*60`, strict : 2160 min = nominal, 2161 = warn — simul. C, C2) |
| 11 | Branche timedOut | ✅ statique + simul. | `Health l.114-115` (simul. D) |
| 12 | Branche nominale DEBUG | ✅ statique + simul. | `Health l.116-118` `LOG_DEBUG` : **non visible** au `logging.level = LOG_INFO` du script (l.5) ; visible seulement si niveau passé à DEBUG (cf. checklist). Simul. A |
| 13 | Échec pcall | ✅ **validé statiquement + simulation (mock)** — non reproductible en prod nominale | `Health l.121-123`, `Config l.96-97` ; simul. E (lastUpdate nil), F (`forEach` lève), K (Config) |
| 14 | `getLinkyDevices` : API dzVents correcte, `d.name` nil-safe | ✅ | `global_data.lua:218-227` : `domoticz.devices().forEach(function(d) … end)` (même idiome que `Supervision_IoT_devices.lua:42`, callback sans `return false` ⇒ itération complète) ; `string.sub(tostring(d.name), 1, #prefix)` ; retourne toujours une table ; préfixe lu via `domoticz.helpers.DEVICE_LINKY_PREFIX` (l.55, `'Linky'`, sans espace). Attributs dzVents utilisés : `idx`, `lastUpdate.minutesAgo`, `timedOut` (U2 ✅ Phase 0) |
| 15 | Config_check 1bis : `nbErrors` + message final existant | ✅ | `Config l.96-103` : `nbErrors = nbErrors + 1` (l.102) ; section 5 existante `l.170-180` : `nbErrors == 0` → `Contrôle de configuration OK — tous les prérequis sont présents.` sinon `Contrôle de configuration INCOMPLET — N prérequis manquant(s)…`. Simul. I (OK), J (0 device → INCOMPLET 1), K (pcall en échec → INCOMPLET 1) |
| 16 | Aucune fuite `d.name` / description / ID dans les logs | ✅ | `d.name` n'apparaît qu'en `global_data.lua:222` (comparaison locale, jamais loggé) ; aucune occurrence de `description`/`.id` dans le diff (`rg` → 0) ; messages = `idx` + préfixe constant `Linky*`. Simul. : nom synthétique `LinkySECRETNAME` absent de **tous** les logs/notifications (A, C, D, E, G, I) |
| 17 | `rg -n "[0-9]{14}" domoticz` → 0 | ✅ | `rg -n "[0-9]{14}" domoticz` → 0 résultat (exit 1) |
| 18 | Non-régression DEV-1/2/4/5 | ✅ | Diff 100 % additif (0 ligne supprimée) ; aucune écriture `scenePhase` (`rg "scenePhase"` dans le diff → 0 ; seule lecture préexistante Health l.22), aucun ID Tydom (`TYDOM_DEVICES` non touché), aucun `commandArray`/`emitEvent` ajouté. DEV-5 : indicateurs 1-5 et seuils (Phase 25 h, Freebox 10 min, Tydom 90 min) intacts ; indicateur 6 s'ajoute dans un `pcall` isolé (une panne Linky ne court-circuite pas le résumé — simul. E/F) |
| 19 | Format fichiers | ✅ | CRLF homogène : global_data 428/428, Health_check 136/136, Config_check 183/183 (CR/LF) |

#### Simulation (exécution du code RÉEL avec mocks)

- **Interpréteur Lua natif : absent** (`lua`, `luac`, `luajit` introuvables ; `luac -p` non exécutable). Substitut : **fengari** (Lua 5.3 en JS, Node v26.12.1), installé dans `%TEMP%\qalvin_lua_sim` (**hors dépôt**, supprimé après usage : `Test-Path` → False ; `git status --short` vide). Le harnais charge les **3 sources réelles** (`global_data.lua`, `Health_check_dzVents.lua`, `Config_check.lua`) et mocke uniquement `domoticz` (`log`, `notify`, `devices()/forEach`, `groups`, `scenes`, `variables`, `emitEvent`, `globalData`). Données **synthétiques** (aucun PRM, aucun nom réel).
- **Résultat : 30/30 assertions OK, 0 échec** (scénarios A nominal, B 0 device, B2 name nil/autre nom, C >36 h + timedOut, C2 frontière 36 h, D timedOut, E lastUpdate nil, F `forEach` lève, G 2 devices, H idx nil, I/J/K Config_check).
- **Détection de régression (mutations du code, chacune ⇒ ≥ 1 échec) :** `36*60`→`36*600000` (2 échecs) ; `elseif`→`if` (2 échecs : double comptage) ; `#linkyDevices == 0`→`== -1` dans Health (3+ échecs) ; suppression du `warn` « Linky inaccessible » (3+ échecs) ; idem condition Config_check 1bis (3+ échecs) ; préfixe `'Linky'`→`'Zinky'` (échecs dès le scénario A). Code de production rétabli par construction (mutations en mémoire uniquement ; fichiers du dépôt jamais écrits).
- **Limites explicites :** simulation ≠ runtime dzVents (le mock reproduit le contrat d'API supposé : `devices().forEach`, `lastUpdate.minutesAgo`, `timedOut`, `idx`). Les **branches dégradées** (0 device, >36 h, timedOut, échec pcall) sont validées **statiquement + par simulation mock**, **pas sur le NAS** (non provoquables sans altérer la production). Pas de couverture chiffrée (non applicable à dzVents, cf. `qa.instructions.md`). Aucun test ignoré.

#### Checklist runtime pour 👤 (après copie manuelle des 3 scripts sur le NAS) — ⏳ en attente 👤

Copier : `global_data.lua`, `Health_check_dzVents.lua`, `Config_check.lua` (dossier `scripts/dzVents` du conteneur Domoticz). Domoticz recharge les scripts modifiés automatiquement. **Ne recopier aucune sortie contenant le PRM** (nom/ID/description du device Linky) ; consigner seulement ✅/❌ + `idx`.

1. **Chargement sans erreur** (Setup › Log, ou `docker compose -f _docker/envs/pi/domotique-compose.yml logs domoticz`) : dans les logs suivant la copie, **aucune** ligne `dzVents: Error` / « Error parsing » / « attempt to … » / « syntax error » mentionnant `global_data`, `Health_check_dzVents` ou `Config_check`. (Attendu : lignes d'info `dzVents: Info: Handling events for … / script … loaded`, sans erreur.)
2. **Config_check** (trigger `system start` uniquement) : redémarrer Domoticz (ou le conteneur `domoticz`). Attendu, marker `[CONFIG CHECK] ` :
   - ✅ `[CONFIG CHECK] Contrôle de configuration OK — tous les prérequis sont présents.` (niveau INFO), **et** aucune ligne `PREREQUIS MANQUANT [Device] : Linky*`.
   - ❌ si présent : `Contrôle de configuration INCOMPLET — N prérequis manquant(s)` (+ `PREREQUIS MANQUANT [Device] : Linky*` = device préfixé introuvable ; autres lignes = prérequis préexistants, hors S4).
3. **Health check** (trigger `timer 'at 08:00'` **uniquement** — pas de customEvent, pas de déclenchement manuel prévu par le script) :
   - Attendu à 08:00 : ✅ `[HEALTH CHECK] [<uuid>] Santé dzVents OK — tous les indicateurs sont nominaux.` (INFO) ; **aucune** ligne `Linky …` en ERROR, aucune ligne `Health check dzVents : N indicateur(s) dégradé(s)`.
   - Anomalies possibles : `Linky — aucun device "Linky*" trouvé` · `Linky (idx N) — plugin inactif depuis X min (seuil 36h)` · `Linky (idx N) — aucune donnée Enedis depuis plus de 1,5 j (TimedOut)` · `Linky inaccessible : …` (suivies de `Health check dzVents : N indicateur(s) dégradé(s) — consulter les logs.` + notification).
   - **Sans attendre 08:00 :** le script ne le permet pas (aucun customEvent/bouton). Option 👤, **modification temporaire côté NAS uniquement** : dans la copie NAS de `Health_check_dzVents.lua`, remplacer `timer = { 'at 08:00' }` par `timer = { 'every minute' }` (et, pour voir la ligne DEBUG nominale `[<uuid>] Linky (idx 90) — OK (N min)`, `logging.level` → `domoticz.LOG_DEBUG`), constater un cycle, puis **rétablir** (`'at 08:00'`, `LOG_INFO`) — ne pas recopier cette version temporaire dans le dépôt. Sinon, attendre le 08:00 suivant.
4. **Attendu nominal prod** (U1/U2 Phase 0) : device `Linky` (idx 90) `lastUpdate` < 1 min (Touch ~50 s), `HaveTimeout=false` ⇒ branche nominale ; aucune notification Signal.
5. **Consigner** dans ce rapport : date/heure, ✅/❌ pour 1, 2, 3, `idx` seul, aucune sortie brute.

**Statut runtime : ⏳ en attente 👤** (critères plan « Chargement sans erreur », « Contrôle de configuration OK », « Santé dzVents OK au 08:00 suivant »).

### T2.3 - Documenter S4 (🟣 DOCly)

**Statut :** ✅ DONE (Gate P2-#3 GO ; mises à jour ciblées, aucun commit/push)

**Source de vérité :** code `global_data.lua` (`DEVICE_LINKY_PREFIX = 'Linky'`, `getLinkyDevices`), `Health_check_dzVents.lua` (bloc 6, l. 103-123), `Config_check.lua` (contrôle 1bis). Comportement documenté : aucun device préfixé → anomalie ; `lastUpdate` > 36 h → « plugin inactif » ; sinon `timedOut` (plugin : aucune donnée Enedis > 1,5 j) → anomalie ; sinon OK ; messages avec `idx` uniquement ; erreur interne → « Linky inaccessible » ; limite post-redémarrage (`timedOut` faux ≤ 1,5 j, couverte par la règle 36 h).

**Fichiers de doc modifiés (5) :**

| Fichier | Changement |
|---|---|
| `domoticz/README.md` | Section `Config_check.lua` : puce contrôle par préfixe `Linky*` ; « 5 → 6 indicateurs » (intro de liste **et** ligne du tableau d'inventaire) ; nouveau point 6 (règles, `idx` seul, « Linky inaccessible », limite) ; ligne `Config_check.lua` du tableau complétée |
| `docs/ARCHITECTURE.md` | § 5.4 : retrait de « aucun script dzVents ne les référence (ni `Config_check.lua` ni `Health_check_dzVents.lua`) » (remplacé : Linky supervisé, deCONZ non) et réécriture du point « Supervision » (plus de « aucune vérification ») ; § 6.1 : contrôle 1bis par préfixe ; § 6.2 : « 5 → 6 indicateurs », ligne 6 du tableau, note `idx`/limite 36 h |
| `docs/RETROCONCEPTION_dzVents.md` | « quatre » (déjà faux) → « six » ; ajout des points 5 (jours fériés, qui manquait) et 6 (Linky) ; puce Config_check par préfixe ; tableau d'inventaire (Config_check + Health_check, 6 indicateurs) ; tableau « lot DEV-5 » : seuil Freebox corrigé 5 → 10 min (écart préexistant) + indicateurs jours fériés et Linky |
| `.github/copilot-instructions.md` | § DEV-5 : « 5 → 6 indicateurs », ligne Linky (seuil 36 h puis `timedOut`, `idx` uniquement), rappel prérequis `Linky*` de `Config_check.lua` |
| `.github/instructions/qa.instructions.md` | Ligne « Polling » : seuil Linky (`lastUpdate` < 36 h puis `timedOut` faux) ajouté aux seuils Health check |

(5 fichiers de doc + ce rapport.) Non touchés : fork `DomoticzLinky` (T4.1), scripts Lua, `PHASE_3_COMPLETION_REPORT.md`, `docs/plans/README.md` (aucun changement de statut global de plan).

**Vérifications :**
- `rg -n "5 indicateurs|cinq indicateurs|quatre indicateurs" README.md docs domoticz .github` : **0 occurrence dans la documentation vivante**. Restent (historique, non modifiés) : `docs/plans/010_linky_suites.plan.md` l. 50 (état initial) et l. 232-233 (énoncé T2.3), `docs/plans/010_reports/ANALYSE_ARCOS.md` l. 474-479, ce rapport (l. 24), et **`.github/tasks/todo/INSTRUCTIONS_TRAVAUX_dzVents.md` l. 154** (« quatre indicateurs », ordre de travaux historique du lot DEV-5 — **hors périmètre T2.3, laissé en l'état ; à trancher par MAINa**).
- Aucun nombre à 14 chiffres ajouté (`rg "[0-9]{14}"` sur les 5 fichiers modifiés : 0 ; les seuls résultats globaux sont préexistants : SVG, plans 007/009).
- Liens : seuls ajouts = ancres internes `#6-supervision-et-observabilité` et `#62-health_check_dzventslua-quotidien-0800` (titres § 6 et § 6.2 existants de `docs/ARCHITECTURE.md`) ; aucun nouveau lien externe/relatif.
- Aucun exemple de code ajouté ; aucune valeur de PRM/nom de device réel dans la doc (préfixe constant `Linky*` uniquement).
- Reste hors périmètre (T4.1) : rétrodoc du fork § 15 (« supervision » → livré).

---

## 📊 Synthèse de Phase (section DEVon)

**Tâches complétées :** 1/1 (T2.1 — périmètre DEVon). T2.2 (QALvin) et T2.3 (DOCly) non démarrées.
**Critères de réussite :**
- ✅ 3 fichiers Lua modifiés, 0 PRM dans le diff (preuves statiques ci-dessus).
- ⏳ Chargement sans erreur, `Contrôle de configuration OK`, `Santé dzVents OK` à 08:00 : runtime différé (T2.2, après synchronisation NAS — Q4) ; `luac -p` non disponible (analyse `luaparse` seulement).
- ✅ Documentation « 6 indicateurs » : T2.3 (DOCly) livrée (5 fichiers de doc, cf. section T2.3).

**Synthèse 🟢 QALvin (T2.2 — statique) :** 19/19 contrôles ✅ ; simulation 30/30 assertions + 6 mutations détectées ; `rg "[0-9]{14}" domoticz` → 0 ; aucun script de prod modifié. **Runtime : ⏳ en attente 👤** (chargement sans erreur, `Contrôle de configuration OK`, `Santé dzVents OK` à 08:00) — checklist ci-dessus. Phase 2 non clôturable avant retour 👤 sur le runtime.

**Bloqueurs :** Aucun
**❓ Questions pour 👤 :** Aucune bloquante.
**Prochaine phase :** Gate P2-#2 (MAINa) puis 🟢 QALvin T2.2 ; 🟣 DOCly T2.3 après Gate P2-#3.
