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

---

## 📊 Synthèse de Phase (section DEVon)

**Tâches complétées :** 1/1 (T2.1 — périmètre DEVon). T2.2 (QALvin) et T2.3 (DOCly) non démarrées.
**Critères de réussite :**
- ✅ 3 fichiers Lua modifiés, 0 PRM dans le diff (preuves statiques ci-dessus).
- ⏳ Chargement sans erreur, `Contrôle de configuration OK`, `Santé dzVents OK` à 08:00 : runtime différé (T2.2, après synchronisation NAS — Q4) ; `luac -p` non disponible (analyse `luaparse` seulement).
- ⏳ Documentation « 6 indicateurs » : T2.3 (DOCly) après Gate P2-#3.

**Bloqueurs :** Aucun
**❓ Questions pour 👤 :** Aucune bloquante.
**Prochaine phase :** Gate P2-#2 (MAINa) puis 🟢 QALvin T2.2 ; 🟣 DOCly T2.3 après Gate P2-#3.
