# Plan d'Action 002 — Durcissement `tydom-bridge` (rétro-documentation)

## 1) Objectif global et périmètre

Formaliser, dans un format de plan standard, les travaux de durcissement de `tydom-bridge` déjà menés : stabilité runtime, contrat API, sécurité, observabilité, qualification de migration `tydom-client`.

**Périmètre inclus :**
- module `tydom-bridge` (runtime Node, dépendances, API HTTP) ;
- documentation de qualification/migration ;
- règles d’exploitation (healthchecks, erreurs, reconnect, arrêt propre).

**Hors périmètre :**
- migration effective vers `tydom-client@0.15.x` (décision No-Go actée) ;
- refonte fonctionnelle du bridge non liée au hardening.

---

## 2) Sources de référence (obligatoires)

- `.github/tasks/todo/PLAN_ACTIONS_tydom-bridge.md`
- `.github/tasks/todo/QUALIFICATION_tydom-client_0.15.md`
- `.github/instructions/doc.instructions.md`

---

## 3) Phasage du plan

> Ce plan est **rétrospectif** : il structure des travaux déjà qualifiés et en fixe la décision finale pour éviter toute ambiguïté backlog.

### Phase 0 — Baseline dépendances et cadrage
**Objectif :** figer une base reproductible.

- **T0.1** — Valider la baseline `tydom-client`  
  **Agent :** 🟠 ARCos  
  **Fichiers ciblés :** `tydom-bridge/package.json`, `tydom-bridge/package-lock.json`  
  **Critères d’acceptation :**
  - baseline explicite et justifiée ;
  - versions runtime alignées lock/manifeste.

- **T0.2** — Implémenter le pin exact baseline  
  **Agent :** 🔵 DEVon  
  **Fichiers ciblés :** `tydom-bridge/package.json`, `tydom-bridge/package-lock.json`  
  **Critères d’acceptation :**
  - `tydom-client` fixé en version exacte ;
  - installation déterministe.

- **T0.3** — Documenter la baseline et le prérequis Node  
  **Agent :** 🟣 DOCly  
  **Fichiers ciblés :** `tydom-bridge/README.md`  
  **Critères d’acceptation :**
  - baseline et version Node visibles ;
  - procédure d’installation cohérente.

### Phase 1 — Stabilisation d’exécution
**Objectif :** garder l’API disponible même si le backend Tydom échoue.

- **T1.1** — Découpler bootstrap HTTP / connexion backend  
  **Agent :** 🔵 DEVon  
  **Fichiers ciblés :** `tydom-bridge/app.js`  
  **Critères d’acceptation :**
  - process HTTP démarre sans connexion Tydom ;
  - état backend exposé côté runtime.

- **T1.2** — Valider les variables d’environnement au démarrage  
  **Agent :** 🔵 DEVon  
  **Fichiers ciblés :** `tydom-bridge/app.js`  
  **Critères d’acceptation :**
  - erreurs de config explicites ;
  - absence de crash silencieux.

- **T1.3** — Qualifier les modes dégradés  
  **Agent :** 🟢 QALvin  
  **Fichiers ciblés :** `tydom-bridge/tests/**` (ou protocole manuel qualifié)  
  **Critères d’acceptation :**
  - indisponibilité backend couverte ;
  - réponses de repli vérifiées.

### Phase 2 — Contrat API et sécurité
**Objectif :** rendre le contrat HTTP prédictible et sûr.

- **T2.1** — Normaliser les réponses JSON et la gestion d’erreurs  
  **Agent :** 🔵 DEVon  
  **Fichiers ciblés :** `tydom-bridge/app.js`  
  **Critères d’acceptation :**
  - `Content-Type` cohérent ;
  - statuts HTTP alignés aux cas d’erreur.

- **T2.2** — Corriger et fiabiliser la Basic Auth  
  **Agent :** 🔵 DEVon  
  **Fichiers ciblés :** `tydom-bridge/app.js`  
  **Critères d’acceptation :**
  - contrôle d’accès effectif sur `/_info` ;
  - refus explicite des credentials invalides.

- **T2.3** — Vérifier non-régression sécurité/API  
  **Agent :** 🟢 QALvin  
  **Fichiers ciblés :** `tydom-bridge/tests/**`  
  **Critères d’acceptation :**
  - cas auth valides/invalides couverts ;
  - routes métier en 503 si backend indisponible.

### Phase 3 — Observabilité et exploitabilité
**Objectif :** superviser simplement l’état service vs backend.

- **T3.1** — Exposer les endpoints de santé  
  **Agent :** 🔵 DEVon  
  **Fichiers ciblés :** `tydom-bridge/app.js`  
  **Critères d’acceptation :**
  - `/health/live` reflète la vie process ;
  - `/health/ready` reflète disponibilité backend.

- **T3.2** — Gérer arrêt propre et état backend  
  **Agent :** 🔵 DEVon  
  **Fichiers ciblés :** `tydom-bridge/app.js`  
  **Critères d’acceptation :**
  - fermeture propre client/serveur ;
  - dernière erreur backend traçable.

- **T3.3** — Documenter exploitation et healthchecks  
  **Agent :** 🟣 DOCly  
  **Fichiers ciblés :** `tydom-bridge/README.md`, `README.md`  
  **Critères d’acceptation :**
  - mode opératoire lisible ;
  - endpoints de santé documentés.

### Phase 4 — Qualification migration `tydom-client` et décision
**Objectif :** statuer formellement sur la migration `0.13.4 -> 0.15.1`.

- **T4.1** — Définir la matrice de qualification  
  **Agent :** 🟢 QALvin  
  **Fichiers ciblés :** `.github/tasks/todo/QUALIFICATION_tydom-client_0.15.md`  
  **Critères d’acceptation :**
  - scénarios local/distant explicités ;
  - critères Go/No-Go définis.

- **T4.2** — Exécuter qualification comparative 0.13.4 vs 0.15.1  
  **Agent :** 🟢 QALvin  
  **Fichiers ciblés :** `.github/tasks/todo/QUALIFICATION_tydom-client_0.15.md`  
  **Critères d’acceptation :**
  - comportements comparés sur scénarios identiques ;
  - écarts objectivés (état backend, erreurs réseau).

- **T4.3** — Statuer et clôturer backlog migration  
  **Agent :** 🟠 ARCos  
  **Fichiers ciblés :** `.github/tasks/todo/QUALIFICATION_tydom-client_0.15.md`, `tydom-bridge/package.json`  
  **Critères d’acceptation :**
  - décision explicite et non ambiguë ;
  - backlog courant mis à jour avec décision finale.

- **T4.4** — Consolider la décision dans la documentation  
  **Agent :** 🟣 DOCly  
  **Fichiers ciblés :** `tydom-bridge/README.md`, `.github/tasks/todo/QUALIFICATION_tydom-client_0.15.md`  
  **Critères d’acceptation :**
  - mention No-Go visible ;
  - baseline maintenue clairement documentée.

---

## 4) Dépendances entre tâches et phases

### Dépendances clés
- `T0.1 -> T0.2 -> T0.3`
- `T1.1` et `T1.2` dépendent de `T0.2`
- `T1.3` dépend de `T1.1` + `T1.2`
- `T2.1` dépend de `T1.1`
- `T2.2` dépend de `T2.1`
- `T2.3` dépend de `T2.1` + `T2.2`
- `T3.1` dépend de `T1.1`
- `T3.2` dépend de `T3.1`
- `T3.3` dépend de `T3.1` + `T3.2`
- `T4.2` dépend de `T4.1`
- `T4.3` dépend de `T4.2`
- `T4.4` dépend de `T4.3`

### Dépendances de phase
- Phase 1 dépend de Phase 0
- Phase 2 dépend de Phase 1
- Phase 3 dépend de Phase 1 (et alimente la stabilisation d’exploitation)
- Phase 4 dépend des acquis Phases 1 à 3

---

## 5) Décision historique de qualification (finale)

### Décision actée

**⛔ No-Go définitif pour `tydom-client@0.15.1`.**

### Effets de décision
- baseline maintenue : **`tydom-client@0.13.4`** ;
- rollback de la tentative `0.15.1` considéré terminé ;
- migration `0.15.x` **retirée du backlog courant** ;
- toute future montée de version nécessite un **nouveau plan dédié** + qualification complète.

---

## 6) Critères de succès globaux

Le plan est considéré conforme si :
1. la baseline `0.13.4` est explicitement maintenue et justifiée ;
2. le bridge reste vivant et observable sans backend prêt ;
3. le contrat API en mode dégradé est stable (503 JSON, erreurs contrôlées) ;
4. la sécurité minimale d’exploitation est effective (Basic Auth, logs maîtrisés) ;
5. healthchecks et arrêt propre sont documentés et vérifiables ;
6. la décision No-Go `0.15.1` est écrite sans ambiguïté ;
7. aucun item backlog ne laisse entendre une migration `0.15.x` implicite.

---

## 7) Risques et mitigations

- **Risque :** confusion sur la version cible `tydom-client`  
  **Mitigation :** pin exact `0.13.4` + décision No-Go centralisée.

- **Risque :** divergence entre état réel et documentation  
  **Mitigation :** synchronisation README/qualification/plan dans le même flux de changement.

- **Risque :** réouverture implicite de migration `0.15.x`  
  **Mitigation :** clause explicite “hors backlog courant”, nouveau plan obligatoire.

- **Risque :** faible observabilité en cas d’incident  
  **Mitigation :** health endpoints, backend state, dernière erreur traçable.

---

## 8) Protocole de reporting (rapports de phase)

### Emplacement
- Dossier : `.github/plans/002_reports/`
- Fichier par phase : `PHASE_<N>_COMPLETION_REPORT.md`

### Contenu minimal attendu par rapport
1. statut phase (`✅ DONE` / `❌ BLOCKED`) ;
2. tâches `T<N>.<M>` traitées ;
3. fichiers modifiés (chemins exacts) ;
4. critères d’acceptation validés (preuves courtes) ;
5. risques/bloqueurs et décisions prises ;
6. impacts backlog (notamment migration `tydom-client`).

### Règle de clôture de phase
- Une phase est clôturable uniquement si toutes ses tâches sont `DONE` ou explicitement `BLOCKED` avec justification.

---

## 9) Statut global du plan

**Statut : ✅ ARCHIVÉ / RÉTRO-DOCUMENTÉ**

Ce plan formalise rétrospectivement un hardening et une qualification déjà menés, avec décision finale consolidée : **No-Go `0.15.1` et maintien `0.13.4`**.

