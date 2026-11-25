# Phase 4 : Documentation et publication du fork (`DomoticzLinky`, branche `fix/v2.7.0`)

**Plan :** `docs/plans/010_linky_suites.plan.md`
**Responsable Agent :** 🟣 DOCly (T4.1) — T4.2 : 👤
**Date Début :** 2026-11-25
**Date Fin :** TBD (T4.1 livrée le 2026-11-25 ; Gate P4-#4, merge de la PR fork et tag `v2.7.0` en attente)
**Statut :** 🔄 EN_COURS — T4.1 livrée (documentation du fork modifiée, **non commitée, non poussée**) ; T4.2 (tag + release, 👤) à venir

---

## 📝 Tâches

### T4.1 - Mettre à jour la documentation du fork (🟣 DOCly)

**Statut :** ✅ DONE (fichiers du fork modifiés dans le clone `DomoticzLinky`, branche `fix/v2.7.0` ; aucun commit, aucun push ; `plugin.py`, `tests/`, `.github/workflows` non touchés)

**Source de vérité :** `plugin.py` v2.7.0 du fork (bloc XML `<params>`, `onStart()`, `onStop()`, `SENSITIVE_KEYS` / `_SECRET_PATTERNS` / `maskSecrets()` / `maskValue()`, `myMessage()` et dérivés), `.github/workflows/ci.yml`, `tests/`, rapports PHASE_1/2/3, ADR 007, journal des gates (P3-#2, P3-#3).

**Fichiers du fork créés / modifiés (3) :**

| Fichier | Changement |
|---|---|
| `docs/RETROCONCEPTION.md` | **En-tête** : titre « v2.6.1, annotée v2.7.0 », périmètre (sections portant l'état v2.7.0 : 1, 3, 9.4, 11, 12, 13, 14, 15), version courante. **§ 1** : version `2.7.0` (analyse initiale `2.6.1` @ `1ef6adf` conservée), auteur (`vzwingma` / `Barberousse` en 2.6.1), `externallink`, tag `v2.7.0` (posé après merge, T4.2) ; avertissement « Upstream non épinglé » **remplacé** par « Provenance épinglée » (SHA + tag, Renovate sans automerge, ADR 007, pin initial `v2.6.1` / `f3df258`) ; liste des fichiers du dépôt (`tests/`, `CHANGELOG.md`, `requirements-dev.txt`, `ruff.toml`, `ci.yml` ; plus de mention « aucun workflow CI »). **§ 3** : ligne `Mode3` = 2 renvoyant à D17. **§ 9.4** : fichier de debug fermé par `onStop()` (D16), jamais supprimé, aucun `chmod` dans `plugin.py` (droits `tempfile`). **§ 11** : « jamais fermé » corrigé ; nouvelle sous-section **« Masquage des secrets (v2.7.0) »** (clés sensibles, motifs, fonctions couvertes, éléments laissés en clair, hors périmètre = framework). **§ 12** : Python CI 3.11 + 3.13, production NAS 3.13.5. **§ 13** : colonne **Statut** (S1/S2 « Corrigé v2.7.0 », S3/S4 « Accepté », S5 « Accepté », S7 « Partiellement corrigé », S8 « Accepté ») + nouvelle ligne **S9 / D17** (risque connu, backlog) ; mention « non protégé » **corrigée** (cf. note 1). **§ 14** : colonne **Statut** D1-D16 + **D17** et **D18** (backlog) + ligne « Backlog résiduel ». **§ 15** : provenance épinglée ; supervision Linky livrée (6ᵉ indicateur du health check : 0 device / `lastUpdate` > 36 h / `timedOut` ; `Config_check` : prérequis `Linky*` ; `idx` seul dans les messages ; limite après redémarrage). |
| `CHANGELOG.md` (nouveau) | Format Keep a Changelog ; entrée **[2.7.0] - 2026-11-25** : Sécurité (masquage M1, `setConfigItem`, laissés en clair, limite D17) / Corrigé (D1a, D2, D3, D5, D16) / Ajouté (tests, CI 3.11 + 3.13, `requirements-dev.txt`, `ruff.toml`, doc) / Modifié (version, `externallink`, D4 commentaire, inchangés : persistance, D12). Entrée **[2.6.1]** de référence (sans date, non reconstituée). |
| `readme.md` | **Section fork** (haut du fichier) : usage (CI `domotique` sur le fork épinglé, ADR 007), notes techniques, lien `CHANGELOG.md`, puce **Tests et CI** (`tests/`, `ruff.toml`, `ci.yml` Python 3.11 + 3.13, commandes locales) ; ligne EN actualisée. **Nouvelle section « Paramètres du plugin »** (avant « Dépannage ») : tableau `Mode1`-`Mode6` + `Port` (nom technique, libellé affiché lu dans le XML de `plugin.py`, rôle, valeurs, défaut), tableau « Effets du paramètre Debug (`Mode3`) » (Non / Simple / Avancé / Reset consentement / Reset cache / Faux clients), avertissement **« Debug = fichiers `/tmp` »**, avertissement **D17** (debug avancé = debug complet du framework Domoticz, jetons potentiellement en clair dans le log Domoticz ; ponctuellement, puis purger le log) avec renvoi vers `docs/RETROCONCEPTION.md` § 3 et § 13. Reste du guide **inchangé**. |

**Décisions de documentation (écarts / choix explicites) :**
1. **Fichier de debug — état exact** (S7, § 9.4) : le code utilise `tempfile.NamedTemporaryFile(mode='w+t', delete=False, prefix=…, suffix=".log")` ; ce **n'est pas `mkstemp()` direct** et il n'y a **aucun `chmod`** dans `plugin.py`. La doc ne dit donc **pas** « 0600 via mkstemp » (formule du plan) mais : droits par défaut de `tempfile` (mêmes règles que `mkstemp()` selon la documentation Python : utilisateur créateur seul), **non vérifié sur le NAS** ; fermé par `onStop()` (D16) ; jamais supprimé ; contenu masqué. La mention « non protégé » est supprimée.
2. **D17 / D18** : D17 documenté dans § 3, § 11, § 13 (S9), § 14 et dans le readme utilisateur ; D18 uniquement en § 14 (backlog). La nature exacte de la fuite du framework (`Bearer`, `refresh_token`, réponse de jetons) est rapportée **d'après la revue de code P3-#2** et **non reproduite à l'exécution** : la doc l'indique.
3. **Tag `v2.7.0`** : formulé « posé après merge (T4.2) » car le tag n'existe pas à la rédaction.
4. **`client_secret`** : masqué (T3.6, vérifié dans `plugin.py` : `SENSITIVE_KEYS` et 2 motifs) ; la doc précise qu'il n'apparaît nulle part dans le plugin (défense en profondeur).
5. **Guide EN** : la section « Paramètres du plugin » est rédigée en **français seulement** (langue du projet) ; la note EN de la section fork la signale. Pas de traduction du guide.
6. Aucun PRM, jeton ni faux PRM de debug du code recopié.

**Vérifications (preuves) :**
- `rg`-équivalent (outil `grep`) `Upstream non épinglé|non épinglé` sur `docs/RETROCONCEPTION.md`, `readme.md`, `CHANGELOG.md` → **0** occurrence.
- `[0-9]{14}` sur les 3 fichiers : **0 ajout** ; seules occurrences = exemples de syntaxe HC **préexistants** du guide (`12345678901234`, `88888888888888`, l. 142-159 et 392-409 du readme, non modifiés) ; aucune dans `RETROCONCEPTION.md` ni `CHANGELOG.md`.
- Liens **relatifs** existants dans le fork : `../CHANGELOG.md`, `../readme.md`, `docs/RETROCONCEPTION.md`, `CHANGELOG.md`, `.github/workflows/ci.yml`, ancres internes (`#11-journalisation-et-debug`, `#13-sécurité`, `#10-planification-et-résilience`, `#15-intégration-dans-le-projet-domotique`, `#3-paramètres-du-plugin`, `#paramètres-du-plugin`, `#nombre-de-jours-à-récupérer`, `#heures-creuses`, `#affichage`, `#ordre-des-index`, `#obtention-du-consentement`) → sections correspondantes présentes (vérification **par lecture**, pas de vérificateur de liens exécuté).
- Liens **externes** : ADR 007 et `docs/ARCHITECTURE.md` du dépôt `domotique` (URL `blob/master`) — non résolus par requête réseau (outil indisponible) ; à confirmer par 👤/MAINa après merge de la PR contenant l'ADR (le journal indique PR #233 mergée).
- Cohérence avec le code : paramètres, libellés, bornes, défauts et effets de `Mode3` relus dans `plugin.py` (XML + `onStart()`) ; `onStop()` (`flush`/`close`/`fDebug = None`), `maskSecrets()`/`SENSITIVE_KEYS` relus ; `plugin.py` fait 2 776 lignes (utilisé en § 1 et D7).
- Fins de ligne : `RETROCONCEPTION.md` et `readme.md` restent homogènes **CRLF** (578/578 et 485/485 lignes) ; `CHANGELOG.md` créé en LF (normalisé par git).
- Périmètre : seuls 3 fichiers du fork touchés (`docs/RETROCONCEPTION.md`, `readme.md`, `CHANGELOG.md`). **`git --no-pager diff --stat` non exécuté** (aucun shell disponible pour cet agent) : à lancer par MAINa — attendu : `docs/RETROCONCEPTION.md`, `readme.md` modifiés ; `CHANGELOG.md` non suivi ; **aucun** `plugin.py`, `tests/`, `.github/`.

**Notes :**
- Les numéros de ligne et noms de fonctions de la colonne « Preuve » du § 14 restent ceux de `1ef6adf` (analyse initiale), comme indiqué dans le texte introductif.
- Après publication du tag `v2.7.0` et montée du pin (T5.1), la formulation « montée vers `v2.7.0` après publication du tag » (§ 1, § 15) devra être passée au présent : **à traiter par DOCly en T5.4** (avec `docs/ARCHITECTURE.md` § 5.4).
- Les statuts de la colonne § 13/§ 14 suivent le journal des gates (P3-#2, P3-#3) et la section « 🔭 Suites » du plan.

---

## 📊 Synthèse de Phase

**Tâches complétées :** 1/2 (T4.1 ✅ 🟣 DOCly ; T4.2 ⏳ 👤)
**Critères de réussite (T4.1) :**
- ✅ Rétrodoc (§ 1, 11, 13, 14, 15), `CHANGELOG.md` et readme du fork à jour
- ✅ Aucune affirmation contraire au code (relecture `plugin.py`) ; fichier de debug décrit tel que codé
- ✅ Section « Paramètres du plugin » + avertissements « debug = `/tmp` » et D17
- ⏳ Liens relatifs : valides par lecture ; PR fork à merger par 👤
- ⏳ Tag `v2.7.0` publié sur le commit de merge (T4.2, 👤)

**Bloqueurs :** Aucun
**❓ Questions pour 👤 :** (1) Confirmer que la formulation sur les droits du fichier de debug (droits `tempfile`, non vérifiés sur le NAS) vous convient, ou vérifier `ls -l /tmp/DomoticzLinky_*.log` dans le conteneur après un test `Mode3` = 1. (2) Une traduction EN de la section « Paramètres du plugin » est-elle souhaitée ?
**Prochaine phase :** Gate P4-#4 → commit/push/PR fork par ⚫ MAINa puis merge par 👤 ; T4.2 (tag `v2.7.0` + release) ; Phase 5 (T5.1 pin v2.7.0).
