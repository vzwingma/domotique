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
- le certificat TLS auto-signé (`certs/httpddomoticzserver.crt` + `.key`)
- la configuration Apache (`httpd.conf`) avec le placeholder `__SERVER_NAME__` substitué au build via CI/CD (secret `SERVER_NAME`)

---

## Gestion du certificat TLS

| Propriété | Valeur |
|---|---|
| Type | **Auto-signé** (self-signed) |
| Emplacement image | `/usr/local/apache2/conf/ssl_conf/` |
| Fichiers sources | `certs/httpddomoticzserver.crt` + `certs/httpddomoticzserver.key` |
| Intégration | Copiés dans l'image via `Dockerfile` (`COPY`) |
| Renouvellement | **Manuel** — régénérer, committer, puis rebuilder l'image |

**Renouvellement du certificat (procédure) :**

```bash
# Générer un nouveau certificat auto-signé (valable 3650 jours)
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout certs/httpddomoticzserver.key \
  -out certs/httpddomoticzserver.crt \
  -subj "/CN=domatique.freeboxos.fr"

# Rebuilder l'image (ou laisser la CI/CD le faire au prochain push master)
docker build -t vzwingmadomatic/httpd:latest .
```

> ⚠️ Le certificat auto-signé génère un avertissement dans les navigateurs.
> Il n'y a pas de renouvellement automatique (pas de Let's Encrypt / ACME intégré).

---

## CI/CD

L'image est reconstruite automatiquement à chaque push sur `master` :

[![Build httpd ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-httpd.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/blob/master/.github/workflows/build-httpd.yml)

---

## Fichiers

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Image Alpine + copie cert + conf |
| `httpd.conf` | Configuration Apache (VirtualHosts, SSL termination, proxy) |
| `certs/httpddomoticzserver.crt` | Certificat TLS auto-signé |
| `certs/httpddomoticzserver.key` | Clé privée du certificat |
