# ADR 002 — Migration certificat TLS vers Let's Encrypt (proxy Apache httpd)

**Date :** 2026-06-08  
**Statut :** Amendée (v2 — 2026-06-08)  
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Le proxy Apache HTTPD (`httpd-proxy`) expose l'accès externe à Domoticz sur `https://domatique.freeboxos.fr:38243/`. Il utilisait un certificat TLS **auto-signé** embarqué directement dans l'image Docker (via `COPY` dans le Dockerfile).

**Problèmes identifiés :**
- Avertissement de sécurité dans tous les navigateurs (certificat non reconnu par une CA publique)
- Renouvellement 100% manuel : régénérer le certificat, le committer, déclencher un rebuild d'image en CI/CD
- Le certificat et sa clé privée transitaient par les secrets GitHub et l'image Docker
- Aucune expiration automatique surveillée

**Contraintes initiales :**
- Domaine `domatique.freeboxos.fr` = sous-domaine DNS géré par Free
- Infrastructure sur Raspberry Pi, déployée via Docker Compose
- Port externe non-standard : `38243` (ne change pas la faisabilité du challenge ACME)

**Contrainte découverte post-implémentation v1 :**
- La Freebox ne permet pas de NAT sur les ports publics < 32678 → port 80 public inaccessible
- Le challenge HTTP-01 (certbot) est donc **infaisable** dans ce contexte

---

## Décision

**v1 (2026-06-08, révisée) :** Container `certbot/certbot` (webroot HTTP-01) — requiert NAT port 80.  
**v2 (2026-06-08, retenue) :** Container `neilpang/acme.sh` (challenge DNS-01 via plugin `dns_freebox`).

Le plugin `dns_freebox` d'acme.sh utilise l'API locale Freebox pour créer l'enregistrement TXT `_acme-challenge` requis par Let's Encrypt — aucun port entrant requis.

---

## Alternatives Considérées

### Option 1 : Container certbot dans Docker Compose (webroot HTTP-01) — v1, remplacée

- **Avantages** : Entièrement containerisé, renouvellement automatique toutes les 12h
- **Inconvénients** : Nécessite d'exposer le port 80 publiquement — **impossible** (Freebox NAT min port 32678)
- **Raison de remplacement** : Contrainte NAT Freebox bloque le challenge HTTP-01

### Option 2 : Certbot sur le Pi hôte + volume mount

- **Avantages** : Plus simple à bootstrapper, certbot standalone sans conflit Apache
- **Inconvénients** : Dépendance hôte (certbot installé sur Pi, hors Docker), rupture avec l'approche tout-Docker, hook de restart manuel à maintenir
- **Raison du rejet** : Incohérence architecturale avec le modèle Docker-first du projet

### Option 3 : Challenge DNS-01 avec acme.sh + plugin dns_freebox ✅ Retenue (v2)

- **Avantages** : Pas besoin d'exposer le port 80, entièrement automatisé via l'API Freebox locale, compatible Docker-first
- **Inconvénients** : Nécessite d'enregistrer une app auprès de l'API Freebox (opération manuelle unique), `FREEBOX_APP_ID`/`FREEBOX_API_KEY` à configurer sur le Pi
- **Raison du choix** : Seule option viable compte tenu de la contrainte NAT Freebox

---

## Conséquences

### Positives
- Certificat signé Let's Encrypt : aucun avertissement navigateur
- Renouvellement automatique toutes les 12h (effectif à J-30 avant expiration)
- Certificat et clé privée ne transitent plus dans les secrets GitHub ni dans l'image Docker
- **Aucun port entrant requis** (ni 80, ni autre) — surface d'attaque réduite

### Négatives / Compromis
- Enregistrement initial de l'app Freebox requis (opération manuelle unique, appui physique sur la box)
- `FREEBOX_APP_ID` et `FREEBOX_API_KEY` à gérer comme secrets sur le Pi
- Apache ne relit les certs qu'au restart du container (pas de reload automatique post-renouvellement)

### Neutres
- L'image Docker `httpd-proxy` ne monte plus le volume certbot-www
- Le VirtualHost `:80` et `Listen 80` supprimés de `httpd.conf`
- La configuration `httpd.conf` référence désormais `/acme.sh/__SERVER_NAME__/` pour les certs (substituté au build CI/CD via secret `SERVER_NAME`)

---

## Mise en œuvre

- **Fichiers impactés (v1)** :
  - `_docker/build_httpd/Dockerfile` — suppression COPY certs
  - `.github/workflows/build-httpd.yml` — suppression étape extraction secrets cert
  - `.gitignore` — nettoyage lignes cert supprimées
- **Fichiers impactés (v2)** :
  - `_docker/domotique-compose.yml` — service acme.sh, volumes acme-data, suppression port 80
  - `_docker/build_httpd/httpd.conf` — suppression Listen 80 + VHost ACME, chemins certs acme.sh
  - `_docker/build_httpd/README.md` — procédure bootstrap DNS-01
- **Tâches de suivi (v2)** :
  - 👤 Développeur humain : enregistrer app acme.sh via API Freebox, configurer env vars Pi, créer `/home/pi/appli/acme.sh/`, exécuter bootstrap
- **Date d'effet v1** : 2026-06-08
- **Date d'effet v2** : 2026-06-08

---

## Références

- [Plan d'Action 004 : `.github/plans/004_letsencrypt_migration.plan.md`](./../plans/004_letsencrypt_migration.plan.md)
- [Procédure bootstrap : `_docker/build_httpd/README.md`](./../../_docker/build_httpd/README.md)
- [Documentation architecture : `docs/ARCHITECTURE.md`](../ARCHITECTURE.md)
- [acme.sh — plugin dns_freebox](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_freebox)
- [Let's Encrypt — Challenge DNS-01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
- [Image officielle neilpang/acme.sh](https://hub.docker.com/r/neilpang/acme.sh)


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
