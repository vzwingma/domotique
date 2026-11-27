# Plan 011 — Phase 0 : contrat Conso API V2

**Statut :** ✅ T0.1/T0.2 faits (captures 👤 du 2026-11-27, période 23→26/11/2026) — reste R6b (période max puissance) et R9 (durée de vie du jeton).
**Date :** 2026-11-27
**Sources :** captures `capture_consoapi_v2.ps1` (8 réponses, PRM masqué, aucun jeton) ; `https://conso.boris.sh/documentation`, `/migration-2026`, `/exemples` (lues le 2026-11-27). Aucun jeton ni PRM réel dans ce document.

---

## 1. Établi (documentation publique)

| Point | Constat |
|---|---|
| Route | `GET https://conso.boris.sh/api/<type>?pointId=<PRM>&dateDebut=YYYY-MM-DD&dateFin=YYYY-MM-DD` |
| Types V2 utiles | `courbe_de_charge_consommation`, `puissance_conso_max_quotidienne`, `consommation_quotidienne` (+ `index_consommation`, `*_production` non utilisés — Q3) |
| Correspondance v5 → V2 | `consumption_load_curve` → `courbe_de_charge_consommation` ; `consumption_max_power` → `puissance_conso_max_quotidienne` ; `daily_consumption` → `consommation_quotidienne` |
| Paramètres | `pointId` (PRM 14 chiffres, alias historique `prm`) ; `dateDebut` inclusive (alias `start`) ; `dateFin` **exclusive** (alias `end`) |
| Paramètres spécifiques puissance max | `mesuresPas` = `P1D` (défaut) / `P1M` ; `grandeurPhysique` = `PMA` (défaut) / `TOUT` |
| En-têtes | `Authorization: Bearer <jeton>` obligatoire ; `User-Agent` identifiant le projet exigé (contact via UA ou `From`) |
| Codes | 200 OK ; 400 requête invalide → **ne pas réessayer** ; 401 jeton invalide **ou** sans droit sur ce PRM ; 500 erreur Enedis/Conso API → réessayer après minutes/heures |
| Quotas (Enedis, partagés) | 5 req/s, 10 000 req/h ; blocage IP sans préavis en cas d'abus |
| Cadence conseillée | 1 appel/jour entre 6 h et 10 h à une heure « atypique » ; données de J disponibles vers 8 h à J+1 (parfois +1-2 h) |
| Alias v5 | Encore acceptés jusqu'à la coupure Enedis (annoncée mi-octobre 2026, date réelle inconnue) → **n'utiliser que les noms V2** |

### Écarts avec le plan

- Paramètres et noms de types du plan (T1.2) **confirmés**.
- Codes 404 / 429 : **non documentés** ; conserver la politique du plan (404 → pas de données, 429/5xx → retry différé) jusqu'à constat.
- L'heure de déclenchement doit tomber entre 6 h et 10 h (à intégrer au décalage aléatoire du cycle quotidien, T1.2).

## 2. Constaté par capture (T0.2)

### 2.1 Enveloppe commune des réponses 200

```json
{"idPrm":"00000000000000","etapeMetier":"BRUT","periode":{"dateDebut":"2026-11-23","dateFin":"2026-11-26"},
 "modeCalcul":"MESURE","pas":"P1D",
 "grandeur":[{"grandeurMetier":"CONS","grandeurPhysique":"PMA","unite":"VA",
              "points":[{"v":"3503","d":"2026-11-23 12:48:53"}, ...],"calendrier":[]}],
 "contexte":[]}
```

- Valeurs `v` en **chaîne** (comme v5) ; dates `d` au format `YYYY-MM-DD HH:MM:SS` (ou `YYYY-MM-DD` pour le quotidien), **sans fuseau**.
- `grandeur` est une liste : 1 seul élément (`grandeurMetier = CONS`) observé pour chaque type.

### 2.2 Par type

| Type | `grandeurPhysique` / `unite` | Pas | Champ `d` | Points (3 jours) |
|---|---|---|---|---|
| `courbe_de_charge_consommation` | `PA` / **W** (puissance moyenne) | **`PT15M`** (par point, champ `p`) — v5 = 30 min | **fin d'intervalle** (`00:15` … `J+1 00:00`) | 288 ; champs en plus : `n` = `B`, `iv` = `0`, `ec` = `0` |
| `puissance_conso_max_quotidienne` | `PMA` / **VA** | `P1D` | horodatage **du pic** | 3 |
| `consommation_quotidienne` | `EA` / **Wh** | `P1D` (`modeCalcul = DIFF.INDEX`) | jour (`YYYY-MM-DD`) | 3 |

**Vérification croisée :** Σ(courbe × 0,25 h) sur chaque jour, en rattachant chaque point à la fin de son intervalle, donne **exactement** la consommation quotidienne (5 248 / 6 159 / 5 071 Wh). Le rattachement « début d'intervalle » donne des écarts (5 210 / 5 865 / 5 369). → convention fin d'intervalle confirmée ; heure **locale** (cohérente avec les jours Enedis).

### 2.3 Compatibilité avec le cœur du plugin (v2.7.0)

- `exploreDataHours()` moyenne les points entre deux `:00` (`accumulation / steps`) : avec 4 points de 15 min en W, il produit la moyenne horaire en W = Wh de l'heure. Simulation sur l'échantillon : 72 heures, première `2026-11-23 01:00` = 135 Wh. **Aucune modification du calcul nécessaire.**
- `enedisDateTimeToDatetime()` lit `d` sans changement (`[:10]` + `[11:19]`).
- `exploreDataPeaks()` : valeur VA + date du pic ; seule la date (jour) est utilisée → compatible.
- Contrôle du PRM : `idPrm` remplace `meter_reading.usage_point_id`.

### 2.4 Période maximale

| Type | Constat |
|---|---|
| Courbe de charge | **≤ 7 jours** : 8 j et 31 j → 400 `ADAM-DC-0015` « La période demandée est supérieure à 7 jours. » Le plugin découpe déjà par lots de 7 j (`calculateDaysLeft()`, vue heures) → conforme |
| Puissance max | **R6b non déterminé** : le plugin demande jusqu'à 1 095 j par requête (`calculateDaysLeft()`, vue jours) → capture complémentaire `-Complement` (365 j, 1 095 j) |
| Quotidien | non testé (non utilisé) |

### 2.5 Erreurs

| Cas | HTTP | Corps |
|---|---|---|
| Erreur Enedis (période inversée, > 7 j) | 400 | `{"status":400,"message":"The Enedis API returned an error","error":{"error":"ADAM-…","error_description":"…"}}` |
| Paramètre invalide (validation Conso API) | 400 | `{"status":400,"message":"Paramètres invalides","error":{"issues":[…],"name":"ZodError"}}` — la liste des types acceptés inclut encore les noms v5 |
| Jeton invalide | 401 | `{"status":401,"message":"Votre token est invalide ou ne permet pas d'accéder à ce PRM"}` |
| 404 / 429 / 5xx | — | non observés |

Message à afficher : `error.error_description` si présent, sinon `message`.

### 2.6 En-têtes

Derrière **Cloudflare** ; `Content-Type: application/json` ; **aucun en-tête de quota**. `User-Agent` projet accepté.

## 3. Non déterminé

| # | Point | Suite |
|---|---|---|
| R6b | Période max `puissance_conso_max_quotidienne` | `pwsh .\capture_consoapi_v2.ps1 -Prm <PRM> -Complement` (2 requêtes) ; à défaut, découpage défensif à 365 j |
| R9 | Durée de vie du jeton | 👤 : décoder localement la 2ᵉ partie du JWT, noter seulement `exp` |
| R10 | Passage heure d'été/hiver (doublon/trou à 02:xx) | non observable avant mars 2027 ; adaptateur tolérant ; comportement de `exploreDataHours()` sur doublon/trou à couvrir par un test (T2.2) |
| R11 | Points avec `n` ≠ `B` / `iv` ≠ `0` (qualité / invalidité) | non observés ; adaptateur : conserver la valeur, journaliser en debug |

## 4. Correspondance V2 → forme interne (adaptateur T1.3)

```text
V2                                   → interne (lu par exploreData*)
idPrm                                → meter_reading.usage_point_id
grandeur[i] (grandeurMetier == CONS) → (sélection, 1re occurrence)
grandeur[i].points[j].v              → meter_reading.interval_reading[j].value
grandeur[i].points[j].d              → meter_reading.interval_reading[j].date
corps avec "error" / "status" ≠ 200  → chemin d'erreur existant (showStatusError) avec error_description
```

Fixtures anonymisées (8 JSON) prêtes pour T2.1 : dossier projet `plan011/fixtures_consoapi_v2/`.
