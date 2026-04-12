# Proxy Apache HTTPD — Frontal Domoticz

Image Docker Alpine + Apache 2.4 servant de **frontal sécurisé** devant Domoticz.  
Il expose deux VirtualHosts avec des politiques d'accès distinctes selon l'origine de la requête.

---

## Architecture réseau

```
                  Internet / Réseau local
                          │
          ┌───────────────┴──────────────────┐
          │ Accès externe                     │ Accès local
          │ HTTPS :8243                       │ HTTP :8280
          ▼                                   ▼
  ┌───────────────────────────────────────────────────────┐
  │                   httpd-proxy (Apache 2.4)            │
  │                                                       │
  │  VirtualHost :8243 (HTTPS)   VirtualHost :8280 (HTTP) │
  │  ┌─────────────────────┐    ┌─────────────────────┐   │
  │  │ SSL Termination     │    │ Pas de TLS          │   │
  │  │ Filtre User-Agent   │    │ CORS header *       │   │
  │  │ (3 agents autorisés)│    │ Accès libre         │   │
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
| Port | `8243` (exposé sur le Raspberry Pi) |
| Protocole entrant | HTTPS (TLS terminé par Apache) |
| Protocole sortant | HTTPS vers Domoticz `:8443` |
| Cible | `https://192.168.1.83:8443/` |
| Certificat | Auto-signé embarqué dans l'image |

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
