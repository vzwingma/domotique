# Phase 3 : Clôture — corrections post-revue

**Plan :** `docs/plans/009_retrodoc_domoticzlinky.plan.md`
**Responsable Agent :** 🟣 DOCly
**Date Début :** 2026-11-25
**Date Fin :** 2026-11-25
**Statut :** ✅ COMPLÉTÉE — Gate #4 ✅ GO (2026-11-25)

---

## 📝 Tâches

### T3.1 - Corriger les écarts relevés (E1-E7)

**Statut :** ✅ DONE (modifications chirurgicales de 4 fichiers `.md` ; aucun fichier de code ; aucun commit, aucun changement de branche)

**Dépôts / branches (non modifiés par DOCly) :** fork `DomoticzLinky` sur `feat/fork_and_retrodoc` (HEAD `f3df258`, tag `v2.6.1`) ; `domotique` sur `feat/add_linky` (HEAD `1ae86c9`). Les modifications sont **dans l'arbre de travail, non commitées** (commits à la charge de ⚫ MAINa).

#### Preuves par écart

| Id | Fichier | Avant (résumé) | Après (résumé) | Source vérifiée |
|---|---|---|---|---|
| E1 | `domotique/_docker/build_domoticz/README.md` (note sous « Variables ») | « En production, les scripts sont embarqués dans l'image (pas de volume)… » | « En production, le compose NAS (`_docker/envs/nas/domotique-compose.yml`) **monte** ce dossier (`/volume1/home/vinz/domoticz/scripts/dzVents` → `/opt/domoticz/userdata/scripts/dzVents/generated_scripts`) : les scripts de l'image sont alors remplacés par ceux de l'hôte. » Cohérent avec l'avertissement `userdata` (« …ne monte que `domoticz.db` (et `scripts/dzVents`) ») | `_docker/envs/nas/domotique-compose.yml`, service `domoticz`, `volumes:` : `…/domoticz/scripts/dzVents:/opt/domoticz/userdata/scripts/dzVents/generated_scripts` |
| E2 | `domotique/README.md` § Déploiement rapide | « Éditer domotique-compose.yml et renseigner… MAC, PASSWD, AUTHAPI, PASSWDAPI » | Variables **déclarées dans `stack.env`**, lu via `env_file` par le service `tydom-bridge` du compose NAS, et non dans `domotique-compose.yml` ; précision : `stack.env` les référence en placeholders `${NOM}` → valeurs à fournir par l'environnement de déploiement ou à renseigner dans `stack.env` sans le commiter. Aucune valeur recopiée | `_docker/envs/nas/domotique-compose.yml` (`tydom-bridge` → `env_file: - stack.env`, aucun `environment:` MAC/PASSWD…) ; `_docker/envs/nas/stack.env` (grep **noms** : `MAC=${MAC}`, `PASSWD=${PASSWD}`, `AUTHAPI=${AUTHAPI}`, `PASSWDAPI=${PASSWDAPI}` — placeholders, pas de secret) |
| E3 | — | — | **Aucune édition** (requalifié par QALvin) : 0 lien en 404 ; liens absolus OK. La cible « `docs/ARCHITECTURE.md` § 5.4 » (readme du fork § « Usage », RETRO § 15) n'est visible sur `master` qu'**après merge de `feat/add_linky`** (PR prévue à la clôture) → à revérifier après merge | Revue QA PHASE_2 (E3) |
| E4 | `DomoticzLinky/docs/RETROCONCEPTION.md` § 1 (tableau « Identité et provenance ») | « Commit analysé = `1ef6adf` = `HEAD` = `origin/master` du fork au 2026-11-25 » ; « le clone local ne contient aucun tag au-delà de `2.3.8` » | « Code analysé : commit `1ef6adf` (v2.6.1), identique à l'upstream `guillaumezin/DomoticzLinky` (`master`). `plugin.py` est **inchangé** dans le tag `v2.6.1` du fork (commit documentaire `f3df258`) » ; ligne « Tag » : `v2.6.1` sur `f3df258`, code de référence identifié par `1ef6adf`. Plus aucune référence à `HEAD` ni à « 2.3.8 ». **Cohérence induite** : l'avertissement « Écart fork ↔ upstream non vérifié » (même § 1) contredisait la nouvelle formulation → reformulé en « Upstream non épinglé » (identité = constat transmis par le pilote, non recomparé ; l'upstream `master` non épinglé peut dériver) | Énoncé de tâche ; revue QA PHASE_2 #30 (`git diff 1ef6adf HEAD -- plugin.py` vide, `origin/master` = `f3df258`, tag `v2.6.1` → `f3df258`) ; `.git/packed-refs` du fork (`1ef6adf` = `origin/master` au clone) |
| E5 | RETRO § 2.1 | « …délèguent **tous** à une instance unique `_plugin` » | « …délèguent à `_plugin`, **à l'exception de `onDeviceAdded`, `onDeviceModified` et `onDeviceRemoved`**, callbacks **vides** (simple `global _plugin`, aucune délégation) » | `plugin.py` fonctions de module l. 2389-2399 : corps = `global _plugin` seul ; `onStart/onStop/onConnect/onMessage/onCommand/onNotification/onDisconnect/onHeartbeat` appellent `_plugin.<méthode>` |
| E6 | `DomoticzLinky/readme.md` | 4 lignes vides en tête (l. 1-4) avant « # Fork vzwingma / notes techniques » | Titre en ligne 1 ; **rien d'autre modifié**. Fins de ligne préservées : 446 lignes / 446 CRLF (avant : 450 / 450) | grep `\r$` et `^` (comptes) ; vue des 8 premières lignes |
| E7 | RETRO § 5.2 (table des transitions) | `nextcons` : sans la propagation d'échec ; `parseaccesstoken` : pas de ligne pour `authorization_pending` + JSON invalide | (a) Ligne `nextcons` : « si `bHasAFail` : `bGlobalHasAFail = True` puis `bHasAFail = False` (propagation de l'échec du PRM précédent) ». (b) Nouvelle ligne `parseaccesstoken` : `authorization_pending` avec corps non JSON (`ValueError`) → message « Les données reçues ne sont pas du JSON », retour `retry` (et non `pending`), `setNextConnectionForLater(iInterval)` → `retry` ; ligne `retry` existante précisée (« Pas assez de données reçue » / « Pas de données reçue » / autre statut) | `plugin.py` `handleConnection()` bloc `nextcons` (l. 1932-1939 : `if self.bHasAFail: self.bGlobalHasAFail = True; self.bHasAFail = False`) ; `parseAccessToken()` l. 558-570 (`authorization_pending` → `json.loads` → `except ValueError` → `showSimpleStepError(...)` → `return "retry"`), retour par défaut `"retry"` l. 602 |

#### Vérifications

| Contrôle | Commande / méthode | Résultat |
|---|---|---|
| Aucun fichier de code touché | seuls 4 `.md` édités (`README.md`, `_docker/build_domoticz/README.md`, `RETROCONCEPTION.md`, `readme.md` du fork) + ce rapport | ✅ |
| Fins de ligne CRLF préservées | grep `\r$` vs `^` (comptes) : `readme.md` 446/446 ; `RETROCONCEPTION.md` 557/557 ; `README.md` 135/135 (avant édition E2 : 134 ; +1 ligne de commentaire dans le bloc bash) ; build `README.md` 97/97 ; aucune ligne `[^\r]$` | ✅ |
| Ancres internes de `RETROCONCEPTION.md` | aucun titre (`##`/`###`) modifié ; les éditions portent sur des lignes de tableau/paragraphe ; l'unique lien interne ajouté/conservé (`#15-intégration-dans-le-projet-domotique`, `#5-machine-à-états-de-connexion`) pointe vers des titres inchangés | ✅ (33/33 ancres inchangées) |
| Liens relatifs | aucun lien ajouté ni modifié (E1/E2/E4-E7 = texte) | ✅ |
| Secret | `stack.env` lu pour les **noms** seuls (valeurs = placeholders `${…}`), rien recopié | ✅ |
| `git diff --stat` / `git status` | **non exécutable** dans cette session (outils view/grep/edit/create uniquement, pas de shell) → à lancer par ⚫ MAINa avant commit : attendu = 4 `.md` modifiés + rapport/plan | ⚠️ non exécuté |

---

## 📊 Synthèse de Phase

**Tâches complétées :** 1/1
**Critères de réussite :**
- ✅ Écarts phase 2 corrigés : E1, E2, E4, E5, E6, E7 corrigés ; E3 sans édition (à revérifier après merge de `feat/add_linky`)
- ⏳ Plan et index `docs/plans/README.md` au statut final : non traité par DOCly dans cette tâche (consigne limitée à T3.1) → à faire à la clôture (Gate #4)

**Bloqueurs :** Aucun
**Prochaine phase :** Clôture après validation 👤 (Gate #4)
