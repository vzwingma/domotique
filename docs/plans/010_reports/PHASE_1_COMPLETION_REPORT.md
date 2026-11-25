# Phase 1 : S1 — provenance CI épinglée (branche `ci/linky_fork_pin`)

**Plan :** `docs/plans/010_linky_suites.plan.md`
**Responsable Agent :** 🔵 DEVon (T1.1, T1.2) — T1.3 à T1.6 : autres agents, après gates
**Date Début :** 2026-11-25
**Date Fin :** TBD (section DEVon terminée le 2026-11-25 ; Gate P1-#2 en attente)
**Statut :** 🔄 EN_COURS — code DEVon livré, Gate P1-#2 en attente (pas de commit ni de push)

---

## 📝 Tâches

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
