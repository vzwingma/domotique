# ADR 007 — Plugins Domoticz : provenance épinglée par SHA de commit (fork Linky, deCONZ) et mises à jour par Renovate sans automerge

---

**Date :** 2026-11-25  
**Statut :** Acceptée
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Le workflow `.github/workflows/build-domoticz.yml` embarque dans l'image `vzwingmadomatic/domoticz` deux plugins Python
récupérés **à chaque build** depuis `refs/heads/master` de dépôts tiers :

- `guillaumezin/DomoticzLinky` : upstream **non maintenu**. Le fork maintenu `vzwingma/DomoticzLinky` n'est pas consommé ;
- `Smanar/Domoticz-deCONZ`.

Conséquences :
- le contenu de l'image n'est **ni reproductible, ni traçable** : une modification amont part en production sans aucun changement dans `domotique` ;
- l'image `latest` est reconstruite à chaque push sur `master` et aucun tag d'image immuable n'existe ;
- le plugin Linky manipule des jetons OAuth et un cache de consommation persistés dans `domoticz.db` : une dérive silencieuse de son code est sensible.

Éléments de cadrage :
- le plan 009 a documenté le fork (rétro-conception ; tag `v2.6.1` = code upstream `1ef6adf`) et identifié cette provenance comme suite S1 ;
- le plan 010 prévoit des correctifs dans le fork (publiés en **v2.7.0**) qui doivent atteindre la production de façon contrôlée ;
- le tag `v2.6.1` du fork est un tag léger, déjà publié, sur le commit `f3df2584ab398110eefe8d65df1b83d9a9d95395`, et son `plugin.py` est identique à l'upstream `master` (constat C1 de l'annexe) :
  la provenance peut donc changer **sans aucun changement fonctionnel** ;
- deCONZ : dernier tag `1.0.35` = `95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a` ; `master` n'a qu'un commit de plus, qui ne modifie que `README.md` ;
- Renovate est déjà actif sur le dépôt (`config:recommended`, automerge des mises à jour minor/patch), mais son gestionnaire `github-actions`
  **ne lit pas** les entrées `with.repository` / `with.ref` d'`actions/checkout` : une règle dédiée est nécessaire.

## Décision

**Nous avons décidé de** récupérer le plugin Linky depuis le fork `vzwingma/DomoticzLinky` et le plugin deCONZ depuis `Smanar/Domoticz-deCONZ`,
chacun **épinglé sur le SHA du commit** de son tag, avec le tag en commentaire (`ref: <sha40> # <tag>`) dans `.github/workflows/build-domoticz.yml`.
Les pins initiaux sont `f3df2584ab398110eefe8d65df1b83d9a9d95395 # v2.6.1` (Linky) et `95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a # 1.0.35` (deCONZ).
Les mises à jour arrivent par PR Renovate (`customManagers` regex, datasource `github-tags`) avec `automerge: false` pour ces deux dépendances : la PR est revue et fusionnée par un humain.

Ordonnancement retenu (O-B) :
1. pin sur `v2.6.1` d'abord, sans changement fonctionnel ;
2. correctifs du fork publiés en **v2.7.0** (et non 2.6.2) ;
3. montée du pin vers `v2.7.0` (PR Renovate ou PR manuelle d'une ligne).

## Alternatives Considérées

### Option 1 : SHA de commit + commentaire de tag, mises à jour par Renovate regex sans automerge ✅ Retenue

- **Avantages** : référence immuable et reproductible ; lisible grâce au commentaire de tag ; Renovate met à jour le couple SHA + tag ;
  chaque montée de version est proposée mais reste volontaire (merge humain) ; même outil que le reste du dépôt ; retour arrière par un pin d'une ligne.
- **Inconvénients** : une configuration Renovate personnalisée (`customManagers` + `packageRules`) à maintenir ;
  le SHA du **commit** (`git rev-list -n1 <tag>`) doit être obtenu à chaque montée manuelle ;
  un commentaire désaligné du SHA est possible en édition manuelle.

### Option 2 : tag seul (`ref: v2.6.1`)

- **Avantages** : simple et lisible.
- **Inconvénients** : référence mutable (`git push -f --tags` rend le build non reproductible).
- **Raison du rejet** : la reproductibilité repose sur une convention et non sur une garantie ; le SHA ne coûte presque rien de plus avec Renovate.

### Option 3 : branche `master` du fork (`ref: refs/heads/master`)

- **Avantages** : aucun entretien.
- **Inconvénients** : non épinglé ; toute fusion dans `master` du fork part directement en production.
- **Raison du rejet** : conserve le problème actuel (déploiement non contrôlé), seul le dépôt source change.

### Option 4 : statu quo upstream non épinglé (`guillaumezin/DomoticzLinky@refs/heads/master`) ou mise à jour manuelle sans Renovate

- **Avantages** : aucune configuration ; aucune dépendance à Renovate.
- **Inconvénients** : upstream non maintenu, donc aucun moyen d'y livrer nos correctifs ; en mise à jour manuelle, montée de version oubliée possible, aucune visibilité sur les nouveautés.
- **Raison du rejet** : ne traite ni la traçabilité ni la livraison des correctifs du fork ; Renovate est déjà en place sur le dépôt.

### Option 5 : vendoring des plugins dans `domotique`

- **Avantages** : reproductibilité totale, aucune dépendance réseau au build.
- **Inconvénients** : duplication du code des plugins (le plugin Linky est sous licence AGPL) ; deux sources de vérité ; historique et correctifs du fork dissociés du dépôt de maintenance.
- **Raison du rejet** : le fork est le lieu de maintenance du plugin Linky ; un épinglage par SHA donne la même reproductibilité sans duplication.

### Option 6 : ordonnancement O-A (corriger le fork en v2.7.0, puis épingler directement sur v2.7.0)

- **Avantages** : un seul changement de pin.
- **Inconvénients** : changement de provenance et changement de code dans le même déploiement : diagnostic ambigu en cas de régression ; S1 devrait attendre les correctifs.
- **Raison du rejet** : O-B retire immédiatement la dépendance à l'upstream sans changement fonctionnel (constat C1), sépare chaîne d'approvisionnement et code, rend le retour arrière lisible
  et exerce la procédure de montée de version sur un cas réel. Coût : deux reconstructions et deux déploiements d'image.

### Option 7 : deCONZ hors périmètre

- **Avantages** : périmètre plus réduit.
- **Inconvénients** : la provenance de deCONZ resterait non épinglée, incohérence assumée dans l'ADR.
- **Raison du rejet** : même risque, traité par la même règle et la même regex Renovate pour 2 lignes de workflow ; `1.0.35` a le même code Python que `master`.

## Conséquences

### Positives
- Build reproductible : le contenu des plugins de l'image est défini par deux SHA versionnés dans `domotique`.
- Provenance visible dans le résumé du job (SHA et `version=` du plugin tracés par une étape dédiée) ; l'artefact Linky ne contient plus que `plugin.py`
  (`if-no-files-found: error`), ce qui supprime l'embarquement involontaire d'un `.py` ajouté à la racine du fork.
- Les correctifs du fork (v2.7.0) atteignent la production de façon contrôlée, par une PR relue.
- Retour arrière : `git revert` du commit de workflow, ou re-pin sur `f3df2584ab398110eefe8d65df1b83d9a9d95395 # v2.6.1`. La persistance du plugin
  (jetons et cache dans `domoticz.db`) est inchangée : le retour arrière est sans perte.

### Négatives / Compromis
- Chaque version du fork exige un tag, puis la fusion d'une PR dans `domotique` (action humaine à chaque montée).
- Les correctifs amont de deCONZ n'arrivent plus automatiquement : ils passent par une PR Renovate à relire.
- Un oubli ou une régression de la règle `automerge: false` (à placer en dernier dans `packageRules`) réactiverait le déploiement automatique des plugins ; une erreur de regex ferait ignorer le pin par Renovate.
  Parades : vérification dans le tableau de bord Renovate après merge et sur la première PR de montée.
- O-B impose deux reconstructions et deux déploiements d'image (pin v2.6.1, puis montée de pin v2.7.0).
- `latest` étant écrasée à chaque build, le retour rapide côté NAS passe par le digest d'image précédent (`docker image ls --digests vzwingmadomatic/domoticz`).

### Neutres
- Mise à jour requise de `docs/ARCHITECTURE.md` § 5.4, de `_docker/build_domoticz/README.md`, de `README.md` et des § 1 et § 15 de la rétro-conception du fork.
- Les builds `pull_request` du dépôt continuent de pousser une image `:merge`, et `workflow_dispatch` sur une branche `x/y` pousse `:y` (comportement existant, hors périmètre) ; seul `master` produit `latest`.

## Mise en œuvre

- **Fichiers impactés** : `.github/workflows/build-domoticz.yml` (jobs `download-linky` et `download-deconz` : `repository`/`ref` épinglés, étape de traçabilité, chemins d'artefact),
  `renovate.json` (`customManagers` regex + règle `packageRules` `automerge: false` en dernier), `docs/ARCHITECTURE.md`, `_docker/build_domoticz/README.md`, `README.md`,
  `docs/RETROCONCEPTION.md` du fork.
- **Contraintes de format** : ne pas séparer `repository:` et `ref:` (la regex Renovate attend `ref` sur la ligne suivante) ; le SHA est toujours celui du commit, même pour un tag annoté.
- **Tâches de suivi** : DEVon — pin du workflow et configuration Renovate (phase 1 du plan) ; QALvin — `workflow_dispatch` sur la branche, comparaison octet pour octet du blob de l'artefact avec `v2.6.1:plugin.py`
  et des `*.py` deCONZ avec le tag `1.0.35` ; DOCly — documentation, puis passage de l'ADR à `Acceptée` au Gate #1 (MAINa) ; 👤 — merge, détection des 2 dépendances dans le tableau de bord Renovate,
  tag `v2.7.0` du fork.
- **Date d'effet** : phase 1 du plan 010 (Linky `v2.6.1`, deCONZ `1.0.35`), puis montée du pin à `v2.7.0` en phase 5.

## Références

- Plan d'Action associé : [`docs/plans/010_linky_suites.plan.md`](../plans/010_linky_suites.plan.md)
- Analyse ARCos (§ 1 : options, modifications exactes, contenu de l'ADR) : [`docs/plans/010_reports/ANALYSE_ARCOS.md`](../plans/010_reports/ANALYSE_ARCOS.md)
- Plan d'origine (suite S1) : [`docs/plans/009_retrodoc_domoticzlinky.plan.md`](../plans/009_retrodoc_domoticzlinky.plan.md)
- [Architecture — § 5.4 Plugins Python Domoticz (Linky, deCONZ)](../ARCHITECTURE.md#54-plugins-python-domoticz-linky-deconz)
- [Image Docker Domoticz — provenance des plugins](../../_docker/build_domoticz/README.md)
- ADR voisin de même nature (CI et images Docker) : [ADR 006](./006-tydom-node26-arm64-tls-legacy.md)
- [Fork `vzwingma/DomoticzLinky`](https://github.com/vzwingma/DomoticzLinky) · [`Smanar/Domoticz-deCONZ`](https://github.com/Smanar/Domoticz-deCONZ)
- [Renovate — Custom Managers (regex)](https://docs.renovatebot.com/modules/manager/regex/)
