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
| Challenge | HTTP-01 (webroot, port 80) |
| Emplacement sur le Pi | `/home/pi/appli/letsencrypt/` (bind-mount) |
| Emplacement dans le container | `/etc/letsencrypt/live/<domaine>/fullchain.pem` + `privkey.pem` |
| Renouvellement | Automatique — container `certbot` toutes les 12h |
| NAT requis | Freebox port 80 public → Pi port 80 (en plus de 38243→8243) |

### Bootstrap — 1ère installation (procédure manuelle)

À exécuter **une seule fois** avant le premier démarrage de la stack avec SSL :

```bash
# 1. Créer les répertoires sur le Pi
mkdir -p /home/pi/appli/letsencrypt /home/pi/appli/certbot-www

# 2. Démarrer httpd-proxy seul (port 80 disponible pour ACME)
docker compose -f domotique-compose.yml up -d httpd-proxy

# 3. Obtenir le certificat initial
docker compose -f domotique-compose.yml run --rm certbot \
  certbot certonly --webroot \
  -w /var/www/certbot \
  -d domatique.freeboxos.fr \
  --email votre@email.com \
  --agree-tos --no-eff-email

# 4. Démarrer la stack complète
docker compose -f domotique-compose.yml up -d
```

> ⚠️ Le NAT Freebox port 80 doit être ouvert **avant** l'étape 3.

### Renouvellement automatique

Le container `certbot` tourne en boucle et tente un renouvellement toutes les 12h.
Let's Encrypt renouvelle effectivement le certificat à partir de J-30 avant expiration.
Apache relit les certificats à chaque nouvelle connexion TLS — aucun reload manuel requis.

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
