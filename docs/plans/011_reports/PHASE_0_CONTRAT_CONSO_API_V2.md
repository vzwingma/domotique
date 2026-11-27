# Plan 011 — Phase 0 : contrat Conso API V2 (brouillon)

**Statut :** 🟡 En cours — partie « requête » établie depuis la documentation publique ; partie « réponse » en attente des captures 👤 (T0.1/T0.2).
**Date :** 2026-11-27
**Sources :** `https://conso.boris.sh/documentation`, `/migration-2026`, `/exemples` (lues le 2026-11-27). Aucun jeton ni PRM réel dans ce document.

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

## 2. Non déterminé — à constater par capture (T0.2)

| # | Question | Capture |
|---|---|---|
| R1 | Structure JSON de chaque type (racine, liste de mesures, champs) | `200_*` |
| R2 | Horodatage : début ou fin d'intervalle, format, fuseau | `200_courbe_*` |
| R3 | Pas de la courbe (30 min ?) et champ qui le porte | `200_courbe_*` |
| R4 | Unités (W, Wh, kW, VA) par type | `200_*` |
| R5 | Champ portant le PRM (contrôle T1.3) | `200_*` |
| R6 | Période maximale par requête (courbe) | `periode_8j`, `periode_31j` |
| R7 | Format JSON des erreurs 400 / 401 / type inconnu | `err_*` |
| R8 | En-têtes de quota éventuels | en-têtes des `200_*` |
| R9 | Durée de vie du jeton (JWT : champ `exp`, à lire **par 👤 localement**, ne pas coller le jeton) | — |

## 3. Procédure de capture (👤)

Script : [`capture_consoapi_v2.ps1`](./capture_consoapi_v2.ps1) (PowerShell 7+, ~8 requêtes).

1. Consentement sur conso.boris.sh, réception du jeton (T0.1).
2. `pwsh .\capture_consoapi_v2.ps1 -Prm <PRM> -Jours 3` ; jeton saisi masqué.
3. Relire les fichiers produits (PRM remplacé par `00000000000000`, aucun jeton), puis les partager pour analyse.
4. Optionnel R9 : décoder localement la 2ᵉ partie du jeton (base64url) et noter uniquement `exp`.

## 4. Correspondance V2 → forme interne

À rédiger après captures : cible `interval_reading[{date, value}]` lue par `exploreDataHours()` / `exploreDataPeaks()`.
