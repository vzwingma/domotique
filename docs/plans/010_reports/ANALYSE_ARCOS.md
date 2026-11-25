<!-- Annexe du plan docs/plans/010_linky_suites.plan.md — analyse 🟠 ARCos du 2026-11-25 (lecture seule), conservée verbatim. Numéros de ligne de plugin.py valables pour v2.6.1 (f3df258 = code 1ef6adf). -->

# Analyse ARCos — Plan 010 : suites du plan 009 (DomoticzLinky S1 à S4)

Analyse faite en lecture seule. Je n'ai lancé aucune commande shell : **la présence de Python, pytest, ruff, luac et node sur la machine n'est pas vérifiée**. Les commandes à lancer pour le vérifier sont en § 6.

Les numéros de ligne de `plugin.py` valent pour la copie de travail actuelle. Son code est identique à `1ef6adf` et au tag `v2.6.1` (`f3df258`).

## 0. Faits vérifiés et quatre constats qui changent le cadrage

**État des dépôts**

| Élément | Constat (source) |
|---|---|
| `domotique` | La branche locale est `feat/add_linky` (`.git/HEAD`). La § 5.4 d'`ARCHITECTURE.md` et le tableau « Provenance » du README de build n'existent que sur cette branche (PR #232). |
| ADR | Il existe 001 à 006 et `ADR-TEMPLATE.md`. **Prochain numéro libre : 007.** Prochain plan : **010**. |
| Fork | Branche locale `feat/fork_and_retrodoc` (`7c89964`). `master` est sur `f3df258`. Le tag `v2.6.1` est un tag léger : `refs/tags/v2.6.1` contient directement le commit `f3df2584ab398110eefe8d65df1b83d9a9d95395`. Il est **déjà publié** sur GitHub. Les anciens tags du fork n'ont pas de préfixe `v` (`2.3.8`…). |
| Contenu du fork | Racine : `plugin.py`, `readme.md`, `LICENSE`, `assets/`, `docs/`, `.github/` (sans workflow). Il n'y a ni `.gitignore`, ni `tests/`, ni configuration de lint. |
| Renovate | Actif sur `domotique` : 42 PR `renovate[bot]`, la dernière est #230 du 25/11/2026. `renovate.json` contient `config:recommended` et l'automerge des mises à jour minor/patch quand la version ne commence pas par `0`. Le gestionnaire `github-actions` ne lit pas les entrées `with.repository` / `with.ref`. |
| deCONZ | Dernier tag `1.0.35` = `95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a`. `master` = `f1a3134`, soit **un seul commit de plus qui ne modifie que `README.md`** (comparaison GitHub `1.0.35...master`). |

**Constat C1 — S1 peut partir en premier.** Le tag `v2.6.1` du fork existe déjà et son `plugin.py` est identique à l'upstream `master`. On peut donc changer la provenance (passer au fork, épinglé) **sans aucun changement fonctionnel**, avant S2/S3 et sans attendre le merge de la PR fork #2. Cela découple le changement de chaîne d'approvisionnement du changement de code.

**Constat C2 — S4 : `lastUpdate` ne mesure pas la fraîcheur des données Linky.**
- Toutes les ≈ 50 s, `onHeartbeat()` (l. 2212-2236) appelle `oDevice.Touch()`, ou `oDevice.Update(..., TimedOut=1)` quand le délai est dépassé. D'après la documentation du framework, `Touch()` met à jour l'heure de dernière vue.
- Conséquence : `lastUpdate` reste frais tant que le plugin tourne, même sans donnée Enedis.
- Le bon indicateur des données est **`timedOut`**, que le plugin passe à 1 après 1,5 jour.
- `lastUpdate` ne sert qu'à détecter un **plugin arrêté** : désactivé après une réponse 403, plantage, matériel désactivé.
- Ces deux points sont à confirmer à l'exécution (vérifications U1 et U2, § 5).

**Constat C3 — D12 ne doit pas être corrigé.** En mode production, `handleConnection()` (l. 1793) classe le statut 500 comme « pas de production » **avant** la branche `429/500 → retry` (l. 1816). C'est très probablement un contournement voulu : Enedis renvoie 500 ou `ADAM-ERR0123` pour un compteur sans production. Si on le « corrige », un compteur en consommation seule échouerait à chaque cycle, avec une nouvelle tentative toutes les heures et sans jamais aboutir.

**Constat C4 — CI : trois effets de bord à connaître pour la validation.**
- L'artefact Linky prend `/home/runner/work/domotique/domotique/*.py` (`build-domoticz.yml` ≈ l. 36). Il embarquerait tout `.py` ajouté à la racine du fork, par exemple un `conftest.py`.
- Les événements `pull_request` **poussent** une image `vzwingmadomatic/domoticz:merge` : le tag est dérivé de `refs/pull/N/merge`.
- `workflow_dispatch` sur une branche `x/y` pousse `:y`. Seul `master` produit `:latest`.

## 1. S1 — Provenance des plugins dans la CI (ADR 007)

### 1.1 Options

**Forme de la référence (D-S1a)**

| Critère | A : SHA de commit + commentaire `# vX.Y.Z` ✅ | B : tag seul `ref: v2.6.1` | C : branche du fork `master` |
|---|---|---|---|
| Avantages | Immuable et reproductible. Renovate sait mettre à jour le couple SHA + tag. Lisible grâce au commentaire. | Simple et lisible. | Aucun entretien. |
| Inconvénients | Il faut obtenir le SHA à chaque montée de version. | Un tag peut être déplacé (risque faible, c'est notre fork). | Non épinglé : on garde le problème actuel. |
| Risques | Commentaire désaligné du SHA (Renovate met les deux à jour). | `git push -f --tags` le rend non reproductible. | Toute fusion dans `master` part directement en production. |
| Effort | Faible | Faible | Faible |

**Mécanisme de mise à jour (D-S1b)**

| Critère | R1 : regex Renovate, **automerge désactivé** ✅ | R2 : mise à jour manuelle seule | R3 : R1 + `dependencyDashboardApproval` |
|---|---|---|---|
| Avantages | Une PR est proposée à chaque tag ; la validation reste volontaire (merge humain). Même outil que le reste du dépôt. | Rien à configurer. | Aucune PR tant que la case du tableau de bord n'est pas cochée. |
| Inconvénients | Une règle `customManagers` à maintenir. | Une montée de version peut être oubliée. Pas de visibilité. | Deux étapes manuelles. |
| Risques | Si la règle `automerge:false` est oubliée, la règle globale fusionnerait un patch automatiquement, ce qui reconstruit `latest`. | Dérive silencieuse. | Faible |
| Effort | Faible | Nul | Faible |

**deCONZ (D-S1c)**

| Critère | Inclus dans le périmètre : pin sur `1.0.35` ✅ | Hors périmètre |
|---|---|---|
| Avantages | Même risque traité par la même règle et la même regex Renovate. `1.0.35` a le même code Python que `master` (seul le README diffère). | Plan plus petit. |
| Inconvénients | Il faut valider que l'image deCONZ ne régresse pas. | La provenance reste non épinglée, ce que l'ADR acterait comme incohérence assumée. |
| Effort | Très faible (2 lignes) | Nul |

**Recommandation :** A + R1 + deCONZ inclus. Le pin initial de Linky se fait sur `v2.6.1` (constat C1), puis on monte à `v2.6.2` après S2/S3.

### 1.2 Modifications exactes

**Fichier : `C:\Users\vzwingma\IdeaProjects\domotique-workspace\domotique\.github\workflows\build-domoticz.yml`**

Job `download-linky`. Code actuel (≈ l. 25-36) :

```yaml
      - 
        name: Checkout the code Linky
        uses: actions/checkout@v7
        with:
            repository: guillaumezin/DomoticzLinky
            ref: refs/heads/master
      # Upload plugin Linky
      - uses: actions/upload-artifact@v7
        name: Upload Python script
        with:
            name: linky-plugin
            path: /home/runner/work/domotique/domotique/*.py
```

Code cible :

```yaml
      - 
        name: Checkout the code Linky
        uses: actions/checkout@v7
        with:
            repository: vzwingma/DomoticzLinky
            ref: f3df2584ab398110eefe8d65df1b83d9a9d95395 # v2.6.1
      - 
        name: Trace Linky provenance
        run: |
          echo "Linky : vzwingma/DomoticzLinky @ $(git rev-parse HEAD)" >> "$GITHUB_STEP_SUMMARY"
          grep -m1 -o 'version="[^"]*"' plugin.py >> "$GITHUB_STEP_SUMMARY"
      # Upload plugin Linky
      - uses: actions/upload-artifact@v7
        name: Upload Python script
        with:
            name: linky-plugin
            path: ${{ github.workspace }}/plugin.py
            if-no-files-found: error
```

Job `download-deconz` (≈ l. 44-55), même principe :
- `repository: Smanar/Domoticz-deCONZ` reste inchangé.
- `ref: 95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a # 1.0.35`.
- Ajouter une étape de traçabilité identique (`echo "deCONZ : … @ $(git rev-parse HEAD)"`).
- `path: ${{ github.workspace }}/*.py`, plus `if-no-files-found: error`.

Règles :
- **Ne pas** séparer `repository:` et `ref:` : la regex Renovate attend `ref` sur la ligne qui suit.
- Le SHA épinglé doit toujours être celui du **commit** (`git rev-list -n1 <tag>`), même pour un tag annoté.

**Fichier : `C:\Users\vzwingma\IdeaProjects\domotique-workspace\domotique\renovate.json`.** Ajouter :

```json
  "customManagers": [
    {
      "customType": "regex",
      "description": "Plugins Python Domoticz épinglés (SHA + tag) dans build-domoticz.yml — ADR 007",
      "managerFilePatterns": ["/^\\.github/workflows/build-domoticz\\.yml$/"],
      "matchStrings": [
        "repository:\\s*(?<depName>[\\w.-]+/[\\w.-]+)\\s*\\n\\s*ref:\\s*(?<currentDigest>[0-9a-f]{40})\\s*#\\s*(?<currentValue>[\\w.-]+)"
      ],
      "datasourceTemplate": "github-tags"
    }
  ],
```

Puis ajouter cette entrée **en dernier** dans `packageRules` (la dernière règle l'emporte) :

```json
    {
      "description": "Plugins Domoticz : mise à jour volontaire, jamais d'automerge (ADR 007)",
      "matchManagers": ["custom.regex"],
      "matchDepNames": ["vzwingma/DomoticzLinky", "Smanar/Domoticz-deCONZ"],
      "automerge": false
    }
```

Si le validateur refuse `managerFilePatterns` (nom introduit en Renovate v41), utiliser `"fileMatch": ["^\\.github/workflows/build-domoticz\\.yml$"]`.

### 1.3 Validation S1

1. Valider la configuration Renovate (nécessite Node) : `npx --yes --package renovate -- renovate-config-validator renovate.json` → `Config validated successfully`.
2. Lancer le build sur la branche : `gh workflow run build-domoticz.yml --repo vzwingma/domotique --ref <branche>` → image `vzwingmadomatic/domoticz:<dernier segment de la branche>`, **pas** `latest`.
3. Repérer le run : `gh run list --repo vzwingma/domotique --workflow build-domoticz.yml --limit 1` → récupérer `<id>`, conclusion `success`.
4. Contrôler le résumé : `gh run view <id> --repo vzwingma/domotique --log | Select-String "Linky : |deCONZ : |version="` → les SHA `f3df258…` et `95b8f8b…`, et `version="2.6.1"`.
5. Télécharger l'artefact : `gh run download <id> --repo vzwingma/domotique -n linky-plugin -D $env:TEMP\linky` → **un seul fichier** `plugin.py`.
6. Comparer octet pour octet, sans dépendre de l'encodage :
   - `git hash-object --no-filters $env:TEMP\linky\plugin.py`
   - doit être égal à `git -C C:\Users\vzwingma\IdeaProjects\domotique-workspace\DomoticzLinky rev-parse v2.6.1:plugin.py`.
7. deCONZ : `gh run download <id> -n deconz-plugin -D $env:TEMP\deconz`, puis comparer avec la liste et le contenu des `*.py` du tag `1.0.35` (`gh api repos/Smanar/Domoticz-deCONZ/git/trees/1.0.35` pour la liste des blobs).
8. Après le merge sur `master` : le tableau de bord Renovate liste `vzwingma/DomoticzLinky v2.6.1` et `Smanar/Domoticz-deCONZ 1.0.35` dans « Detected dependencies » (preuve différée).

**Retour arrière S1 :** `git revert` du commit de workflow (retour à `guillaumezin` / `master`), puis exécution du workflow sur `master`. L'image `latest` étant écrasée à chaque build, le retour rapide côté NAS passe par le digest précédent : `docker image ls --digests vzwingmadomatic/domoticz`. Les jetons et le cache sont dans `domoticz.db`, et aucun format n'est modifié : le retour arrière est sans perte.

### 1.4 Contenu de l'ADR à rédiger (pour DOCly)

**Fichier cible :** `docs/adr/007-plugins-domoticz-provenance-epinglee.md` — **Date :** 2026-11-25 — **Statut :** Proposée — **Décideurs :** 🟠 ARCos + 👤

**Contexte.**
- `build-domoticz.yml` embarque dans l'image `vzwingmadomatic/domoticz` deux plugins Python récupérés à chaque build depuis `refs/heads/master` de dépôts tiers :
  - `guillaumezin/DomoticzLinky` : upstream non maintenu ; le fork maintenu `vzwingma/DomoticzLinky` n'est pas consommé ;
  - `Smanar/Domoticz-deCONZ`.
- Le contenu de l'image n'est ni reproductible ni traçable : une modification amont part en production sans changement dans `domotique`.
- L'image `latest` est reconstruite à chaque push sur `master`. Aucun tag d'image immuable n'existe.
- Le plan 009 a documenté le fork (rétrodoc, tag `v2.6.1` = code upstream `1ef6adf`).
- Le plan 010 prévoit des correctifs dans le fork (v2.6.2), qui doivent atteindre la production de façon contrôlée.

**Décision.** Nous avons décidé de récupérer le plugin Linky depuis le fork `vzwingma/DomoticzLinky` et deCONZ depuis `Smanar/Domoticz-deCONZ`, chacun **épinglé sur un SHA de commit annoté du tag correspondant** (`ref: <sha> # <tag>`). Les mises à jour arrivent par PR Renovate (gestionnaire regex, datasource `github-tags`) **sans automerge**, et sont validées par un humain.

**Alternatives.**
1. **SHA + tag + Renovate sans automerge ✅.** Avantages : immuable, traçable, mise à jour proposée mais volontaire. Inconvénients : une configuration Renovate personnalisée à maintenir.
2. **Tag seul.** Avantages : simple. Inconvénients : référence mutable. Rejet : la reproductibilité dépend d'une convention.
3. **Branche `master` du fork.** Avantages : aucun entretien. Inconvénients : non épinglé. Rejet : ne traite pas le risque.
4. **Mise à jour manuelle sans Renovate.** Avantages : aucune configuration. Inconvénients : oubli possible, pas de visibilité. Rejet : Renovate est déjà en place sur le dépôt.
5. **Vendoring des plugins dans `domotique`.** Avantages : reproductibilité totale. Inconvénients : duplication de code AGPL, deux sources de vérité. Rejet : le fork est le lieu de maintenance.

**Conséquences.**
- Positives : build reproductible ; provenance visible dans le résumé du job ; correctifs du fork déployés de façon contrôlée ; retour arrière par un pin d'une ligne.
- Négatives : chaque version du fork exige un tag, puis la fusion d'une PR dans `domotique` ; les correctifs deCONZ amont n'arrivent plus automatiquement ; un oubli de la règle `automerge:false` réactiverait le déploiement automatique.
- Neutres : mettre à jour `docs/ARCHITECTURE.md` § 5.4, `_docker/build_domoticz/README.md`, `README.md`, et les § 1 et § 15 de la rétrodoc du fork. Les PR de `domotique` continuent de pousser une image `:merge` (comportement existant, hors périmètre).

**Mise en œuvre.**
- Fichiers : `.github/workflows/build-domoticz.yml`, `renovate.json` et les documents listés ci-dessus.
- Tâches : DEVon (pin + Renovate), QALvin (`workflow_dispatch` + comparaison de blobs), DOCly (documentation).
- Date d'effet : phase 1 du plan 010 (Linky `v2.6.1`, deCONZ `1.0.35`), puis montée à `v2.6.2` en phase 5.

**Références :** `docs/plans/010_linky_suites.plan.md` ; `docs/plans/009_retrodoc_domoticzlinky.plan.md` (suite S1).

## 2. S2 — Corrections du plugin (fork)

### 2.1 Tri D1 à D16

| # | Décision recommandée | Justification |
|---|---|---|
| D1 onCommand / onNotification | **Corriger maintenant** | `AttributeError` réel. `onNotification` défini au niveau du module enregistre probablement le plugin comme canal de notification Domoticz, d'où un appel possible lors des notifications vers tous les canaux (vérification U3). |
| D2 `iVersion` | **Maintenant** | Une ligne, aucun risque. |
| D3 `mergeCounters` (mauvaise boucle + `KeyError`) | **Maintenant** | Bug avéré. Le `KeyError` sur `value_year` survient dès qu'un PRM n'a aucune donnée dans l'année : `dCalculate` vide, voir `resetCalculate()` l. 1189 et `doCalculation()` l. 1235. Le cycle passe alors en échec global, avec une nouvelle tentative **toutes les heures**. |
| D5 unité 256 inaccessible | **Maintenant** | Trivial. |
| D8 (= S3) | **Maintenant** | Voir § 3. |
| D16 / S7 fichier de debug non fermé | Maintenant (option bon marché) : `close()` dans `onStop()` | Le `/tmp` du conteneur est éphémère, la purge est inutile. `NamedTemporaryFile` crée le fichier en 0600 (via `mkstemp`) : la rétrodoc « non protégé » est à corriger. |
| D11 historique plafonné à 35 j | **Décision 👤** : utile seulement si `Mode2` > 35 | Correction d'une ligne, faible risque. |
| D4 `sTypeHour2` | **Ne pas changer le comportement**, ajouter un commentaire explicatif | Remplacer par `production2_hours` (jamais rempli, voir `storeData()` l. 1088-1121) exigerait 23 h de production. Si Enedis omet les heures de nuit, le cache n'est jamais complet, d'où des requêtes à chaque cycle. |
| D12 statut 500 en production | **Ne pas corriger, documenter comme intentionnel** | Constat C3. |
| D6 `except:` nus | Plus tard ; seul celui de `mergeCounters` est traité avec D3 | Refactorisation large. |
| D7 monolithe, sans tests | Partiellement : le harnais de tests (§ 6) est le premier pas | — |
| D9 / S4 pickle | Hors périmètre, risque accepté (§ 3.4) | — |
| D10 proxy tiers | Hors périmètre (externe) | — |
| D13 Mode3 = 19 | Plus tard (faible valeur) | — |
| D14 jours fériés / préfixe `p` | Plus tard (évolution fonctionnelle) | — |
| D15 code mort | Plus tard (bruit dans le diff) | — |

### 2.2 Fiches de correction

**D1 — fichier `C:\Users\vzwingma\IdeaProjects\domotique-workspace\DomoticzLinky\plugin.py`**
- **Code actuel :** les fonctions de module l. 2384-2386 (`def onCommand(...)` qui appelle `_plugin.onCommand(Unit, Command, Level, Hue)`) et l. 2401-2403 (`_plugin.onNotification(...)`). Aucune méthode correspondante dans `BasePlugin`.
- **Correction (option recommandée D1a)** : ajouter dans `BasePlugin`, après `onDisconnect()` (l. 2207-2209) :

  ```python
      def onCommand(self, Unit, Command, Level, Hue):
          if self.isStarted:
              self.myDebug("onCommand ignoré (unité " + str(Unit) + ", commande " + str(Command) + ")")

      def onNotification(self, Name, Subject, Text, Status, Priority, Sound, ImageFile):
          if self.isStarted:
              self.myDebug("onNotification ignoré")
  ```

  Ne pas journaliser `Text`, qui peut contenir n'importe quoi.
- **Alternative D1b** : supprimer les deux fonctions de module. Le plugin ne s'enregistre plus comme canal de notification, ce qui est plus propre mais modifie la liste des canaux visibles dans Domoticz.
- **Risque :** nul avec D1a.
- **Vérification :** les tests `onCommand(1, "On", 0, 0)` et `onNotification(...)` du module ne lèvent pas d'exception.

**D2 — `onStart()` l. 2030-2047**
- **Code actuel :**

  ```python
  self.iAlternateDevice = 1
  matchVersions = re.search(r"(\d+)\.(\d+)", Parameters["DomoticzVersion"])
  if (matchVersions):
      ...
      iVersion = (iVersionMaj * 1000000) + iVersionMin
  ...
  if iVersion < 4011070:
  ```

- **Correction :** initialiser `iVersion = 0` avant `re.search`, et ajouter `else: self.myError("Version de Domoticz non reconnue : " + str(Parameters["DomoticzVersion"]))`. Le test `< 4011070` provoque ensuite un arrêt explicite.
- **Alternative (D-S2b)** : considérer la version comme récente. Non recommandé : un échec explicite vaut mieux.
- **Risque :** nul, les versions Domoticz `AAAA.N` correspondent toujours à la regex.
- **Vérification :** un test avec `DomoticzVersion="inconnue"` ne lève pas `NameError`, laisse `isStarted is False` et journalise le message. Un test avec `"2026.1"` laisse `iAlternateDevice == 0`.

**D3 — `mergeCounters()` l. 1024-1084**
- **Code actuel, boucle fautive (l. ≈ 1060) :**

  ```python
  # create production data to merged device where dates don't coincide for consumption
  for sDate, dProdData in self.dData[sUsagePointConsumptionId]["data"].items():
  ```

- **Corrections :**
  - Boucle : `for sDate, dProdData in self.dData[sUsagePointProductionId]["data"].items():`
  - Les 8 accès `[...]["value_year"]` (l. 1030-1043) deviennent `.get("value_year", 0)`.
  - Garde : `if sUsagePointConsumptionId not in self.dData or sUsagePointProductionId not in self.dData: continue`.
  - Remplacer le `except:` nu de la l. 1082 par `except Exception as err: self.myError("Erreur lors de la fusion des points de livraison : " + str(err)); bResult = False`.
- **Risque :** faible. Le comportement ne change que pour les installations à deux PRM (consommation seule + production seule) ou pour un PRM sans donnée dans l'année, qui ne provoque plus d'échec global.
- **Vérification (tests) :**
  - PRM A en consommation seule (date d1), PRM B en production seule (dates d1 et d2), `saveDataToDb` simulé → `dData["A / B"]["data"]` contient d2 avec les valeurs `production1_hours` de B.
  - Un `dCalculate` aux dictionnaires vides fait retourner `True` à `mergeCounters()`.

**D5 — `getOrCreateDevice()` l. 632-655**
- **Code actuel :** `for iIndexUnit in range(1, 256): if iIndexUnit == 256: ... return None` (l. 637-641).
- **Correction :** retirer le test `== 256` dans la boucle, et appeler `self.showSimpleStepError("Ne peut ajouter de dispositif Linky … faites le ménage SVP")` puis `return None` **après** la boucle.
- **Risque :** nul.
- **Vérification :** un test avec `Devices` rempli de 255 unités d'un autre `DeviceID` retourne `None` et le message d'erreur est capturé.

**D11 (si GO) — `setHistoryDays()` l. 1479-1497**
- Dans la branche `if bGrabAll and (...)`, ajouter `self.iHistoryDaysForDaysView = self.iSavedHistoryDaysForDaysView`. Ce champ est relu par `resetDates()` l. 1428-1431.
- **Risque :** faible. On retrouve le volume complet de requêtes prévu par conception.
- **Vérification :** un test enchaîne un cycle court puis un cycle complet, et vérifie `iHistoryDaysForDaysView == iSavedHistoryDaysForDaysView` (ex. 365).

**D4 — `getDataHours()` l. 1615-1619**
- Ajouter un commentaire seulement : `# Volontaire : la production n'est stockée que dans production1_hours ; le double comptage ramène le seuil de complétude à ~12 h (production diurne). Voir RETROCONCEPTION D4.`
- **Vérification :** un test de caractérisation montre que 12 heures de production suffisent (cache utilisé) et que 11 heures ne suffisent pas.

**D16 — `onStop()` l. 2173-2180**
- Après `flush()` : `self.fDebug.close(); self.fDebug = None`.
- **Risque :** les écritures suivantes tombent dans le `try/except` de `myMessage()`, ou sont ignorées puisque `fDebug` vaut `None`.

**Version** (DEVon)
- Bloc XML l. 25 : `version="2.6.1"` devient `"2.6.2"`. La valeur est reprise dans l'en-tête `User-Agent` via `Parameters["Version"]`.
- `externallink` : passer à `https://github.com/vzwingma/DomoticzLinky` (D-S2c).
- **Interdit dans ce plan :** modifier les clés ou le format de persistance (`setConfigItem`, `getConfigItem`), pour que le retour arrière vers v2.6.1 reste sûr.

## 3. S3 — Secrets dans les journaux (fork)

### 3.1 Points de fuite (code actuel)

| Point | Ligne | Ce qui fuit | Sortie |
|---|---|---|---|
| `getData()` → `dumpDictToLog(sendData)` | 612, 627 | `Headers["Authorization"]` = `token_type + " " + access_token` (profondeur 2) | Fichier `/tmp` si `Mode3` ≥ 1 ; journal Domoticz si `Mode3` ≥ 2 |
| `refreshToken()` → `dumpDictToLog(sendData)` | 529-545 | Chaîne `Data` encodée URL : `refresh_token=…&usage_points_id=…` | idem |
| `getAccessToken()` → `dumpDictToLog(sendData)` | 507-519 | `device_code=…` | idem |
| `getDeviceCode()` | 434 | `client_id` public, aucun secret | — |
| `handleConnection()` → `dumpDictToLog(Data)` | 1689 | Réponse brute ; `Data["Data"]` en octets JSON contenant `access_token` et `refresh_token` (réponse token) ; en-têtes de réponse | idem |
| `setConfigItem()` en erreur | 2304-2305 | `str(Value)`, donc la valeur du jeton | `Domoticz.Error` (toujours) + fichier |
| `parseDeviceCode()` | 488-490 | `user_code` + URL de consentement : **fonctionnel**, à conserver (S8) | Journal d'erreurs |
| `loadCache()` → `dumpDictToLog(self.dData)` | 2353 | Données de consommation, sans secret | — |

### 3.2 Options de masquage (D-S3a)

| Critère | M1 : masquage par clé dans `dumpDictToLog` + filtre regex dans les `my*()` ✅ | M2 : masquage par clé seulement | M3 : supprimer les appels `dumpDictToLog` sur les requêtes et réponses |
|---|---|---|---|
| Avantages | Défense en profondeur : couvre aussi le corps encodé URL, les octets JSON et les futurs messages. | Changement minimal. | Aucune fuite possible. |
| Inconvénients | Une regex sur chaque message (négligeable). | Ne couvre pas `Data` (chaîne ou octets), alors que c'est là que se trouve le `refresh_token`. | Perte du diagnostic de debug. |
| Effort | Faible à moyen | Faible | Faible |

### 3.3 Code proposé

À placer au niveau du module, après `NO_STATUS_ERROR_CODE` (l. 162) ; `re` est déjà importé :

```python
# Masquage des secrets dans les journaux (v2.6.2)
SENSITIVE_KEYS = frozenset(("authorization", "access_token", "refresh_token", "device_code", "id_token", "cookie", "set-cookie"))
MASK = "***"
_SECRET_PATTERNS = (
    (re.compile(r"(?i)\b(access_token|refresh_token|device_code|id_token)=[^&\s'\"]*"), r"\1=" + MASK),
    (re.compile(r"(?i)(\"(?:access_token|refresh_token|device_code|id_token)\"\s*:\s*\")[^\"]*\""), r"\1" + MASK + "\""),
    (re.compile(r"(?i)\b(bearer|basic)\s+[A-Za-z0-9\-._~+/=]+"), r"\1 " + MASK),
)

def maskSecrets(sText):
    s = str(sText)
    for oPattern, sRepl in _SECRET_PATTERNS:
        s = oPattern.sub(sRepl, s)
    return s

def maskValue(key, value):
    return MASK if str(key).casefold() in SENSITIVE_KEYS else maskSecrets(value)
```

Points d'application :
- `dumpDictToLog()` (l. 1967-1984) : remplacer chaque `str(dictToLog[x])`, `str(dictToLog[x][y])` et `str(dictToLog[x][y][z])` par `maskValue(<clé>, <valeur>)`, et `str(dictToLog)` (branche « Pas de dict reçu ») par `maskSecrets(dictToLog)`.
- `myMessage()`, `myLog()`, `myStatus()`, `myError()` (l. 323-350) : ajouter `message = maskSecrets(message)` en première ligne. L'opération est idempotente.
- `setConfigItem()` l. 2305 : remplacer `+ "\" value \"" + str(Value) + "\""` par `+ "\" (type " + type(Value).__name__ + ")"`.

Ce qui reste volontairement en clair :
- Le `user_code` du message de consentement. L'URL est `.../device?code=`, que les motifs ne visent pas.
- Le PRM (D-S3b) : il figure déjà dans les noms de dispositifs et les messages « Traitement pour le point de livraison ». Le masquer serait incohérent et rendrait le diagnostic difficile.

**Vérification :**
- Tests : un jeton d'accès sentinelle `TOK-ACCESS-SENTINEL`, un refresh sentinelle et un device code sentinelle ne doivent apparaître **ni** dans le fichier de debug (`io.StringIO` injecté dans `fDebug`) **ni** dans les appels `Domoticz.Log/Status/Error` simulés. Cela couvre `getData()`, `refreshToken()`, `getAccessToken()`, `dumpDictToLog({"Status": 200, "Data": b'{"access_token":"…","refresh_token":"…"}'})` et `setConfigItem` avec `Configuration` qui lève une exception.
- Non-régression : `Verb`, `URL` (hors secrets) et le `user_code` du consentement restent présents.
- Contrôle statique : `rg -n 'str\(Value\)' plugin.py` → aucune ligne dans `setConfigItem`.
- Exécution (optionnelle, 👤) : `Mode3=1`, redémarrer le matériel Linky dans la plage 8 h-22 h, puis
  `docker compose -f domotique-compose.yml exec domoticz sh -c 'grep -cE "(access_token|refresh_token|device_code)=[^*&]|Bearer [^*]" /tmp/DomoticzLinky_*.log'` → `0`.
  Ensuite remettre `Mode3=0` et lancer `... exec domoticz sh -c 'rm -f /tmp/DomoticzLinky_*.log'`.

### 3.4 `pickle.loads` avant le checksum (S4 / D9 de la rétrodoc) — **hors périmètre recommandé**

- Le checksum est stocké au même endroit que les données. Le contrôler avant `pickle.loads` n'apporte **aucune** authenticité.
- Un attaquant capable d'écrire dans `domoticz.db` contrôle déjà Domoticz : les scripts d'événements internes y sont stockés (à confirmer, mais le modèle de menace ne change pas).
- Migrer vers JSON (dates dans `dData`) demanderait une compatibilité de lecture avec l'ancien format. En cas d'échec, il faudrait refaire le consentement. Effort moyen, bénéfice faible.
- Décision proposée : risque accepté et documenté dans la rétrodoc § 13 (S4, colonne de statut « Accepté »), puis inscription au backlog.

## 4. S4 — Supervision Linky dans `Health_check_dzVents.lua`

### 4.1 Identification du dispositif (D-S4a)

| Critère | I1 : préfixe `'Linky '` (constante + helper) ✅ | I2 : constante avec le nom complet `Linky <PRM>` | I3 : variable utilisateur Domoticz (nom ou idx) | I4 : `hardwareName` du matériel |
|---|---|---|---|---|
| Avantages | Le PRM reste hors du dépôt. Gère plusieurs PRM et le PRM fusionné `Linky A / B`. Cohérent avec les constantes `DEVICE_*`. | Correspondance exacte, comme les autres constantes. | Correspondance exacte, rien de personnel dans le dépôt. | Résiste au renommage du dispositif. |
| Inconvénients | Collision possible avec un autre dispositif nommé « Linky… » (ex. TIC Zigbee). Casse si le dispositif est renommé. | **Donnée personnelle versionnée** (dépôt GitHub). | Configuration manuelle de plus ; nouvelle variable à ajouter dans `Config_check`. | Dépend d'un nom de matériel libre et inconnu. Plusieurs dispositifs possibles. |
| Effort | Faible | Faible | Faible | Faible |

**Recommandation : I1**, sous réserve que 👤 confirme les noms réels (Q1).

### 4.2 Seuils et comportement (D-S4b)

Une boucle sur les dispositifs trouvés, dans un `pcall` comme les autres indicateurs :

| Cas | Condition | Niveau |
|---|---|---|
| Aucun dispositif | `#liste == 0` | `warn` (ERROR, compté dans la notification) |
| Plugin inactif | `d.lastUpdate.minutesAgo > 36*60` | `warn` |
| Pas de données Enedis | sinon `d.timedOut == true` (plugin : aucune mise à jour du tableau de bord depuis 1,5 j) | `warn` |
| Nominal | sinon | `LOG_DEBUG` |

Pourquoi 36 h : la valeur fonctionne **quel que soit** le résultat de la vérification U1.
- Si `Touch()` met bien `lastUpdate` à jour : on détecte un plugin arrêté en 36 h au plus (contrôle quotidien, acceptable).
- Sinon, `lastUpdate` vaut la dernière collecte, au plus ≈ 24 h à 08:00 en fonctionnement normal : pas de faux positif.

Le `if / elseif` évite le double comptage. Journaliser l'**idx** plutôt que le nom, pour garder le PRM hors des journaux partagés (D-S4c). Le message Signal reste générique.

**Limite connue à documenter :** après un redémarrage de Domoticz, le plugin réarme son délai à 1,5 j (`onStart()` → `setTimeout(dtNow)`, l. 2167). `timedOut` reste donc faux pendant 1,5 j au plus, même si les données sont anciennes.

### 4.3 Code proposé

**Fichier `C:\Users\vzwingma\IdeaProjects\domotique-workspace\domotique\domoticz\scripts\dzVents\global_data.lua`**, après `DEVICE_STATUT_PHASE = 'Phase',` (l. 53) :

```lua
        -- Énergie : plugin Python Linky (devices nommés 'Linky <PRM>' ; PRM non versionné)
        DEVICE_LINKY_PREFIX = 'Linky ',
```

Helper à ajouter dans `helpers`, par exemple après `getLevelFromState` :

```lua
        -- Retourne la liste des devices dont le nom commence par DEVICE_LINKY_PREFIX.
        getLinkyDevices = function(domoticz)
            local prefix = domoticz.helpers.DEVICE_LINKY_PREFIX
            local found = {}
            domoticz.devices().forEach(function(d)
                if string.sub(d.name, 1, #prefix) == prefix then
                    table.insert(found, d)
                end
            end)
            return found
        end,
```

**Fichier `Health_check_dzVents.lua`** : nouveau bloc **6**, entre la fin du bloc 5 (jours fériés) et `-- Résumé` :

```lua
        -- -----------------------------------------------
        -- 6. Plugin Linky : données Enedis (TimedOut plugin après 1,5 j)
        --    et activité du plugin (Touch ~50 s ; seuil 36h)
        -- -----------------------------------------------
        local okLinky, errLinky = pcall(function()
            local linkyDevices = domoticz.helpers.getLinkyDevices(domoticz)
            if #linkyDevices == 0 then
                warn('Linky — aucun device "' .. domoticz.helpers.DEVICE_LINKY_PREFIX .. '<PRM>" trouvé')
            end
            for _, d in ipairs(linkyDevices) do
                if d.lastUpdate.minutesAgo > (36 * 60) then
                    warn('Linky (idx ' .. tostring(d.idx) .. ') — plugin inactif depuis ' .. d.lastUpdate.minutesAgo .. ' min (seuil 36h)')
                elseif d.timedOut then
                    warn('Linky (idx ' .. tostring(d.idx) .. ') — TimedOut : aucune donnée Enedis depuis plus de 1,5 j')
                else
                    domoticz.log('[' .. uuid .. '] Linky (idx ' .. tostring(d.idx) .. ') — OK (' .. d.lastUpdate.minutesAgo .. ' min)', domoticz.LOG_DEBUG)
                end
            end
        end)
        if not okLinky then
            warn('Linky inaccessible : ' .. tostring(errLinky))
        end
```

**Fichier `Config_check.lua`**, après la boucle de la section 1 (`checkExists(... 'Device')`), D-S4d :

```lua
        -- 1bis. Device(s) plugin Linky (nom dynamique 'Linky <PRM>')
        if #domoticz.helpers.getLinkyDevices(domoticz) == 0 then
            domoticz.log('PREREQUIS MANQUANT [Device] : ' .. domoticz.helpers.DEVICE_LINKY_PREFIX .. '<PRM>', domoticz.LOG_ERROR)
            nbErrors = nbErrors + 1
        end
```

Le déclencheur, les événements émis et le marqueur ne changent pas : `[HEALTH CHECK]`, `uuid` et `tostring()` sont respectés. Le script n'a aucun effet de bord, à part la notification existante.

### 4.4 Documentation impactée (S4)

- `domoticz/README.md` l. 38-48 : « 5 indicateurs » devient 6, avec ajout du point 6. Même chose l. 108.
- `docs/ARCHITECTURE.md` :
  - § 5.4 : retirer « aucun script dzVents ne les référence (ni `Config_check.lua` ni `Health_check_dzVents.lua`) » et le point « Supervision : aucune vérification » ;
  - § 6.2 : nouvelle ligne 6 dans le tableau, « 5 indicateurs » devient 6.
- `docs/RETROCONCEPTION_dzVents.md` :
  - l. 40 « quatre indicateurs » est **déjà faux** (il y en a 5) : passer à « six » et ajouter les points 5 et 6 ;
  - lignes de tableau l. 106 et l. 437 ;
  - section `Config_check` : ajouter la vérification par préfixe.
- `.github/copilot-instructions.md` § DEV-5 : liste des indicateurs → 6.
- `.github/instructions/qa.instructions.md` l. 56 : ajouter le seuil Linky.
- Ces deux derniers fichiers relèvent du harnais : DOCly ou MAINa, selon les règles du harnais.
- Rétrodoc du fork § 15 : « supervision » passe à livré.

## 5. Incertitudes à lever à l'exécution (avant S4 et D1)

| Id | Hypothèse | Vérification (👤 ou QALvin, accès Domoticz) |
|---|---|---|
| U1 | `Touch()` rafraîchit `LastUpdate` toutes les ≈ 50 s | `curl -k "https://<hôte>:8043/json.htm?type=command&param=getdevices&rid=<idxLinky>"` à deux reprises, à 2 min d'intervalle : `LastUpdate` change |
| U2 | `timedOut` (dzVents) reflète le `TimedOut` du plugin | Même appel JSON : champ `HaveTimeout` à `false` en fonctionnement normal (dzVents s'appuie sur ce même indicateur). Confirmation finale si un `TimedOut` réel survient. |
| U3 | `onNotification` défini au niveau du module enregistre le plugin comme canal de notification | Interface Domoticz, Configuration > Paramètres > Notifications : présence d'un onglet ou d'un canal « Linky ». Ou bien une `AttributeError … onNotification` dans le journal après une notification. |

Ces sorties contiennent le PRM : **ne pas les recopier** dans le dépôt ni dans les rapports. Ne noter que des résultats booléens.

## 6. Stratégie de test et d'assurance qualité

### S2 et S3 (D-S2a)

| Critère | Q1 : pytest + bouchon du module `Domoticz` + ruff minimal + CI du fork ✅ | Q2 : statique (`py_compile` + ruff) + test manuel sous Domoticz | Q3 : intégration en conteneur Domoticz + sandbox (`Mode3` 10-18) |
|---|---|---|---|
| Avantages | Reproduit D1, D2, D3 et D5 et prouve S3 de façon déterministe. Filet pour l'avenir (D7). | Effort minimal. | Réaliste ; `Mode3=17` donne 3 faux PRM. |
| Inconvénients | Bouchon à maintenir ; nouveaux fichiers dans le fork. | D3 et S3 ne sont pas vérifiables sur l'installation réelle (un seul PRM). | Dépend de la sandbox tierce. Lourd. L'authentification est sautée, donc S3 n'est que partiellement testé. |
| Effort | Moyen | Faible | Élevé |

**Recommandation : Q1**, complétée par un test de fumée en production (phase 5).

Fichiers à créer à la racine du fork `C:\Users\vzwingma\IdeaProjects\domotique-workspace\DomoticzLinky\` :

**`tests/conftest.py`** (jamais à la racine : sinon il finirait dans l'artefact si le chemin restait `*.py`)
- Créer `types.ModuleType("Domoticz")` avec :
  - `Log`, `Error`, `Status`, `Debug` qui enregistrent dans des listes ;
  - `Debugging` sans effet ;
  - `Configuration(d=None)` à état (sans argument : renvoie une copie ; avec argument : remplace et renvoie) ;
  - `Connection` et `Device` = `unittest.mock.MagicMock`.
- `sys.modules["Domoticz"] = fake`.
- Charger `plugin.py` avec `importlib.util.spec_from_file_location("linky_plugin", <racine>/plugin.py)`.
- Injecter `module.Parameters` (`Mode1`-`Mode6`, `Port`, `Name`, `Version`, `DomoticzVersion`, `DomoticzHash`, `DomoticzBuildTime`) et `module.Devices = {}`.
- Fixture `plugin` : un `BasePlugin()` neuf, avec `iDebugLevel = 2`, `fDebug = io.StringIO()` et `iAlternateAddress = 0`.

**Autres fichiers**
- `tests/test_callbacks.py` (D1, D2), `tests/test_merge_counters.py` (D3), `tests/test_devices.py` (D5), `tests/test_cache.py` (D4 caractérisation, D11), `tests/test_secrets_masking.py` (S3).
- `requirements-dev.txt` : `pytest` et `ruff`, en **versions exactes** (les dernières stables le jour de l'implémentation).
- `ruff.toml` :

  ```toml
  target-version = "py311"
  builtins = ["Parameters", "Devices"]

  [lint]
  select = ["E9", "F63", "F7", "F82"]
  ```

  `builtins` évite un faux F821 sur les globales injectées par Domoticz. Le jeu de règles reste minimal, sinon des centaines d'alertes héritées apparaîtraient (E722…).
- `.gitignore` : `__pycache__/`, `.pytest_cache/`, `.ruff_cache/`, `.venv/`.
- `.github/workflows/ci.yml` : déclenché sur `push` vers `master`, `pull_request` et `workflow_dispatch`, avec `permissions: contents: read`.
  - `actions/checkout@v7` (même version que `domotique`) ;
  - `actions/setup-python` en dernière version majeure, **à vérifier sur ses releases** ;
  - `python-version: "3.11"` (Domoticz/Debian 12, à confirmer avec `docker compose exec domoticz python3 --version` sur le NAS) ;
  - étapes : `pip install -r requirements-dev.txt` ; `python -m py_compile plugin.py` ; `ruff check plugin.py tests` ; `python -m pytest -q`.

Méthode de travail :
- Les tests de bug D1, D2, D3 et D5 sont écrits **d'abord**, marqués `@pytest.mark.xfail(strict=True)`, pour prouver le bug.
- DEVon corrige, puis QALvin retire les `xfail`.
- Si ruff signale des F821 existants, QALvin les trie : vrai bug ou faux positif (dans ce cas, ajout dans `builtins`).

**Commandes locales (PowerShell ; disponibilité non vérifiée)**

```
cd C:\Users\vzwingma\IdeaProjects\domotique-workspace\DomoticzLinky
python --version                      # ou: py -3 --version
python -m pip install -r requirements-dev.txt
python -m py_compile plugin.py
python -m ruff check plugin.py tests
python -m pytest -q
```

Si Python est absent : la référence d'exécution est la CI du fork (`gh run list --repo vzwingma/DomoticzLinky --limit 1` puis `gh run watch <id> --repo vzwingma/DomoticzLinky`).

### S1

Voir § 1.3 : `workflow_dispatch` sur la branche, comparaison de blob `git hash-object --no-filters`, résumé du job, validateur Renovate.

### S4

Il n'existe pas de suite Lua ni de tooling dans le dépôt (aucune occurrence de `luac`, `busted` ou `luacheck`).
- **Statique :** revue du déclencheur, de `pcall`, de `tostring`, du marqueur et de `uuid`. `rg -n "DEVICE_LINKY_PREFIX|getLinkyDevices" domoticz/scripts/dzVents` → 3 fichiers. `luac -p <fichier>` seulement si `luac -v` répond.
- **Exécution :**
  - les scripts de production viennent du montage NAS `/volume1/home/vinz/domoticz/scripts/dzVents` et non de l'image (voir Q4) ;
  - au démarrage de Domoticz : pas de `Error … Config_check` / `Health_check` au chargement, et `Contrôle de configuration OK` ;
  - à 08:00 le lendemain : `[HEALTH CHECK] [uuid] Santé dzVents OK` ;
  - les lignes `LOG_DEBUG` Linky ne sont pas visibles (niveau du script : `LOG_INFO`) ;
  - les branches dégradées ne sont prouvées que **statiquement**, et c'est à indiquer comme tel.

## 7. Ordonnancement (D-ORD)

| Critère | O-A (votre proposition) : S3+S2 → v2.6.2 → S1 épinglé sur v2.6.2 → S4 | O-B ✅ : S1 sur **v2.6.1** + S4, puis S3+S2 → v2.6.2 → montée de version |
|---|---|---|
| Avantages | Un seul changement de pin. | Retire tout de suite la dépendance à l'upstream, sans changement fonctionnel. Sépare la chaîne d'approvisionnement du code. Rend le retour arrière lisible. Exerce la procédure de mise à jour sur un cas réel. S1 n'attend pas la PR fork #2. |
| Inconvénients | Provenance et code changent dans le même déploiement : diagnostic ambigu en cas de régression. | Deux reconstructions et deux déploiements d'image. |
| Effort | Identique | Identique, plus une PR de montée de version triviale |

**Branches :**
- `domotique`, après le merge de #232 :
  - `ci/linky_fork_pin` : plan 010, index, ADR 007, S1 et sa documentation ;
  - `feat/health_linky` : S4 ;
  - `ci/linky_v2.6.2` : montée de version (ou la PR Renovate).
  - Trois PR séparées, pour ne pas mélanger CI et dzVents (`copilot-instructions` § « À éviter »).
- Fork, après le merge de #2 : `fix/v2.6.2` depuis `master`.

**Prérequis :**
- #232 doit être fusionnée : la documentation à modifier (§ 5.4, tableau de provenance) n'existe que sur cette branche.
- #2 doit être fusionnée avant la phase 3 : rétrodoc sur `master`, et les liens `blob/master/docs/RETROCONCEPTION.md` déjà publiés dans `domotique` doivent se résoudre.
- Le tag `v2.6.2` et les merges sont faits par 👤.

## 8. Décisions à prendre au Gate #0

1. **Ordonnancement :** O-B (S1 sur v2.6.1 d'abord) ou O-A. *Reco : O-B.*
2. **S1, forme du pin :** SHA de commit + commentaire de tag, tag seul, ou branche. *Reco : SHA + tag.*
3. **S1, mise à jour :** Renovate regex avec `automerge:false`, manuelle, ou Renovate + approbation dans le tableau de bord. *Reco : Renovate sans automerge.*
4. **deCONZ :** inclus (pin `1.0.35` = `95b8f8b…`) ou hors périmètre. *Reco : inclus.*
5. **Périmètre S2 :** maintenant D1, D2, D3 (y compris `KeyError` et `except`), D5, D16 ; D4 en commentaire seulement ; D12 non corrigé (intentionnel) ; D6, D7 (hors harnais), D10, D13, D14, D15 au backlog. **D11 : oui ou non ?** (dépend de Q2).
6. **D1 :** méthodes vides (D1a) ou suppression des fonctions de module (D1b). *Reco : D1a.*
7. **D2 :** version non reconnue → arrêt explicite, ou supposer une version récente. *Reco : arrêt explicite.*
8. **S3 :** masquage par clé + regex (M1), par clé seule (M2), ou suppression des dumps (M3) ; masque `***` complet ; PRM non masqué. *Reco : M1, PRM en clair.*
9. **pickle (S4 / D9 de la rétrodoc) :** hors périmètre, risque accepté et documenté. *Reco : oui.*
10. **Tests S2/S3 :** Q1 (pytest + bouchon + ruff minimal + CI du fork) ou Q2. *Reco : Q1.*
11. **S4, identification :** I1 préfixe `'Linky '`, I2, I3 ou I4. *Reco : I1.*
12. **S4, règles :** 0 dispositif, `lastUpdate` > 36 h, `timedOut` → ERROR + notification ; journaliser l'idx et non le nom. *Reco : oui.*
13. **S4 dans `Config_check` :** ajout de la vérification par préfixe. *Reco : oui.*
14. **Version du fork :** v2.6.2 + `externallink` vers le fork + `CHANGELOG.md` à la racine du fork. *Reco : oui.*

## 9. Découpage candidat (entrée pour MAINa)

Effort indiqué par tâche entre parenthèses. Gates selon `gate-protocol`.

**Phase 0 — Prérequis (👤 / MAINa / DOCly)**

| Tâche | Agent | Contenu | Acceptation |
|---|---|---|---|
| T0.1 | 👤 | Fusionner #232 (`domotique`) et vzwingma/DomoticzLinky#2 | `gh pr view 232 --repo vzwingma/domotique --json state` → `MERGED` ; même vérification pour `--repo vzwingma/DomoticzLinky 2` |
| T0.2 | ⚫ MAINa | Créer `docs/plans/010_linky_suites.plan.md` et mettre à jour `docs/plans/README.md` (010 « EN COURS ») | Index modifié dans le même commit |
| T0.3 | 🟣 DOCly | Écrire `docs/adr/007-plugins-domoticz-provenance-epinglee.md` (Proposée) à partir du § 1.4 | Toutes les sections du gabarit, ≥ 2 alternatives avec motif de rejet |
| T0.4 | 👤 (+ QALvin pour la trace) | Lever U1, U2, U3 et répondre à Q1, Q2 (§ 5 et § 11) | Résultats booléens consignés, sans PRM |

**Phase 1 — S1 (`domotique`, branche `ci/linky_fork_pin`)**

- **T1.1 🔵 DEVon** — `build-domoticz.yml` selon § 1.2 (Linky : `vzwingma/DomoticzLinky` @ `f3df258…` `# v2.6.1` ; deCONZ : `95b8f8b…` `# 1.0.35` ; étapes de traçabilité ; chemins d'artefact ; `if-no-files-found: error`). (Faible)
  - Acceptation :
    - `rg -n "guillaumezin|refs/heads/master" .github/workflows/build-domoticz.yml` → 0 ;
    - `rg -n "ref: [0-9a-f]{40} # " .github/workflows/build-domoticz.yml` → 2 lignes.
- **T1.2 🔵 DEVon** — `renovate.json` selon § 1.2. (Faible)
  - Acceptation : le validateur renvoie OK, ou bien « non exécuté, Node absent » est consigné.
- **T1.3 🟢 QALvin** — Étapes 2 à 7 du § 1.3.
  - Acceptation : run `success` ; artefact Linky = 1 fichier ; blob égal à `v2.6.1:plugin.py` ; `*.py` deCONZ égaux à `1.0.35` ; image poussée avec un tag ≠ `latest`.
- **T1.4 🟣 DOCly** (après le gate de QA) — Mises à jour :
  - `docs/ARCHITECTURE.md` § 5.4 : tableau « Source embarquée », schéma, puce « Provenance non épinglée » → épinglée + lien ADR 007 ;
  - `_docker/build_domoticz/README.md` : tableau « Provenance des plugins » et avertissement de reproductibilité ;
  - `README.md` l. 78 ;
  - fork `docs/RETROCONCEPTION.md` § 1 (avertissement « Upstream non épinglé ») et § 15 ;
  - acceptation : plus aucune mention de « non épinglé / guillaumezin consommé » ; liens valides.
- **T1.5 👤** — Fusionner la PR, puis contrôler dans le tableau de bord Renovate la détection des 2 dépendances.

**Phase 2 — S4 (`domotique`, branche `feat/health_linky` ; indépendante, parallélisable avec la phase 3)**

- **T2.1 🔵 DEVon** — `global_data.lua` (constante + `getLinkyDevices`), `Health_check_dzVents.lua` (bloc 6), `Config_check.lua` (1bis), selon § 4.3. (Faible)
  - Acceptation : `rg` → 3 fichiers ; aucune autre modification ; pas de PRM dans le diff (`rg -n "Linky [0-9]{14}"` → 0).
- **T2.2 🟢 QALvin** — Revue statique (déclencheur, `pcall`, `tostring`, marqueur, `uuid`, `if / elseif`) et exécution (chargement sans erreur, `Contrôle de configuration OK` au démarrage, `Santé dzVents OK` au 08:00 suivant). Les branches dégradées sont validées statiquement.
- **T2.3 🟣 DOCly** — Documentation du § 4.4.

**Phase 3 — S3 + S2 (fork, branche `fix/v2.6.2`)**

| Tâche | Agent | Contenu | Acceptation |
|---|---|---|---|
| T3.1 | 🟢 QALvin | Harnais du § 6 (conftest, requirements-dev, ruff.toml, .gitignore, ci.yml) + tests de caractérisation et de bug en `xfail(strict=True)` | `pytest -q` passe avec les xfail attendus ; CI du fork verte |
| T3.2 | 🔵 DEVon | S3 selon § 3.3 | Tests S3 verts ; `rg 'str\(Value\)'` → 0 dans `setConfigItem` |
| T3.3 | 🔵 DEVon | S2 : D1a, D2, D3, D5, D16, commentaire D4, D11 si GO | Tests correspondants verts une fois `xfail` retiré |
| T3.4 | 🔵 DEVon | Version `2.6.2` + `externallink` | `rg -n 'version="2.6.2"' plugin.py` → 1 ; `git diff master -- plugin.py` ne touche pas aux clés `setConfigItem` / `getConfigItem` |
| T3.5 | 🟢 QALvin | Retirer les xfail ; `py_compile`, `ruff` et `pytest` en local ou en CI ; revue du diff (persistance inchangée, D12 inchangé) | 0 échec, 0 xfail restant ; preuve = sortie de commande ou lien du run CI |

**Phase 4 — Documentation et publication du fork**

- **T4.1 🟣 DOCly** — Fork :
  - `docs/RETROCONCEPTION.md` : § 1 (version 2.6.2, SHA de référence conservé pour l'historique) ; § 11 (masquage) ; § 13 (colonne Statut : S1/S2 « Corrigé v2.6.2 », S4 « Accepté », S7 corrigé « 0600 ») ; § 14 (colonne Statut D1-D16 selon le Gate) ;
  - `CHANGELOG.md` (nouveau) ;
  - `readme.md` : mention de `tests/` et de la CI.
- **T4.2 👤** — Fusionner `fix/v2.6.2`, puis `git tag v2.6.2 <sha-merge>` + push du tag + GitHub Release.
  - Acceptation : `git ls-remote --tags https://github.com/vzwingma/DomoticzLinky v2.6.2` renvoie un SHA.

**Phase 5 — Montée de version et vérification en production (`domotique`, `ci/linky_v2.6.2` ou PR Renovate)**

- **T5.1 🔵 DEVon** (ou PR Renovate) — `ref: <sha de v2.6.2> # v2.6.2`.
  - Acceptation : diff d'une seule ligne ; SHA = `git rev-list -n1 v2.6.2`.
- **T5.2 🟢 QALvin** — Procédure du § 1.3 avec `v2.6.2`.
- **T5.3 👤 / QALvin** — Après merge et redéploiement :
  - le journal Domoticz au démarrage du plugin montre la version 2.6.2 ;
  - la collecte suivante réussit (« Prochaine connexion » au lendemain) ;
  - aucune `AttributeError` ;
  - option : contrôle S3 avec `Mode3=1`, `grep` → 0, puis remise à `Mode3=0` et suppression du fichier.
- **T5.4 🟣 DOCly** — `ARCHITECTURE.md` § 5.4 (« v2.6.2 »), README de build.

**Phase 6 — Clôture** : ADR 007 « Acceptée », plan et index « COMPLÉTÉ ».

## 10. Critères de succès, risques, retour arrière

**Critères de succès mesurables**
1. 0 référence à `guillaumezin` ou à `refs/heads/master` dans `build-domoticz.yml` ; 2 pins SHA commentés.
2. Le blob de l'artefact Linky est égal au blob `plugin.py` du tag épinglé (v2.6.1 puis v2.6.2).
3. Renovate détecte les 2 dépendances, avec `automerge:false` effectif (la PR v2.6.2 n'est pas fusionnée automatiquement).
4. CI du fork verte : `py_compile`, `ruff`, `pytest` ; 0 xfail résiduel.
5. Aucun secret sentinelle dans les sorties capturées ; `grep` à l'exécution → 0 (si réalisé).
6. Health check : 6 indicateurs, `Santé dzVents OK` en production, aucun PRM dans le dépôt.
7. Documentation alignée : ADR 007, plan 010, index, §§ cités.

**Risques et parades**

| Risque | Parade |
|---|---|
| Une erreur de regex fait que Renovate ignore le pin | Preuve dans le tableau de bord (T1.5) ; montée manuelle toujours possible |
| La règle d'automerge globale s'applique au plugin | Règle `automerge:false` placée en dernier ; vérifiée sur la PR v2.6.2 |
| Le masquage regex masque trop ou pas assez | Tests sentinelles + test de non-régression du consentement |
| Régression S2 non couverte (un seul PRM réel) | Tests unitaires D3 ; persistance inchangée, donc retour au pin v2.6.1 en une ligne |
| U1 ou U2 infirmés | Seuils choisis pour fonctionner dans les deux cas ; ajuster si `HaveTimeout` n'est pas exposé (repli : `lastUpdate` > 36 h seul) |
| Collision du préfixe « Linky » | Q1 ; repli I3 (variable utilisateur) |
| La validation sur branche pousse des images `:<branche>` ou `:merge` | Accepté (pas `latest`) ; nettoyage manuel Docker Hub facultatif |
| Jetons déjà exposés par un debug activé par le passé | Q2 : si `Mode3` ≥ 1 a été utilisé, après S3 faire `Mode3=3` (refaire le consentement), purger `/tmp` et les journaux |

**Retours arrière**
- S1 : `git revert` du workflow, puis exécution sur `master` ; ou réutiliser l'image du digest précédent sur le NAS.
- S2/S3 : remettre le pin `f3df258… # v2.6.1`. C'est sûr, puisque la persistance est inchangée.
- S4 : `git revert` des 3 fichiers Lua, puis resynchroniser le montage NAS.

## 11. ❓ Questions pour 👤

1. **Q1** — Noms exacts des dispositifs Linky dans Domoticz : commencent-ils tous par « Linky » ? Existe-t-il un autre dispositif dont le nom commence par « Linky » (TIC Zigbee…) ? Quel est le nom du matériel du plugin ?
2. **Q2** — Valeurs actuelles de `Mode2` (pour décider D11) et de `Mode3`. `Mode3` ≥ 1 a-t-il déjà été utilisé en production ? Si oui, il faut faire tourner les jetons après S3.
3. **Q3** — `vzwingma/domotique` est-il public ? Cela renforce I1 et le refus d'I2.
4. **Q4** — Comment les scripts dzVents sont-ils synchronisés vers le montage NAS (manuel, rsync…) ? Cela conditionne la validation de S4 à l'exécution.
5. **Q5** — Python 3.11+ et Node sont-ils disponibles sur le poste ? Sinon, la CI du fork sert de référence et la validation Renovate est faite par l'application Renovate.
6. **Q6** — Les merges et le tag `v2.6.2` sont-ils faits par vous ? Le plan les suppose faits par 👤.
7. Les 14 décisions du § 8.

```yaml
handoff:
  plan: docs/plans/010_linky_suites.plan.md   # à créer par MAINa après Gate #0
  phase: 0
  agent: ARCos
  tasks: [analyse-S1, analyse-S2, analyse-S3, analyse-S4, decoupage-candidat, contenu-ADR-007]
  status: done
  report: "contenu rendu dans la réponse (lecture seule) — sections 0 à 11"
  files: []
  criteria:
    - id: options-comparees
      met: true
      evidence: "≥2 options + reco pour S1 (pin, MAJ, deCONZ), S2 (D1, D2, tests), S3 (masquage, pickle), S4 (identification, seuils), ordonnancement"
    - id: contenu-ADR
      met: true
      evidence: "§1.4 : docs/adr/007-plugins-domoticz-provenance-epinglee.md (numéro libre vérifié : 001-006 existants)"
    - id: localisation-code
      met: true
      evidence: "plugin.py lu (l. 25, 162, 323-350, 417-627, 632-655, 1024-1084, 1088-1121, 1189-1263, 1416-1497, 1611-1650, 1687-1830, 1915-1984, 1987-2180, 2212-2403) ; build-domoticz.yml, renovate.json, Dockerfile, Health_check, Config_check, global_data.lua lus"
  evidence:
    - command: "lecture .git/refs du fork"
      result: "tag v2.6.1 léger = f3df2584ab398110eefe8d65df1b83d9a9d95395 = master local ; branche feat/fork_and_retrodoc = 7c89964"
    - command: "web_fetch github.com/Smanar/Domoticz-deCONZ/compare/1.0.35...master"
      result: "1 commit README seul ; 1.0.35 = 95b8f8baf6aacda21f2e3aec18d75ac705fd0b8a"
    - command: "web_fetch PR renovate vzwingma/domotique"
      result: "42 PR renovate[bot], dernière #230 du 2026-11-25 → Renovate actif"
    - command: "python/pytest/ruff/luac/node --version"
      result: "non exécuté (aucun outil shell disponible pour ARCos) — disponibilité inconnue"
  risks:
    - "S4 : Touch() toutes les ~50 s rend lastUpdate inutilisable pour la fraîcheur des données → indicateur timedOut + lastUpdate>36h ; U1/U2 à confirmer à l'exécution"
    - "D12 ne doit pas être corrigé (contournement 500 = pas de production) : boucle de nouvelles tentatives sinon"
    - "D3 : KeyError value_year → échec global et nouvelle tentative toutes les heures si un PRM n'a pas de données dans l'année"
    - "règle Renovate globale automerge minor/patch : packageRule automerge:false obligatoire pour les plugins"
    - "les validations workflow_dispatch/PR poussent des images :<branche>/:merge (comportement existant)"
    - "rétrodoc fork à corriger : fichier de debug créé en 0600 (mkstemp), RETROCONCEPTION_dzVents l.40 indique déjà 'quatre' indicateurs au lieu de 5"
  questions:
    - "Q1 noms exacts des devices/matériel Linky, collision de préfixe ?"
    - "Q2 Mode2 (D11) et Mode3 actuels/historiques (rotation des jetons ?)"
    - "Q3 dépôt domotique public ?"
    - "Q4 mode de synchronisation des scripts dzVents vers le NAS"
    - "Q5 Python 3.11+/Node disponibles localement ?"
    - "Q6 merges et tag v2.6.2 réalisés par 👤 ?"
    - "Décisions Gate #0 n°1 à 14 (§8)"
  next: "Gate #0 (MAINa) → MAINa crée le plan 010 + index, DOCly rédige l'ADR 007 (Proposée) → Gate #1 → Phase 1 (DEVon T1.1-T1.2)"
```