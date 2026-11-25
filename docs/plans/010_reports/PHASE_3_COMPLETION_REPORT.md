# Phase 3 : S3 + S2 — correctifs du plugin (fork, branche `fix/v2.7.0`)

**Plan :** `docs/plans/010_linky_suites.plan.md`
**Responsable Agent :** 🟢 QALvin (T3.1) — T3.2 à T3.4 : 🔵 DEVon ; T3.5 : 🟢 QALvin
**Date Début :** 2026-11-25
**Date Fin :** TBD
**Statut :** 🔄 EN_COURS — T3.1 livrée (commit `9b0cb51`) ; T3.2 à T3.4 livrées par 🔵 DEVon (non commitées, non poussées, Gate #2 en attente) ; T3.5 à venir

---

## 📝 Tâches

### T3.1 - Poser le harnais de tests et la CI du fork (🟢 QALvin)

**Statut :** ✅ DONE (en attente de commit/push par ⚫ MAINa ; preuve CI après push)

**Fichiers créés (fork `DomoticzLinky`, branche `fix/v2.7.0` depuis `master` 91059c6) — `plugin.py` NON modifié :**
- `tests/conftest.py` — faux module `Domoticz` (`Log/Error/Status/Debug` capturés dans `domoticz.logs`, `Debugging` sans effet, `Configuration(d=None)` à état avec bascules de panne `config_fail_on_get/set`, `Connection`/`Device` = `MagicMock`) ; chargement de `plugin.py` par `importlib.util.spec_from_file_location` (module **neuf à chaque test**) ; injection `Parameters` (`Mode1`-`Mode6`, `Port`, `Name`, `Version`, `DomoticzVersion`, `DomoticzHash`, `DomoticzBuildTime`) et `Devices = {}` ; fixtures `domoticz`, `plugin_module`, `plugin` (`BasePlugin` neuf, `iDebugLevel = 2`, `fDebug = io.StringIO()`, `iAlternateAddress = 0`), `captured` (journaux + fichier de debug), `sentinels` (`TOK-ACCESS-SENTINEL`, `TOK-REFRESH-SENTINEL`, `TOK-ID-SENTINEL`, `DEVCODE-SENTINEL`, `COOKIE-SENTINEL`, `USER-CODE-SENTINEL`, `PRM-SENTINEL-0001`).
- `tests/test_callbacks.py` — D1/D1a, D2, D16.
- `tests/test_merge_counters.py` — D3.
- `tests/test_devices.py` — D5.
- `tests/test_cache.py` — D4 (caractérisation 12 h vs 11 h) + cache consommation.
- `tests/test_secrets_masking.py` — S3.
- `tests/test_persistence.py` — caractérisation clés/format de persistance (ajouté : exigé par la règle « clés/format persistance inchangés »).
- `tests/test_d12_production_500.py` — caractérisation D12 (ajouté : exigé par la règle « D12 inchangé »).
- `requirements-dev.txt` — `pytest==9.2.0`, `ruff==0.17.6`.
- `ruff.toml` — `target-version = "py311"`, `builtins = ["Parameters", "Devices"]`, `[lint] select = ["E9", "F63", "F7", "F82"]`.
- `.gitignore` — `__pycache__/`, `.pytest_cache/`, `.ruff_cache/`, `.venv/`.
- `.github/workflows/ci.yml` — déclencheurs `push` (`master`), `pull_request`, `workflow_dispatch` ; `permissions: contents: read` ; `actions/checkout@v7` ; `actions/setup-python@v7` ; Python `3.11` ; étapes `pip install -r requirements-dev.txt`, `py_compile plugin.py`, `ruff check plugin.py tests`, `pytest -q`.

**Versions épinglées / vérifiées (le 2026-11-25) :**
| Élément | Version | Vérification |
|---|---|---|
| pytest | 9.2.0 | `python -m pip index versions pytest` → `pytest (9.2.0)` (dernière stable) |
| ruff | 0.17.6 | `python -m pip index versions ruff` → `ruff (0.17.6)` (dernière stable) |
| actions/checkout | `v7` (dernière release `v7.0.1`) | `gh api repos/actions/checkout/releases/latest --jq .tag_name` → `v7.0.1` ; tag flottant `refs/tags/v7` existe |
| actions/setup-python | `v7` (dernière release `v7.1.0`) | `gh api repos/actions/setup-python/releases/latest --jq .tag_name` → `v7.1.0` ; tag flottant `refs/tags/v7` existe |
| Python local | 3.14.7 (venv `.venv`, ignoré) | `python --version` |
| Python CI | 3.11 | **non confirmé** sur le NAS (`docker compose exec domoticz python3 --version` non exécuté) |

**Résultats (preuves, commandes exécutées dans le fork avec le venv `.venv` contenant pytest 9.2.0 / ruff 0.17.6) :**
- `python -m py_compile plugin.py` : ✅ rc = 0.
- `python -m ruff check plugin.py tests` : ✅ `All checks passed!` (rc = 0).
- F821 hérités : triés. Sans `builtins` (`ruff check plugin.py --isolated --select E9,F63,F7,F82`) : 22 × F821, **tous** sur `Parameters` (l. 412, 1990, 2033, 2057-2067, 2130-2131) ou `Devices` (l. 634, 643, 650, 655, 1580, 2225) = globales injectées par Domoticz → **faux positifs**, couverts par `builtins`. Aucun bug réel ; `plugin.py` non modifié.
- `python -m pytest -q -rxX` : ✅ **`42 passed, 45 xfailed in 1.47s`** (0 XPASS, 0 échec, 0 ignoré/skip).
- `git status --short` (fork) : `?? .github/workflows/`, `?? .gitignore`, `?? requirements-dev.txt`, `?? ruff.toml`, `?? tests/` — rien d'autre ; `git diff --stat` vide (`plugin.py` inchangé) ; seul `.py` à la racine : `plugin.py`.
- Les `xfail` échouent pour la **bonne raison** (vérifié avec `--runxfail --tb=line`) : `AttributeError: 'BasePlugin' object has no attribute 'onCommand'/'onNotification'` (plugin.py l. 2387/2404), `UnboundLocalError: ... 'iVersion'` (plugin.py l. 2048), `fDebug non fermé`, `aucune erreur 'Trop de dispositifs'`, `la date de production seule 2026-01-11 est perdue…`, `assert False is True` (KeyError avalé par le `except:` nu), `aucune erreur journalisée`, `secrets présents dans les sorties : [sentinelles]`.
- **Contre-épreuve du correctif** : copie hors dépôt (dossier temporaire, supprimé) de `plugin.py` + application du code de l'annexe ARCos (D1a, D2, D3, D5, D16, S3 § 3.3) → `python -m pytest -q --runxfail` : **87 passed** (les 45 tests xfail passent **et** les 42 tests de caractérisation restent verts, dont consentement/PRM/Verb/URL en clair). Les tests sont donc valides pour DEVon.
- **Détection de régression** (mutations sur la copie corrigée, un test au moins échoue à chaque fois) : D4 seuil `< 23` → `< 22` ✅ ; D12 retrait du 500 en production ✅ ; clé `cache_checksum` renommée ✅ ; `user_code` masqué dans le consentement ✅ ; `maskSecrets` qui masque tout (PRM/messages ordinaires) ✅ ; retour à la boucle D3 fautive ✅ ; `maskValue` neutralisé ✅ (7/7 détectées).

**Liste des tests de BUG — `@pytest.mark.xfail(strict=True)` (45 cas, 21 fonctions ; à dé-xfailer en T3.5 après correctifs) :**
| Fichier / test | Bug ciblé |
|---|---|
| `test_callbacks.py::TestD1CommandNotification::test_module_onCommand_ne_leve_pas` | D1 (`AttributeError`) |
| `…::test_module_onNotification_ne_leve_pas` | D1 |
| `…::test_methode_onCommand_ne_leve_pas` | D1a |
| `…::test_methode_onNotification_ne_log_pas_le_texte` | D1a (le `Text` n'est pas journalisé) |
| `test_callbacks.py::TestD2DomoticzVersion::test_version_inconnue_arret_explicite` | D2 (`UnboundLocalError` → message « Version de Domoticz non reconnue », `isStarted` False) |
| `test_callbacks.py::TestD16DebugFile::test_onStop_ferme_et_libere_fDebug` | D16 (`close()` + `fDebug = None`) |
| `test_devices.py::TestD5Devices::test_aucune_unite_libre_retourne_none_avec_erreur` | D5 (255 unités occupées → `None` + message « Trop de dispositifs ») |
| `test_merge_counters.py::TestD3Bugs::test_dates_de_production_sans_consommation_sont_fusionnees` | D3 (mauvaise boucle) |
| `…::test_dCalculate_vide_retourne_true` | D3 (`KeyError value_year`) |
| `…::test_prm_vide_n_empeche_pas_la_fusion_des_autres` | D3 (`.get("value_year", 0)`) |
| `…::test_prm_absent_de_dData_est_ignore` | D3 (garde d'existence des deux PRM) |
| `…::test_exception_interne_est_journalisee` | D3 (`except Exception as err` + `myError` « fusion », retour `False`) |
| `test_secrets_masking.py::TestFuitesDansLesRequetes::test_getData_masque_authorization` | S3 |
| `…::test_refreshToken_masque_le_corps` | S3 |
| `…::test_getAccessToken_masque_le_device_code` | S3 |
| `…::TestFuitesDansLesReponses::test_dump_reponse_token_en_octets` | S3 |
| `…::test_dump_entetes_sensibles` | S3 (`Set-Cookie`, `AUTHORIZATION`, insensible à la casse) |
| `…::test_dump_cle_sensible_profondeur_3` | S3 |
| `…::test_dump_valeur_non_dict` | S3 |
| `…::test_handleConnection_masque_la_reponse` | S3 (réponse brute) |
| `…::TestFiltreDesMessages::test_message_libre_masque[6 gabarits × myLog/myStatus/myError/myDebug]` (24 cas) | S3 (filtre regex dans `my*()` : `refresh_token=`, JSON `"access_token"`, `Bearer`, `Basic`, `id_token=`, `device_code=`) |
| `…::test_setConfigItem_en_erreur_ne_log_pas_la_valeur` | S3 (`str(Value)` dans `setConfigItem`) |

**Tests de caractérisation — verts maintenant et après correctifs (42) :**
- `test_callbacks.py` : autres callbacks module sans effet (1) ; versions reconnues `2026.1` / `4.11774` → `iAlternateDevice == 0`, `4.11773` / `4.11070` → `1` (4) ; `4.10717` → « trop ancienne » + arrêt (1) ; D16 `onStop` → `isStarted False` (1) et journaliser après arrêt ne lève pas (1).
- `test_merge_counters.py::TestMergeNominal` (5) : fusion « A / B » créée ; production copiée aux dates communes ; sources non modifiées ; pas de fusion avec un seul PRM ; échec `saveDataToDb` → `False`.
- `test_devices.py` (4) : dispositif existant réutilisé ; première unité libre ; unité 255 atteignable ; création refusée par Domoticz → `None` + message.
- `test_cache.py` (9) : **D4** — 12 h de production suffisent (cache utilisé), 11 h non (requête `production_load_curve`), `production2_hours` ignoré ; consommation 23 h / 22 h ; HP+HC s'additionnent ; date/PRM absents → requête ; cache « aucune donnée » → pas de requête.
- `test_persistence.py` (10) : format base64(pickle) + checksum `blake2s` ; aller-retour ; défaut si clé absente ; `datetime` relu en timestamp ; `resetTokens` = 5 clés (`usage_points_id`, `token_type`, `refresh_token`, `access_token`, `expires_at`) ; `parseAccessToken` écrit ces 5 clés ; `saveCache` = `cache` + `cache_checksum` (purge des PRM hors index) ; `loadCache` aller-retour et checksum incohérent ; `onStart` écrit `history_days`.
- `test_d12_production_500.py` (2) : **D12** — 500 en production = absence de données (pas de nouvelle tentative, sauvegarde) ; 500 en consommation = `retry`.
- `test_secrets_masking.py::TestNonRegressionEnClair` (3) + `test_setConfigItem_en_erreur_journalise_la_cle` (1) : consentement (`user_code` + URL `https://enedis.domoticz.russandol.pro/device?code=…` en clair, `device_code` jamais journalisé) ; PRM et messages ordinaires inchangés ; `Verb`/`URL`/`Host` conservés dans le dump ; clé citée dans l'erreur de `setConfigItem`.

**Notes :**
- D11 hors périmètre (Gate #0) : aucun test. D4 : aucun correctif (commentaire seul, T3.3).
- Aucun vrai PRM/jeton : sentinelles uniquement (`PRM-SENTINEL-…`, `*-SENTINEL`) ; aucune sortie réelle recopiée.
- **Observation hors périmètre (non testée, non corrigée)** : dans `setConfigItem()`, si `Domoticz.Configuration()` (lecture) lève, la variable `checksum` n'est jamais affectée et `return checksum` lève `UnboundLocalError` après le `myError`. Cas non couvert par le plan ; à arbitrer par 👤/ARCos (backlog). Le test S3 `setConfigItem` fait donc échouer l'**écriture** (`config_fail_on_set`), seul scénario où le plan attend un message d'erreur sans valeur.
- Python local 3.14.7 vs CI 3.11 : aucun test n'utilise de syntaxe > 3.11, mais l'exécution sous 3.11 n'est prouvée que par la CI après push (`gh run list --repo vzwingma/DomoticzLinky --limit 1`).
- `onStart()` appelle `self.fDebug.name` quand `fDebug` est truthy : les tests `onStart` posent donc `plugin.fDebug = None` (équivalent de `Mode3 = 0`) — le flux `Mode3 ≥ 1` (vrai `NamedTemporaryFile`) n'est pas couvert (écrit dans `/tmp`).
- Pour T3.5 : retirer **tous** les `@pytest.mark.xfail(strict=True, …)` (`rg -n "xfail" tests` → 0 attendu) ; ils sont `strict`, donc un correctif livré sans retrait du marqueur fera échouer la suite (XPASS strict) — garde-fou voulu.

---

### T3.2 / T3.3 / T3.4 — Correctifs `plugin.py` (🔵 DEVon)

**Statut :** ✅ DONE (code livré, **non commité, non poussé** ; fork `DomoticzLinky`, branche `fix/v2.7.0`, base `9b0cb51`). Seul fichier modifié : `plugin.py` (+69 / −20). `tests/`, `ruff.toml`, `ci.yml`, `requirements-dev.txt`, docs : intacts. Aucun nouveau `.py`.

**T3.2 — S3 masquage (annexe § 3.3, option M1)**
- Au niveau module, après `NO_STATUS_ERROR_CODE` : `SENSITIVE_KEYS`, `MASK = "***"`, `_SECRET_PATTERNS` (3 regex : `clé=valeur` encodé URL, JSON `"clé":"valeur"`, `Bearer|Basic …`), `maskSecrets()`, `maskValue()`.
- `dumpDictToLog()` : `maskValue(<clé>, <valeur>)` aux 3 profondeurs ; branche non-dict → `maskSecrets()`.
- `myMessage/myLog/myStatus/myError` : `message = maskSecrets(message)` en 1re ligne (idempotent ; `myDebug` passe par `myMessage`).
- `setConfigItem()` en erreur : `str(Value)` remplacé par `(type <Nom>)`.
- Laissés en clair (volontaire) : `user_code` + URL de consentement, PRM.
- Preuve : `rg -n 'str\(Value\)' plugin.py` → 0 ligne.

**T3.3 — S2 correctifs**
- **D1a** : `BasePlugin.onCommand()` / `onNotification()` ajoutées après `onDisconnect()` (debug seul, `Text` non journalisé).
- **D2** : `iVersion = 0` avant `re.search` ; `else: myError("Version de Domoticz non reconnue : …")` → le test `< 4011070` arrête ensuite explicitement.
- **D3** : boucle « dates sans consommation » itère sur `dData[sUsagePointProductionId]` ; 8 accès → `.get("value_year", 0)` ; garde `if sUsagePointConsumptionId not in self.dData or sUsagePointProductionId not in self.dData: continue` (dans la branche de fusion, avant tout accès `dData`) ; `except Exception as err` → `myError("Erreur lors de la fusion des points de livraison : …")` + `bResult = False`.
- **D5** : test `== 256` supprimé de la boucle ; `showSimpleStepError("… Trop de dispositifs …")` + `return None` **après** la boucle.
- **D16** : `onStop()` → `flush()`, `close()`, `fDebug = None`.
- **D4** : commentaire explicatif seulement au-dessus de `sTypeHour2 = "production1_hours"` (comportement inchangé).
- Inchangés : D12, D11/D6/D7/D10/D13/D14/D15, `pickle`, appels `setConfigItem`/`getConfigItem` et clés de persistance (`git diff -U0 plugin.py | rg '^[+-].*(setConfigItem|getConfigItem)'` → 0). Défaut `setConfigItem`/`checksum` (`UnboundLocalError` si lecture `Configuration` échoue) : **non corrigé** (backlog).

**T3.4 — Version 2.7.0**
- Ligne 26 : `version="2.6.1"` → `"2.7.0"`. `externallink="https://github.com/vzwingma/DomoticzLinky"` **déjà présent** (commit 91059c6, métadonnées auteur conservées : `author="vzwingma"`, en-tête copyright) — non modifié.
- Preuve : `rg -n 'version="2.7.0"' plugin.py` → 1 ligne (l. 26).

**Preuves (venv `.venv`, Python 3.14.7) :**
| Commande | Résultat |
|---|---|
| `.venv\Scripts\python -m py_compile plugin.py` | rc 0 |
| `.venv\Scripts\python -m ruff check plugin.py tests` | `All checks passed!` |
| `.venv\Scripts\python -m pytest -q --runxfail` | **87 passed** |
| `.venv\Scripts\python -m pytest -q -rxX` | **42 passed, 45 failed = 45 × `XPASS(strict)`**, 0 autre échec (attendu : QALvin retire les `xfail` en T3.5) |
| `git --no-pager diff --stat` | `plugin.py | 89 ++++++++++-----` — fichier seul |
| `rg -n "[0-9]{14}" plugin.py` | 9 lignes (l. 2042-2058) = **faux PRM de debug préexistants** (`lFalseCustomer`, `Mode3` ≥ 10), non touchés ; **0** dans les lignes ajoutées (`git diff -U0 | rg '^\+.*[0-9]{14}'` → 0) |

**Notes :** hypothèse — la garde D3 est placée dans la branche de fusion (après les `.get`), si bien qu'un PRM absent de `dData` est ignoré sans journal. Python CI 3.11 : non exécuté localement (CI après push).

---

### T3.5 — Valider S2/S3 (🟢 QALvin)

**Statut :** ✅ DONE côté QA (changements **non commités, non poussés** — à committer par ⚫ MAINa ; preuve CI verte = après push). Base : `b7e939d` (correctifs, non poussé) sur `9b0cb51` (harnais, poussé). `plugin.py` **non modifié**.

**Fichiers modifiés (fork `DomoticzLinky`, `git diff --stat` : 5 fichiers, +15 / −27) :**
- `tests/test_callbacks.py`, `tests/test_devices.py`, `tests/test_merge_counters.py`, `tests/test_secrets_masking.py` : retrait des **22 décorateurs** `@pytest.mark.xfail(strict=True, …)` (= les **45 cas** : 21 fonctions simples + 1 fonction paramétrée `test_message_libre_masque` = 6 gabarits × 4 méthodes = 24 cas ; soit 22 marqueurs) et des mentions « xfail » des docstrings de module. Rien d'autre affaibli (diff filtré : seules lignes supprimées = décorateurs + 4 lignes de docstring reformulées).
- `tests/test_secrets_masking.py` : **+1 test** `test_dump_authorization_sans_schema_masque_par_la_cle` (voir mutation « Authorization » ci-dessous).
- `.github/workflows/ci.yml` (décision MAINa, 👤 a confirmé **Python 3.13.5 sur le NAS**) : job `test` passé en matrice `python-version: ["3.11", "3.13"]` (3.13 = production, 3.11 = compatibilité minimale), `fail-fast: false`, nom de job `test (Python ${{ matrix.python-version }})`, `setup-python` lit `${{ matrix.python-version }}`. `ruff.toml` **inchangé** (`target-version = "py311"`). YAML relu avec PyYAML : `strategy = {'fail-fast': False, 'matrix': {'python-version': ['3.11', '3.13']}}`.

**Preuves :**
| Commande | Résultat |
|---|---|
| `.venv\Scripts\python -m py_compile plugin.py` (3.14.7) | rc 0 |
| `.venv\Scripts\python -m ruff check plugin.py tests` | `All checks passed!` |
| `.venv\Scripts\python -m pytest -q -rxX` (3.14.7) | **88 passed**, 0 xfail / xpass / skip / échec |
| `rg -n "xfail" tests` | 0 ligne (rc 1) |
| **Python 3.11.9** (venv temporaire hors dépôt, pytest 9.2.0 / ruff 0.17.6) : `py_compile`, `ruff check`, `pytest -q -rxX` | rc 0 / `All checks passed!` / **88 passed** |
| **Python 3.13.15** (idem) : `py_compile`, `ruff check`, `pytest -q -rxX` (+ `-W error::DeprecationWarning`) | rc 0 / `All checks passed!` / **88 passed**, 0 avertissement |

Écart de comptage : 87 tests (demande) + 1 test ajouté = 88. Les venv temporaires (`%TEMP%\qal311`, `qal313`) et copies de mutation ont été supprimés. La CI GitHub (matrice 3.11 + 3.13) reste à constater après push : `gh run list --repo vzwingma/DomoticzLinky --limit 1`.

**Revue du diff `b7e939d` (`git --no-pager show b7e939d -U4`) :**
- **Persistance inchangée** : aucune ligne `+/-` ne touche un appel `setConfigItem`/`getConfigItem` ni un nom de clé ; seule la **chaîne du message d'erreur** de `setConfigItem` change (`str(Value)` → `(type <Nom>)`) ; `pickle`/base64/`blake2s`/`sha512` intacts. Les 10 tests de `test_persistence.py` (clés `usage_points_id`, `token_type`, `refresh_token`, `access_token`, `expires_at`, `cache`, `cache_checksum`, `history_days`) sont verts ; mutation « clé `cache_checksum` renommée » détectée.
- **D12 inchangé** : aucun hunk dans la gestion du 500 en production ; `test_d12_production_500.py` (2) vert.
- **Clair conservé** : `user_code` + URL de consentement + PRM + `Verb`/`URL`/`Host` toujours journalisés en clair (`TestNonRegressionEnClair`, 3 tests verts) ; `device_code` jamais journalisé.
- **Couverture du masquage** : `SENSITIVE_KEYS` = `authorization`, `access_token`, `refresh_token`, `device_code`, `id_token`, `cookie`, `set-cookie` (comparaison `casefold`, 3 profondeurs de `dumpDictToLog`) ; motifs : `clé=valeur` (URL-encodé), JSON `"clé":"valeur"`, `Bearer|Basic <jeton>`. Les 4 `my*()` filtrent le message (idempotent). `Domoticz.Log/Status/Error/Debug` appelés directement **uniquement** dans les `my*()` (l. 348-374) ; aucun `print`/`logging`. Aucune sentinelle dans les sorties capturées (tests `assert_no_leak` sur journaux + fichier de debug).
- ⚠️ **Écart vs demande : `client_secret` n'est PAS masqué** (ni clé sensible, ni motif) — vérifié : `maskSecrets("client_secret=ABC123&x=1")` et JSON `"client_secret"` inchangés. **Sans impact actuel** : `client_secret` n'apparaît **nulle part** dans `plugin.py` (`rg client_secret plugin.py` → 0 ; flux device-code avec seulement `client_id`), donc aucun chemin de fuite. Recommandation défense en profondeur (non bloquante, à arbitrer par MAINa/👤) : ajouter `client_secret` à `SENSITIVE_KEYS` et aux 2 motifs. Aucun test n'a été écrit pour ce comportement non livré (pas de test en échec).
- Observation (cosmétique) : `setConfigItem`, ligne du `myError` → `str(Key)             + "\" (type "` : espaces superflus avant `+` (valide, sans effet).
- D17 (`Domoticz.Debugging(1)`, Mode3 ≥ 2 → jetons exposés par le framework, l. 2031) et D18 (`setConfigItem`/`checksum` → `UnboundLocalError`) : **BACKLOG** (décision 👤), non testés comme bugs. D4/D11 : hors périmètre.
- **Compat Python 3.11** : aucune syntaxe 3.12+ (pas de f-string imbriquée, pas de `type X =`, pas de génériques PEP 695) ; **prouvée** par exécution réelle sous 3.11.9 (compilation + 88 tests + ruff) et 3.13.15.
- Pas de `.py` supplémentaire à la racine (`plugin.py` seul).

**Détection de régression** (mutations sur **copies temporaires hors dépôt** de `plugin.py` + `tests/`, suite complète lancée ; baseline non mutée = 88 passed) :
| Mutation | Résultat |
|---|---|
| `myMessage` sans `maskSecrets` | ✅ 6 failed |
| `myLog`/`myStatus`/`myError` sans `maskSecrets` | ✅ 18 failed |
| `setConfigItem` : retour à `str(Value)` | ✅ 1 failed |
| D3 : boucle remise sur `dData[consommation]` | ✅ 1 failed |
| D3 : `except` sans `myError` | ✅ 1 failed |
| D3 : garde d'existence des PRM neutralisée | ✅ 1 failed |
| D3 : `.get("value_year", 0)` → accès direct | ✅ 2 failed |
| `maskValue` neutralisé (`str(value)`) | ✅ 3 failed |
| motif `Bearer/Basic` retiré | ✅ 8 failed |
| motif `device_code=` retiré | ✅ 5 failed |
| motif JSON retiré | ✅ 6 failed |
| D5 : plus d'erreur « Trop de dispositifs » | ✅ 1 failed |
| D16 : `close()` retiré | ✅ 1 failed |
| D2 : message « Version … non reconnue » retiré | ✅ 1 failed |
| D1a : `onNotification` renommée | ✅ 2 failed |
| persistance : clé `cache_checksum` renommée | ✅ 2 failed |
| `user_code` masqué (non-régression du clair) | ✅ 1 failed |
| PRM sur-masqué | ✅ 2 failed |
| `Authorization` retiré de `SENSITIVE_KEYS` | ⚠️ **non détectée au 1er passage** (motif `Bearer` masquait déjà la valeur) → test ajouté (valeur sans schéma) → ✅ 1 failed |
| `dumpDictToLog` branche non-dict : `maskSecrets(...)` → `str(...)` | ℹ️ non détectée : **mutant équivalent** (`myDebug → myMessage` re-masque ; défense en profondeur redondante) — pas de test ajouté |

Bilan : 20/20 mutations non équivalentes détectées (après ajout d'1 test) ; 1 mutant équivalent documenté.

**Tests ignorés / désactivés :** aucun. **Couverture :** pas de mesure chiffrée (pas de `pytest-cov` dans `requirements-dev.txt`, non ajouté pour ne pas élargir le périmètre) ; couverture fonctionnelle = chaque correctif S3/D1a/D2/D3/D5/D16 + caractérisation persistance/D12/D4/consentement, validée par les mutations ci-dessus.

---

### T3.6 — Masquage de `client_secret` (🔵 DEVon + 🟢 QALvin)

**Statut :** ✅ DONE (changements **non commités, non poussés**, fork `DomoticzLinky`, branche `fix/v2.7.0`). Suite à l'écart relevé en T3.5 (défense en profondeur, sans fuite actuelle : `client_secret` absent de `plugin.py`).

**🔵 DEVon — diff `plugin.py` (3 lignes modifiées, +3 / −3) :** `client_secret` ajouté à `SENSITIVE_KEYS` (comparaison `casefold`, `dumpDictToLog` à 3 profondeurs) et aux 2 motifs de `_SECRET_PATTERNS` (texte `clé=valeur` et JSON `"clé":"valeur"`). Motif `Bearer|Basic` inchangé.

**🟢 QALvin — tests (`plugin.py` non modifié par QA) :**
- `tests/conftest.py` : sentinelle `CLIENT_SECRET = "CLIENT-SECRET-SENTINEL"` + attribut `sentinels.CLIENT_SECRET`.
- `tests/test_secrets_masking.py` : **+23 tests** (88 → 111) :
  - `test_client_secret_message_libre_masque` : 5 gabarits (form-urlencoded en milieu / seul / casse `CLIENT_SECRET`, JSON compact / avec espaces) × 4 méthodes (`myLog`, `myStatus`, `myError`, `myDebug`) = 20 cas ;
  - `test_client_secret_form_conserve_les_autres_parametres` : non-régression (`client_id`, `usage` restent en clair) ;
  - `test_dump_reponse_client_secret_json_en_octets` : corps JSON (octets) via `dumpDictToLog` ;
  - `test_dump_client_secret_imbrique` : clé `client_secret` (casse variable) à 3 profondeurs, valeur brute → masquage par nom de clé.

**Preuves (`.venv`, Python 3.14.7) :**
| Commande | Résultat |
|---|---|
| `python -m py_compile plugin.py` | rc 0 |
| `python -m ruff check plugin.py tests` | `All checks passed!` |
| `python -m pytest -q -rxX` | **111 passed**, 0 xfail / xpass / skip / échec |
| `git status --short` | `M plugin.py`, `M tests/conftest.py`, `M tests/test_secrets_masking.py` |

**Détection de régression** (copie temporaire hors dépôt de `plugin.py` + `tests/`, supprimée ensuite ; baseline = 111 passed) :
| Mutation | Résultat |
|---|---|
| `client_secret` retiré de `SENSITIVE_KEYS` **et** des 2 motifs | ✅ **22 failed** (tous les nouveaux tests de fuite) |
| retiré de `SENSITIVE_KEYS` seul | ✅ 1 failed (`test_dump_client_secret_imbrique`) |
| retiré des 2 motifs seuls | ✅ 21 failed |
| retiré du motif JSON seul | ✅ 9 failed |
| retiré du motif texte seul | ✅ 12 failed |

**Notes :** Python 3.11 / 3.13 et CI non réexécutés pour T3.6 (aucune syntaxe nouvelle ; CI après commit/push par ⚫ MAINa). Tests ignorés / désactivés : aucun.

---

## 📊 Synthèse de Phase

**Tâches complétées :** 5/5 côté exécution (T3.1 ✅ ; T3.2-T3.4 ✅ 🔵 DEVon ; T3.5 ✅ 🟢 QALvin — commit/push et run CI matrice 3.11 + 3.13 en attente, Gate P3-#3)
**Critères de réussite (T3.1) :**
- ✅ `python -m pytest -q` → caractérisation verts (42) + bugs en `xfail` attendus (45), 0 XPASS
- ✅ `python -m py_compile plugin.py` OK
- ✅ `python -m ruff check plugin.py tests` OK (F821 triés : 22 faux positifs `Parameters`/`Devices` → `builtins`)
- ✅ Aucun `.py` à la racine du fork autre que `plugin.py` ; `plugin.py` non modifié
- ⏳ Run CI fork vert : après commit/push par ⚫ MAINa (`gh run list --repo vzwingma/DomoticzLinky --limit 1`)

**Bloqueurs :** Aucun
**❓ Questions pour 👤 :** (1) Confirmer Python 3.11 sur le NAS (`docker compose exec domoticz python3 --version`). (2) Observation `setConfigItem`/`checksum` non initialisé : backlog ou correctif ?
**Prochaine phase :** T3.2-T3.4 (🔵 DEVon) après validation du séquencement xfail ; Phase 3 Gate P3-#2 / P3-#3 selon le plan.
