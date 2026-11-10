# Plan d'Action 007 - Tydom : qualification ARM64 et migration Node 26 slim

**Document :** [007_tydom_node26_arm64.plan.md](./007_tydom_node26_arm64.plan.md)  
**Date :** 2026-11-10  
**Statut :** ⏳ Planifié - choix de solution et validation humaine requis  
**Priorité :** HIGH  
**Rapports futurs :** `007_reports/`, à créer au lancement de la première phase.

## Objectif global

Vérifier que la nouvelle plateforme Docker peut exécuter nativement le bridge Tydom en `linux/arm64`, puis qualifier et déployer une image Node 26 slim sans modifier le contrat API, les automatismes Domoticz ou la version `tydom-client@0.13.4`.

Le déplacement du conteneur est déclaré par l'utilisateur, mais la configuration réellement déployée n'est pas accessible ici. Ce plan ne constitue ni une preuve de compatibilité de l'hôte ni une autorisation de déploiement. Aucun changement de code, build ou test distant n'a été exécuté.

## Constats et preuves disponibles

| Surface | Constat vérifié dans le dépôt | Conséquence |
|---|---|---|
| [Dockerfile](../../_docker/build_tydom/Dockerfile) | `FROM node:lts-slim`, `npm install --save`, copie du contexte complet | Base flottante et installation à rendre reproductibles ; Node réellement déployé inconnu |
| [CI](../workflows/build-tydom.yml) | Tests configurés sur Node `26`, mais build `linux/arm/v7` avec QEMU/Buildx | Configuration des tests ne prouve pas leur succès ; ARMv7 n'est pas ARM64 |
| [Manifeste](../../tydom-bridge/package.json) | `tydom-client` fixé à `0.13.4`, Jest et supertest disponibles | Conserver cette baseline ; pas de montée de version du client dans ce chantier |
| [Lockfile](../../tydom-bridge/package-lock.json) | Dépendances natives de développement, dont `@parcel/watcher`, variantes ARM64 glibc et `unrs-resolver` | Vérifier les installations de test et de production séparément ; ne pas supposer un arbre entièrement JavaScript |
| [Recette Compose](../../_docker/tydom-compose-rec.yml) | Tag `:tydom`, port hôte `5102`, bind-mount de `app.js`, pas de plateforme explicite | Identifier le vrai service de production ; un montage peut masquer le code contenu dans l'image |
| [Documentation image](../../_docker/build_tydom/README.md) et [bridge](../../tydom-bridge/README.md) | Références Node 22 ; documentation image annonçant AMD64 contrairement à la CI ARMv7 | Alignement documentaire à prévoir, sans prendre ces mentions pour une preuve du runtime |
| [Configuration OpenSSL](../../_docker/build_tydom/openssl.cnf) | Fichier présent mais aucune activation explicite dans le Dockerfile | Vérifier TLS réel sous Node 26 ; ne pas activer automatiquement la renégociation legacy |

### Sources officielles consultées

- [Calendrier Node.js](https://github.com/nodejs/Release/blob/main/schedule.json) : Node 26, début prévu le 2026-05-05, LTS le 2026-10-28, fin de support le 2029-04-30.
- [Liste officielle des images Node](https://github.com/docker-library/official-images/blob/master/library/node) : les variantes `26-bookworm-slim` et `26-trixie-slim` annoncent `arm64v8`. Dans la liste consultée, `26-slim` et `lts-slim` sont des alias de la variante Node 26 trixie-slim.
- Ces listes sont évolutives : revérifier les manifests du registre et enregistrer les digests au lancement. Elles ne prouvent ni le téléchargement sur l'hôte ni le fonctionnement avec la box Tydom.

**Cible recommandée :** Node 26 LTS, variante Debian slim explicitement choisie, par exemple `node:26-trixie-slim`, puis version corrective et digest validés. `node:lts-slim` correspond actuellement à l'objectif mais changera de majeure ; ne pas l'utiliser seul pour garantir Node 26. Le digest de l'image applicative publiée sera également conservé pour chaque déploiement.

## Options à soumettre au choix humain

| Option | Avantages | Coûts / limites |
|---|---|---|
| A - Image ARM64 seule | Migration la plus simple, qualification centrée sur la plateforme cible | Plus de support ARMv7 pour ce nouveau tag ; ne convient pas à un hôte AMD64 |
| B - Image multiarchitecture ARM64 + AMD64 | Même version applicative sur deux familles de machines | Deux builds et deux qualifications runtime ; aucun bénéfice si tous les hôtes sont ARM64 |

**Recommandation conditionnelle :** A si l'inventaire confirme un hôte ARM64 et aucun consommateur AMD64. B seulement si un besoin AMD64 est confirmé. Conserver l'ancienne image ARMv7 par digest pour l'ancien hôte ; ne pas promettre Node 26 ARMv7, absent des variantes slim consultées.

Choisir également la variante Debian après inventaire de l'image actuelle : conserver la distribution si possible pour isoler le changement Node/architecture. Le choix final et ses conséquences feront l'objet d'un ADR après accord, pas d'une décision présentée comme déjà approuvée.

## Phase 1 - Inventaire, faisabilité et décision

### Contexte

Le modèle de machine, l'OS, Docker et le mode de déploiement de la nouvelle plateforme ne sont pas fournis. Le Compose de recette n'est pas une source fiable de l'état de production.

### T1.1 - Établir la fiche des plateformes

- **Agent :** ARCos avec opérateur humain.
- **Scope :** hôte Docker ancien et nouveau ; rapport `007_reports/PHASE_1_COMPLETION_REPORT.md`.
- **Travail :** relever modèle/CPU, OS et userland 64 bits, noyau, RAM, stockage disponible, versions Docker/Compose, architecture du serveur Docker, image/digest/Node actuellement exécutés et éventuelle émulation.
- **Contrôles à exécuter sur l'hôte Linux ou son contexte Docker approuvé :**

```sh
uname -m
getconf LONG_BIT
docker info --format '{{.OSType}}/{{.Architecture}}'
docker version
docker compose version
docker buildx imagetools inspect node:26-trixie-slim
docker run --rm --platform linux/arm64 node:26-trixie-slim node -p \
  'JSON.stringify({node:process.version,arch:process.arch,platform:process.platform})'
```

- **Acceptation :** hôte natif `aarch64`/`arm64`, userland 64 bits, serveur Docker Linux ARM64 et conteneur `v26.*`, `arm64`, `linux`. Un succès sous QEMU sur AMD64 ne satisfait pas ce critère.
- **Précaution :** commandes données à titre de protocole futur ; ne pas lancer de conteneur sans accord de l'opérateur. Adapter les commandes si la plateforme masque l'accès à l'hôte.

### T1.2 - Cartographier exploitation et retour arrière

- **Agent :** ARCos avec opérateur humain.
- **Scope :** déploiement effectif, [recette](../../_docker/tydom-compose-rec.yml), [architecture](../../docs/ARCHITECTURE.md).
- **Travail :** inventorier sans publier les secrets : variables par nom, source de configuration, volumes, UID/GID, ports, réseau, DNS/mDNS `tydom.local`, accès box Tydom, accès depuis Domoticz, supervision et Watchtower éventuel.
- **Acceptation :** ancien et nouvel endpoints identifiés, ancienne image conservée avec digest et architecture, sauvegarde de configuration/volumes restaurable ; aucun secret dans les rapports. Confirmer l'hôte capable d'exécuter l'image de rollback, éventuellement l'ancien hôte ARMv7.

### T1.3 - Valider la cible

- **Agent :** ARCos.
- **Scope :** présent plan, manifests officiels, rapport phase 1 ; ADR futur dans `docs/adr/` avec numéro libre.
- **Acceptation :** option A/B, variante Debian, digest candidat, ressources et fenêtre d'interruption approuvés ; aucun blocage d'architecture non résolu.

**Critères de réussite :** les trois tâches satisfaites, accès réseau réalisable, rollback possible.  
**Gate humain #1 :** validation du plan et de la décision avant toute modification d'implémentation. Une confirmation initiale autorise seulement l'inventaire ; les choix issus de cet inventaire restent à approuver.

## Phase 2 - Construire une candidate reproductible

### Contexte

Après gate #1 uniquement. Conserver une image candidate séparée de `latest` et du tag actuellement déployé.

### T2.1 - Adapter le build

- **Agent :** DEVon.
- **Fichiers :** [Dockerfile](../../_docker/build_tydom/Dockerfile), [CI](../workflows/build-tydom.yml) ; [package.json](../../tydom-bridge/package.json) et [lockfile](../../tydom-bridge/package-lock.json) seulement si adaptation justifiée.
- **Travail :** épingler Node 26 slim et digest ; remplacer l'installation par `npm ci --omit=dev` pour l'image runtime. Utiliser un contexte maîtrisé excluant `node_modules`, données sensibles et artefacts locaux ; ne jamais copier des binaires Windows/AMD64.
- **Acceptation :** build propre ARM64 réussi depuis le lockfile sans mutation ; chargement réel de `tydom-client@0.13.4` ; aucune nouvelle bibliothèque système ou modification TLS sans justification. Si un module natif l'exige, documenter sa compilation et ne garder que ses bibliothèques runtime.

### T2.2 - Adapter publication et déploiement candidat

- **Agent :** DEVon.
- **Fichiers :** [CI](../workflows/build-tydom.yml), [recette](../../_docker/tydom-compose-rec.yml) et configuration effective à identifier en phase 1.
- **Travail :** cible `linux/arm64` (et AMD64 si option B), tag candidat immuable lié au commit, publication limitée aux événements autorisés ; une pull request ne doit pas publier de tag de production. Conserver tests Node 26 et scan existants. Préparer service candidat sans montage masquant `app.js`, sans accès aux commandes domotiques tant que non autorisé.
- **Acceptation :** manifest publié contenant exactement les plateformes approuvées, digest archivé, `process.arch=arm64` et Node `v26.*` vérifiés dans la candidate. Aucun remplacement automatique de la production.

**Critères de réussite :** installation verrouillée, image candidate disponible, architecture et version confirmées.  
**Gate humain #2 :** revue du code/build et autorisation avant QA.

## Phase 3 - Qualifier Node 26 ARM64 et le contrat Tydom

### Contexte

Les tests existants simulent `tydom-client`. Ils ne prouvent pas la compatibilité TLS/WebSocket avec une box réelle.

### T3.1 - Exécuter les tests automatisés

- **Agent :** QALvin.
- **Fichiers :** [tests](../../tydom-bridge/tests/app.test.js), [configuration Jest](../../tydom-bridge/jest.config.js), [manifeste](../../tydom-bridge/package.json).
- **Travail :** `npm ci` puis `npm test` en environnement Linux ARM64 Node 26 avec dépendances de développement ; comparer à la baseline disponible. Pas de script build applicatif à inventer : le projet exécute directement `app.js`.
- **Acceptation :** 100 % des tests passent, dont configuration invalide, santé, auth 401, API nominale, 503 dégradé, 500, 404, corrélation et backoff. Toute variante AMD64 publiée est également testée. Examiner les logs : `--forceExit` existant ne vaut pas preuve d'arrêt propre.

### T3.2 - Qualifier l'image finale sur la plateforme native

- **Agent :** QALvin avec opérateur humain.
- **Scope :** image candidate exacte, [application](../../tydom-bridge/app.js), rapport `007_reports/PHASE_3_COMPLETION_REPORT.md`.
- **Travail :** tester d'abord sans accès à la box (santé disponible, routes métier en 503, variables absentes en échec explicite), puis autoriser une fenêtre de connexion réelle sans deuxième bridge concurrent. Vérifier DNS/routage, certificats, négociation TLS/OpenSSL, WebSocket, authentification Tydom et lectures `/info`, `/devices/data`, endpoint connu.
- **Acceptation :** `/health/live` 200, `/health/ready` 200 après connexion ; auth incorrecte 401 ; JSON, données et headers conformes. Trois cycles arrêt/démarrage et une coupure réseau contrôlée suivie d'un retour à l'état prêt en moins de 120 s après rétablissement du réseau et de la box ; aucune boucle de crash.
- **Limite :** ne pas activer aveuglément `openssl.cnf` ou affaiblir TLS pour faire passer le test. Un échec bloque la migration et impose un diagnostic explicite.

### T3.3 - Vérifier les flux Domoticz

- **Agent :** QALvin avec opérateur humain.
- **Scope :** consommateurs Tydom existants, sans modification Lua prévue.
- **Travail :** lectures température/volets ; propagation `uuid`/`X-CorrId`, headers device/endpoint ; seulement après autorisation, une commande réversible par famille d'équipements utilisée puis lecture de réconciliation et restauration de l'état initial. Tester les routes POST selon leur contrat ; pas d'action physique sans présence humaine.
- **Acceptation :** 0 régression de contrat, 0 commande doublée, groupes alignés dans les deux sens, aucune écriture directe de `scenePhase`, fréquence de polling inchangée et température fraîche avant le seuil de 90 min du health check.
- **Prérequis conditionnel :** si un changement Lua devient nécessaire, arrêter l'extension du scope et obtenir accord après lecture de `global_data.lua` et des documents dzVents requis. La référence `.github/tasks/todo/RETROCONCEPTION_dzVents.md` n'est pas présente au chemin attendu dans cet état du dépôt.

**Critères de réussite :** suite entièrement verte, tests natifs et réels passants, aucune régression Domoticz.  
**Gate humain #3 :** validation des résultats avant documentation et préparation de bascule.

## Phase 4 - Documenter, basculer et surveiller

### Contexte

La nouvelle plateforme est peut-être déjà utilisée en production. La bascule peut donc se limiter au remplacement de l'image ; ne pas refaire un déplacement déjà effectué.

### T4.1 - Livrer le dossier d'exploitation

- **Agent :** DOCly.
- **Fichiers :** [README image](../../_docker/build_tydom/README.md), [README bridge](../../tydom-bridge/README.md), [architecture](../../docs/ARCHITECTURE.md), [instructions](../copilot-instructions.md) si impactées, ADR décidé après gate #1, présent plan et [index](./README.md).
- **Travail :** corriger les références obsolètes Node22/AMD64 et le contexte de build ; documenter plateformes réellement qualifiées, digests, réseau, secrets par référence, santé, séquence de bascule et rollback.
- **Acceptation :** commandes adaptées au déploiement inventorié ; aucune compatibilité non testée annoncée ; ADR numéroté sans collision et décision approuvée reflétée.
- **Gate humain #4 :** validation documentaire et autorisation explicite de la fenêtre de production. Initiative toujours ouverte tant que la vérification post-bascule n'est pas terminée.

### T4.2 - Exécuter la bascule contrôlée

- **Agent :** DEVon avec opérateur humain ; QALvin pour les contrôles.
- **Scope :** plateforme cible et configuration effective identifiée en phase 1 ; rapport `007_reports/PHASE_4_COMPLETION_REPORT.md`.
- **Séquence :**
  1. Sauvegarder la configuration et les volumes concernés ; conserver ancien digest et procédure de restauration. Télécharger et inspecter la candidate avant interruption.
  2. Suspendre les commandes automatisées Tydom pendant la fenêtre ; neutraliser temporairement Watchtower ou tout autre mécanisme d'auto-update pour ce service.
  3. Arrêter le bridge actif ; démarrer la candidate épinglée par digest avec la configuration validée. Un seul bridge autorisé à piloter la box.
  4. Conserver l'endpoint Domoticz si possible ; sinon modifier uniquement la configuration hôte/port prévue, sans toucher aux IDs Tydom.
  5. Contrôler architecture/Node, santé et lectures ; effectuer uniquement les commandes réversibles autorisées, puis réactiver les automatismes.
  6. Surveiller pendant 24 h avec vérification explicite d'au moins deux cycles de lecture température et deux cycles volets. Relever redémarrages, erreurs, RAM et CPU ; rester sous les limites approuvées en phase 1.
- **Acceptation :** disponibilité retrouvée en moins de 5 min après démarrage, 0 redémarrage inattendu sur 24 h, 0 erreur inexpliquée de commande, température toujours sous 90 min d'ancienneté, aucun double pilotage.

### Retour arrière obligatoire

- **Déclencheurs :** readiness absente après 5 min, erreur TLS persistante, crash répété, commande non conforme ou réconciliation incorrecte. Ne pas attendre 24 h en cas d'erreur fonctionnelle.
- **Actions :** suspendre les automatismes ; arrêter la candidate ; restaurer l'image et la configuration précédentes par digest, sur un hôte compatible (ancien hôte si ARMv7) ; restaurer le routage/endpoint Domoticz ; vérifier santé et lectures avant réactivation.
- **Données :** ne pas restaurer aveuglément un volume partagé modifié depuis la sauvegarde. Identifier ses propriétaires et arrêter les services concernés avant restauration.
- **Validation :** répéter la restauration en recette avant la production ; objectif de reprise de 10 min à confirmer en phase 1. Ne jamais prétendre qu'une image ARMv7 est un rollback natif ARM64.
- **Clôture :** QALvin consigne les preuves ; humain valide l'observation et le rollback disponible ; DOCly synchronise uniquement le statut global du plan et de l'index. Conserver l'ancienne image jusqu'à accord explicite de suppression.

## Résumé par agent et estimation

| Agent | Tâches | Livrable | Estimation indicative |
|---|---|---|---|
| ARCos | T1.1-T1.3 | Inventaire, choix argumenté, décision soumise à accord | 0,5 jour avec accès opérateur |
| DEVon | T2.1-T2.2, T4.2 | Candidate reproductible, CI adaptée, bascule contrôlée | 0,5-1 jour hors diagnostic |
| QALvin | T3.1-T3.3, contrôles T4.2 | Tests ARM64, intégration réelle, observation et rollback | 0,5-1 jour + 24 h d'observation |
| DOCly | T4.1 et clôture | Docs d'exploitation, ADR approuvé, index synchronisé | 0,5 jour |

## Dépendances et exécution

```text
Accord initial pour inventaire
  -> Phase 1 + choix humain + gate #1
  -> Phase 2 (DEVon) + gate #2
  -> Phase 3 (QALvin) + gate #3
  -> Phase 4 documentation (DOCly) + gate #4
  -> Bascule autorisée + observation + validation humaine finale
  -> Clôture documentaire
```

Chaque phase démarre seulement si les critères précédents sont satisfaits et son gate humain enregistré. Créer le dossier `007_reports/` et les rapports au démarrage effectif ; ne pas générer de faux rapports de complétion.

## Critères de succès globaux

1. Hôte et runtime natifs Linux ARM64 confirmés, sans émulation utilisée comme preuve.
2. Node `v26.*` slim exécuté depuis une image identifiée par digest.
3. Installation déterministe, `tydom-client@0.13.4` conservé, tous les tests existants passants.
4. Connexion réelle Tydom et reprise après coupure validées.
5. API, auth, corrélation et flux Domoticz inchangés ; aucune double commande.
6. Observation de 24 h satisfaisante et rollback répété, exécutable sur une architecture compatible.
7. Documentation, ADR approuvé et statuts synchronisés ; validations humaines enregistrées.

## Informations attendues avant lancement

- Quelle plateforme exacte héberge maintenant le conteneur (machine/CPU, OS, Docker ou gestionnaire de conteneurs) ?
- Quelle image/tag est actuellement exécutée, et avec quelle architecture et version Node ?
- Le besoin porte-t-il uniquement sur ARM64 ou faut-il aussi publier pour AMD64 ?
- La box Tydom et Domoticz sont-ils sur le même LAN que le nouvel hôte ? Quel endpoint du bridge utilise Domoticz ?
- Quelle interruption est acceptable, et l'ancien hôte reste-t-il disponible pour le retour arrière ?
