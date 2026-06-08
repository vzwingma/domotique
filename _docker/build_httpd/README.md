# Proxy Apache HTTPD — Frontal Domoticz

Image Docker Alpine + Apache 2.4 servant de **frontal sécurisé** devant Domoticz.  
Il expose deux VirtualHosts avec des politiques d'accès distinctes selon l'origine de la requête.

---

## Point d'entrée externe

L'accès depuis Internet suit le chemin suivant :

```
  https://domatique.freeboxos.fr:38243/
          │  DNS Free → IP publique domicile
          ▼
  Freebox (routeur FAI)
  NAT : port 38243 (public) → port 8243 (Raspberry Pi LAN)
          │
          ▼
  httpd-proxy :8243  (ce composant)
  TLS termination → SSLProxy → Domoticz :8443
```

Le **routeur Freebox** assure le NAT. Aucun autre composant réseau intermédiaire entre Internet et ce proxy.

---

## Architecture réseau

```
                https://domatique.freeboxos.fr:38243/
                          │  (DNS Free → IP publique)
          ┌───────────────▼──────────────────┐
          │ Freebox (routeur FAI)            │
          │ NAT : 38243 → Pi :8243           │
          └───────────────┬──────────────────┘
                          │
           ┌──────────────┴──────────────────┐
           │ Accès externe                   │ Accès local
           │ HTTPS :8243                     │ HTTP :8280
           ▼                                 ▼
   ┌───────────────────────────────────────────────────────┐
   │                   httpd-proxy (Apache 2.4)            │
   │                                                       │
   │  VirtualHost :8243 (HTTPS)   VirtualHost :8280 (HTTP) │
   │  ┌─────────────────────┐    ┌─────────────────────┐   │
   │  │ TLS termination     │    │ Pas de TLS          │   │
   │  │ Cert auto-signé     │    │ CORS header *       │   │
   │  │ SSLProxy            │    │ Accès libre         │   │
   │  └──────────┬──────────┘    └──────────┬──────────┘   │
   └─────────────┼─────────────────────────┼───────────────┘
                 │ SSLProxy                 │ HTTP Proxy
                 ▼                          ▼
         Domoticz :8443 (HTTPS)     Domoticz :8080 (HTTP)
         (192.168.1.83)             (192.168.1.83)
```

---

## VirtualHost :8243 — Accès externe sécurisé

| Paramètre | Valeur |
|---|---|
| URL publique | `https://domatique.freeboxos.fr:38243/` |
| Port exposé Pi | `8243` |
| Protocole entrant | HTTPS (TLS terminé par Apache) |
| Protocole sortant | HTTPS vers Domoticz `:8443` (SSLProxy) |
| Cible | `https://192.168.1.83:8443/` |
| Certificat | Auto-signé, embarqué dans l'image Docker |

### Accès et authentification

Le VirtualHost `:8243` est un **proxy SSL transparent** : il termine le TLS et transmet toutes les requêtes à Domoticz sans filtrage ni authentification propre.

**L'authentification est entièrement déléguée à Domoticz** (login/mot de passe natif Domoticz, configurable dans `Setup → Settings → Security`).

```
Client externe  →  httpd :8243 (TLS termination)  →  Domoticz :8443 (auth native)
```

### Directives SSL (proxy sortant)

La vérification du certificat Domoticz (auto-signé) est désactivée côté proxy :

```apache
SSLProxyVerify none
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
SSLProxyCheckPeerExpire off
```

---

## VirtualHost :8280 — Accès local sans TLS

| Paramètre | Valeur |
|---|---|
| Port | `8280` (LAN uniquement) |
| Protocole entrant | HTTP (pas de TLS) |
| Protocole sortant | HTTP vers Domoticz `:8080` |
| Cible | `http://192.168.1.83:8080/` |
| Contrôle d'accès | `Require all granted` (pas de filtrage) |
| CORS | `Access-Control-Allow-Origin: *` |

Ce VirtualHost est destiné aux clients internes (scripts, dzVents, domoticz-ext-bridge) qui n'ont pas besoin de TLS sur le réseau local.

---

## Construction de l'image

```bash
# Depuis _docker/build_httpd/
docker build -t vzwingmadomatic/httpd:latest .
```

Le Dockerfile (`FROM httpd:2.4-alpine`) embarque :
- la configuration Apache (`httpd.conf`) avec le placeholder `__SERVER_NAME__` substitué au build via CI/CD (secret `SERVER_NAME`)
- **le certificat n'est plus embarqué** — il est monté via volume Docker depuis `/home/pi/appli/letsencrypt`

---

## Gestion du certificat TLS (Let's Encrypt)

| Propriété | Valeur |
|---|---|
| Type | **Let's Encrypt** (signé, 90 jours) |
| Challenge | DNS-01 (plugin `dns_freebox`, aucun port entrant requis) |
| Emplacement sur le Pi | `/home/pi/appli/acme.sh/` (bind-mount) |
| Emplacement dans le container httpd | `/acme.sh/<domaine>/fullchain.cer` + `<domaine>.key` |
| Renouvellement | Automatique — container `acme.sh` en mode daemon toutes les 12h |
| NAT requis | **Aucun port 80 nécessaire** — challenge DNS uniquement |

### Pré-requis — Enregistrement de l'application Freebox (une seule fois)

acme.sh utilise l'API Freebox pour créer le TXT record `_acme-challenge`. Il faut d'abord autoriser l'accès :

```bash
# 1. Déclarer l'application auprès de la Freebox
curl -X POST http://mafreebox.freebox.fr/api/v9/login/authorize \
  -H "Content-Type: application/json" \
  -d '{"app_id":"acme_sh","app_name":"ACME.sh","app_version":"1.0","device_name":"Raspberry Pi"}'

# → Appuyer sur le bouton physique de la Freebox pour autoriser l'accès
# → La réponse contient { "app_token": "..." }
```

Conserver `app_id` (`acme_sh`) et `app_token` — ils constituent `FREEBOX_APP_ID` et `FREEBOX_API_KEY`.

Les exposer comme variables d'environnement sur le Pi (fichier `.env` dans `_docker/` ou `~/.profile`) :

```bash
export FREEBOX_APP_ID=acme_sh
export FREEBOX_API_KEY=<app_token obtenu ci-dessus>
```

### Bootstrap — 1ère installation (procédure manuelle)

À exécuter **une seule fois** avant le premier démarrage de la stack avec SSL :

```bash
# 1. Créer le répertoire sur le Pi
mkdir -p /home/pi/appli/acme.sh

# 2. Émettre le certificat initial (DNS-01, sans port 80)
docker compose -f domotique-compose.yml run --rm \
  -e FREEBOX_APP_ID=${FREEBOX_APP_ID} \
  -e FREEBOX_API_KEY=${FREEBOX_API_KEY} \
  acme.sh --issue --dns dns_freebox \
  -d domatique.freeboxos.fr \
  --server letsencrypt

# 3. Démarrer la stack complète
docker compose -f domotique-compose.yml up -d
```

> ℹ️ Aucun NAT port 80 requis. Le challenge DNS-01 crée un enregistrement TXT via l'API Freebox.

### Renouvellement automatique

Le container `acme.sh` tourne en mode daemon et tente un renouvellement toutes les 12h.
Let's Encrypt renouvelle effectivement le certificat à partir de J-30 avant expiration.
Apache relit les certificats au prochain redémarrage du container — aucun reload manuel requis pour les renouvellements courants (fenêtre de 30 jours).

---

## CI/CD

L'image est reconstruite automatiquement à chaque push sur `master` :

[![Build httpd ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-httpd.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/blob/master/.github/workflows/build-httpd.yml)

---

## Fichiers

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Image Alpine + conf Apache (certificat monté via volume, non embarqué) |
| `httpd.conf` | Configuration Apache (VirtualHosts :80/:8243/:8280, ACME webroot, SSLProxy) |
