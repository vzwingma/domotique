# Phase 1 : S1 — provenance CI épinglée (branche `ci/linky_fork_pin`)

**Plan :** `docs/plans/010_linky_suites.plan.md`
**Responsable Agent :** 🔵 DEVon (T1.1, T1.2) — T1.3 à T1.6 : autres agents, après gates
**Date Début :** 2026-11-25
**Date Fin :** TBD (section DEVon terminée le 2026-11-25 ; Gate P1-#2 en attente)
**Statut :** 🔄 EN_COURS — code DEVon livré, Gate P1-#2 en attente (pas de commit ni de push)

---

## 📝 Tâches

> Sections par agent : 🔵 DEVon (T1.1, T1.2), 🟢 QALvin (T1.3, T1.6), 🟣 DOCly (T1.4, en fin de fichier).
### T1.1 - Épingler les plugins dans le workflow

**Statut :** ✅ DONE

**Fichiers créés / modifiés :**
- `.github/workflows/build-domoticz.yml` — jobs `download-linky` (fork `vzwingma/DomoticzLinky`, `ref: f3df2584ab398110eefe8d65df1b83d9a9d95395 # v2.6.1`) et `download-deconz` (`ref: 95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a # 1.0.35`) ; `ref:` immédiatement après `repository:` ; étapes « Trace Linky provenance » / « Trace deCONZ provenance » (`git rev-parse HEAD` + ligne `version=` de `plugin.py` → `$GITHUB_STEP_SUMMARY`) ; artefacts `linky-plugin` (`${{ github.workspace }}/plugin.py`) et `deconz-plugin` (`${{ github.workspace }}/*.py`) avec `if-no-files-found: error`. Noms d'artefacts et job `build-push-domoticz` inchangés.

**Résultats (preuves) — contrôle statique (aucun run CI exécuté ici ; T1.3 = QALvin) :**
- SHA Linky = commit du tag : ✅ `git -C ..\DomoticzLinky rev-list -n1 v2.6.1` → `f3df2584ab398110eefe8d65df1b83d9a9d95395`
- SHA deCONZ = tag : ✅ `git ls-remote --tags https://github.com/Smanar/Domoticz-deCONZ 1.0.35 "1.0.35^{}"` → `95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a refs/tags/1.0.35` (tag léger : aucune ligne `^{}`, SHA = commit)
- Plus d'upstream ni de `master` : ✅ `rg -n "guillaumezin|refs/heads/master" .github/workflows/build-domoticz.yml` → 0 résultat (exit 1)
- 2 pins : ✅ `rg -n "ref: [0-9a-f]{40} # " .github/workflows/build-domoticz.yml` → 2 lignes (l. 30 Linky, l. 55 deCONZ)
- YAML valide : ✅ `python -c "import yaml; yaml.safe_load(...)"` → `YAML OK ['download-linky', 'download-deconz', 'build-push-domoticz']` ; étapes Linky : checkout / Trace Linky provenance / Upload ; deCONZ : idem
- `grep -m1 -o 'version="[^"]*"' plugin.py` cohérent avec le contenu des tags : ✅ `v2.6.1:plugin.py` → `version="2.6.1"` ; deCONZ `95b8f8b:plugin.py` (via raw.githubusercontent) → `version="1.0.35"`. Le tag deCONZ contient `API_KEY.py`, `fonctions.py`, `plugin.py`, `widget.py` (`gh api .../git/trees/1.0.35`) : le glob `*.py` reste valide.

**Notes :**
- Le step de traçabilité s'exécute dans le workspace du checkout (répertoire par défaut, `git rev-parse HEAD` et `plugin.py` à la racine).
- Fins de ligne : le fichier de travail est en CRLF (autocrlf) sur toute sa longueur (128 CRLF / 128 LF), le blob `HEAD` est en LF : pas de mélange introduit.

---

### T1.2 - Configurer Renovate pour les pins

**Statut :** ✅ DONE

**Fichiers créés / modifiés :**
- `renovate.json` — ajout de `customManagers` (regex, `managerFilePatterns: ["/^\\.github/workflows/build-domoticz\\.yml$/"]`, `datasourceTemplate: github-tags`, captures `depName` / `currentDigest` / `currentValue`) ; `packageRules` : règle existante conservée, nouvelle règle `{ matchManagers: ["custom.regex"], matchDepNames: [Linky, deCONZ], automerge: false }` ajoutée **en dernière position**. `extends`, `dependencyDashboard` inchangés.

**Résultats (preuves) :**
- JSON valide : ✅ `python -c "json.load(...)"` → `JSON OK ['$schema','extends','dependencyDashboard','customManagers','packageRules']` ; dernière règle = `automerge: False` sur `custom.regex`.
- Validateur Renovate : ✅ `npx --yes --package renovate@44.262.1 -- renovate-config-validator renovate.json` → `INFO: Config validated successfully against 1 file(s)`.
- Regex testée sur le workflow modifié (node, regex lue depuis `renovate.json`, flags `gm`) : ✅ 2 extractions, motif de fichier valide pour `.github/workflows/build-domoticz.yml`, résultat identique en LF et CRLF :
  - `{"depName":"vzwingma/DomoticzLinky","currentDigest":"f3df2584ab398110eefe8d65df1b83d9a9d95395","currentValue":"v2.6.1"}`
  - `{"depName":"Smanar/Domoticz-deCONZ","currentDigest":"95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a","currentValue":"1.0.35"}`
- `git diff --stat` : ✅ 2 fichiers (`build-domoticz.yml` +17/−5, `renovate.json` +17) — le rapport est un fichier non suivi.

**Notes :**
- **Choix `managerFilePatterns`** (Renovate ≥ v40, remplace `fileMatch`) retenu car le validateur le plus récent (44.262.1) l'accepte. Un premier `npx ... renovate-config-validator` sans version fixée a utilisé un cache npx ancien (renovate 37.440.7) et a rejeté `managerFilePatterns` (« Custom Manager contains disallowed fields »). Conséquence : ce cache local est obsolète ; l'application Renovate hébergée (GitHub App) est à jour, mais si l'instance utilisée était < v40, il faudrait le repli `fileMatch` (annexe § 1.2). Preuve réelle : T1.6 (Dependency Dashboard).
- Preuve que la règle `automerge:false` l'emporte réellement (ordre des `packageRules`) : différée (T1.6 / T5.1), non simulée ici.

---

## 📊 Synthèse de Phase (section DEVon)

**Tâches complétées :** 2/2 (T1.1, T1.2 — périmètre DEVon). T1.3 à T1.6 non démarrées (hors périmètre de cet appel).
**Critères de réussite (DEVon) :**
- ✅ Workflow épinglé (fork Linky `v2.6.1`, deCONZ `1.0.35`), traçabilité, artefacts stricts — contrôle statique ; run CI non exécuté.
- ✅ Config Renovate valide (v44.262.1) et regex démontrée sur les 2 dépendances.
- ⏳ Détection réelle par Renovate (Dependency Dashboard) : preuve différée T1.6.

**Bloqueurs :** Aucun
**❓ Questions pour 👤 :** Aucune bloquante. À confirmer : version de l'application Renovate hébergée ≥ v40 (sinon repli `fileMatch`).
**Prochaine phase :** Gate P1-#2 (MAINa) puis 🟢 QALvin T1.3 (`workflow_dispatch` sur la branche, comparaison d'octets des artefacts). Phase 2 après validation 👤.

---

## 🟢 Section QALvin — T1.3 Valider le build épinglé

**Statut :** ✅ DONE (5/5 contrôles ✅) — Gate P1-#2 = GO (2026-11-25)
**Run CI :** https://github.com/vzwingma/domotique/actions/runs/45600293531 (`workflow_dispatch`, branche `ci/linky_fork_pin`, commit `433e146d00a890ac838b8f8ca59b6c6e2ff71561`, conclusion `success`)
**Périmètre :** lecture seule (aucune modification du code de production ni de la doc, pas de commit/push).

| # | Contrôle | Commande | Résultat | |
|---|----------|----------|----------|---|
| 1 | Run `success` | `gh workflow run build-domoticz.yml --repo vzwingma/domotique --ref ci/linky_fork_pin` ; `gh run watch 45600293531 --exit-status` ; `gh run view 45600293531 --json conclusion,status` | exit 0 ; `conclusion: success`, `status: completed` ; 3 jobs ✓ : Download Linky Script, Download DeCONZ Script, Build and Push ARM Docker Image (1 m 41 s) | ✅ |
| 2 | Provenance (SHA + version) | `gh run view 45600293531 --log` filtré sur « Trace » / « Checkout » ; `Select-String 'version="…"'` sur les artefacts | Étapes « Trace Linky provenance » et « Trace deCONZ provenance » exécutées ✓. Checkout Linky : `vzwingma/DomoticzLinky`, `git checkout … f3df2584ab398110eefe8d65df1b83d9a9d95395`, `rev-parse HEAD` = `f3df2584…`. Checkout deCONZ : `git checkout … 95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a`, `rev-parse HEAD` = `95b8f8ba…`. `version="2.6.1"` (artefact Linky), `version="1.0.35"` (artefact deCONZ). | ✅ (voir note 1) |
| 3 | Artefact `linky-plugin` | `gh run download 45600293531 --repo vzwingma/domotique -n linky-plugin -D $env:TEMP\linky` ; `git hash-object --no-filters …\plugin.py` ; `git -C <fork> rev-parse v2.6.1:plugin.py` | 1 seul fichier `plugin.py` (123 479 octets). Blob artefact = `6767ab67c25131519cdb529d8df407191925c1a1` = blob `v2.6.1:plugin.py` du fork (identique) ; `git rev-list -n1 v2.6.1` = `f3df2584ab398110eefe8d65df1b83d9a9d95395` | ✅ |
| 4 | Artefact `deconz-plugin` | `gh run download 45600293531 -n deconz-plugin -D $env:TEMP\deconz` ; `git hash-object --no-filters` par fichier ; `gh api repos/Smanar/Domoticz-deCONZ/git/trees/95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a` (entrées `*.py`) | 4 fichiers, blobs identiques au tag 1.0.35 : `API_KEY.py` `d94e8290…108a` ; `fonctions.py` `8a508f9c…ee76` ; `plugin.py` `5833061b…7625` ; `widget.py` `d2dc20ba…008f` (4/4 type `blob`, ensembles égaux, pas de fichier en trop/manquant) | ✅ |
| 5 | Tag d'image ≠ `latest` | logs étapes « Get image metadata » / « Build and Push ARM Docker Image » | `VERSION` dérivée de `refs/heads/ci/linky_fork_pin` → `DOCKER_IMAGE_TAG=vzwingmadomatic/domoticz:linky_fork_pin` ; commande `docker buildx build … --tag vzwingmadomatic/domoticz:linky_fork_pin --output type=image,push=true` ✓ ; aucun tag `latest` (la règle `master → latest` ne s'applique pas) | ✅ (voir note 2) |
| — | Nettoyage | `Remove-Item -Recurse -Force $env:TEMP\linky,$env:TEMP\deconz` ; `Test-Path` | `False` / `False` | ✅ |

**Notes :**
1. Les étapes « Trace … provenance » écrivent dans `$GITHUB_STEP_SUMMARY` (et non dans le log) : leur sortie n'est pas exposée par `gh run view --log` ni par l'API REST. La preuve est donc reconstituée par des éléments équivalents et indépendants : exécution ✓ de l'étape, SHA exact du `git checkout`/`rev-parse` dans le log du checkout, et `version="…"` lue dans le contenu réel des artefacts. La lecture visuelle du Step Summary (onglet Summary du run) reste possible à titre de confirmation, non bloquante.
2. L'étape « Get image metadata » est un script bash (pas `docker/metadata-action`) ; le tag est calculé à partir du nom de branche. Le tag `linky_fork_pin` est une image jetable poussée sur Docker Hub (non nettoyée ici : hors périmètre ; suppression éventuelle par 👤).
3. Régression : la détection d'écart d'octets repose sur une égalité d'identifiants de blob git (SHA-1) — aucune différence de fin de ligne (hash `--no-filters`).

### T1.6 - Preuve Renovate (différée)

**Statut :** ⏳ DIFFÉRÉ après merge de `ci/linky_fork_pin` sur `master`.
- `gh issue list --repo vzwingma/domotique --search "Dependency Dashboard" --state open` → #139 « Dependency Dashboard » (dernière mise à jour 2026-11-25T08:27:35Z, scan de `master`).
- `gh issue view 139` : la section `.github/workflows/build-domoticz.yml (9)` ne liste que les dépendances `github-actions` ; `vzwingma/DomoticzLinky v2.6.1` et `Smanar/Domoticz-deCONZ 1.0.35` **absents** → attendu (Renovate ne scanne pas la branche). À re-vérifier après merge (si toujours absents : retour T1.2, regex / `managerFilePatterns`).
- Point d'attention : le dashboard affiche « Config Migration Needed » (migration de config proposée par Renovate sur `master`) ; à examiner par 👤/MAINa, sans lien démontré avec ce changement.

**Synthèse QALvin :** 5/5 contrôles ✅, T1.6 différée. Aucun bloqueur.

---

## 🟣 Section DOCly — T1.4 Documenter la provenance épinglée

**Statut :** ✅ DONE — Gate P1-#3 = GO (2026-11-25). Pas de commit ni de push ; branche `ci/linky_fork_pin` inchangée.

**Fichiers modifiés (dépôt `domotique` uniquement) :**
- `docs/ARCHITECTURE.md` § 5.4 : tableau « Source embarquée » (Linky : fork `vzwingma/DomoticzLinky` épinglé `f3df258…` / `v2.6.1` ; deCONZ : `95b8f8b…` / `1.0.35`) ; schéma de chaîne (sources épinglées par SHA) ; puce « Provenance non épinglée » remplacée par « Provenance épinglée » (lien [ADR 007](../../adr/007-plugins-domoticz-provenance-epinglee.md), traçabilité Step Summary, `if-no-files-found: error`, mention historique « avant l'ADR 007 ») ; nouvelle puce « Mise à jour des plugins » (Renovate, **sans automerge**, lien vers la procédure).
- `_docker/build_domoticz/README.md` : tableau « Provenance des plugins » (dépôt, `ref`, tag) ; paragraphe **Reproductibilité** ; nouvelle sous-section « Montée de version d'un plugin » (tag publié → PR Renovate ou modification manuelle `ref: <sha> # <tag>` avec `git rev-list -n1 <tag>` → revue → merge ; **retour arrière** = revert / re-pin) ; avertissement « non reproductible » supprimé.
- `README.md` (racine) : ligne composant Linky — fork épinglé sur le tag `v2.6.1`, mises à jour par PR Renovate revue manuellement, lien ADR 007.
- Autres docs vérifiées (hors `docs/plans/`, `docs/adr/`) : `deCONZ/README.md`, `domoticz/README.md`, `.github/copilot-instructions.md`, `docs/RETROCONCEPTION_tydom-bridge.md` ne décrivent pas l'état de provenance → aucune modification.

**Hors périmètre (reporté) :** fork `DomoticzLinky/docs/RETROCONCEPTION.md` § 1 (avertissement « Upstream non épinglé ») et § 15 → **T4.1** ; le fork n'a pas été touché.

**Vérifications :**
- Acceptation : `rg -n "non épingl|guillaumezin/DomoticzLinky.*master" README.md docs/ARCHITECTURE.md _docker/build_domoticz/README.md` → **0 occurrence**.
- SHA/tags documentés = ceux du workflow et du rapport T1.1 (`f3df2584ab398110eefe8d65df1b83d9a9d95395` / `v2.6.1` ; `95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a` / `1.0.35`) ; preuve QA : run [45600293531](https://github.com/vzwingma/domotique/actions/runs/45600293531).
- Liens relatifs : `docs/adr/007-plugins-domoticz-provenance-epinglee.md`, `renovate.json`, `.github/workflows/build-domoticz.yml`, `_docker/build_domoticz/README.md`, ancres `#54-plugins-python-domoticz-linky-deconz` et `#montée-de-version-dun-plugin` → cibles existantes.
- Aucun PRM, token ni sortie brute dans les ajouts.

**Notes :**
- Les fichiers de doc sont en attente de commit (à inclure dans la PR `ci/linky_fork_pin`, T1.5).
- Le détail « Dependency Dashboard liste les 2 dépendances » reste à prouver en T1.6 après merge ; la doc affirme la détection par Renovate selon la config (non encore observée).
