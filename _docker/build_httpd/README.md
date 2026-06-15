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
- un **certificat TLS auto-signé** généré à build time via `openssl`, avec CN/SAN alignés sur `SERVER_NAME` (valide 10 ans, renouvelé à chaque rebuild CI/CD)

---

## Gestion du certificat TLS

| Propriété | Valeur |
|---|---|
| Type | Certificat **auto-signé** généré à build time (`openssl req -x509`) |
| Identité TLS | `CN` + `subjectAltName` alignés sur `SERVER_NAME` |
| Durée de validité | 10 ans (renouvelé à chaque rebuild CI/CD) |
| Emplacement dans le container | `/usr/local/apache2/conf/ssl_conf/httpddomoticzserver.crt/.key` |
| Impact | Avertissement navigateur sur l'accès externe — normal et attendu |

### Côté Domoticz mobile

L'application mobile consomme le **même certificat PEM** exporté depuis le serveur HTTPS et le place dans `assets/certificates/domoticz.crt`.
Le hostname configuré dans le plugin SSL doit donc rester cohérent avec `SERVER_NAME` côté HTTPD.

### Évolution vers Let's Encrypt

Let's Encrypt est impossible avec `domatique.freeboxos.fr` :

| Challenge | Raison du blocage |
|---|---|
| HTTP-01 (port 80) | NAT Freebox min port public 32678 |
| DNS-01 | `freeboxos.fr` géré par Free — pas d'API pour ajouter des TXT |

**Prérequis pour Let's Encrypt :** acquérir un domaine personnel + déléguer le DNS à un provider avec API (ex: Cloudflare `dns_cf`).  
Une fois le domaine disponible, ajouter `neilpang/acme.sh` à la stack Compose avec le hook `dns_cf` — aucun port entrant requis.

---

## CI/CD

L'image est reconstruite automatiquement à chaque push sur `master` :

[![Build httpd ARM Docker Image](https://github.com/vzwingma/domotique/actions/workflows/build-httpd.yml/badge.svg?branch=master)](https://github.com/vzwingma/domotique/blob/master/.github/workflows/build-httpd.yml)

---

## Fichiers

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Image Alpine + conf Apache + certificat auto-signé généré à build time (`openssl`) |
| `httpd.conf` | Configuration Apache (VirtualHosts :8243/:8280, SSLProxy) |
