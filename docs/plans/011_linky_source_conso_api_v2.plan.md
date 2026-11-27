# Plan d'Action 011 — Plugin Linky : source de données Conso API (Enedis Mesure synchrone V2)

**Document :** `docs/plans/011_linky_source_conso_api_v2.plan.md`
**Date de création :** 2026-11-25
**Statut :** 🟢 Phase 2 (tests) — Gate #2 ✅ GO ; Gate #0 ✅ GO ; Gate #1 ✅ GO (2026-11-27)
**Objectif Prioritaire :** HIGH (plus aucune donnée Linky depuis le 24/11/2026)
**ADR associé :** [`docs/adr/008-source-donnees-linky-conso-api-v2.md`](../adr/008-source-donnees-linky-conso-api-v2.md) — `Proposée` → `Acceptée` au Gate #1
**Issues :** vzwingma/DomoticzLinky#1 · upstream guillaumezin/DomoticzLinky#258 (API V2) et guillaumezin/DomoticzLinky#259 (502/500)
**Plans précédents :** [009](./009_retrodoc_domoticzlinky.plan.md) (rétroconception), [010](./010_linky_suites.plan.md) (provenance épinglée, tests pytest, v2.7.0)

---

## 🧭 Démarrage en nouvelle session (à lire en premier)

1. Lire : ce plan ; l'ADR 008 ; `DomoticzLinky/docs/RETROCONCEPTION.md` (§ 2.2, 5, 6, 7, 13) ; `docs/ARCHITECTURE.md` § 5.4 ; ADR 007.
2. Revérifier l'état initial ci-dessous ; noter tout écart dans le journal des gates.
3. Dérouler les phases dans l'ordre ; chaque gate suit `.github/skills/gate-protocol/SKILL.md`. Rapports : `docs/plans/011_reports/PHASE_<N>_COMPLETION_REPORT.md`.

---

## 🎯 Objectif Global

Le plugin Linky ne récupère plus aucune donnée : le proxy Russandol renvoie HTTP 500 sur toute route qui touche sa base (diagnostic du 2026-11-25), et l'API Enedis Metering Data v5 qu'il relaie est en fin de vie (remplacée le 28/09/2026 par l'API Mesure synchrone V2).

Résultat attendu : le plugin `DomoticzLinky` v3.0.0 alimente chaque jour les devices `Linky <PRM>` existants (historique conservé) à partir de **Conso API** (`conso.boris.sh`, API V2, jeton personnel), le proxy Russandol restant sélectionnable en repli.

### Solution retenue (Gate #0)

**Option B — Conso API comme source principale**, derrière une couche source sélectionnable ; **Russandol (v5) conservé en repli** jusqu'à la coupure v5. Lecture locale TIC (ZLinky) écartée pour l'instant (matériel payant). Raison : seule voie couvrant courbe de charge + puissance max sans contrat ni matériel, déjà migrée V2.

Décisions 👤 associées :

| # | Décision |
|---|---|
| Q1 | Dépendance à Conso API acceptée |
| Q2 | Module ZLinky_TIC écarté pour l'instant (pas d'achat) |
| Q3 | Pas de production solaire → aucune requête production en mode Conso API |
| Q4 | Pas de rattrapage d'historique ; un trou de données est accepté |
| Q5 | Consentement Conso API fait par 👤 ; échantillons V2 analysés ensemble en Phase 0 |
| Q6 | Russandol conservé en repli |

### Hors périmètre (backlog)

- Message clair pour les réponses 5xx HTML du proxy Russandol (aujourd'hui la page HTML est recopiée dans le log).
- Retrait du code Russandol / v5 : quand la coupure v5 sera constatée (futur plan). *Le bac à sable `opensrcdev` et les « Faux client » de `Mode3` ont été retirés dès la revue du Gate #2 (demande 👤 du 2026-11-27).*
- Lecture TIC locale (ZLinky + deCONZ) ; production ; alimentation de la vue « jours » par `consommation_quotidienne`.

---

## 🌍 Contexte

### Dépôts

| Dépôt | Chemin local | Rôle dans ce plan |
|---|---|---|
| `DomoticzLinky` | `C:\Users\vzwingma\IdeaProjects\domotique-workspace\DomoticzLinky` | Code, tests, readme, rétroconception, CHANGELOG. ⚠️ `gh pr create --repo vzwingma/DomoticzLinky` (sinon cible l'upstream) |
| `domotique` | `C:\Users\vzwingma\IdeaProjects\domotique-workspace\domotique` | Plan, ADR, `docs/ARCHITECTURE.md` § 5.4, épinglage du plugin dans `.github/workflows/build-domoticz.yml` (ADR 007) |

### État initial (2026-11-25) — à revérifier

| Élément | Valeur | Vérification |
|---|---|---|
| Fork | `master` = `a7b2320` (v2.7.0), arbre propre | `git -C <fork> log --oneline -1` |
| Épinglage `domotique` | `build-domoticz.yml` l. 30 : `ref: a7b232042a0ac725390583416043e327882510d5 # v2.7.0` | `Select-String build-domoticz.yml -Pattern 'ref:'` |
| Tests fork | pytest + stub `Domoticz` (`tests/conftest.py`), `ruff.toml`, CI `.github/workflows/ci.yml` | `python -m pytest -q` |
| Proxy prod | `/device/code` et `/device/token` → 500 ; routes sans base → 400 ; sandbox → 200 | curl (voir rapport Phase 0) |
| Health check | indicateur 6 « Plugin Linky » (`timedOut` + `lastUpdate` > 36 h) | `Health_check_dzVents.lua` l. 102 |
| Paramètres libres du matériel | `Address`, `Username`, `Password` (`Port` = ordre des index, `Mode1`-`Mode6` utilisés) | en-tête XML de `plugin.py` |

### Points d'ancrage dans `plugin.py` (v2.7.0)

Constantes d'adresses l. 137-160 · `SENSITIVE_KEYS`/masquage l. 166-183 · `getDeviceCode()` ~l. 443 · `refreshToken()` l. 550 · `getData()` l. 632 · `exploreDataHours()` l. 1156 · `exploreDataPeaks()` l. 1296 · `getDataHours()` l. 1642 · `getDataPeaks()` l. 1685 · `handleConnection()` ~l. 1721 · sélection sandbox (`iAlternateAddress`) l. 2040-2060.

---

## 🛠️ Phases

### Phase 0 — Investigation du contrat Conso API V2 (👤 + ⚫ MAINa / 🟠 ARCos) — ✅ Terminée — [rapport](./011_reports/PHASE_0_CONTRAT_CONSO_API_V2.md)

**Contexte :** le format V2 est « totalement différent » de v5 et non documenté dans le dépôt. Travail conjoint avec 👤 ; **aucun jeton ni PRM réel dans le dépôt ni dans les rapports**. Se termine **avant** Gate #1 : le plan est ajusté selon le contrat constaté.

**Critères de réussite :**
- ✅ Contrat V2 documenté pour `courbe_de_charge_consommation` et `puissance_conso_max_quotidienne` (+ `consommation_quotidienne` pour comparaison)
- ✅ Échantillons anonymisés (PRM masqué) prêts à servir de fixtures en Phase 2

#### T0.1 - Obtenir le consentement et le jeton Conso API
- **Agent :** 👤
- **Fichier(s) :** aucun (jeton conservé hors dépôt)
- **Couvrir :** consentement sur conso.boris.sh, jeton reçu, PRM confirmé ; vérifier la révocation possible dans l'espace Enedis.
- **Acceptation :** un appel `curl` authentifié renvoie 200 (exécuté par 👤 ou avec 👤, jeton jamais affiché dans la session).

#### T0.2 - Capturer et analyser les réponses V2
- **Agent :** 👤 + ⚫ MAINa / 🟠 ARCos
- **Fichier(s) :** `docs/plans/011_reports/PHASE_0_CONTRAT_CONSO_API_V2.md`
- **Couvrir :**
  - réponses 200 des 3 types sur une même période (2 à 7 jours), PRM remplacé par `00000000000000` ;
  - horodatage début ou fin d'intervalle, fuseau, pas (30 min ?), unité (W, Wh, kW ?), champ portant le PRM ;
  - période maximale par requête, borne `dateFin` exclusive ;
  - réponses d'erreur : 400 (période invalide), 401 (jeton invalide), 404/autre ; format JSON d'erreur ;
  - en-têtes de quota éventuels ; durée de vie du jeton si indiquée ; `User-Agent` attendu.
- **Acceptation :** chaque point ci-dessus a une réponse constatée ou explicitement « non déterminé » ; correspondance V2 → forme interne (`interval_reading[{date, value}]`) écrite.

#### T0.3 - Ajuster le plan
- **Agent :** ⚫ MAINa
- **Fichier(s) :** ce plan
- **Acceptation :** tâches T1.x / T2.x mises à jour selon T0.2 ; écarts notés au journal avant Gate #1.

**→ Gate #1** (plan ajusté + ADR 008 `Proposée` + rapport Phase 0)

---

### Phase 1 — Implémentation dans le fork (🔵 DEVon) — ✅ Terminée — [rapport](./011_reports/PHASE_1_COMPLETION_REPORT.md)

**Contexte :** branche `feat/consoapi-v2` du fork. Changements limités à `plugin.py`. Le comportement Russandol doit rester identique (tests existants verts sans modification).

**Critères de réussite :**
- ✅ `python -m py_compile plugin.py`, `python -m ruff check plugin.py tests`, `python -m pytest -q` verts
- ✅ Chemin Russandol inchangé (tests existants verts sans modification)

#### T1.1 - Ajouter le sélecteur de source et les paramètres
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `DomoticzLinky/plugin.py` (en-tête XML, `onStart()`)
- **Implémenter :**
  - `Address` = liste « Source des données » : `consoapi` (défaut) / `russandol` ;
  - `Password` (`password="true"`) = jeton Conso API ; `Username` = PRM(s) de 14 chiffres séparés par des virgules (format `pointId` confirmé en T0.2) ;
  - ~~mode sandbox `Mode3` ≥ 10 inchangé~~ → bac à sable et faux clients **retirés** (revue Gate #2) ; libellés `Mode3` 3/4 clarifiés ;
  - `consoapi` sans jeton ou sans PRM → erreur claire au démarrage, aucune requête.
- **Acceptation :** les 3 combinaisons (consoapi complet, consoapi incomplet, russandol) se comportent comme décrit.

#### T1.2 - Implémenter la source Conso API
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `DomoticzLinky/plugin.py` (constantes, `getData()`, `handleConnection()` étapes `idle`/`start`/`getdatahours`/`getdatapeakdays`/`prod`)
- **Implémenter :**
  - hôte `conso.boris.sh:443`, chemin `/api/<type>`, paramètres `pointId`, `dateDebut`, `dateFin` ;
  - en-têtes `Authorization: Bearer <jeton>` et `User-Agent: DomoticzLinkyPlugin/<version> (+https://github.com/vzwingma/DomoticzLinky)` ;
  - étape `idle` : `start` direct (pas de Device Flow, pas de `refreshToken`) ; PRM issus de `Username` ;
  - aucune requête production en mode Conso API (`prod` → `save`) ;
  - codes : 401 → erreur « jeton Conso API invalide ou expiré », pas de nouvelle tentative avant le lendemain ; 400 → erreur sans retry, message = `error.error_description` (code `ADAM-*`) sinon `message` ; 404 → pas de données ; 429/5xx/timeout → **une seule** nouvelle tentative différée (T1.5), jamais le retry 5 s actuel (`setNextConnectionForLater(iInterval)`) ;
  - découpage : courbe ≤ 7 jours (déjà fait par `calculateDaysLeft()`) ; puissance max par lots de **365 j** (décision 👤 du 2026-11-27, au lieu de 1 095 j) ;
  - cycle quotidien existant (8 h + minutes aléatoires) conforme à la fenêtre 6 h-10 h recommandée.
- **Acceptation :** requêtes construites conformes au contrat Phase 0 (vérifié par les tests de Phase 2) ; aucune régression des tests existants.

#### T1.3 - Implémenter l'adaptateur V2 → forme interne
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `DomoticzLinky/plugin.py` (nouvelle fonction de normalisation appelée avant `exploreDataHours()` / `exploreDataPeaks()`)
- **Implémenter :** `idPrm` → `meter_reading.usage_point_id` ; `grandeur[CONS].points[{v,d}]` → `meter_reading.interval_reading[{value,date}]` (horodatage fin d'intervalle, heure locale, inchangé) ; pas 15 min (`PT15M`) absorbé par la moyenne horaire existante ; corps d'erreur `{status,message,error}` → chemin d'erreur existant ; réponse inattendue → erreur explicite, pas d'exception non gérée.
- **Acceptation :** `exploreData*` et le calcul HC/HP restent inchangés ; sur la fixture `200_courbe_de_charge_consommation`, Σ des 24 valeurs horaires de chaque jour = `consommation_quotidienne` du même jour (5 248 / 6 159 / 5 071 Wh).

#### T1.4 - Protéger le jeton et passer en v3.0.0
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `DomoticzLinky/plugin.py` (masquage, attribut `version`)
- **Implémenter :** jeton masqué dans tous les logs (en-tête `Authorization`, éventuels dumps de `Parameters`) ; `version="3.0.0"`.
- **Acceptation :** aucune occurrence du jeton dans `/tmp/DomoticzLinky_*.log` ni dans le log Domoticz en debug niveau 3 (vérifié en Phase 2).

#### T1.5 - Respecter le budget d'appels Conso API
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `DomoticzLinky/plugin.py` (`setNextConnection()`, `setNextConnectionForLater()`, `setHistoryDays()`, `handleConnection()` étape `done`, config persistée)
- **Contexte :** règles d'usage Conso API (page `blocage-ip`, formalisées par 👤) : blocage d'IP automatique sous 12 h, durée de plusieurs mois, sans recours. En v2.7.0, une erreur 429/500 relance après **5 s** sans limite et un échec relance **toutes les heures** jusqu'à 22 h — interdit en mode Conso API.
- **Implémenter (mode `consoapi` uniquement, Russandol inchangé) :**
  - **≤ 3 requêtes par jour et par PRM, retries compris** : compteur `(date, PRM) → nb` persisté (`setConfigItem`), donc conservé après redémarrage du plugin ou de Domoticz ; budget épuisé → plus aucune requête avant le lendemain ;
  - cycle nominal = **2 requêtes par PRM** : courbe (≤ 7 j) + puissance max (historique court ≤ 35 j) ;
  - **historique complet étalé sur plusieurs jours** (décision 👤 du 2026-11-27) : au plus **un lot de 365 j de puissance max par jour**, en plus du cycle nominal ou à sa place, sans dépasser le budget ; reprise le lendemain là où le lot précédent s'est arrêté (position persistée) ;
  - échec (429/5xx/timeout/données absentes) → **une seule** nouvelle tentative 2 à 4 h plus tard (avant 22 h), sinon lendemain 8 h + minutes et secondes aléatoires ; 400/401 → lendemain ;
  - redémarrage le même jour après un cycle réussi → aucune requête (date du dernier succès persistée) ;
  - requêtes strictement **séquentielles** (une connexion à la fois), y compris en multi-PRM ;
  - log statut : nombre de requêtes consommées / budget du jour.
- **Acceptation :** aucun chemin de code ne permet une 4ᵉ requête dans la journée pour un PRM (vérifié par test en Phase 2), y compris après redémarrage ou erreurs répétées.

**→ Gate #2** (handoff DEVon + `git diff --stat` + revue de code automatique)

---

### Phase 2 — Tests (🟢 QALvin) — ⏳ Planifié

**Critères de réussite :**
- ✅ `python -m pytest -q` vert, CI du fork verte
- ✅ Couverture ≥ 80 % sur le code nouveau si mesurable (sinon préciser)
- ✅ Au moins un test qui échoue si l'adaptateur ou le masquage est cassé

#### T2.1 - Ajouter les fixtures V2 anonymisées
- **Agent :** 🟢 QALvin
- **Fichier(s) :** `DomoticzLinky/tests/fixtures/consoapi_v2/*.json` (hors racine du fork, cf. ADR 007)
- **Acceptation :** fixtures issues de T0.2 (8 JSON déjà anonymisés, dossier projet `plan011/fixtures_consoapi_v2/`), sans PRM ni jeton réels.

#### T2.2 - Tester la source Conso API et l'adaptateur
- **Agent :** 🟢 QALvin
- **Fichier(s) :** `DomoticzLinky/tests/test_consoapi_source.py`, `DomoticzLinky/tests/test_consoapi_adapter.py`
- **Couvrir :**
  - construction des requêtes (hôte, chemin, paramètres, en-têtes, User-Agent) ;
  - `idle` → `start` sans Device Flow ; pas de requête production ;
  - 200 nominal → valeurs horaires et pics attendus, HC/HP inclus ;
  - 400, 401, 404, 429, 500, 502 → étape et message attendus ; réponse vide ou JSON invalide ;
  - jeton ou PRM manquant au démarrage ;
  - découpage des périodes ;
  - doublon/trou horaire (changement d'heure) et points `n`/`iv` inhabituels sans exception ;
  - budget T1.5 : 500 répétés, 429, timeout, 401, redémarrage le même jour → ≤ 3 requêtes/jour/PRM ; une seule tentative différée ; historique complet étalé (≤ 1 lot/jour).
- **Acceptation :** tous verts ; régression détectée si on casse l'adaptateur (preuve dans le rapport).

#### T2.3 - Tester le masquage et la non-régression Russandol
- **Agent :** 🟢 QALvin
- **Fichier(s) :** `DomoticzLinky/tests/test_secrets_masking.py` (extension), suites existantes
- **Acceptation :** sentinelle jeton absente des logs ; suites existantes vertes sans modification de leurs assertions.

**→ Gate #3**

---

### Phase 3 — Documentation (🟣 DOCly) — ⏳ Planifié

#### T3.1 - Documenter le fork
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `DomoticzLinky/readme.md` (consentement Conso API, jeton, révocation, paramètres `Address`/`Username`/`Password`, migration depuis v2.x), `DomoticzLinky/docs/RETROCONCEPTION.md` (§ 2.2, 5, 6, 7, 13, 14), `DomoticzLinky/CHANGELOG.md` (3.0.0)
- **Acceptation :** procédure de configuration suivable sans autre source ; liens vérifiés.

#### T3.2 - Documenter `domotique`
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `docs/ARCHITECTURE.md` § 5.4, ADR 008 (liens de mise en œuvre)
- **Acceptation :** architecture cible reflétée ; aucune contradiction avec l'ADR 008.

---

### Phase 4 — Livraison et validation en production (🔵 DEVon + 👤 + 🟢 QALvin) — ⏳ Planifié

#### T4.1 - Publier v3.0.0
- **Agent :** 🔵 DEVon
- **Fichier(s) :** PR fork `feat/consoapi-v2` → `master`, tag `v3.0.0` ; `domotique/.github/workflows/build-domoticz.yml` (SHA + commentaire `# v3.0.0`, ADR 007)
- **Acceptation :** CI fork verte ; build image `vzwingmadomatic/domoticz` vert ; SHA épinglé = tag `v3.0.0`.

#### T4.2 - Reconfigurer le matériel en production
- **Agent :** 👤
- **Couvrir :** déploiement de l'image sur le NAS ; matériel Linky : `Address` = Conso API, `Username` = PRM, `Password` = jeton ; `Mode3` = Non.
- **Acceptation :** cycle complet sans erreur dans le log Domoticz.

#### T4.3 - Vérifier en production
- **Agent :** 🟢 QALvin (avec 👤)
- **Couvrir :** devices `Linky <PRM>` mis à jour, même idx et historique conservé ; aucun jeton dans les logs ; indicateur 6 du health check au vert.
- **Acceptation :** 3 cycles quotidiens consécutifs réussis (au plus 1 cycle par jour) avant Gate #4.

**→ Gate #4** (clôture)

---

## 📊 Résumé par Agent

| Agent | Tâches | Livrable |
|---|---|---|
| 👤 | T0.1, T0.2, T4.2 | Jeton, échantillons, configuration production |
| ⚫ MAINa / 🟠 ARCos | T0.2, T0.3 | Contrat V2 documenté, plan ajusté |
| 🔵 DEVon | T1.1 – T1.5, T4.1 | Source Conso API + adaptateur V2, v3.0.0 publiée et épinglée |
| 🟢 QALvin | T2.1 – T2.3, T4.3 | Fixtures, tests pytest, vérification en production |
| 🟣 DOCly | ADR 008, T3.1 – T3.2 | ADR, readme, rétroconception, CHANGELOG, ARCHITECTURE |

---

## 📍 Dépendances entre Phases

```
Phase 0 (contrat V2, 👤)  → Gate #1 (plan ajusté + ADR 008)
    ↓ GO
Phase 1 (code)            → Gate #2
    ↓ GO
Phase 2 (tests)           → Gate #3
    ↓ GO
Phase 3 (docs)
    ↓
Phase 4 (livraison + 3 cycles en prod) → Gate #4
```

---

## ✅ Critères de Succès Globaux

1. Devices `Linky <PRM>` alimentés par Conso API, historique existant conservé (mêmes idx).
2. 3 cycles quotidiens consécutifs réussis en production ; indicateur 6 du health check au vert.
3. Au plus 1 cycle par jour et **≤ 3 requêtes par jour et par PRM, retries compris** ; aucune requête production en mode Conso API.
4. Aucun jeton ni PRM réel dans les dépôts, les rapports ou les logs.
5. Mode Russandol toujours fonctionnel en code (tests existants verts sans modification).
6. CI du fork verte ; image `vzwingmadomatic/domoticz` construite avec le SHA `v3.0.0`.
7. ADR 008 `Acceptée` ; readme, rétroconception, CHANGELOG et ARCHITECTURE à jour.

---

## 🚦 Journal des gates

| Gate | Date | Objet | Décision 👤 | Notes |
|---|---|---|---|---|
| #0 | 2026-11-25 | Choix de solution | ✅ GO | Option B (Conso API, V2) ; Russandol en repli ; ZLinky écarté (pas d'achat) ; pas de production ; pas de rattrapage d'historique ; échantillons V2 analysés ensemble. Diagnostic de la panne : proxy Russandol → 500 sur routes avec base, 400 sur routes sans base, sandbox 200 |
| — | 2026-11-27 | Reprise Phase 0 | — | État revérifié : fork `master` = `a7b2320` (v2.7.0), aucune branche `feat/consoapi-v2`. Contrat « requête » établi depuis la doc publique (rapport Phase 0 § 1) ; réponses V2 non documentées → captures 👤 requises (script `capture_consoapi_v2.ps1`) |
| — | 2026-11-27 | Phase 0 / T0.2-T0.3 | — | Captures 👤 (3 j). Écarts vs hypothèses : pas **15 min** (et non 30) ; unités W / VA / Wh ; horodatage fin d'intervalle confirmé par recoupement exact avec le quotidien ; courbe limitée à 7 j (`ADAM-DC-0015`) ; erreurs `{status,message,error}`. Cœur `exploreData*` compatible sans changement → T1.3 réduit à un adaptateur de clés. Ouverts : R6b (période max puissance), R9 (durée de vie jeton) |
| — | 2026-11-27 | R6b, R9, quotas | 👤 | R6b : lots de **365 j** pour la puissance max (pas de test). R9 : consentement / jeton valable **3 ans**. Règles d'usage Conso API ajoutées → nouvelle tâche **T1.5** (budget ≤ 3 req/jour/PRM, une seule tentative différée, historique complet étalé sur plusieurs jours — 👤) ; le retry 5 s / horaire de v2.7.0 est exclu en mode Conso API |
| #1 | 2026-11-27 | Validation plan (après Phase 0) + ADR 008 | ✅ GO (« démarre le code ») | ADR 008 → `Acceptée`. Historique complet de puissance max étalé sur plusieurs jours (≤ 1 lot de 365 j/jour) |
| — | 2026-11-27 | Phase 1 | — | Code poussé sur `DomoticzLinky` branche `claude/project-thread-kei9q4` (`ffd2545`). 111 tests verts, ruff OK ; essai de bout en bout sur fixtures OK. Écart : nom de branche imposé par la session |
| #2 | 2026-11-27 | Validation code | ✅ GO (« ok » + 2 remarques) | Remarques traitées : retrait `opensrcdev` (bac à sable) et options `Mode3` 10-19 ; libellés `Mode3` 3/4 explicites. Conso API passe à l'index d'adresse 1 |
