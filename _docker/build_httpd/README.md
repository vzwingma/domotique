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

## Gestion du certificat TLS

### Contraintes Let's Encrypt avec `freeboxos.fr`

| Challenge ACME | Port requis | Faisable avec cette config ? |
|---|---|---|
| HTTP-01 (webroot) | port 80 public | ❌ NAT Freebox min port 32678 |
| TLS-ALPN-01 | port 443 public | ❌ même contrainte |
| DNS-01 (automatique) | aucun | ❌ `freeboxos.fr` = DNS géré par Free, pas d'API pour ajouter des TXT |

> **Let's Encrypt automatisé est impossible avec `domatique.freeboxos.fr`** dans la configuration actuelle.  
> Le container `acme.sh` est en place et prêt — il fonctionnera dès qu'un **domaine personnel** avec une API DNS supportée sera utilisé.

---

### Option A — Domaine personnel + Cloudflare DNS ✅ Recommandé

Acheter un domaine (~1–10 €/an chez OVH, Namecheap…) et déléguer le DNS à Cloudflare (gratuit).  
acme.sh dispose d'un hook `dns_cf` (Cloudflare) pleinement automatisé — aucun port entrant requis.

#### Pré-requis

1. Domaine enregistré, nameservers pointant vers Cloudflare
2. Clé API Cloudflare (`CF_Token` ou `CF_Key`+`CF_Email`) sur le Pi
3. Enregistrement DNS A `mon-domaine.tld` → IP publique Freebox (ou DDNS)
4. NAT Freebox 38243 → Pi 8243 (déjà en place)

#### Variables d'environnement (`.env` dans `_docker/`)

```bash
CF_Token=<Cloudflare API Token>       # ou CF_Key + CF_Email
```

#### Bootstrap

```bash
# 1. Créer le répertoire sur le Pi
mkdir -p /home/pi/appli/acme.sh

# 2. Émettre le certificat initial
docker compose -f domotique-compose.yml run --rm \
  -e CF_Token=${CF_Token} \
  acme.sh --issue --dns dns_cf \
  -d mon-domaine.tld \
  --server letsencrypt

# 3. Mettre à jour ServerName dans la config (secret GitHub SERVER_NAME)
# 4. Démarrer la stack complète
docker compose -f domotique-compose.yml up -d
```

#### Renouvellement automatique

Le container `acme.sh` en mode daemon renouvelle toutes les 12h (effectif à J-30).  
Apache reprend le cert renouvelé au prochain restart du container.

---

### Option B — Certificat auto-signé (fallback)

Si aucun domaine personnel n'est disponible, revenir à un certificat auto-signé embarqué dans l'image :  
voir l'historique git avant le Plan 004 (commit de migration Let's Encrypt).

---
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
