# Plan 011 — Phase 2 : tests (rapport)

**Date :** 2026-11-27 · **Statut :** ✅ Terminée — Gate #3 en attente
**Dépôt :** `vzwingma/DomoticzLinky`, PR #5, commit `b43529d`

## Livrables

| Tâche | Fichier(s) | Contenu |
|---|---|---|
| T2.1 | `tests/fixtures/consoapi_v2/*.json` (7) | Captures réelles du 2026-11-27, PRM `00000000000000`, aucun jeton ; 3 réponses 200 + 4 erreurs (400 > 7 j, 400 période inversée, 400 type inconnu, 401) |
| — | `tests/consoapi_helpers.py` | Horloge figée (`FakeDatetime`), démarrage `onStart()` Conso API, pilote de cycle complet de la machine à états |
| T2.2 | `tests/test_consoapi_adapter.py` (26) | Conversion V2 ; autres formes inchangées ; points incomplets / qualité inhabituelle ; **Σ horaire = quotidien Enedis** (5 248 / 6 159 / 5 071 Wh) ; moyenne 4 × 15 min ; pics ; autre PRM refusé ; corps vide / non JSON sans exception ; doublon/trou d'heure (R10) ; erreurs V2 (`ADAM-*`, ZodError, 401) ; erreur OAuth Russandol inchangée |
| T2.2 | `tests/test_consoapi_source.py` (41) | Paramètres (complet, multi-PRM, défaut, incomplet → aucune requête, Russandol) ; URL/en-têtes/User-Agent/hôte ; pas de Device Flow ni de production ; 401/403/400 → lendemain ; 404 ; 429/500/502/503/sans statut/délai dépassé → une tentative à +3 h puis lendemain ; pas de tentative après 22 h ; **≤ 3 requêtes/jour/PRM sur 8 cycles forcés** (500, 429, 401, 400) ; budget persisté au redémarrage, remis à zéro le lendemain ; garde-fou à l'envoi ; pas de resynchronisation au redémarrage ; budget par PRM et requêtes séquentielles ; **historique étalé** (1 lot/jour, reprise le lendemain) ; lots de puissance max de 365 j |
| T2.3 | `tests/test_secrets_masking.py` (+4, assertions existantes inchangées) | Cycle complet en debug avancé : jeton absent des journaux Domoticz et du fichier `/tmp/DomoticzLinky_*.log` ; jeton renvoyé dans une réponse masqué ; clé `password` masquée |

## Résultats

| Commande | Résultat |
|---|---|
| `python -m pytest -q` | **182 passed** (111 existants + 71 nouveaux) |
| `python -m ruff check plugin.py tests` | All checks passed |
| CI GitHub du fork | verte sur `ffd2545` ; relancée sur `b43529d` |
| Couverture (`pytest-cov`, mesure locale) | `plugin.py` 75 % global ; **lignes ajoutées par le plan : 228 / 233 = 97,9 %** (non couvertes : deux retours du garde-fou d'envoi, une branche cache) |

## Preuves de détection de régression

- **Adaptateur cassé** (remplacé par l'identité) → `test_regression_detectee_si_adaptateur_casse` : la réponse V2 n'est plus lue (test dédié, vert car il vérifie l'échec).
- **Masquage cassé** (`registerSecret` neutralisé, mutation temporaire puis restauration) → 2 échecs : `test_jeton_renvoye_dans_une_reponse`, `test_masquage_jeton_sans_schema`.

## Notes

- HC/HP : code inchangé (répartition au moment de `saveDataToDb`), couvert par les suites existantes ; les valeurs horaires fournies sont identiques en forme à v5.
- `pytest-cov` n'est pas ajouté à `requirements-dev.txt` (mesure ponctuelle).
