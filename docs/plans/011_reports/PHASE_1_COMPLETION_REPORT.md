# Plan 011 — Phase 1 : implémentation (rapport)

**Date :** 2026-11-27 · **Statut :** ✅ Terminée — Gate #2 en attente
**Dépôt :** `vzwingma/DomoticzLinky`, branche `claude/project-thread-kei9q4` (au lieu de `feat/consoapi-v2` : branche imposée par l'environnement de session), commit `ffd2545`
**Diff :** `plugin.py` +315/−26 ; `tests/conftest.py` +2 (paramètre `Address = russandol` par défaut pour les suites v2.x, aucune assertion modifiée)

## Tâches

| Tâche | Réalisation |
|---|---|
| T1.1 | En-tête XML : `Address` (liste `consoapi` par défaut / `russandol`), `Username` (PRM, virgules), `Password` (jeton, `password="true"`). Lus dans `onStart()` **avant** le retrait historique de `Username`/`Password` de `Parameters`. Jeton vide ou PRM ≠ 14 chiffres → erreur explicite, plugin non démarré, aucune requête. `Mode3` ≥ 10 force le bac à sable Russandol |
| T1.2 | Index d'adresse 2 = `conso.boris.sh:443`, chemin `/api/<type>` (correspondance `CONSOAPI_TYPES`), `pointId`/`dateDebut`/`dateFin`, `Authorization: Bearer`, `User-Agent: DomoticzLinkyPlugin/<version> (+https://github.com/vzwingma/DomoticzLinky)`. `idle` → `start` sans Device Flow. Pas de production. 401/403 → message jeton, pas de nouvelle tentative avant demain ; 400 → erreur `ADAM-*` + description, pas de retry ; 404 → chemin existant ; 429/5xx/absence de statut/délai dépassé → arrêt du cycle + tentative différée |
| T1.3 | `consoApiV2ToInternal()` : `idPrm` → `usage_point_id`, `grandeur[CONS].points[{v,d}]` → `interval_reading[{value,date}]`. Appelée dans `exploreDataHours()`/`exploreDataPeaks()` ; toute autre forme est renvoyée inchangée (Russandol). `getError()` lit l'erreur imbriquée V2 et `message` |
| T1.4 | `registerSecret()` : le jeton est masqué partout (`maskSecrets`) ; clé `password` ajoutée à `SENSITIVE_KEYS` ; `version="3.0.0"` |
| T1.5 | Budget persisté `consoapi_budget` (jour, compteur par PRM, lots d'historique, tentative différée) : **≤ 3 requêtes/jour/PRM** (contrôle avant requête + garde-fou à chaque envoi réel), **≤ 1 lot d'historique/jour/PRM** (lot ≠ le plus récent, jamais sur la dernière requête du jour ; les lots suivants sont reportés aux jours suivants → étalement), **une seule tentative différée** à +3 h (avant 22 h) si échec temporaire ou veille incomplète, sinon lendemain 8 h + minutes aléatoires. Redémarrage le jour d'un cycle réussi → pas de connexion avant demain. Lots de puissance max de 365 j |

## Vérifications

| Commande | Résultat |
|---|---|
| `python -m py_compile plugin.py` | OK |
| `python -m ruff check plugin.py tests` | All checks passed |
| `python -m pytest -q` | **111 passed** (suites existantes, chemin Russandol) |
| Essai de bout en bout hors dépôt (fixtures Phase 0, stub Domoticz) | 4/4 : cycle nominal = **2 requêtes** (courbe 7 j + puissance max) ; URL/en-têtes conformes ; 401 → lendemain ; 500 → une tentative à +3 h puis lendemain ; 8 cycles forcés → **3 requêtes max** ; jeton absent des journaux ; Σ horaire (convention fin d'intervalle) = quotidien Enedis 5 248 / 6 159 / 5 071 Wh |

## Points d'attention pour la revue

- Convention horaire héritée de v5 : la valeur horaire stockée à `J 00:00` est la dernière heure de `J-1` (horodatage fin d'intervalle) — comportement inchangé.
- Défaut `Address` vide → Conso API : une installation v2.x mise à jour sans reconfiguration s'arrête avec un message clair (version incompatible 3.0.0, attendu).
- Les tests de Phase 2 reprendront l'essai de bout en bout dans `tests/test_consoapi_*.py`.
