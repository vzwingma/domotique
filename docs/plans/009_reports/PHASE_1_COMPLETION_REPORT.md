# Phase 1 : Rédaction de la rétrodoc et des README

**Plan :** `docs/plans/009_retrodoc_domoticzlinky.plan.md`
**Responsable Agent :** 🟣 DOCly
**Date Début :** 2026-11-25
**Date Fin :** 2026-11-25
**Statut :** ✅ COMPLÉTÉE — validation 👤 en attente (Gate #2) — 2 écarts à signaler (voir « Notes »)

---

## 📝 Tâches

### T1.1 - Créer la rétrodocumentation technique du plugin

**Statut :** ✅ COMPLÉTÉE (⚠️ emplacement : racine du fork, et non `docs/`)

- **Fichier :** `DomoticzLinky/RETROCONCEPTION.md` (nouveau, ≈ 54 Ko, français, LF).
- **Contenu :** 16 sections du plan ; diagramme d'états en bloc ```plantuml``` + table des transitions (§ 5) ; tableau de dette D1–D16 avec gravité (§ 14) + liste des corrections aux faits ARCos ; renvoi vers `https://github.com/vzwingma/domotique/blob/master/docs/ARCHITECTURE.md` (§ 15, branche `master` vérifiée dans `.git` de `domotique`).
- **Références :** noms de fonctions + v2.6.1 + SHA `1ef6adf` ; numéros de ligne indicatifs seulement. Statut de maintenance écrit tel que décidé par 👤.
- **Écart :** le dossier `DomoticzLinky/docs/` n'existe pas et les outils de l'agent (`create`, `edit`) ne créent pas de répertoire (pas de shell). Le fichier a donc été créé à la **racine** du fork. Tous les liens (readme du fork, `ARCHITECTURE.md`, README `domotique`, README de build) pointent vers cet emplacement réel et fonctionnent. Déplacement vers `docs/` possible ensuite (voir « Questions »).

### T1.2 - Ajouter la section « Fork / notes techniques » au readme du fork

**Statut :** ✅ COMPLÉTÉE

- **Fichier :** `DomoticzLinky/readme.md` : section « Fork vzwingma / notes techniques » (FR + 1 note EN) insérée juste avant `# Participer aux frais d'hébergement…`. Statut de maintenance, usage dans `vzwingma/domotique` (précision : la CI consomme encore l'upstream), lien relatif `RETROCONCEPTION.md`.
- Le reste du readme est inchangé ; la modification locale existante (bandeau « non maintenu » retiré, lignes vides de tête) est **conservée**. Fins de ligne CRLF préservées (aucune ligne sans `\r` détectée).

### T1.3 - Documenter les plugins Python dans l'architecture

**Statut :** ✅ COMPLÉTÉE

- **Fichier :** `domotique/docs/ARCHITECTURE.md` : nouvelle **§ 5.4 « Plugins Python Domoticz (Linky, deCONZ) »** (tableau des plugins, chaîne CI → Dockerfile → image → compose, points d'attention : provenance non épinglée, proxy Enedis tiers, persistance `domoticz.db`, plateforme `linux/arm/v7`, deCONZ sur l'hôte Pi, absence de lien dzVents, supervision) ; ligne ajoutée au tableau « Intégrations externes » (§ 1.2) ; date passée à « novembre 2026 ». Lien vers la rétrodoc du fork (`https://github.com/vzwingma/DomoticzLinky/blob/master/RETROCONCEPTION.md`).

### T1.4 - Mettre à jour les README de `domotique`

**Statut :** ✅ COMPLÉTÉE

- `domotique/README.md` : ligne « Plugin Linky » dans le tableau Composants (liens fork + rétrodoc + § 5.4) ; deux liens ajoutés dans « Documentation » ; déploiement rapide corrigé (`_docker/envs/nas`) ; mention **Watchtower** corrigée (absente des composes versionnés).
- `domotique/_docker/build_domoticz/README.md` : section « Provenance des plugins » (upstream `master` non épinglé, deCONZ idem, fork non consommé) ; **plateforme corrigée** (CI = `linux/arm/v7`, exemples arm64 signalés) ; **avertissement** sur le montage de tout `userdata` qui masque `plugins/` ; section Compose corrigée (`envs/nas` / `envs/pi`, pas de `_docker/domotique-compose.yml`, pas de Watchtower).

---

## 🔍 Preuves

### Fichiers touchés (aucun fichier de code)

| Dépôt | Fichier | Nature |
|---|---|---|
| `DomoticzLinky` | `RETROCONCEPTION.md` | nouveau (doc) |
| `DomoticzLinky` | `readme.md` | modifié (section en tête) |
| `domotique` | `docs/ARCHITECTURE.md` | modifié |
| `domotique` | `README.md` | modifié |
| `domotique` | `_docker/build_domoticz/README.md` | modifié |
| `domotique` | `docs/plans/009_reports/PHASE_1_COMPLETION_REPORT.md` | modifié (ce rapport) |
| `domotique` | `docs/plans/009_reports/PHASE_1_COMPLETION_REPORT.new.md` | ⚠️ **fichier parasite** créé par erreur (contenu « placeholder ») — **à supprimer** |

Non touchés : `plugin.py`, workflows, `Dockerfile`, composes, scripts dzVents, plan 009.

### `git --no-pager diff --stat` et `git status --short`

**Non exécutés** : l'agent DOCly ne dispose pas de shell dans cette session (outils `view` / `create` / `edit` / `grep` / `glob` uniquement). Aucune sortie n'est fabriquée. Commandes à lancer par ⚫ MAINa (résultat attendu : aucun fichier `.py`, `.yml`, `Dockerfile` ni `.lua` modifié ; `plugin.py` inchangé) :

```bash
cd C:\Users\vzwingma\IdeaProjects\domotique-workspace\DomoticzLinky && git --no-pager diff --stat && git status --short
cd C:\Users\vzwingma\IdeaProjects\domotique-workspace\domotique && git --no-pager diff --stat && git status --short
```

Attendu — fork : ` M readme.md` (+ la modification locale préexistante, déjà dans cette même diff) et `?? RETROCONCEPTION.md` ; domotique : ` M README.md`, ` M _docker/build_domoticz/README.md`, ` M docs/ARCHITECTURE.md`, ` M docs/plans/009_reports/PHASE_1_COMPLETION_REPORT.md`, `?? docs/plans/009_reports/PHASE_1_COMPLETION_REPORT.new.md` (à supprimer) et les éventuels fichiers de plan déjà non commités.

### Liens vérifiés (existence des cibles locales, par `glob`)

- ✅ `DomoticzLinky/RETROCONCEPTION.md`, `DomoticzLinky/readme.md`
- ✅ `domotique/docs/ARCHITECTURE.md` (ancre `#54-plugins-python-domoticz-linky-deconz`), `deCONZ/README.md`, `_docker/build_domoticz/README.md`, `docs/Retroconception.md`, `docs/Orchestration.md`, `.github/workflows/build-domoticz.yml`
- ✅ URL GitHub : branche `master` dans les deux dépôts (`origin/HEAD → origin/master`). Les URL vers `RETROCONCEPTION.md` ne résoudront qu'après commit + push du fork.
- ✅ Aucun secret/token : les `client_id` ne sont pas recopiés ; seuls les noms de champs sont cités.

### Corrections apportées aux faits de l'analyse ARCos

1. `sTypeHour2 = production1_hours` ne fausse **que** le test de complétude du cache de `getDataHours()` (seuil ≈ 12 h), pas les valeurs écrites.
2. 403 → `disablePlugin()` vaut pour `getdatahours` **et** `getdatapeakdays` ; s'y ajoutent `unauthorized` / `invalid_grant` / `invalid_request` dans `parseAccessToken()`.
3. L'état transitoire `nothingtosend` existe (absent de l'analyse).
4. Format `sValue` : le Managed Counter est distinct (`-1.0;total[;date]`).
5. « Tous les N/2 jours » vaut après succès ; échec en mode complet → nouvelle tentative sous 1 à 7 jours.
6. Mode3 = 3 / 4 activent aussi le debug avancé ; Mode3 = 19 n'a aucun faux client.
7. Marge d'expiration du jeton effective = 20 min (10 min à l'enregistrement + 10 min au contrôle `idle`).
8. **Watchtower** : absent de tous les composes versionnés (`envs/nas`, `envs/pi`), malgré les mentions README.
9. **Plateforme** : la CI construit `linux/arm/v7` (`DOCKER_TARGET_PLATFORM`) ; le README de build annonçait arm64.
10. Compose `pi` = deCONZ seulement ; compose `nas` = httpd + tydom + domoticz (volumes : `domoticz.db` seul + `scripts/dzVents`).
11. Le README de build référençait `_docker/domotique-compose.yml` (inexistant).
12. Nouvelles dettes : D11 (`setHistoryDays` plafonne à 35 j en session), D12 (500 = « pas de production »), `mergeCounters` (accès non protégés + `except:` nu), `getOrCreateDevice` muet quand 255 unités prises, préfixe `p` de Mode4, ≥ 14 `except:` nus, code mort.
13. La CI ne consomme **pas** le fork (`guillaumezin/DomoticzLinky` @ `refs/heads/master`).

---

## 📌 Notes

- **Écart 1 — emplacement de la rétrodoc** (racine du fork au lieu de `docs/`), cause : pas de création de dossier possible (voir T1.1).
- **Écart 2 — fichier parasite** `PHASE_1_COMPLETION_REPORT.new.md` à supprimer.
- **Limite d'outillage** : pas de `git diff --stat` / `git status --short` exécutés (voir ci-dessus).
- **Non vérifié** : écart fork `1ef6adf` ↔ upstream `master` (non comparé) ; constats de dette = lecture statique, aucun reproduit à l'exécution (D11 notamment « probable ») ; numéros de ligne indicatifs issus de la lecture, pas d'un outil.
- **Non vérifié** : le stockage effectif dans `domoticz.db` est un comportement du framework Domoticz (non visible dans `plugin.py`).

---

## 📊 Synthèse de Phase

**Tâches complétées :** 4/4
**Bloqueurs :** aucun bloquant ; 2 écarts à traiter par MAINa (déplacement éventuel vers `docs/`, suppression du fichier `.new.md`)
**Prochaine phase :** Phase 2 (QALvin) après validation 👤 (Gate #2)

## ⚫ Actions MAINa post-handoff (2026-11-25)

- Écart 1 résolu : `RETROCONCEPTION.md` déplacé vers `DomoticzLinky/docs/RETROCONCEPTION.md` (conforme au plan) ; liens mis à jour (readme du fork ×2, `README.md` ×2, `ARCHITECTURE.md`, `_docker/build_domoticz/README.md`) ; lien interne `readme.md` → `../readme.md`.
- Écart 2 résolu : fichier parasite `PHASE_1_COMPLETION_REPORT.new.md` supprimé.
- Preuves git : fork ` M readme.md`, `?? docs/` (`readme.md | 14 +++++---------`) ; domotique ` M README.md`, ` M _docker/build_domoticz/README.md`, ` M docs/ARCHITECTURE.md`, ` M docs/plans/README.md`, `?? docs/plans/009_*` (`4 files changed, 64 insertions(+), 8 deletions(-)`). Aucun fichier de code modifié.
- Fork vs upstream : `git ls-remote guillaumezin/DomoticzLinky refs/heads/master` = `1ef6adf` → code identique au fork.
- Revue automatique (code-review) : 0 bloquant, 3 non bloquants — (1) `_docker/build_domoticz/README.md` note « scripts embarqués, pas de volume » contredite par le compose NAS (montage `scripts/dzVents`) ; (2) `README.md` démarrage : variables à renseigner dans `stack.env` et non `domotique-compose.yml` ; (3) liens GitHub absolus en 404 tant que les deux dépôts ne sont pas poussés.

