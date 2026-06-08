# ADR 002 — Migration certificat TLS vers Let's Encrypt (proxy Apache httpd)

**Date :** 2026-06-08  
**Statut :** Acceptée  
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Le proxy Apache HTTPD (`httpd-proxy`) expose l'accès externe à Domoticz sur `https://domatique.freeboxos.fr:38243/`. Il utilisait un certificat TLS **auto-signé** embarqué directement dans l'image Docker (via `COPY` dans le Dockerfile).

**Problèmes identifiés :**
- Avertissement de sécurité dans tous les navigateurs (certificat non reconnu par une CA publique)
- Renouvellement 100% manuel : régénérer le certificat, le committer, déclencher un rebuild d'image en CI/CD
- Le certificat et sa clé privée transitaient par les secrets GitHub et l'image Docker
- Aucune expiration automatique surveillée

**Contraintes :**
- Domaine `domatique.freeboxos.fr` = sous-domaine DNS géré par Free (pas d'API DNS-01 disponible)
- Infrastructure sur Raspberry Pi, déployée via Docker Compose
- Port externe non-standard : `38243` (ne change pas la faisabilité du challenge ACME)

---

## Décision

**Nous avons décidé de** remplacer le certificat auto-signé par un certificat **Let's Encrypt** géré via un container `certbot/certbot` dans la stack Docker Compose, en utilisant le challenge HTTP-01 (webroot).

---

## Alternatives Considérées

### Option 1 : Container certbot dans Docker Compose (webroot HTTP-01) ✅ Retenue

- **Avantages** : Entièrement containerisé (cohérent avec l'architecture Docker-first), renouvellement automatique toutes les 12h, certificat signé CA publique (aucun avertissement navigateur), cert non embarqué dans l'image (surface d'attaque réduite)
- **Inconvénients** : Nécessite d'exposer le port 80 publiquement (nouvelle règle NAT Freebox), procédure bootstrap manuelle au premier déploiement

### Option 2 : Certbot sur le Pi hôte + volume mount

- **Avantages** : Plus simple à bootstrapper, certbot standalone sans conflit Apache
- **Inconvénients** : Dépendance hôte (certbot installé sur Pi, hors Docker), rupture avec l'approche tout-Docker, hook de restart manuel à maintenir
- **Raison du rejet** : Incohérence architecturale avec le modèle Docker-first du projet

### Option 3 : Challenge DNS-01 (Let's Encrypt)

- **Avantages** : Pas besoin d'exposer le port 80
- **Inconvénients** : Impossible en pratique — `freeboxos.fr` est géré par Free, aucune API DNS pour créer les enregistrements TXT requis
- **Raison du rejet** : Infaisable techniquement avec ce domaine

---

## Conséquences

### Positives
- Certificat signé Let's Encrypt : aucun avertissement navigateur
- Renouvellement automatique toutes les 12h (effectif à J-30 avant expiration)
- Certificat et clé privée ne transitent plus dans les secrets GitHub ni dans l'image Docker
- Suppression des secrets `HTTPDDOMOTICZSERVER_CERT` / `HTTPDDOMOTICZSERVER_KEY` de GitHub Actions

### Négatives / Compromis
- Port 80 exposé publiquement (nécessaire pour le challenge ACME HTTP-01)
- Procédure de bootstrap manuelle requise au premier déploiement
- Si le port 80 est fermé, le renouvellement automatique échoue (Let's Encrypt envoie des alertes email)

### Neutres
- L'image Docker `httpd-proxy` est allégée (plus de COPY cert/key)
- Les fichiers `certs/httpddomoticzserver.*` supprimés du dépôt
- La configuration `httpd.conf` référence désormais `__SERVER_NAME__` dans les chemins de certificat (substituté au build CI/CD via secret `SERVER_NAME`)

---

## Mise en œuvre

- **Fichiers impactés** :
  - `_docker/domotique-compose.yml` — service certbot, volumes, port 80
  - `_docker/build_httpd/httpd.conf` — Listen 80, VHost ACME, chemins certs
  - `_docker/build_httpd/Dockerfile` — suppression COPY certs
  - `.github/workflows/build-httpd.yml` — suppression étape extraction secrets cert
  - `.gitignore` — nettoyage lignes cert supprimées
- **Tâches de suivi** :
  - 👤 Développeur humain : ouvrir NAT Freebox port 80, créer répertoires Pi, exécuter bootstrap certbot
- **Date d'effet** : 2026-06-08

---

## Références

- [Plan d'Action 004 : `.github/plans/004_letsencrypt_migration.plan.md`](./../plans/004_letsencrypt_migration.plan.md)
- [Procédure bootstrap : `_docker/build_httpd/README.md`](./../../_docker/build_httpd/README.md)
- [Documentation architecture : `docs/ARCHITECTURE.md`](../ARCHITECTURE.md)
- [Let's Encrypt — Challenge HTTP-01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)
- [Image officielle certbot/certbot](https://hub.docker.com/r/certbot/certbot)
