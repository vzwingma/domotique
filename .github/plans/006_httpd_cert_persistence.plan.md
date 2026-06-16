# Plan d'Action 006 — Persistance du certificat HTTPD

## Métadonnées
- ID : 006
- Fichier : `.github/plans/006_httpd_cert_persistence.plan.md`
- Statut global : EN_COURS
- Date : 2026-06-16

## Objectif global

Rendre le certificat TLS du frontal HTTPD stable entre les rebuilds de l'image Docker afin qu'un client mobile puisse conserver sa confiance sans rebuild de l'application.

## Périmètre

### In scope
- génération du certificat au démarrage si le volume est vide
- persistance du couple clé/certificat dans un volume Docker nommé
- mise à jour de la documentation HTTPD
- formalisation de la décision dans un ADR

### Out of scope
- migration vers un certificat ACME public
- modifications du client mobile
- refonte du proxy Apache

## Phases

### Phase 1 — Cadrage technique
**Contexte :** confirmer le chemin exact du certificat, le stockage cible et les impacts runtime.
**Critères de réussite :**
- chemin de certificat identifié
- stratégie de persistance figée

#### T1.1 - Cartographier le flux TLS
- **Agent :** ARCos
- **Fichiers :** `_docker/build_httpd/Dockerfile`, `_docker/build_httpd/httpd.conf`, `_docker/domotique-compose.yml`
- **À faire :** confirmer le point de génération du certificat et le point d'injection du volume.
- **Acceptation :** la cible de montage et le contrat de stabilité sont explicités.

### Phase 2 — Implémentation
**Contexte :** déplacer la génération du certificat hors du build et la rendre idempotente au démarrage.
**Critères de réussite :**
- image HTTPD sans régénération à chaque build
- certificat réutilisé si le volume existe

#### T2.1 - Ajouter l'init TLS runtime
- **Agent :** DEVon
- **Fichiers :** `_docker/build_httpd/Dockerfile`, `_docker/build_httpd/httpd-cert-init.sh`
- **À faire :** générer le certificat au premier démarrage, puis le réutiliser.
- **Acceptation :** le script fonctionne avec le volume vide et le volume déjà initialisé.

#### T2.2 - Monter le volume persistant
- **Agent :** DEVon
- **Fichiers :** `_docker/domotique-compose.yml`
- **À faire :** ajouter le volume nommé pour `ssl_conf`.
- **Acceptation :** le conteneur HTTPD redémarre avec le même certificat.

### Phase 3 — Documentation et validation
**Contexte :** documenter le nouveau contrat d'exploitation et vérifier le comportement.
**Critères de réussite :**
- doc alignée sur le runtime réel
- décision archivée

#### T3.1 - Mettre à jour la documentation
- **Agent :** DOCly
- **Fichiers :** `_docker/build_httpd/README.md`, `docs/adr/004-httpd-cert-persistence.md`, `.github/plans/README.md`
- **À faire :** documenter la persistance, la rotation et le plan associé.
- **Acceptation :** le fonctionnement sans rebuild mobile est décrit clairement.

#### T3.2 - Valider la stabilité TLS
- **Agent :** QALvin
- **Fichiers :** `_docker/build_httpd/httpd-cert-init.sh`
- **À faire :** vérifier qu'un rebuild de l'image ne change pas le certificat si le volume persiste.
- **Acceptation :** l'empreinte TLS reste stable entre deux rebuilds successifs.

## Dépendances
- Phase 2 dépend de Phase 1
- Phase 3 dépend de Phase 2

## Critères de succès globaux
- le certificat n'est plus régénéré à chaque build
- la clé et le certificat vivent dans un volume Docker nommé
- `domotique-mobile` peut rester inchangé lors d'un rebuild HTTPD
- la rotation manuelle est documentée
- l'ADR décrit la décision et ses compromis

## Risques / mitigations
- Risque : volume perdu ou supprimé
  - Mitigation : procédure de rotation/régénération documentée
- Risque : désalignement entre hostname et certificat
  - Mitigation : utiliser le même `SERVER_NAME` pour build et runtime

## Plan d'exécution
1. Lancer la Phase 1
2. Implémenter la Phase 2
3. Mettre à jour la doc et valider la Phase 3
