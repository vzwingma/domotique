# Plan 007 - Préparation du build candidat

**Date :** 2026-11-10  
**Statut :** préparation locale réalisée ; validation Docker ARM64 en attente.

## Périmètre et changements

- Dockerfile : Node 26.13.0 bookworm-slim, digest d'index `sha256:add5c17c14752c54d2f3d519ec46a3815684d41c33f198bcb09fb998f7dcbf68`, installation `npm ci --omit=dev`, copie explicite de `app.js` et des manifestes.
- Contexte Docker `tydom-bridge/`, exclusions des dépendances locales et données d'environnement par fichier Dockerfile.dockerignore.
- Workflow : ajout de `main`, build candidat ARM64 sur push/PR sans login ni publication. Smoke test isolé vérifiant architecture, version Node et chargement de `tydom-client@0.13.4`.
- Publication uniquement manuelle et explicite, après tests/build et scan Sonar ; tag lié au SHA complet, contrôle de non-écrasement, exclusion mutuelle des publications d'un même SHA. Le job de publication reconstruit, teste l'image exacte puis la pousse.
- Aucune publication de `latest`, aucun changement du Compose NAS, de l'application, de TLS ou des versions de dépendances.

## Preuves disponibles

- DEVon : digest lu sur le registre Docker Hub avec entrée ARM64 ; installation de production depuis les manifestes copiés en dossier temporaire, chargement de `tydom-client@0.13.4` réussi sous Windows.
- `npm test --prefix tydom-bridge` : 33/33 tests passants, Node local v26.12.1, Windows. Ce résultat n'est pas une preuve Linux ARM64.
- Analyse YAML du workflow : syntaxe et dépendances des jobs vérifiées.
- `git diff --check` sur les changements de build : aucun problème.
- Diff du Compose NAS : aucune modification.
- Relecture directe : maintien du scan Sonar avant publication, test de l'image publiée avant push, erreurs de registre autres qu'absence de manifest remontées explicitement.

## Limites / suite

- Docker et actionlint non disponibles localement : aucun build Docker ni smoke test d'image exécuté ici. Les étapes CI sont préparées mais leurs résultats ne sont pas acquis.
- L'utilisateur a confirmé uniquement le démarrage de Node 26 ARM64 sur le NAS ; la qualification complète Tydom relève de la phase 3 après validation humaine.
- Le noyau NAS 4.9 reste hors support officiel Node 26 ; aucune modification des protections Docker ni de la politique TLS n'est prévue.
- Digest de l'ancienne image encore requis avant bascule ; ne pas supprimer l'image actuelle.
- Aucun commit, push, publication ou déploiement effectué. Aucune preuve de réussite distante inventée.
- La décision de préparation est consignée dans le [plan](../007_tydom_node26_arm64.plan.md). Un ADR de migration effective et la documentation d'architecture seront finalisés après qualification et décision humaine ; la production n'est pas migrée.
