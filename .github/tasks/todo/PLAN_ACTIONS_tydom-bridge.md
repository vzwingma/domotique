# Plan d'actions pour `tydom-bridge`

## 1. Objectif

Faire évoluer `tydom-bridge` d'un proxy HTTP minimal vers un bridge :

- reproductible ;
- observable ;
- robuste aux pannes Tydom ;
- sûr en exploitation ;
- compatible avec une migration maîtrisée de `tydom-client` `0.13.x` vers `0.15.x`.

Le plan ci-dessous est dérivé de `RETROCONCEPTION_tydom-bridge.md` et sert de base de planification opérationnelle.

---

## 2. Principes de conduite

- stabiliser d'abord, migrer ensuite ;
- rendre le runtime reproductible avant toute optimisation ;
- découpler la disponibilité du bridge de la disponibilité immédiate de Tydom ;
- privilégier les erreurs contrôlées aux échecs silencieux ;
- documenter au fil de l'eau les décisions sur la dépendance critique `tydom-client`.

---

## 3. Améliorations majeures recommandées

### A. Reproductibilité du runtime

- choisir explicitement une baseline `tydom-client` ;
- réaligner `package.json`, `package-lock.json` et installation effective ;
- documenter et vérifier la version de Node.js requise.

### B. Robustesse du bootstrap

- démarrer l'API HTTP même si la connexion Tydom échoue ;
- introduire un état interne du bridge (`connected`, `disconnected`, `degraded`) ;
- valider les variables d'environnement au démarrage.

### C. Gestion d'erreur et contrat HTTP

- ajouter une gestion d'erreurs centralisée ;
- normaliser les réponses JSON ;
- distinguer clairement :
  - erreurs de configuration ;
  - indisponibilité Tydom ;
  - erreurs internes ;
  - erreurs d'authentification ;
- conserver les en-têtes de corrélation.

### D. Observabilité et exploitation

- exposer `/health/live` ;
- exposer `/health/ready` ;
- éventuellement exposer `/health/status` ;
- tracer la dernière erreur backend connue ;
- fermer proprement le client Tydom à l'arrêt.

### E. Sécurité d'exploitation

- corriger l'authentification Basic ;
- éviter les logs sensibles ;
- ne pas laisser le mode TLS permissif actif globalement par défaut.

### F. Migration contrôlée vers `0.15.x`

- qualifier `0.15.x` dans un chantier dédié ;
- comparer objectivement `0.13.4` et `0.15.x` ;
- ne décider la migration qu'après validation locale et distante.

---

## 4. Architecture cible

Le bridge doit être organisé autour de quatre responsabilités claires :

1. **API HTTP**
   - expose les endpoints métier existants ;
   - formate les réponses et les erreurs ;
   - transporte la corrélation.

2. **Gestionnaire de connexion Tydom**
   - encapsule la connexion ;
   - expose l'état courant ;
   - gère reconnexion, timeout, fermeture et dernière erreur.

3. **Garde-fous de runtime**
   - validation de configuration ;
   - validation de version Node ;
   - activation explicite du mode TLS permissif si nécessaire.

4. **Supervision**
   - healthchecks ;
   - logs exploitables ;
   - état synthétique du bridge.

---

## 5. Phasage recommandé

## Phase 0 — Baseline et cadrage

### Objectif

Supprimer l'ambiguïté actuelle autour de la dépendance `tydom-client`.

### Livrables

- version cible court terme choisie ;
- manifestes et lockfile réalignés ;
- prérequis Node documenté.

### Recommandation

Geler d'abord sur la dernière version validée fonctionnellement (`0.13.4`) si `0.15.x` n'est pas encore qualifiée.

---

## Phase 1 — Stabilisation d'exécution

### Objectif

Faire en sorte que le bridge démarre et reste observable même si Tydom est indisponible.

### Travaux

- validation des variables d'environnement ;
- démarrage HTTP découplé de `client.connect()` ;
- état de connexion interne ;
- gestion d'erreurs centralisée sur les routes async.

---

## Phase 2 — Contrat API et sécurité

### Objectif

Fiabiliser l'interface du bridge pour ses clients et pour l'exploitation.

### Travaux

- `Content-Type` cohérent (`application/json`) ;
- structure JSON homogène ;
- correction du contrôle Basic Auth ;
- réduction des logs sensibles ;
- encadrement du mode TLS permissif.

---

## Phase 3 — Observabilité et exploitation

### Objectif

Permettre une supervision simple et fiable.

### Travaux

- endpoints de santé ;
- arrêt propre du serveur et du client Tydom ;
- dernier état et dernière erreur visibles ;
- stratégie de reconnexion documentée.

---

## Phase 4 — Qualification de la migration `0.13 -> 0.15`

### Objectif

Valider ou invalider proprement la montée de version de `tydom-client`.

### Travaux

- matrice de compatibilité Node / mode local / mode distant ;
- protocole de tests comparatifs ;
- qualification des appels :
  - `/info`
  - `/devices/data`
  - lecture endpoint
  - écriture endpoint
  - `/refresh/all`
  - reconnexion
  - timeout
- décision finale :
  - migrer ;
  - geler ;
  - patcher localement ;
  - contribuer upstream ;
  - remplacer la dépendance.

---

## 6. Répartition des travaux par agent

## Dev

- stabiliser la baseline dépendances ;
- durcir le bootstrap ;
- introduire un gestionnaire d'état de connexion ;
- centraliser la gestion d'erreurs ;
- normaliser le contrat HTTP ;
- ajouter les healthchecks ;
- sécuriser l'arrêt ;
- préparer la piste de migration `0.15.x`.

## Qa

- définir la matrice de test ;
- valider les comportements en cas d'absence de configuration ;
- valider les cas backend indisponible / dégradé / reconnecté ;
- comparer les comportements `0.13.4` et `0.15.x` ;
- statuer sur le Go / No-Go de migration.

## Doc

- mettre à jour le `README.md` ;
- documenter les variables d'environnement ;
- documenter la politique TLS ;
- documenter les endpoints de santé ;
- consigner la décision sur la version retenue de `tydom-client`.

---

## 7. Critères de succès

Le plan sera considéré comme exécuté avec succès lorsque :

- l'état des dépendances sera cohérent et reproductible ;
- le bridge démarrera même sans backend Tydom disponible ;
- les healthchecks distingueront le process vivant de la disponibilité backend ;
- les erreurs backend seront traduites en réponses HTTP propres ;
- la politique de sécurité et de logs sera clarifiée ;
- la documentation reflétera l'état réel du bridge ;
- une décision formelle sera prise sur `tydom-client@0.15.x`.

---

## 8. Risques et mitigations

### Risque 1 — Dépendance critique non maîtrisée

**Mitigation :**
- baseline figée ;
- lockfile aligné ;
- qualification dédiée de la migration.

### Risque 2 — Régression silencieuse en exploitation

**Mitigation :**
- healthchecks ;
- logs utiles ;
- gestion d'erreurs centralisée ;
- tests local/distant.

### Risque 3 — Refonte trop large trop tôt

**Mitigation :**
- refactor minimal structurant ;
- séquencement strict :
  - baseline
  - robustesse
  - observabilité
  - migration

---

## 9. Recommandation immédiate

Ordre recommandé pour lancer les travaux :

1. décider officiellement de la baseline `tydom-client` ;
2. réaligner le projet et le runtime ;
3. rendre le bridge observable et tolérant aux indisponibilités Tydom ;
4. sécuriser l'API et les logs ;
5. seulement ensuite reprendre la migration vers `0.15.x`.
