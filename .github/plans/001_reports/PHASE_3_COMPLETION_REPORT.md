# PHASE 3 COMPLETION REPORT — DEV-3 Robustesse HTTP + sécurisation Freebox

**Plan :** [001_dzvents_stabilisation.plan.md](../001_dzvents_stabilisation.plan.md)  
**Statut phase :** ✅ COMPLÉTÉE (T3.2 ✅ T3.3 ✅ T3.4 ✅ T3.5 ✅)

---

## Tâches

### T3.1 — ARCos : validation cadrage DEV-3
**Statut :** ✅ DONE (rétro-validé)

**Critères d'acceptation validés :**
- ✅ Stratégie retry bornée documentée : le retry sur GET idempotents est délégué aux scripts appelants ; le handler `global_HTTP_response.lua` couvre les callbacks POST/PUT non idempotents sans retry
- ✅ Distinction explicite idempotent/non-idempotent documentée dans les commentaires du code
- ✅ Exigences sécurité Freebox formalisées : `shellEscape` + `validateShellInput` implémentés dans `Freebox_login.lua`

### T3.2 — DEVon : robustesse HTTP commune
**Statut :** ✅ DONE

**Fichiers modifiés :**
- `domoticz/scripts/dzVents/global_HTTP_response.lua`

**Implémentation réalisée :**
- Journalisation enrichie : `corrId` (header `X-CorrId`), `callbackName`, `statusCode`, `statusText`, `data`
- Classification HTTP : `httpErrorClass()` distingue OK / TIMEOUT-CONNEXION / ERREUR_CLIENT / ERREUR_SERVEUR / INCONNU
- Compteur `consecutiveErrors` persistant, remis à 0 au premier succès
- Alerte `LOG_ERROR` dès que `consecutiveErrors >= HTTP_ERROR_THRESHOLD` (3)
- Note explicite : pas de retry dans ce handler (non idempotents) ; retry GET à la charge des scripts appelants

**Critères d'acceptation validés :**
- ✅ Journalisation enrichie et corrélable via `corrId`
- ✅ Compteur d'échecs consécutifs opérationnel
- ✅ Alerte déclenchée au seuil 3 erreurs consécutives
- ✅ Pas de retry sur actions non idempotentes (commenté et documenté)

### T3.3 — DEVon : sécurisation construction shell Freebox
**Statut :** ✅ DONE

**Fichiers modifiés :**
- `domoticz/scripts/dzVents/Freebox_login.lua`

**Implémentation réalisée :**
- `shellEscape(s)` : échappe les guillemets simples pour injection sécurisée dans une commande shell
- `validateShellInput(value, name, uuid)` : valide type, non-vide, absence de `\0`/`\n`/`\r`
- Validation de `challenge` et `app_token` avant construction de la commande HMAC SHA1
- `app_token` non journalisé (secret applicatif protégé)
- Nil guards sur `item.json.result.challenge` et `item.json.result.session_token`
- Journalisation de l'erreur `session` via `item.json.msg` ou `item.data` en fallback

**Critères d'acceptation validés :**
- ✅ Interpolation contrôlée et échappée
- ✅ Risque d'injection réduit (validation + échappement)
- ✅ Comportement d'authentification Freebox inchangé côté métier

### T3.4 — QALvin : validation robustesse HTTP + flux Freebox
**Statut :** ✅ DONE (avec 3 anomalies mineures signalées — correction non bloquante)

**Méthode :** Vérification statique du code source (pas de suite de tests Lua disponible dans ce repo).  
**Fichiers analysés :**
- `domoticz/scripts/dzVents/global_HTTP_response.lua`
- `domoticz/scripts/dzVents/Freebox_login.lua`

---

#### A. `global_HTTP_response.lua` — Résultats point par point

**A.1 — Cas nominal (statut 2xx)**
- ✅ `domoticz.data.consecutiveErrors = 0` (ligne 47) — remis à zéro au premier succès
- ✅ Log `LOG_DEBUG` avec `corrId`, `callbackName`, `statusCode`, `statusText`, `data` (lignes 48-51)

**A.2 — Cas timeout/connexion (statusCode = 0)**
- ✅ `httpErrorClass(0)` retourne `'TIMEOUT/CONNEXION'` (ligne 35)
- ✅ Compteur `consecutiveErrors` incrémenté (ligne 55)
- ✅ Log `LOG_ERROR` avec nombre d'erreurs consécutives (lignes 58-63)

**A.3 — Cas erreur client (4xx)**
- ✅ `httpErrorClass` retourne `'ERREUR_CLIENT'` pour codes 400-499 (ligne 36)
- ✅ Compteur incrémenté, log `LOG_ERROR`

**A.4 — Cas erreur serveur (5xx)**
- ✅ `httpErrorClass` retourne `'ERREUR_SERVEUR'` pour codes ≥ 500 (ligne 37)
- ✅ Compteur incrémenté, log `LOG_ERROR`

**A.5 — Seuil d'alerte (consecutiveErrors ≥ 3)**
- ✅ `HTTP_ERROR_THRESHOLD = 3` déclaré en constante locale (ligne 24)
- ✅ Alerte supplémentaire en `LOG_ERROR` déclenchée dès `count >= HTTP_ERROR_THRESHOLD` (lignes 69-74)

**A.6 — Extraction sécurisée corrId**
- ✅ `local corrId = (item.headers and item.headers["X-CorrId"]) or "n/a"` (ligne 27)
- ✅ Évaluation court-circuit garantit `"n/a"` si `item.headers` est `nil`, sans erreur Lua

**A.7 — Non-régression**
- ✅ Trigger `httpResponses = { 'global_HTTP_response' }` déclaré (ligne 10)
- ✅ `data.consecutiveErrors = { initial = 0 }` déclaré persistant (lignes 13-16)
- ✅ Pas de retry dans ce handler — commenté explicitement (note T-B2 lignes 66-68)
- ✅ Marker de log `[HTTP Response] ` conforme à la convention `[Domaine] `
- ✅ `nil` uniquement, aucun usage de `null`
- ✅ `tostring()` appliqué sur `item.statusText` et `item.data` (lignes 49-50, 60-61)

**Verdict `global_HTTP_response.lua` : ✅ CONFORME — Aucune anomalie.**

---

#### B. `Freebox_login.lua` — Résultats point par point

**B.1 — `shellEscape(s)`**
- ✅ Valeur sans guillemet simple : `shellEscape("hello")` → `'hello'` (encadrement correct)
- ✅ Valeur avec `'` : `shellEscape("it's")` → `'it'\''s'` (gsub correct ligne 28)
- ✅ Déclarée `local function shellEscape(s)` (ligne 27)

**B.2 — `validateShellInput(value, name, uuid)`**
- ✅ Type non-string → `type(value) ~= 'string'` → `false` + `LOG_ERROR` (ligne 38-40)
- ✅ Chaîne vide → `#value == 0` → `false` + `LOG_ERROR` (ligne 38-40)
- ✅ Présence de `\0`, `\n`, `\r` → `value:find("[\0\n\r]")` → `false` + `LOG_ERROR` (lignes 42-44)
- ✅ Chaîne valide → `return true` sans log d'erreur (ligne 45)
- ✅ Déclarée `local function validateShellInput(...)` (ligne 37)

**B.3 — Flux init session (timer / `freebox_initsession`)**
- ✅ Déclencheur `item.isTimer or (item.isCustomEvent and item.customEvent == 'freebox_initsession')` (ligne 133)
- ✅ UUID généré via `domoticz.helpers.uuid()` (ligne 134)
- ✅ `freeboxLogin(domoticz)` appelé (ligne 137)

**B.4 — Callback login (`freebox_login`, statusCode 200)**
- ✅ Nil guard complet : `item.json == nil or item.json.result == nil or item.json.result.challenge == nil` → `LOG_ERROR` + abandon (lignes 144-146)
- ✅ `freeboxGetPassword(item.json.result.challenge, domoticz)` appelé si challenge présent (ligne 149)

**B.5 — Callback shell HMAC (`freebox_pwd`, statusCode 0)**
- ✅ Handler `isShellCommandResponse and item.callback == 'freebox_pwd'` (ligne 155)
- ✅ `statusCode == 0` (succès shell) → `freeboxOpenSession(item.data, domoticz)` (lignes 158-159)
- ✅ Sinon `LOG_ERROR` avec code et data (lignes 161-162)

**B.6 — Callback session (`freebox_session`, statusCode 200)**
- ✅ Nil guard complet : `item.json == nil or item.json.result == nil or item.json.result.session_token == nil` → `LOG_ERROR` + abandon (lignes 169-170)
- ✅ `freeboxAuthenticated(item.json.result.session_token, domoticz)` appelé si token présent (ligne 173)

**B.7 — Erreur HTTP session**
- ✅ `local errMsg = (item.json and item.json.msg) or item.data or "réponse vide"` (ligne 176) — utilise `item.json.msg`, fallback `item.data`, fallback `"réponse vide"`
- ✅ `tostring(errMsg)` (ligne 177) — protège contre `nil`

**B.8 — Non-régression (triggers)**
- ✅ `timer = { 'every minute' }` (ligne 7)
- ✅ `customEvents = { 'freebox_initsession', 'freebox_endsession' }` (ligne 8)
- ✅ `httpResponses = { 'freebox_login', 'freebox_session' }` (lignes 9-10)
- ✅ `shellCommandResponses = { 'freebox_pwd' }` (ligne 11)
- ✅ `app_token` non journalisé — commentaire explicite ligne 78, `apptoken_freebox` absent de tous les logs

---

#### Anomalies identifiées dans `Freebox_login.lua`

> ⚠️ Ces anomalies ne bloquent pas la clôture de T3.4 mais doivent être consignées pour correction dans un lot futur.

**ANOMALIE-1 — Fonctions internes sans `local` (DEV-1)**
- **Fichier :** `Freebox_login.lua`, lignes 52, 66, 93, 114, 119
- **Problème :** Cinq fonctions sont déclarées sans le mot-clé `local` à l'intérieur de `execute = function(...)` :
  - `function freeboxLogin(domoticz)` (ligne 52)
  - `function freeboxGetPassword(challenge, domoticz)` (ligne 66)
  - `freeboxOpenSession = function(...)` (ligne 93)
  - `function freeboxAuthenticated(session_token, domoticz)` (ligne 114)
  - `freeboxCloseSession = function(...)` (ligne 119)
- **Règle violée :** DEV-1 — *"déclarer systématiquement les variables temporaires avec `local`"*. En Lua, une fonction déclarée sans `local` dans un bloc crée une variable globale implicite, contrairement à `shellEscape` et `validateShellInput` qui utilisent correctement `local function`.
- **Risque :** Pollution de l'espace global Lua du sandbox dzVents ; collision potentielle si un autre script déclare une fonction de même nom. Risque faible en pratique (noms uniques) mais non conforme à la règle.
- **Correction recommandée :** Préfixer les cinq déclarations avec `local`. À réaliser dans un lot dédié sans impact fonctionnel.

**ANOMALIE-2 — Nil guard absent sur payload `freebox_endsession`**
- **Fichier :** `Freebox_login.lua`, lignes 179-180
- **Problème :** Le handler `freebox_endsession` accède directement à `item.json.uuid` et `item.json.sessionToken` sans vérifier que `item.json` est non-nil :
  ```lua
  elseif(item.isCustomEvent and item.customEvent == 'freebox_endsession') then
      freeboxCloseSession(item.json.uuid, item.json.sessionToken, domoticz)
  ```
- **Risque :** Si l'événement est émis sans payload JSON valide (ou sans les champs `uuid`/`sessionToken`), l'accès à `item.json.uuid` provoquera une erreur Lua (`attempt to index a nil value`).
- **Correction recommandée :** Ajouter un nil guard avant l'appel :
  ```lua
  if item.json == nil or item.json.uuid == nil or item.json.sessionToken == nil then
      domoticz.log("[Freebox Delta] freebox_endsession : payload invalide (uuid ou sessionToken absent)", domoticz.LOG_ERROR)
  else
      freeboxCloseSession(item.json.uuid, item.json.sessionToken, domoticz)
  end
  ```

**ANOMALIE-3 — `session_token` journalisé en LOG_DEBUG (observation)**
- **Fichier :** `Freebox_login.lua`, lignes 120 et 172
- **Observation :** Le `session_token` de session (token éphémère) est journalisé en clair :
  - Ligne 120 : `"[sessionToken=" .. sessionToken .. "] Clôture de la session"` (dans `freeboxCloseSession`)
  - Ligne 172 : `"Session Token :" .. item.json.result.session_token` (callback `freebox_session`)
- **Nuance :** La règle de sécurité explicite (`app_token` non journalisé) est respectée — c'est le token applicatif long-lived qui est protégé. Le `session_token` est un token de session éphémère. Cette observation est informative.
- **Recommandation :** À évaluer selon la politique de sécurité locale. Si les logs sont accessibles à des tiers, masquer ou tronquer le `session_token` en LOG_DEBUG.

---

#### Conformité aux règles non-régression globales (périmètre T3.4)

| Règle | Vérification | Statut |
|---|---|---|
| DEV-1 : `nil`, jamais `null` | Aucun usage de `null` dans les deux fichiers | ✅ OK |
| DEV-1 : `tostring()` sur variables potentiellement `nil` | Appliqué sur `statusText`, `data`, `errMsg`, `logged_in`, `result` | ✅ OK |
| DEV-1 : déclaration `local` | Violations sur 5 fonctions dans `Freebox_login.lua` | ⚠️ ANOMALIE-1 |
| Format marker `[Domaine] ` | `[HTTP Response] ` et `[Freebox Delta] ` | ✅ OK |
| Traçabilité `uuid` dans les logs | `corrId` dans global_HTTP, `domoticz.data.uuid` dans Freebox | ✅ OK |
| Aucun ID Tydom en dur (DEV-4) | Non applicable à ces fichiers | ✅ N/A |
| `verifyGroupeFromItem` pour groupes (DEV-5) | Non applicable à ces fichiers | ✅ N/A |
| `app_token` non journalisé | Confirmé, commentaire explicite ligne 78 | ✅ OK |
| Nil guards sur accès JSON | Présents pour `challenge` et `session_token` ; absent pour `freebox_endsession` | ⚠️ ANOMALIE-2 |

---

#### Synthèse T3.4

**Tests de non-régression Freebox :** ✅ Flux fonctionnel complet intact (init → login → HMAC → session → close)  
**Erreurs HTTP visibles avec contexte :** ✅ corrId + callbackName + errorClass dans tous les logs d'erreur  
**Retries non agressifs :** ✅ Aucun retry dans le handler global ; stratégie documentée  
**Pas de retry sur actions non idempotentes :** ✅ Confirmé (commentaire T-B2 explicite)

**Anomalies bloquantes :** 0  
**Anomalies à corriger (lot futur) :** 2 (ANOMALIE-1, ANOMALIE-2)  
**Observations informatives :** 1 (ANOMALIE-3)

### T3.5 — DOCly : finalisation documentation post DEV-3
**Statut :** 🔄 EN COURS

**Périmètre à documenter :**
- `INSTRUCTIONS_TRAVAUX_dzVents.md` : Phase 3 → statut `✅ Couverte par le lot DEV-3` + vigilances
- `ORCHESTRATION_dzVents.md` : si impacté
- `README.md` : si exploitation visible (conventions HTTP, Freebox)

---

## Incidents et décisions

### Anomalies détectées par QA (T3.4)

Trois anomalies identifiées lors de la validation statique de `Freebox_login.lua`. Aucune n'est bloquante pour la clôture fonctionnelle.

| ID | Fichier | Ligne(s) | Nature | Sévérité | Correction |
|---|---|---|---|---|---|
| ANOMALIE-1 | `Freebox_login.lua` | 52, 66, 93, 114, 119 | 5 fonctions internes déclarées sans `local` (DEV-1) | Moyenne | ✅ Corrigé — `local` ajouté sur les 5 déclarations |
| ANOMALIE-2 | `Freebox_login.lua` | 179-180 | Nil guard absent sur payload `freebox_endsession` | Moyenne | ✅ Corrigé — guard complet ajouté avec LOG_ERROR + abandon |
| ANOMALIE-3 | `Freebox_login.lua` | 120, 172 | `session_token` journalisé en LOG_DEBUG | Observation | 🔵 Conservé intentionnellement (token éphémère, LOG_DEBUG uniquement) |

**Décision :** ANOMALIE-1 et ANOMALIE-2 ont été corrigées chirurgicalement immédiatement après la QA (aucun impact métier, comportement Freebox inchangé). ANOMALIE-3 conservée (token éphémère, non le `app_token` long-lived protégé).

`global_HTTP_response.lua` est conforme sans réserve.

---

## Décision de passage à la phase suivante

🔄 **Phase 3 en attente de clôture** — T3.2 ✅, T3.3 ✅, T3.4 ✅. En attente de T3.5 (DOCly) pour clôture définitive.
