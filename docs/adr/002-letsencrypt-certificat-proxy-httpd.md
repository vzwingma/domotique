# ADR 002 — Migration certificat TLS vers Let's Encrypt (proxy Apache httpd)

**Date :** 2026-06-08  
**Statut :** En cours — bloqué (contraintes DNS `freeboxos.fr`)  
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

**Contraintes découvertes post-implémentation :**
- La Freebox ne permet pas de NAT sur les ports publics < 32678 → port 80 public inaccessible → HTTP-01 impossible
- `freeboxos.fr` est géré par Free — il est **impossible d'y ajouter des enregistrements TXT** → DNS-01 impossible sur ce domaine
- Le plugin `dns_freebox` n'existe pas dans acme.sh (confirmé à l'exécution)

**Conclusion :** Let's Encrypt est inaccessible avec `domatique.freeboxos.fr`. Un **domaine personnel** avec une API DNS supportée (ex: Cloudflare) est nécessaire.

---

## Décision

**v1 (remplacée) :** Container `certbot/certbot` (HTTP-01) — port 80 requis → impossible.  
**v2 (remplacée) :** Container `acme.sh` + plugin `dns_freebox` → plugin inexistant, `freeboxos.fr` DNS non modifiable.  
**v3 (retenue — en attente d'action humaine) :** Container `acme.sh` + plugin `dns_cf` (Cloudflare) sur un **domaine personnel**.

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

### Option 3 : Challenge DNS-01 avec acme.sh + Cloudflare (`dns_cf`) ✅ Retenue (v3, en attente)

- **Avantages** : Pas besoin d'exposer le port 80, entièrement automatisé, `dns_cf` est le hook acme.sh le plus éprouvé, gratuit via Cloudflare
- **Inconvénients** : Nécessite un domaine personnel (~1–10€/an) et délégation DNS à Cloudflare ; `CF_Token` à configurer sur le Pi
- **Raison du choix** : Seule option compatible avec la contrainte NAT Freebox et la structure DNS de `freeboxos.fr`

### Option 4 (rejetée) : Challenge DNS-01 avec `dns_freebox`

- **Inconvénients** : Plugin inexistant dans acme.sh ; de plus `freeboxos.fr` est géré par Free, impossible d'y ajouter des TXT
- **Raison du rejet** : Infaisable techniquement

---

## Conséquences

### Positives (acquises)
- Infrastructure acme.sh en place — opérationnelle dès qu'un domaine sera configuré
- Certificat et clé privée ne transitent plus dans les secrets GitHub ni dans l'image Docker
- Le VirtualHost `:80` supprimé — surface d'attaque réduite

### Négatives / Compromis
- **Let's Encrypt non opérationnel** avec `domatique.freeboxos.fr` — domaine personnel requis
- `CF_Token` Cloudflare à gérer comme secret sur le Pi
- Apache ne relit les certs qu'au restart du container

### Neutres
- L'image Docker `httpd-proxy` ne monte plus le volume certbot-www
- La configuration `httpd.conf` référence `/acme.sh/__SERVER_NAME__/` (substituté au build via secret `SERVER_NAME`)

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
- **Tâches de suivi (v3)** :
  - 👤 Développeur humain : acquérir domaine personnel, déléguer DNS à Cloudflare, configurer `CF_Token` sur Pi, mettre à jour secret GitHub `SERVER_NAME`, exécuter bootstrap `acme.sh --dns dns_cf`
- **Date d'effet v1** : 2026-06-08
- **Date d'effet v2** : 2026-06-08

---

## Références

- [Plan d'Action 004 : `.github/plans/004_letsencrypt_migration.plan.md`](./../plans/004_letsencrypt_migration.plan.md)
- [Procédure bootstrap : `_docker/build_httpd/README.md`](./../../_docker/build_httpd/README.md)
- [Documentation architecture : `docs/ARCHITECTURE.md`](../ARCHITECTURE.md)
- [acme.sh — plugin dns_cf (Cloudflare)](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_cf)
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
