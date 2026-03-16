# Qualification de `tydom-client@0.15.1`

> ⛔ **MIGRATION ANNULÉE** — `tydom-client@0.15.1` a été qualifié comme incompatible. La baseline reste `0.13.4`. Ce document est conservé à titre historique.

## 1. Objet

Ce document consigne la qualification menée après le durcissement de `tydom-bridge`, afin d'évaluer si une migration de `tydom-client` `0.13.4` vers `0.15.1` est envisageable à court terme.

La baseline du bridge reste `0.13.4`.

---

## 2. Environnement de qualification

- dépôt : `domotique`
- module : `tydom-bridge`
- runtime local : `Node.js v22.18.0`
- baseline bridge : `tydom-client@0.13.4`
- sandbox isolé de qualification : `tydom-client@0.15.1`

Le bridge de production n'a pas été migré pendant cette qualification.

---

## 3. Méthode

### 3.1 Baseline validée

Le bridge durci a d'abord été validé avec `tydom-client@0.13.4` :

- `node --check app.js` OK ;
- `/health/live` OK ;
- `/health/ready` retourne `503` si backend non prêt ;
- `/_info` protégé par Basic Auth ;
- routes métier retournent `503` JSON si Tydom n'est pas connecté.

### 3.2 Qualification isolée de `0.15.1`

Un sandbox indépendant a été créé avec :

- `tydom-client@0.15.1`
- les dépendances runtime du bridge
- une copie du `app.js` durci

Objectif :

- vérifier la compatibilité runtime ;
- observer le comportement du bridge avec `0.15.1` sans impacter la baseline `0.13.4`.

---

## 4. Cas testés

## 4.1 Compatibilité runtime

### Test

- chargement du bridge avec `tydom-client@0.15.1`
- vérification syntaxique
- démarrage HTTP

### Résultat

- **OK**

Le code actuel du bridge durci est compatible au niveau chargement/runtime avec `tydom-client@0.15.1` sur Node 22.

---

## 4.2 Mode local simulé avec backend indisponible

### Paramètres

- `HOST=127.0.0.1`
- faux identifiants

### Résultats observés

#### Baseline `0.13.4`

- bridge démarre ;
- `/health/live` = OK ;
- `/health/ready` = `503` ;
- `/_info` = `200` ;
- `/info` = `503` ;
- état backend observé : `connecting`

#### Sandbox `0.15.1`

- bridge démarre ;
- `/health/live` = OK ;
- `/health/ready` = `503` ;
- `/_info` = `200` ;
- `/info` = `503` ;
- état backend observé : `degraded`
- erreur backend observée : `fetch failed`

### Conclusion

Le bridge encaisse correctement `0.15.1` grâce au durcissement réalisé, mais le comportement de la dépendance diffère de `0.13.4` :

- `0.13.4` reste en `connecting` dans ce scénario ;
- `0.15.1` échoue plus vite et passe en `degraded`.

---

## 4.3 Mode distant simulé (`mediation.tydom.com`) avec faux identifiants

### Paramètres

- `HOST=mediation.tydom.com`
- faux identifiants

### Résultats observés

#### Baseline `0.13.4`

- bridge démarre ;
- `/_info` répond ;
- état backend observé après tentative : `connecting`

#### Sandbox `0.15.1`

- bridge démarre ;
- `/_info` répond ;
- état backend observé après tentative : `degraded`
- erreur backend observée : `fetch failed`

### Conclusion

En mode distant simulé également, `0.15.1` présente un comportement plus brutal et immédiatement dégradé que `0.13.4`.

---

## 5. Ce que la qualification confirme

La qualification confirme les points suivants :

1. le bridge durci peut **charger** et **démarrer** avec `tydom-client@0.15.1` ;
2. l'architecture renforcée protège désormais le service HTTP contre les échecs du backend ;
3. `0.15.1` modifie le comportement d'échec observé par rapport à `0.13.4` ;
4. en l'absence de backend Tydom réellement opérationnel, aucune validation positive des routes métier n'a été obtenue avec `0.15.1`.

---

## 6. Ce que la qualification ne valide pas encore

Cette qualification n'a pas permis de valider :

- une connexion réussie en local vers une vraie box Tydom ;
- une connexion réussie via `mediation.tydom.com` avec de vrais identifiants ;
- les lectures réelles de `/info` et `/devices/data` ;
- les écritures sur endpoint ;
- le comportement de `refresh/all` ;
- les scénarios de reconnexion en production.

Autrement dit, la qualification est suffisante pour une **décision de prudence**, mais pas pour un **Go de migration**.

---

## 7. Migration vers `0.15.1` — Analyse et décision finale

### 7.1 Analyse hexadécimale du dist

Une analyse hexadécimale du `dist/index.cjs` de `0.15.1` (installé) a confirmé que le byte STX (`0x02`) est bien présent dans les deux lignes critiques :

- **Réception (L.380)** : `data.subarray("\x02".length)` → `subarray(1)` : **correct**
- **Envoi (L.503)** : le préfixe `\x02` est bien encodé en mode distant : **correct**

> Note : le rendu terminal affiche `☻` pour le byte de contrôle `0x02`. Ce n'est pas une corruption — c'est uniquement du rendu.

### 7.2 Cause réelle du `fetch failed`

L'erreur `fetch failed` n'est **pas un bug de protocole**. `fetch` (utilisé par `0.15.1`) et `got` (utilisé par `0.13.4`) se comportent différemment face aux erreurs réseau :
- `got` (0.13.4) : `retry: { limit: Infinity }` — boucle silencieusement
- `fetch` (0.15.1) : pas de retry — lève immédiatement `TypeError: fetch failed`

La conséquence : si le boîtier Tydom est indisponible au démarrage, `0.15.1` passe immédiatement en `degraded` sans se récupérer.

### 7.3 Correctifs appliqués dans `app.js`

Les changements suivants ont été appliqués pour rendre `0.15.1` aussi robuste que `0.13.4` :

| Correctif | Détail |
|-----------|--------|
| **Retry exponentiel dans `connectTydom()`** | Backoff : 5 s → 7,5 s → 11 s … → 60 s max, tentatives illimitées |
| **Écoute des events `connect`/`disconnect`** | `backendState` se synchronise automatiquement sur les reconnexions internes de `0.15.1` (`retryOnClose=true`) |
| **Endpoint `POST /reconnect`** | Force une reconnexion manuelle depuis Domoticz ou tout autre client HTTP |
| **Fix `shutdown()` : `client.close()`** | `client.disconnect()` n'existe pas en `0.15.1` ; remplacé par `client.close()` |

### 7.4 Décision

**⛔ Migration vers `tydom-client@0.15.1` — No-Go définitif.**

La migration vers `0.15.1` a été tentée en production sur la branche `feat/upgrade_tydom`.
Elle a provoqué une **incompatibilité fonctionnelle confirmée** avec le backend Tydom réel.

Un **rollback complet** vers `tydom-client@0.13.4` a été réalisé. La baseline est rétablie et pinned en exact dans `package.json`.

La décision est **définitive** : le bridge restera sur `0.13.4` jusqu'à la qualification complète d'une future version de `tydom-client`. La migration vers `0.15.x` n'est pas prévue dans le backlog courant.

---

## 8. Validation restante en production

~~La validation fonctionnelle complète doit être réalisée sur un backend Tydom réel.~~

> ⛔ **Non applicable** — La migration ayant été annulée suite au No-Go définitif, aucune validation en production sur `0.15.1` n'est prévue. La baseline `0.13.4` est en production.
