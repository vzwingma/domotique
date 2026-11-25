# Phase 5 : Montée de pin v2.7.0 et vérification production (`domotique`)

**Plan :** `docs/plans/010_linky_suites.plan.md`
**Responsable Agent :** 🔵 DEVon (T5.1), 🟢 QALvin (T5.2), 👤 (T5.3), 🟣 DOCly (T5.4)
**Date Début :** 2026-11-25
**Date Fin :** 2026-11-25
**Statut :** ✅ COMPLÉTÉ — T5.1-T5.4 ✅ ; Gates P5-#2, P5-#3, P5-#4 GO

---

## 📝 Tâches

### T5.1 - Monter le pin (🔵 DEVon)

**Statut :** ✅ DONE — Gate P5-#2 GO

- Renovate : run forcé via le Dependency Dashboard #139 (12:35Z, après la release 12:29Z) ; le dashboard liste toujours `vzwingma/DomoticzLinky v2.6.1` sans PR v2.7.0 (cache des tags côté Renovate) → **montée manuelle** autorisée par le critère d'acceptation.
- Branche `ci/linky_v2.7.0_pin` (le nom `ci/linky_v2.7.0` était déjà utilisé et mergé via #236), commit `6d75005`, PR #237.
- `.github/workflows/build-domoticz.yml` ligne 30 (+1/−1) : `ref: a7b232042a0ac725390583416043e327882510d5 # v2.7.0`.

**Preuves :**
- `gh api repos/vzwingma/DomoticzLinky/git/ref/tags/v2.7.0 --jq .object.sha` → `a7b232042a0ac725390583416043e327882510d5` (= pin).
- Motif du custom manager Renovate appliqué au fichier → 2 correspondances : `vzwingma/DomoticzLinky` `a7b2320…` `v2.7.0` ; `Smanar/Domoticz-deCONZ` `95b8f8b…` `1.0.35`.
- Fins de ligne CRLF préservées (128/128 avant et après).
- Revue : relecture MAINa (diff d'une ligne).

### T5.2 - Valider le build v2.7.0 (🟢 QALvin)

**Statut :** ✅ DONE — Gate P5-#3 GO

| Contrôle | Résultat | Preuve |
|---|---|---|
| Run PR #237 | ✅ | run 45616307786 `success` (3 jobs), commit `6d75005` |
| Artefact Linky | ✅ | `git hash-object --no-filters plugin.py` = `7317790b9033f2c6e13be43270423710dd8f34c2` = `v2.7.0:plugin.py` |
| Version / provenance | ✅ | `version="2.7.0"` ; checkout `a7b2320` (« Merge pull request #3 from vzwingma/fix/v2.7.0 ») ; step « Trace Linky provenance » ✅ |
| deCONZ inchangé | ✅ | 4/4 `*.py` (`API_KEY`, `fonctions`, `plugin`, `widget`) = blobs du tag `1.0.35` |
| Image / automerge | ✅ | image PR `vzwingmadomatic/domoticz:merge` (≠ `latest`) ; `autoMergeRequest` = null |
| Autres checks PR | ✅ | CodeQL, SonarCloud, GitGuardian, tests unitaires, build httpd |

Après merge par 👤 : #237 → `79398a7` ; run `master` 45617174637 `success` → `vzwingmadomatic/domoticz:latest`.

**Limites :** contenu du Step Summary non lisible via `gh` (preuve équivalente : SHA checkout + version dans l'artefact) ; tag `:merge` partagé entre PR (mutable, jamais `latest`).

### T5.3 - Vérifier en production (👤)

**Statut :** ✅ DONE — déclaré correct par 👤 après redéploiement de `latest`

| Contrôle | Résultat |
|---|---|
| Plugin Linky 2.7.0 au démarrage | ✅ |
| Aucune `AttributeError` | ✅ |
| Collecte réussie | ✅ |
| Health check Linky OK | ✅ |

Résultats booléens uniquement (aucune sortie brute consignée, PRM présent dans les logs Domoticz).

### T5.4 - Documenter la version déployée (🟣 DOCly)

**Statut :** ✅ DONE (non commité au moment du gate P5-#4)

| Dépôt | Fichier | Changement |
|---|---|---|
| `domotique` | `docs/ARCHITECTURE.md` § 5.4 | tableau → v2.7.0 / `a7b2320…` ; schéma `@ v2.7.0` ; « Provenance épinglée » : historique du pin (`v2.6.1` initial → `v2.7.0` depuis le 2026-11-25, montée manuelle) + lien `CHANGELOG.md` du fork |
| `domotique` | `_docker/build_domoticz/README.md` | ligne Linky : SHA complet `a7b23204…` + tag `v2.7.0` ; remarque « pin initial `v2.6.1` » ; procédure de montée inchangée |
| `domotique` | `README.md` (l. 78) | « SHA du tag `v2.7.0` » (hors liste initiale, version courante) |
| fork | `readme.md` (l. 4) | « `domotique` épingle la v2.7.0 (SHA `a7b2320`) depuis le 2026-11-25 » |
| fork | `docs/RETROCONCEPTION.md` (§ 1 l. 45/51, § 15 l. 556) | formulations futures passées à l'accompli ; SHA `a7b2320` du tag |

**Preuves :**
- `git diff --stat` : `domotique` 3 docs (+ plan/rapports MAINa) ; fork 2 fichiers (+4/−4) ; `CHANGELOG.md` du fork inchangé.
- Lignes ajoutées contenant un nombre à 14 chiffres : **0** (les exemples fictifs préexistants du readme du fork ne sont pas touchés).
- `rg "2\.6\.1|f3df258"` dans les docs vivantes : uniquement contexte historique (`ARCHITECTURE.md` l. 370, `build_domoticz/README.md` l. 23, ADR 007).
- « `a7b2320` = merge de `fix/v2.7.0` » confirmé par le log de checkout T5.2 (« Merge pull request #3 from vzwingma/fix/v2.7.0 »).

**Note :** ADR 007 l. 107 et 123 décrivent la montée v2.7.0 au futur ; non modifiées (un ADR décrit la décision à sa date).

---

## 📊 Synthèse de Phase

**Tâches complétées :** 4/4
**Critères de réussite :**
- ✅ PR manuelle **non auto-mergée** ; diff d'une ligne
- ✅ Artefact = `v2.7.0:plugin.py` ; plugin 2.7.0 opérationnel en production
- ✅ Documentation de la version déployée (T5.4)

**Bloqueurs :** Aucun
**Prochaine phase :** Phase 6 (clôture).
