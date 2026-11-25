# Plan d'Action 010 — Plugin Linky : provenance CI épinglée, correctifs, sécurité des logs, supervision

**Document :** `docs/plans/010_linky_suites.plan.md`
**Date de création :** 2026-11-25
**Statut :** 🔄 En cours — Gate #0 ✅ GO, Gate #1 ✅ GO (2026-11-25) ; Phase 1 en cours
**Objectif Prioritaire :** MEDIUM (S3 sécurité : HIGH dans le lot)
**ADR associé :** `docs/adr/007-plugins-domoticz-provenance-epinglee.md` — `Acceptée` (Gate #1, 2026-11-25)
**Annexe obligatoire :** [`010_reports/ANALYSE_ARCOS.md`](./010_reports/ANALYSE_ARCOS.md) — analyse 🟠 ARCos complète (code actuel / code cible, lignes, commandes). **Les références « § x.y » de ce plan renvoient à cette annexe.**
**Plan d'origine :** [`009_retrodoc_domoticzlinky.plan.md`](./009_retrodoc_domoticzlinky.plan.md) (section « Suites identifiées » S1-S4)

---

## 🧭 Démarrage en nouvelle session (à lire en premier)

Ce plan est conçu pour être exécuté **sans le contexte de la session qui l'a créé**. Procédure pour ⚫ MAINa :

1. Lire, dans cet ordre : ce plan ; l'annexe [`ANALYSE_ARCOS.md`](./010_reports/ANALYSE_ARCOS.md) ; `.github/copilot-instructions.md` ; `docs/ARCHITECTURE.md` § 5.4 ; `DomoticzLinky/docs/RETROCONCEPTION.md` (§ 13 Sécurité, § 14 Dette) ; `domoticz/scripts/dzVents/global_data.lua`, `Health_check_dzVents.lua`, `Config_check.lua`.
2. Vérifier l'**état réel** (section « État initial » ci-dessous) avec les commandes indiquées ; si un SHA, une PR ou un numéro de ligne a changé, le noter dans le journal des gates et réajuster (les numéros de ligne de `plugin.py` de l'annexe valent pour v2.6.1).
3. Tenir le **Gate #0** : présenter au 👤 les 14 décisions (section « Décisions Gate #0 ») et les questions Q1-Q6 ; consigner les réponses dans le journal.
4. Dérouler ensuite les phases dans l'ordre, chaque gate selon `.github/skills/gate-protocol/SKILL.md` (preuves, `GO / AJUSTER / STOP`, journal). Rapports de phase dans `docs/plans/010_reports/PHASE_<N>_COMPLETION_REPORT.md` (modèle : `.github/skills/plan-phase-execution/templates/phase-report.template.md`).
5. Si une décision Gate #0 diffère de la recommandation, adapter les tâches concernées **avant** Gate #1 (le plan ajusté est ce qui est validé au Gate #1).

---

## 🌍 Contexte

### Workspace et dépôts

| Dépôt | Chemin local | GitHub | Rôle |
|---|---|---|---|
| `domotique` | `C:\Users\vzwingma\IdeaProjects\domotique-workspace\domotique` | `vzwingma/domotique` (branche par défaut `master`) | Domoticz/dzVents, Docker, CI d'image `vzwingmadomatic/domoticz` |
| `DomoticzLinky` | `C:\Users\vzwingma\IdeaProjects\domotique-workspace\DomoticzLinky` | `vzwingma/DomoticzLinky` (fork de `guillaumezin/DomoticzLinky`, upstream **non maintenu** ; branche par défaut `master`) | Plugin Python Domoticz Linky, monofichier `plugin.py` (~2726 l.), **aucun test, lint ni CI** |

⚠️ `gh pr create` dans le fork : toujours passer `--repo vzwingma/DomoticzLinky` (sinon `gh` cible l'upstream `guillaumezin`).

### Chaîne actuelle (avant ce plan)

`.github/workflows/build-domoticz.yml` (job `download-linky`) fait `actions/checkout` de **`guillaumezin/DomoticzLinky` @ `refs/heads/master` (non épinglé)** → artefact `*.py` → `_docker/build_domoticz/linky/` → `Dockerfile` `COPY linky/plugin.py /opt/domoticz/userdata/plugins/DomoticzLinky` → image `vzwingmadomatic/domoticz` (`linux/arm/v7`, `latest` reconstruite à chaque push `master`) → déployée par `_docker/envs/nas/domotique-compose.yml` (montages : `domoticz.db` + dossier `scripts/dzVents` de l'hôte NAS). Même pattern non épinglé pour deCONZ (`Smanar/Domoticz-deCONZ`). Tokens OAuth et cache Linky persistés dans `domoticz.db`.

### État initial attendu (fin de session 2026-11-25) — à revérifier

| Élément | Valeur | Commande de vérification |
|---|---|---|
| PR doc Linky `domotique` | #232 `feat/add_linky` → `master` (ouverte) | `gh pr view 232 --repo vzwingma/domotique --json state` |
| PR doc fork | vzwingma/DomoticzLinky#2 `feat/fork_and_retrodoc` → `master` (ouverte) | `gh pr view 2 --repo vzwingma/DomoticzLinky --json state` |
| Tag fork `v2.6.1` | tag léger sur `f3df2584ab398110eefe8d65df1b83d9a9d95395` ; `plugin.py` identique à l'upstream `1ef6adf` | `git -C <fork> rev-list -n1 v2.6.1` |
| deCONZ dernier tag | `1.0.35` = `95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a` (master = +1 commit README seul) | `git ls-remote --tags https://github.com/Smanar/Domoticz-deCONZ 1.0.35` |
| ADR existants | 001 à 006 → **prochain : 007** | `Get-ChildItem docs/adr` |
| Renovate | actif sur `domotique` (`renovate.json` : `config:recommended` + automerge minor/patch) | `Get-Content renovate.json` |
| Health check dzVents | 5 indicateurs (scenePhase, device Phase < 25 h, Freebox < 10 min, Tydom Temp < 90 min, joursFeries) | `Health_check_dzVents.lua` |

### Constats structurants (annexe § 0)

- **C1** — Le tag `v2.6.1` du fork = code upstream : S1 peut basculer la provenance **sans changement fonctionnel**, avant S2/S3.
- **C2** — `onHeartbeat()` appelle `Touch()` toutes les ~50 s : `lastUpdate` ne mesure **pas** la fraîcheur des données Enedis ; utiliser `timedOut` (posé par le plugin après 1,5 j) + `lastUpdate` > 36 h pour « plugin arrêté ».
- **C3** — D12 (statut 500 traité comme « pas de production ») est un **contournement volontaire** : ne pas corriger.
- **C4** — L'artefact CI prend `*.py` à la racine du checkout (ne jamais mettre de `.py` de test à la racine du fork) ; les builds `pull_request` / `workflow_dispatch` poussent des images `:merge` / `:<branche>` (pas `latest`).

---

## 🎯 Objectif Global

Traiter les 4 suites du plan 009 :

| Id | Suite | Dépôt |
|---|---|---|
| **S1** | CI : consommer le fork `vzwingma/DomoticzLinky` (et deCONZ) **épinglé par SHA + tag**, mises à jour via PR Renovate **sans automerge** — ADR 007 | `domotique` |
| **S2** | Corriger les bugs avérés du plugin (D1, D2, D3, D5, D16 ; D4 commentaire) → version **2.7.0** | fork |
| **S3** | Ne plus écrire tokens / `Authorization` / `refresh_token` / `device_code` en clair dans les logs (masquage) | fork |
| **S4** | 6ᵉ indicateur `Health_check_dzVents.lua` : supervision des devices `Linky <PRM>` (+ prérequis `Config_check.lua`) | `domotique` |

Résultats mesurables : voir « Critères de succès globaux ».

### Solution retenue (Gate #0)

✅ **GO 👤 du 2026-11-25** — recommandations ARCos (annexe § 8) retenues, avec 2 ajustements : ordonnancement O-B, pin SHA + commentaire tag, Renovate regex `automerge:false`, deCONZ inclus, S2 = D1a/D2/D3/D5/D16 + D4 commentaire, **D11 au backlog** (`Mode2` = 7 en production, ≤ 35 j : bug sans effet), S3 = masquage M1, pickle hors périmètre, tests Q1 (pytest + stub Domoticz + ruff minimal + CI fork), S4 = identification I1 par préfixe `'Linky '`, **version 2.7.0** (au lieu de 2.6.2). `Mode3` n'a jamais été activé en production : pas de rotation des jetons. Ajout 👤 : documenter les paramètres `Mode1`-`Mode6` côté fork, de façon lisible par un utilisateur (T4.1).

### Sources et non-régression (dzVents — phase 2)

- Lire `docs/RETROCONCEPTION_dzVents.md` avant évolution de comportement et `.github/tasks/todo/PLAN_ACTIONS_dzVents.md` avant roadmap/refactor.
- `global_data.lua` source de vérité (constantes `DEVICE_*`, helpers) ; toute dépendance Domoticz critique dans `Config_check.lua`.
- Préserver marker `[HEALTH CHECK]`, propagation `uuid`, `tostring()` sur valeurs potentiellement nil, `pcall` par indicateur, niveaux `LOG_DEBUG/INFO/ERROR`.
- **Aucun PRM (14 chiffres) dans le dépôt ni dans les logs/rapports** : journaliser l'`idx` du device.

### Contraintes transverses

- Pas de modification des **clés ni du format de persistance** du plugin (`setConfigItem`/`getConfigItem`) : le retour arrière au pin v2.6.1 doit rester sûr.
- Lots séparés par dépôt et par nature (CI / dzVents / plugin) : une PR par lot (cf. `copilot-instructions` « À éviter »).
- Merges de PR, tag `v2.7.0` et release GitHub : réalisés par 👤 (sauf décision contraire Q6).
- Ne jamais recopier une sortie contenant un PRM ou un token dans un fichier versionné.

---

## ❓ Décisions Gate #0 (détail et options : annexe § 1-8)

| # | Décision | Options | Reco ARCos |
|---|---|---|---|
| 1 | Ordonnancement | O-A : S3+S2 → v2.7.0 → S1 pin v2.7.0 → S4 · **O-B** : S1 pin v2.6.1 + S4, puis S3+S2 → v2.7.0 → montée de pin | O-B |
| 2 | S1 forme du pin | **SHA + `# tag`** · tag seul · branche fork | SHA + tag |
| 3 | S1 mise à jour | **Renovate regex `automerge:false`** · manuel · Renovate + `dependencyDashboardApproval` | Renovate sans automerge |
| 4 | deCONZ | **Inclus** (pin `1.0.35` = `95b8f8b…`) · hors périmètre | Inclus |
| 5 | Périmètre S2 | D1, D2, D3 (+`KeyError` + `except`), D5, D16 maintenant ; D4 commentaire ; D12 inchangé ; D6/D7/D10/D13/D14/D15 backlog ; **D11 oui/non** | D11 → backlog (`Mode2` = 7) |
| 6 | D1 | **D1a** méthodes vides dans `BasePlugin` · D1b suppression des callbacks module | D1a |
| 7 | D2 version Domoticz non reconnue | **Arrêt explicite** (`iVersion = 0` + erreur) · supposer récente | Arrêt explicite |
| 8 | S3 masquage | **M1** clé + regex (dans `dumpDictToLog` et `my*()`) · M2 clé seule · M3 suppression des dumps ; PRM non masqué | M1 |
| 9 | `pickle.loads` avant checksum | **Hors périmètre, risque accepté et documenté** · migration JSON | Hors périmètre |
| 10 | Tests S2/S3 | **Q1** pytest + stub `Domoticz` + ruff minimal + CI fork · Q2 statique + manuel · Q3 conteneur + sandbox | Q1 |
| 11 | S4 identification device | **I1** préfixe `'Linky '` · I2 nom complet (PRM versionné ❌) · I3 variable utilisateur · I4 hardwareName | I1 |
| 12 | S4 règles | 0 device / `lastUpdate` > 36 h / `timedOut` → ERROR + notification ; log par `idx` | Oui |
| 13 | S4 dans `Config_check.lua` | Ajout contrôle « au moins un device préfixé » | Oui |
| 14 | Version fork | `2.7.0` + `externallink` → fork + `CHANGELOG.md` | Oui |

**Réponses 👤 (2026-11-25)** :
- **Q1** — Matériel nommé « Linky ». **Correction U1 (JSON `getdevices`) : le device réel s'appelle exactement `Linky`** (le PRM n'est que dans `ID`/`Description`, le nom `Linky <PRM>` créé par le plugin l. 643 a été renommé). Le préfixe `'Linky '` (avec espace) ne le trouverait pas → **ajustement I1 : préfixe `'Linky'` sans espace** (couvre `Linky`, `Linky <PRM>`, `Linky A / B`).
- **Q1 (complément)** — Aucun autre device dont le nom commence par « Linky » : pas de collision de préfixe.
- **Q2** — `Mode2` = 7 → D11 au backlog. `Mode3` = 0, debug jamais activé en production → pas de rotation des jetons.
- **Q3** — Dépôt public (vérifié `gh repo view` → `PUBLIC`) : I2 exclu.
- **Q4** — Synchronisation manuelle des scripts dzVents vers le NAS : validation runtime S4 après copie par 👤.
- **Q5** — Oui (vérifié : Python 3.14.7, Node v26.12.1). CI du fork reste en Python 3.11.
- **Q6** — Oui : merges et tag réalisés par 👤. **Prochaine version du fork : `v2.7.0`**.
- T0.1 : #232 et vzwingma/DomoticzLinky#2 `MERGED` (vérifié 2026-11-25) ; `master` à jour dans les deux dépôts (fork : `b90ea14`, tag `v2.6.1` inchangé sur `f3df258`).

**Questions 👤 (annexe § 11)** : Q1 noms exacts des devices/matériel Linky, collision de préfixe « Linky » ? · Q2 valeurs `Mode2` (→ D11) et `Mode3`, debug déjà activé en prod (→ rotation des jetons) ? · Q3 `vzwingma/domotique` public ? · Q4 synchronisation des scripts dzVents vers le NAS (`/volume1/home/vinz/domoticz/scripts/dzVents`) ? · Q5 Python ≥ 3.11 / Node disponibles en local (`python --version`, `node --version`) ? · Q6 merges + tag faits par 👤 ?

---

## 🛠️ Phases

> Ordonnancement présenté selon la reco **O-B**. Chaque phase de code suit le cycle **code → Gate #2 → QA → Gate #3 → docs → Gate #4** (gates numérotés par phase dans le journal, ex. `P1-#2`). **Exécution séquentielle P1 → P2 → P3 (choix 👤 au Gate #1)** ; jamais de franchissement de gate implicite.

### Phase 0 — Prérequis, ADR, levée d'incertitudes — ✅ Complétée (2026-11-25)
**Contexte :** la doc à modifier (§ 5.4, tableau « Provenance des plugins ») n'existe sur `master` qu'après merge de #232 ; les liens publiés vers `DomoticzLinky/blob/master/docs/RETROCONCEPTION.md` exigent le merge de #2.
**Critères de réussite :**
- ✅ #232 et vzwingma/DomoticzLinky#2 `MERGED`
- ✅ ADR 007 rédigé en `Proposée`
- ✅ U1-U3 et Q1-Q6 tranchés (résultats booléens, sans PRM)

#### T0.1 - Fusionner les PR de documentation du plan 009
- **Agent :** 👤
- **Acceptation :** `gh pr view 232 --repo vzwingma/domotique --json state` → `MERGED` ; `gh pr view 2 --repo vzwingma/DomoticzLinky --json state` → `MERGED`. Puis `git switch master; git pull` dans les deux dépôts.

#### T0.2 - Mettre le plan au statut « En cours »
- **Agent :** ⚫ MAINa
- **Fichier(s) :** ce plan, `docs/plans/README.md`
- **Acceptation :** index et plan modifiés dans le même commit, sur la branche `ci/linky_fork_pin` (créée depuis `master` à jour).

#### T0.3 - Rédiger l'ADR 007 (Proposée)
- **Agent :** 🟣 DOCly (skill `adr-writing`, gabarit `docs/adr/ADR-TEMPLATE.md`)
- **Fichier(s) :** `docs/adr/007-plugins-domoticz-provenance-epinglee.md`
- **Contenu :** annexe § 1.4 (contexte, décision, 5 alternatives avec motif de rejet, conséquences, mise en œuvre, références), ajusté aux décisions du Gate #0.
- **Acceptation :** toutes les sections du gabarit ; ≥ 2 alternatives rejetées motivées ; statut `Proposée` ; référencé dans l'en-tête de ce plan.

#### T0.4 - Lever les incertitudes d'exécution U1-U3
- **Agent :** 👤 (trace par 🟢 QALvin dans `PHASE_0_COMPLETION_REPORT.md`)
- **Couvrir (annexe § 5) :**
  - U1 `Touch()` rafraîchit `LastUpdate` (~50 s) : 2 appels `json.htm?type=command&param=getdevices&rid=<idxLinky>` à 2 min d'intervalle.
  - U2 `HaveTimeout` exposé et `false` en nominal.
  - U3 `onNotification` enregistre le plugin comme canal de notification (Paramètres > Notifications) ou `AttributeError … onNotification` dans le log.
- **Acceptation :** 3 résultats booléens consignés, **aucune sortie brute recopiée** (contient le PRM). Si U2 infirmé → repli S4 sur `lastUpdate` > 36 h seul (ajuster T2.1).
- **Résultats (2026-11-25, 👤, Domoticz 2026.4) :** U1 ✅ `LastUpdate` rafraîchi en < 1 min sans nouvelle donnée (`Touch()` confirmé → `lastUpdate` = vivacité du plugin, seuil 36 h = « plugin arrêté ») · U2 ✅ `HaveTimeout` exposé, `false` en nominal (`timedOut` utilisable) · U3 ❌ aucun canal « Linky » dans Paramètres > Notifications (le `onNotification` module n'expose pas de canal ; D1a reste valable pour `onCommand`). Constat additionnel : nom réel du device = `Linky` (→ T2.1 préfixe `'Linky'`). Trace : `010_reports/PHASE_0_COMPLETION_REPORT.md`.

### Phase 1 — S1 : provenance CI épinglée (`domotique`, branche `ci/linky_fork_pin`) — 🔄 En cours
**Dépend de :** Phase 0, Gate #1.
**Critères de réussite :**
- ✅ 0 occurrence `guillaumezin|refs/heads/master` dans `build-domoticz.yml` ; 2 pins `ref: <sha40> # <tag>`
- ✅ Blob `plugin.py` de l'artefact = blob `v2.6.1:plugin.py` du fork ; `*.py` deCONZ = tag `1.0.35`
- ✅ Config Renovate validée ; règle `automerge:false` en dernière position des `packageRules`

#### T1.1 - Épingler les plugins dans le workflow
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `.github/workflows/build-domoticz.yml` (jobs `download-linky`, `download-deconz`)
- **Implémenter (annexe § 1.2, code cible fourni) :**
  - Linky : `repository: vzwingma/DomoticzLinky`, `ref: f3df2584ab398110eefe8d65df1b83d9a9d95395 # v2.6.1` (ligne `ref:` **immédiatement** après `repository:`, requis par la regex Renovate).
  - deCONZ : `ref: 95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a # 1.0.35`.
  - Étape « Trace provenance » (`git rev-parse HEAD` + `version=` → `$GITHUB_STEP_SUMMARY`) pour chaque plugin.
  - Artefact Linky : `path: ${{ github.workspace }}/plugin.py` ; deCONZ : `${{ github.workspace }}/*.py` ; `if-no-files-found: error` sur les deux.
  - SHA = toujours celui du **commit** (`git rev-list -n1 <tag>`).
- **Acceptation :** `rg -n "guillaumezin|refs/heads/master" .github/workflows/build-domoticz.yml` → 0 ; `rg -n "ref: [0-9a-f]{40} # " .github/workflows/build-domoticz.yml` → 2 lignes ; YAML valide (le run T1.3 démarre).

#### T1.2 - Configurer Renovate pour les pins
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `renovate.json`
- **Implémenter (annexe § 1.2) :** `customManagers` regex (`managerFilePatterns` ou repli `fileMatch`), datasource `github-tags`, `currentDigest` + `currentValue` ; `packageRules` **en dernier** : `matchManagers: ["custom.regex"]`, `matchDepNames: ["vzwingma/DomoticzLinky","Smanar/Domoticz-deCONZ"]`, `automerge: false`.
- **Acceptation :** `npx --yes --package renovate -- renovate-config-validator renovate.json` → `Config validated successfully` (si Node absent : le consigner, validation par l'app Renovate après merge — T1.6).

#### T1.3 - Valider le build épinglé
- **Agent :** 🟢 QALvin (après Gate P1-#2)
- **Couvrir (annexe § 1.3, étapes 2-7) :**
  - `gh workflow run build-domoticz.yml --repo vzwingma/domotique --ref ci/linky_fork_pin` ; `gh run list … --limit 1` → `success`.
  - Résumé du job : SHA `f3df258…`, `95b8f8b…`, `version="2.6.1"`.
  - `gh run download <id> -n linky-plugin -D $env:TEMP\linky` → **1 seul fichier** `plugin.py` ; `git hash-object --no-filters $env:TEMP\linky\plugin.py` = `git -C <fork> rev-parse v2.6.1:plugin.py`.
  - deCONZ : artefact `deconz-plugin` = liste/contenu des `*.py` du tag `1.0.35` (`gh api repos/Smanar/Domoticz-deCONZ/git/trees/1.0.35`).
  - Image poussée avec tag ≠ `latest` (`:linky_fork_pin`).
- **Acceptation :** les 5 contrôles ✅ dans `PHASE_1_COMPLETION_REPORT.md` ; nettoyer `$env:TEMP\linky`, `$env:TEMP\deconz`.

#### T1.4 - Documenter la provenance épinglée
- **Agent :** 🟣 DOCly (après Gate P1-#3)
- **Fichier(s) :** `docs/ARCHITECTURE.md` § 5.4 (tableau source, schéma, puce « non épinglée » → épinglée + lien ADR 007) ; `_docker/build_domoticz/README.md` (tableau « Provenance des plugins », reproductibilité, procédure de montée de version : tag fork → PR Renovate → merge) ; `README.md` (ligne composant Linky) ; fork `docs/RETROCONCEPTION.md` § 1 (avertissement « Upstream non épinglé ») et § 15.
- **Acceptation :** `rg -n "non épingl|guillaumezin/DomoticzLinky.*master" README.md docs/ARCHITECTURE.md _docker/build_domoticz/README.md` → 0 occurrence décrivant l'état courant ; liens relatifs valides. (Modif fork : commit séparé sur le fork, branche `docs/pin_provenance` ou incluse en phase 4.)

#### T1.5 - Clôture de phase 1
- **Agent :** 👤 (merge PR `ci/linky_fork_pin`) puis ⚫ MAINa
- **Acceptation :** PR mergée ; build `master` vert (`gh run list --branch master --workflow build-domoticz.yml --limit 1`) ; image `latest` redéployée par 👤 (Watchtower/manuel) sans régression (plugin Linky démarre, version 2.6.1 dans le log Domoticz).

#### T1.6 - Preuve Renovate (différée)
- **Agent :** 🟢 QALvin / ⚫ MAINa
- **Acceptation :** issue « Dependency Dashboard » de `vzwingma/domotique` liste `vzwingma/DomoticzLinky v2.6.1` et `Smanar/Domoticz-deCONZ 1.0.35` (`gh issue list --repo vzwingma/domotique --search "Dependency Dashboard"` puis `gh issue view <n>`). Si absent → corriger la regex (retour T1.2).

### Phase 2 — S4 : supervision Linky dzVents (`domotique`, branche `feat/health_linky`) — ⏳ Planifié
**Dépend de :** Phase 0 (U1/U2, Q1, Q4), Gate #1. Indépendante de la phase 1.
**Critères de réussite :**
- ✅ 3 fichiers Lua modifiés, 0 PRM dans le diff
- ✅ Chargement sans erreur ; `Contrôle de configuration OK` ; `[HEALTH CHECK] [uuid] Santé dzVents OK` au 08:00 suivant
- ✅ Documentation « 6 indicateurs » cohérente partout

#### T2.1 - Implémenter l'indicateur Linky
- **Agent :** 🔵 DEVon
- **Fichier(s) (annexe § 4.3, code cible fourni) :**
  - `domoticz/scripts/dzVents/global_data.lua` : constante `DEVICE_LINKY_PREFIX = 'Linky'` (**sans espace** : le device de production s'appelle exactement `Linky`, cf. T0.4 ; aucun autre device « Linky… » — Q1) (après `DEVICE_STATUT_PHASE`) + helper `getLinkyDevices(domoticz)` (filtre `domoticz.devices()` par préfixe, `string.sub(d.name, 1, #prefix) == prefix`).
  - `domoticz/scripts/dzVents/Health_check_dzVents.lua` : bloc **6** entre le bloc 5 (jours fériés) et `-- Résumé`, dans un `pcall` : 0 device → `warn` ; `lastUpdate.minutesAgo > 36*60` → `warn` « plugin inactif » ; `elseif d.timedOut` → `warn` « aucune donnée Enedis > 1,5 j » ; sinon `LOG_DEBUG`. Messages avec `idx`, jamais le nom.
  - `domoticz/scripts/dzVents/Config_check.lua` : contrôle « 1bis » (au moins un device préfixé, sinon `PREREQUIS MANQUANT [Device] : Linky*` + `nbErrors`).
- **Contraintes :** triggers/évènements/marker inchangés ; `tostring()` ; `uuid` ; pas d'effet de bord hors notification existante. U1/U2 confirmés (T0.4) : règles `lastUpdate` > 36 h + `timedOut` conservées.
- **Acceptation :** `rg -n "DEVICE_LINKY_PREFIX|getLinkyDevices" domoticz/scripts/dzVents` → 3 fichiers ; `git diff --stat` = 3 fichiers ; `rg -n "Linky [0-9]{14}" domoticz` → 0 ; `luac -p` sur les 3 fichiers si `luac -v` disponible.

#### T2.2 - Valider S4
- **Agent :** 🟢 QALvin (après Gate P2-#2)
- **Couvrir :** revue statique (trigger timer 08:00 inchangé, `pcall`, `tostring`, marker, `uuid`, `if/elseif` sans double comptage, compteur d'anomalies et notification) ; runtime après synchronisation NAS (Q4) : log de chargement sans erreur, `Contrôle de configuration OK`, `Santé dzVents OK` à 08:00. Branches dégradées validées **statiquement** (le dire explicitement).
- **Acceptation :** tableau contrôle → preuve dans `PHASE_2_COMPLETION_REPORT.md` ; aucune sortie contenant le PRM recopiée.

#### T2.3 - Documenter S4
- **Agent :** 🟣 DOCly (après Gate P2-#3)
- **Fichier(s) (annexe § 4.4) :** `domoticz/README.md` (5 → 6 indicateurs, 2 endroits) ; `docs/ARCHITECTURE.md` § 5.4 (retirer « aucun script dzVents ne les référence » / « aucune supervision ») et § 6.2 (ligne 6) ; `docs/RETROCONCEPTION_dzVents.md` (l. ~40 « quatre » **déjà faux** → « six » + points 5 et 6 ; tableaux ~l. 106 et ~l. 437 ; section `Config_check`) ; `.github/copilot-instructions.md` § DEV-5 (6 indicateurs + seuil Linky) ; `.github/instructions/qa.instructions.md` (seuils Health check) ; fork `docs/RETROCONCEPTION.md` § 15 (supervision livrée — commit fork séparé ou phase 4).
- **Acceptation :** `rg -n "5 indicateurs|cinq indicateurs|quatre indicateurs" README.md docs domoticz .github` → 0.

### Phase 3 — S3 + S2 : correctifs du plugin (fork, branche `fix/v2.7.0`) — ⏳ Planifié
**Dépend de :** Phase 0 (#2 mergée, Q2, U3), Gate #1. Branche créée depuis `master` du fork à jour.
**Exception de séquencement (décision 10 = Q1) :** 🟢 QALvin pose **d'abord** le harnais et des tests de bug en `xfail(strict=True)` (preuve des bugs), puis 🔵 DEVon corrige, puis 🟢 QALvin retire les `xfail`. **Validé par 👤 au Gate #1 (2026-11-25).**
**Critères de réussite :**
- ✅ CI du fork verte : `py_compile`, `ruff check`, `pytest` ; 0 `xfail` résiduel
- ✅ Aucun secret sentinelle dans les sorties capturées
- ✅ `plugin.py` : clés/format de persistance inchangés ; D12 inchangé ; `version="2.7.0"`

#### T3.1 - Poser le harnais de tests et la CI du fork
- **Agent :** 🟢 QALvin
- **Fichier(s) (annexe § 6) :** `tests/conftest.py` (stub module `Domoticz` : `Log/Error/Status/Debug` capturés, `Debugging`, `Configuration` à état, `Connection`/`Device` = `MagicMock` ; chargement `plugin.py` via `importlib.util.spec_from_file_location` ; injection `Parameters`/`Devices` ; fixture `plugin` avec `fDebug = io.StringIO()`) ; `tests/test_callbacks.py` (D1, D2) ; `tests/test_merge_counters.py` (D3) ; `tests/test_devices.py` (D5) ; `tests/test_cache.py` (D4 caractérisation 12 h vs 11 h) ; `tests/test_secrets_masking.py` (S3, sentinelles `TOK-ACCESS-SENTINEL` etc.) ; `requirements-dev.txt` (`pytest`, `ruff` en versions exactes stables du jour) ; `ruff.toml` (`target-version = "py311"`, `builtins = ["Parameters","Devices"]`, `select = ["E9","F63","F7","F82"]`) ; `.gitignore` (`__pycache__/`, `.pytest_cache/`, `.ruff_cache/`, `.venv/`) ; `.github/workflows/ci.yml` (push `master`, `pull_request`, `workflow_dispatch` ; `permissions: contents: read` ; `actions/checkout@v7` ; `actions/setup-python` dernière majeure **vérifiée** ; Python `3.11` — confirmer avec `docker compose exec domoticz python3 --version` sur le NAS).
- **Interdit :** tout `.py` à la racine du fork autre que `plugin.py` (constat C4).
- **Acceptation :** `python -m pytest -q` → tests de caractérisation verts + tests de bug en `xfail` attendus ; `python -m py_compile plugin.py` OK ; `python -m ruff check plugin.py tests` OK (F821 existants triés : bug réel ou ajout `builtins`) ; run CI fork vert (`gh run list --repo vzwingma/DomoticzLinky --limit 1`). Si Python local absent (Q5) : la CI fait foi.

#### T3.2 - S3 : masquer les secrets dans les journaux
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `plugin.py`
- **Implémenter (annexe § 3.1-3.3, code fourni) :** constantes `SENSITIVE_KEYS`, `MASK`, `_SECRET_PATTERNS` + fonctions `maskSecrets()` / `maskValue()` au niveau module (après `NO_STATUS_ERROR_CODE`) ; `dumpDictToLog()` masque par clé à chaque profondeur et la branche non-dict ; `myMessage/myLog/myStatus/myError` appliquent `maskSecrets` ; `setConfigItem()` en erreur ne logge plus `str(Value)` mais le type. **Conserver** en clair le `user_code`/URL de consentement et le PRM.
- **Acceptation :** tests `test_secrets_masking.py` verts ; `rg -n 'str\(Value\)' plugin.py` → 0 dans `setConfigItem` ; message de consentement toujours présent (test de non-régression).

#### T3.3 - S2 : corriger les bugs retenus
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `plugin.py`
- **Implémenter (annexe § 2.2, fiches avec code actuel/cible) :**
  - D1a : `onCommand()` / `onNotification()` dans `BasePlugin` (debug seulement, ne pas logger `Text`).
  - D2 : `iVersion = 0` avant `re.search` + `myError` si version non reconnue (arrêt explicite via test `< 4011070`).
  - D3 : `mergeCounters()` itère sur `self.dData[sUsagePointProductionId]` ; `.get("value_year", 0)` ; garde d'existence des deux PRM ; `except Exception as err` journalisé + `bResult = False`.
  - D5 : test d'unité pleine **après** la boucle `range(1, 256)` dans `getOrCreateDevice()`.
  - D16 : `onStop()` ferme `fDebug` et le remet à `None`.
  - D4 : commentaire explicatif seulement (comportement inchangé).
  - D11 : **hors périmètre** (Gate #0 : `Mode2` = 7, backlog).
  - **Ne pas toucher** : D12 (contournement volontaire), clés/format de persistance.
- **Acceptation :** tests correspondants verts une fois `xfail` retirés ; `git diff master -- plugin.py` sans modification des appels `setConfigItem`/`getConfigItem` ni des clés.

#### T3.4 - Passer en version 2.7.0
- **Agent :** 🔵 DEVon
- **Fichier(s) :** `plugin.py` (bloc XML : `version="2.7.0"`, `externallink="https://github.com/vzwingma/DomoticzLinky"`)
- **Acceptation :** `rg -n 'version="2.7.0"' plugin.py` → 1.

#### T3.5 - Valider S2/S3
- **Agent :** 🟢 QALvin (après Gate P3-#2)
- **Couvrir :** retrait de tous les `xfail` ; `py_compile` + `ruff` + `pytest` (local et CI) ; revue du diff (persistance inchangée, D12 inchangé, pas de `.py` racine supplémentaire) ; non-régression consentement.
- **Acceptation :** 0 échec, 0 `xfail` ; lien du run CI vert ; résultats dans `PHASE_3_COMPLETION_REPORT.md`.

### Phase 4 — Documentation et publication du fork — ⏳ Planifié
**Dépend de :** Gate P3-#3.
**Critères de réussite :**
- ✅ Rétrodoc, `CHANGELOG.md`, readme du fork à jour
- ✅ Tag `v2.7.0` publié sur le commit de merge

#### T4.1 - Mettre à jour la documentation du fork
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `DomoticzLinky/docs/RETROCONCEPTION.md` (§ 1 version 2.7.0 en conservant le SHA historique `1ef6adf` ; § 11 masquage ; § 13 colonne Statut : fuites tokens « Corrigé v2.7.0 », pickle « Accepté », fichier debug « 0600 via mkstemp » — corriger la mention « non protégé » ; § 14 colonne Statut D1-D16 selon décisions ; § 15 provenance épinglée + supervision si non fait en T1.4/T2.3) ; `DomoticzLinky/CHANGELOG.md` (nouveau, Keep a Changelog, entrée 2.7.0) ; `DomoticzLinky/readme.md` (section fork : mention `tests/` + CI ; **nouvelle section « Paramètres du plugin »** demandée au Gate #0 : tableau lisible `Mode1`-`Mode6` (nom technique, libellé affiché dans Domoticz, rôle, valeurs, défaut) avec les effets de `Mode3` (debug, reset consentement/cache, faux clients) et l'avertissement « debug = fichiers `/tmp` », renvoi vers `docs/RETROCONCEPTION.md` § 3 pour le détail ; reste du guide utilisateur inchangé).
- **Acceptation :** liens relatifs valides ; aucune affirmation contraire au code ; PR fork mergée par 👤.

#### T4.2 - Publier v2.7.0
- **Agent :** 👤
- **Acceptation :** `git tag v2.7.0 <sha-merge>` + `git push origin v2.7.0` + release GitHub ; `git ls-remote --tags https://github.com/vzwingma/DomoticzLinky v2.7.0` → SHA.

### Phase 5 — Montée de pin v2.7.0 et vérification production (`domotique`) — ⏳ Planifié
**Dépend de :** Phase 1 complétée (pin + Renovate) et T4.2.
**Critères de réussite :**
- ✅ PR Renovate (ou manuelle) **non auto-mergée** ; diff d'une ligne
- ✅ Artefact = `v2.7.0:plugin.py` ; plugin 2.7.0 opérationnel en production

#### T5.1 - Monter le pin
- **Agent :** 🔵 DEVon (ou validation de la PR Renovate)
- **Fichier(s) :** `.github/workflows/build-domoticz.yml` (`ref: <sha v2.7.0> # v2.7.0`), branche `ci/linky_v2.7.0` si manuel
- **Acceptation :** diff d'une ligne ; SHA = `git -C <fork> rev-list -n1 v2.7.0` ; si PR Renovate : preuve qu'elle n'a **pas** été auto-mergée (règle `automerge:false` effective).

#### T5.2 - Valider le build v2.7.0
- **Agent :** 🟢 QALvin
- **Acceptation :** procédure T1.3 avec `v2.7.0` (blob identique, résumé `version="2.7.0"`).

#### T5.3 - Vérifier en production
- **Agent :** 👤 (trace 🟢 QALvin)
- **Couvrir :** après merge + redéploiement : log Domoticz au démarrage du plugin = 2.7.0 ; collecte suivante réussie (« Prochaine connexion » au lendemain) ; aucune `AttributeError` ; health check Linky OK. Optionnel S3 : `Mode3=1`, redémarrer le matériel dans la plage 8h-22h, `docker compose -f domotique-compose.yml exec domoticz sh -c 'grep -cE "(access_token|refresh_token|device_code)=[^*&]|Bearer [^*]" /tmp/DomoticzLinky_*.log'` → `0`, puis `Mode3=0` et suppression des fichiers `/tmp/DomoticzLinky_*.log`. Pas de rotation des jetons (Q2 : debug jamais activé en production).
- **Acceptation :** résultats booléens consignés (pas de sortie brute).

#### T5.4 - Documenter la version déployée
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `docs/ARCHITECTURE.md` § 5.4 (v2.7.0), `_docker/build_domoticz/README.md`.

### Phase 6 — Clôture — ⏳ Planifié
- ⚫ MAINa : ADR 007 `Acceptée` (déjà au Gate #1) vérifié ; plan `✅ Complété` ; `docs/plans/README.md` → **COMPLÉTÉ** ; backlog résiduel (D6, D7 hors harnais, D9 pickle, D10, D13, D14, D15) reporté dans la section « Suites » ci-dessous.

---

## 📊 Résumé par Agent

| Agent | Tâches | Livrable |
|---|---|---|
| 👤 | T0.1, T0.4, T1.5, T4.2, T5.3 | Merges, tag/release, contrôles runtime Domoticz |
| ⚫ MAINa | T0.2, T1.5, T1.6, Phase 6 | Plan/index, gates, clôture |
| 🔵 DEVon | T1.1, T1.2, T2.1, T3.2, T3.3, T3.4, T5.1 | Workflow + Renovate, dzVents S4, correctifs plugin |
| 🟢 QALvin | T0.4 (trace), T1.3, T1.6, T2.2, T3.1, T3.5, T5.2 | Validation CI/artefacts, harnais pytest + CI fork, revue dzVents |
| 🟣 DOCly | T0.3, T1.4, T2.3, T4.1, T5.4 | ADR 007, docs domotique + fork, CHANGELOG |

---

## 📍 Dépendances entre Phases

```
Phase 0 (prérequis, ADR 007 Proposée, U1-U3)        → Gate #1 (plan + ADR)
    ↓ GO
Phase 1 (S1 pin v2.6.1)   code → P1-#2 → QA → P1-#3 → doc → P1-#4
Phase 2 (S4 dzVents)      code → P2-#2 → QA → P2-#3 → doc → P2-#4     (indépendante de P1)
Phase 3 (S3+S2 fork)      harnais+xfail → code → P3-#2 → QA → P3-#3   (indépendante de P1/P2)
    ↓ GO
Phase 4 (docs fork + tag v2.7.0)                      → P4-#4
    ↓ GO (+ Phase 1 complétée)
Phase 5 (pin v2.7.0 + prod) code → P5-#2 → QA → P5-#3 → doc → P5-#4
    ↓ GO
Phase 6 (clôture)
```

---

## ✅ Critères de Succès Globaux

1. `build-domoticz.yml` : 0 référence `guillaumezin` / `refs/heads/master` ; 2 pins `ref: <sha40> # <tag>`.
2. Blob de l'artefact Linky = blob `plugin.py` du tag épinglé (v2.6.1 puis v2.7.0).
3. Renovate détecte les 2 dépendances ; la PR de montée v2.7.0 n'est **pas** auto-mergée.
4. CI du fork verte (`py_compile`, `ruff`, `pytest`), 0 `xfail` résiduel.
5. Aucun secret sentinelle dans les sorties capturées ; contrôle runtime `grep` → 0 (si réalisé).
6. Health check : 6 indicateurs, `Santé dzVents OK` en production, aucun PRM dans le dépôt.
7. Documentation alignée : ADR 007 `Acceptée`, § 5.4, README, rétrodoc fork, CHANGELOG, index des plans.

---

## ⚠️ Risques et retours arrière (annexe § 10)

| Risque | Parade |
|---|---|
| Regex Renovate ne détecte pas le pin | Preuve T1.6 ; montée manuelle toujours possible |
| Automerge global appliqué aux plugins | `packageRules` `automerge:false` en dernier ; vérifié en T5.1 |
| Masquage trop/pas assez large | Tests sentinelles + non-régression consentement |
| Régression S2 non couverte (1 seul PRM réel) | Tests D3 ; persistance inchangée → retour pin v2.6.1 en 1 ligne |
| U1/U2 infirmés | Seuils robustes aux deux cas ; repli `lastUpdate` > 36 h seul |
| Collision préfixe « Linky » | Q1 ; repli I3 (variable utilisateur) |
| Images `:<branche>` / `:merge` poussées par les validations | Accepté (≠ `latest`) ; nettoyage Docker Hub facultatif |
| Jetons déjà exposés par un debug passé | Écarté (Q2 : `Mode3` jamais activé en production) |

**Retours arrière :** S1 → `git revert` du commit workflow + build `master` (ou digest d'image précédent sur le NAS : `docker image ls --digests vzwingmadomatic/domoticz`) ; S2/S3 → pin `f3df2584ab398110eefe8d65df1b83d9a9d95395 # v2.6.1` ; S4 → `git revert` des 3 fichiers Lua + resynchronisation du montage NAS.

---

## 🔭 Suites (backlog hors périmètre)

D6 `except:` nus restants · D11 historique plafonné à 35 j (sans effet tant que `Mode2` ≤ 35) · D7 découpage du monolithe · D9 `pickle.loads` avant checksum (risque accepté) · D10 dépendance au proxy tiers RUSSANDOL · D13 Mode3 = 19 sans faux client · D14 jours fériés / préfixe `p` de Mode4 · D15 code mort · images `:merge` poussées par les PR `domotique`.

---

## 🚦 Journal des gates

| Gate | Date | Objet | Décision 👤 | Notes |
|---|---|---|---|---|
| #0 | 2026-11-25 | Choix de solution (14 décisions + Q1-Q6) | ✅ GO | Reco ARCos retenue ; ajustements : version 2.7.0, D11 backlog (`Mode2`=7), pas de rotation jetons (`Mode3` jamais activé), doc utilisateur des `Mode1`-`Mode6` ajoutée en T4.1. État initial revérifié (SHA v2.6.1/1.0.35 OK, PR #232 et fork#2 `MERGED`) |
| #1 | 2026-11-25 | Validation plan + ADR 007 `Proposée` | ✅ GO | Phase 0 complétée (U1 ✅, U2 ✅, U3 ❌) ; T2.1 ajusté (préfixe `'Linky'` sans espace, device réel nommé `Linky`) ; exécution séquentielle P1 → P2 → P3 ; séquence `xfail` phase 3 validée ; ADR 007 → `Acceptée` |
| P1-#2 | 2026-11-25 | Validation code phase 1 (T1.1, T1.2) | ✅ GO | 2 fichiers (+34/−5) ; 0 `guillaumezin`/`refs/heads/master`, 2 pins SHA ; YAML/JSON OK ; `renovate-config-validator@44.262.1` OK ; regex testée LF/CRLF ; code-review : 0 bloquant, 0 non bloquant |
| P1-#3 | 2026-11-25 | Validation tests phase 1 (T1.3) | ✅ GO | Run 45600293531 `success` ; blob `plugin.py` = `v2.6.1:plugin.py` ; 4 `*.py` deCONZ = tag 1.0.35 ; image `:linky_fork_pin` (≠ `latest`) ; T1.6 différée après merge. Volet fork de T1.4 reporté en T4.1 (une seule PR fork) |
