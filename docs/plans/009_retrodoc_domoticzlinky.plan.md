# Plan d'Action 009 — Rétrodocumentation technique du plugin DomoticzLinky

**Document :** `docs/plans/009_retrodoc_domoticzlinky.plan.md`
**Date de création :** 2026-11-25
**Statut :** 🔄 En cours
**Objectif Prioritaire :** MEDIUM
**ADR associé :** aucun (initiative documentaire uniquement ; ADR prévu pour la suite S1)

---

## 🎯 Objectif Global

Le plugin Python Linky (`DomoticzLinky`, fork `vzwingma/DomoticzLinky` de `guillaumezin/DomoticzLinky`) est embarqué dans l'image `vzwingmadomatic/domoticz` mais n'est documenté ni techniquement ni dans l'architecture `domotique`.
Résultat attendu : une rétrodocumentation technique du plugin versionnée avec son code, l'intégration CI → image → Domoticz décrite dans `domotique`, et des README alignés — sans aucune modification de code.

### Solution retenue (Gate #0)

Option **C + B3** (analyse 🟠 ARCos du 2026-11-25) : rétrodoc du code dans le fork (`DomoticzLinky/docs/RETROCONCEPTION.md`), intégration décrite côté `domotique` avec renvois croisés ; README mis à jour des deux côtés (section courte « Fork / notes techniques » en tête du readme du fork, guide utilisateur FR/EN inchangé). Rétrodoc en français. Statut de maintenance à écrire : fork maintenu par vzwingma, upstream non maintenu.

### Périmètre et contraintes

- **Deux dépôts git** : `DomoticzLinky` (fork) et `domotique` → commits distincts.
- **Aucune modification de code** (`plugin.py`, workflows CI, Dockerfile, dzVents) : les écarts et bugs sont documentés, pas corrigés.
- Références au code par **nom de fonction + version 2.6.1 + SHA `1ef6adf`** (numéros de ligne seulement en complément).
- La modification locale non commitée de `DomoticzLinky/readme.md` (retrait du bandeau « non maintenu ») est conservée.
- Pas de secret, token ou URL privée dans la documentation.

---

## 🛠️ Phases

> Initiative documentaire : la phase « code » est remplacée par la phase de rédaction. Les gates restent #2 (validation livrables), #3 (validation revue QA), #4 (clôture).

### Phase 1 — Rédaction de la rétrodoc et des README — ✅ Complété
**Contexte :** analyse ARCos (machine à états, auth device flow via proxy RUSSANDOL, endpoints `clc`/`plc`/`dcmp`, devices P1/Managed Counter, persistance `Domoticz.Configuration` pickle+base64, planification 8h-22h, sécurité, dette) et chaîne d'intégration (`build-domoticz.yml` → `_docker/build_domoticz/linky` → `/opt/domoticz/userdata/plugins/DomoticzLinky/`).
**Critères de réussite :**
- ✅ 16 sections de la rétrodoc présentes, avec diagramme d'états PlantUML
- ✅ 4 fichiers README/architecture mis à jour avec liens croisés
- ✅ Aucun fichier de code modifié (`git diff --stat` des deux dépôts)

#### T1.1 - Créer la rétrodocumentation technique du plugin
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `DomoticzLinky/docs/RETROCONCEPTION.md` (nouveau)
- **Couvrir :** 1. Identité/provenance (version, licences AGPL + MIT JoursFeries, upstream/fork, SHA, statut maintenance) · 2. Contexte (framework plugins Python Domoticz, Enedis Data Connect, proxy) · 3. Paramètres Mode1-6 + Port (bornes, défauts, effets de Mode3 = 3/4/10-19) · 4. Carte du code · 5. Machine à états (PlantUML + table transitions) · 6. Authentification (device flow, refresh, expiration, 403 → désactivation) · 7. Collecte (endpoints, découpage, historique court/long, cache, agrégation 30 min → 1 h, HC/HP + jours fériés, production, fusion PRM) · 8. Devices Domoticz (types, `sValue`, options, nommage, timeout) · 9. Persistance (clés `Configuration`, pickle + checksum, fichier debug `/tmp`) · 10. Planification et résilience · 11. Logs et debug · 12. Dépendances et compatibilité · 13. Sécurité · 14. Dette et risques (tableau gravité) · 15. Intégration dans `domotique` (renvoi) · 16. Glossaire (PRM, HC/HP, courbe de charge).
- **Acceptation :** 16/16 sections, chaque affirmation clé référencée (fonction + SHA `1ef6adf`), faits vérifiés dans `plugin.py`.

#### T1.2 - Ajouter la section « Fork / notes techniques » au readme du fork
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `DomoticzLinky/readme.md`
- **Couvrir :** section courte en tête (FR, + phrase EN) : fork maintenu par vzwingma, upstream non maintenu, usage dans `vzwingma/domotique`, lien vers `docs/RETROCONCEPTION.md`. Guide utilisateur existant FR/EN inchangé ; modification locale existante conservée.
- **Acceptation :** diff limité à l'en-tête ; lien relatif valide.

#### T1.3 - Documenter les plugins Python dans l'architecture
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `domotique/docs/ARCHITECTURE.md`
- **Couvrir :** section « Plugins Python Domoticz (Linky, deCONZ) » : chaîne CI → image → plugin, provenance (upstream `guillaumezin/master` non épinglé), proxy Enedis tiers, persistance dans `domoticz.db`, absence d'interaction dzVents ; ligne dans le tableau des intégrations ; lien vers la rétrodoc du fork.
- **Acceptation :** section présente, cohérente avec `build-domoticz.yml` et `Dockerfile`.

#### T1.4 - Mettre à jour les README de `domotique`
- **Agent :** 🟣 DOCly
- **Fichier(s) :** `domotique/README.md`, `domotique/_docker/build_domoticz/README.md`
- **Couvrir :** composant Linky (lien fork + rétrodoc) ; dans le README de build : provenance du plugin (upstream `master` non épinglé), avertissement sur le montage de tout `userdata` qui masque les plugins de l'image, correction de l'écart d'architecture annoncée (arm64 vs `linux/arm/v7` construit par la CI) après vérification.
- **Acceptation :** liens valides, faits alignés sur le workflow CI.

### Phase 2 — Revue factuelle et liens — 🔄 En cours
**Contexte :** pas de suite de tests applicable (documentation) ; contrôle par échantillonnage contre le code.
**Critères de réussite :**
- ✅ ≥ 15 affirmations techniques vérifiées contre `plugin.py` / CI / Dockerfile, 0 écart bloquant
- ✅ 100 % des liens relatifs et inter-dépôts vérifiés

#### T2.1 - Vérifier les faits et les liens
- **Agent :** 🟢 QALvin
- **Fichier(s) :** lecture seule des livrables T1.1 à T1.4 ; rapport `docs/plans/009_reports/PHASE_2_COMPLETION_REPORT.md`
- **Couvrir :** échantillon de faits (paramètres, états, endpoints, codes HTTP, clés de persistance, types de devices, planification, sécurité) ; liens ; absence de secret ; absence de modification de code.
- **Acceptation :** tableau fait → source → ✅/❌ ; écarts signalés (non corrigés par QALvin).

### Phase 3 — Clôture — ⏳ Planifié
**Contexte :** corrections éventuelles issues de la phase 2, mise à jour du statut.
**Critères de réussite :**
- ✅ Écarts phase 2 corrigés
- ✅ Plan et index `docs/plans/README.md` au statut final

#### T3.1 - Corriger les écarts relevés
- **Agent :** 🟣 DOCly
- **Fichier(s) :** livrables T1.1 à T1.4
- **Acceptation :** 0 écart restant de la phase 2.

---

## 📊 Résumé par Agent

| Agent | Tâches | Livrable |
|---|---|---|
| 🟣 DOCly | T1.1 – T1.4, T3.1 | Rétrodoc du plugin, README fork + domotique, ARCHITECTURE.md |
| 🟢 QALvin | T2.1 | Revue factuelle et vérification des liens |

---

## 📍 Dépendances entre Phases

```
Phase 1 (rédaction : T1.1 → T1.2 ; T1.3 → T1.4)  → Gate #2
    ↓ GO
Phase 2 (revue QA)                                 → Gate #3
    ↓ GO
Phase 3 (corrections + clôture)                    → Gate #4
```

---

## ✅ Critères de Succès Globaux

1. `DomoticzLinky/docs/RETROCONCEPTION.md` existe avec les 16 sections et le diagramme d'états.
2. `DomoticzLinky/readme.md` indique le statut de maintenance du fork et renvoie vers la rétrodoc.
3. `domotique/docs/ARCHITECTURE.md`, `README.md` et `_docker/build_domoticz/README.md` décrivent le plugin et sa chaîne d'intégration.
4. Revue QA : 0 écart bloquant, tous les liens valides.
5. Aucun fichier de code modifié dans les deux dépôts.
6. Index `docs/plans/README.md` à jour.

---

## 🔭 Suites identifiées (hors périmètre, backlog)

| Id | Suite | Nature |
|---|---|---|
| S1 | CI `build-domoticz.yml` : tirer le fork `vzwingma/DomoticzLinky` au lieu de l'upstream, ref épinglé (tag/SHA), mise à jour volontaire | Changement CI/supply chain — ADR requis (`docs/adr/007-…`) |
| S2 | Corriger les bugs probables du plugin : `onCommand`/`onNotification` (méthodes absentes), `iVersion` non défini, `mergeCounters` sur la conso au lieu de la prod, double comptage `sTypeHour2` en production | Correctif code (fork) |
| S3 | Ne plus journaliser tokens/`Authorization` en clair en mode debug | Sécurité (fork) |
| S4 | Supervision Linky dans `Health_check_dzVents.lua` (fraîcheur du device `Linky <PRM>`) | Évolution dzVents |

---

## 🚦 Journal des gates

| Gate | Date | Objet | Décision 👤 | Notes |
|---|---|---|---|---|
| #0 | 2026-11-25 | Choix de solution | ✅ GO | Option C + B3 ; rétrodoc en français ; statut « fork maintenu / upstream non maintenu » ; suites S1-S4 notées en backlog |
| #1 | 2026-11-25 | Validation plan | ✅ GO | Plan validé sans ajustement ; lancement Phase 1 (DOCly) |
| #2 | 2026-11-25 | Validation rédaction phase 1 | ✅ GO | 4/4 tâches ; rétrodoc déplacée vers `docs/` + fichier parasite supprimé par MAINa ; code-review : 0 bloquant, 3 mineurs (→ T3.1) ; correction Watchtower acceptée sans objection |
