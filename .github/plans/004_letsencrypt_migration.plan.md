# Plan d'Action 004 — Migration certificat TLS vers Let's Encrypt

**Statut :** COMPLÉTÉ  
**Date :** 2026-06-08  
**Amendé le :** 2026-06-08 (v2 — migration HTTP-01 → DNS-01)

---

## Objectif Global

Remplacer le certificat TLS auto-signé embarqué dans l'image Docker `httpd-proxy` par un certificat **Let's Encrypt** signé par une CA publique, géré automatiquement via un container dédié dans la stack Docker Compose.

**Motivations :**
- Supprimer les avertissements navigateur liés au certificat auto-signé
- Automatiser le renouvellement (actuellement 100% manuel + rebuild image)
- Aligner la pratique avec les standards de sécurité TLS modernes

---

## Décision architecturale

Voir [ADR-002](`docs/adr/002-letsencrypt-certificat-proxy-httpd.md`).

**Solution initiale (v1) :** Container `certbot/certbot` (webroot HTTP-01) — nécessitait NAT Freebox port 80.  
**Solution finale (v2) :** Container `neilpang/acme.sh` (DNS-01 via API Freebox) — aucun port entrant requis.

---

## ⚠️ Amendement v2 — Migration HTTP-01 → DNS-01

**Contexte :** La Freebox ne permet pas de NAT sur les ports publics inférieurs à 32678.  
Le challenge HTTP-01 (certbot, port 80) est donc **infaisable** dans ce contexte.

**Décision :** Remplacement de `certbot` par `acme.sh` avec le plugin `dns_freebox`.  
Le challenge DNS-01 crée un enregistrement TXT `_acme-challenge` via l'API Freebox — aucun port entrant requis.

### Changements apportés (2026-06-08)

| Fichier | Changement |
|---|---|
| `_docker/domotique-compose.yml` | Service `certbot` → `acme.sh` (daemon), port `80:80` supprimé, volumes `letsencrypt`+`certbot-www` → `acme-data` |
| `_docker/build_httpd/httpd.conf` | `Listen 80` + `VirtualHost *:80` supprimés, chemins SSL → `/acme.sh/__SERVER_NAME__/` |
| `_docker/build_httpd/README.md` | Procédure bootstrap DNS-01, enregistrement app Freebox API, NAT port 80 retiré |
| `docs/adr/002-letsencrypt-certificat-proxy-httpd.md` | Statut mis à jour, amendement DNS-01 documenté |

---

## Prérequis hors code (actions manuelles — v2)

| Action | Responsable | Statut |
|---|---|---|
| Enregistrer app acme.sh auprès de l'API Freebox + autorisation physique box | 👤 Développeur humain | À faire |
| Récupérer et configurer `FREEBOX_APP_ID` / `FREEBOX_API_KEY` (env Pi) | 👤 Développeur humain | À faire |
| Créer répertoire `/home/pi/appli/acme.sh/` sur le Pi | 👤 Développeur humain | À faire |
| Exécuter procédure bootstrap acme.sh (1ère émission) | 👤 Développeur humain | À faire |

> Procédure bootstrap détaillée dans `_docker/build_httpd/README.md` — section "Bootstrap — 1ère installation".

---

## Phase 1 — Implémentation (v1 — certbot HTTP-01)

**Agent :** 🔵 DEVon  
**Statut :** ✅ Complété (remplacé par v2)

### Tâches

#### T1.1 — `_docker/domotique-compose.yml`
- Ajout port `80:80` sur `httpd-proxy`
- Ajout service `certbot/certbot:latest` avec entrypoint de renouvellement (`sleep 12h`)
- Ajout volumes nommés `letsencrypt` + `certbot-www` (bind-mount sur `/home/pi/appli/`)

#### T1.2 — `_docker/build_httpd/httpd.conf`
- Ajout `Listen 80`
- Ajout VirtualHost `:80` dédié ACME (sert uniquement `/.well-known/acme-challenge/`, reste refusé)
- Chemins certificat VHost `:8243` → `/etc/letsencrypt/live/__SERVER_NAME__/fullchain.pem` + `privkey.pem`

#### T1.3 — `_docker/build_httpd/Dockerfile`
- Suppression des `COPY httpddomoticzserver.crt/key`
- Ajout `mkdir /var/www/certbot` dans le RUN

#### T1.4 — `.github/workflows/build-httpd.yml`
- Suppression de l'étape "extract certificate from secrets" (HTTPDDOMOTICZSERVER_CERT/KEY)

#### T1.5 — Nettoyage
- Suppression de `_docker/build_httpd/certs/httpddomoticzserver.crt`
- Suppression de `_docker/build_httpd/certs/httpddomoticzserver.key`
- Suppression du répertoire `_docker/build_httpd/certs/`
- Nettoyage `.gitignore` (lignes cert + certs/ supprimées)

---

## Phase 1b — Migration DNS-01 (v2 — acme.sh)

**Agent :** 🔵 DEVon  
**Statut :** ✅ Complété (2026-06-08)

---

## Phase 2 — Documentation

**Agent :** 🟣 DOCly  
**Statut :** ✅ Complété

### Tâches

#### T2.1 — `docs/ARCHITECTURE.md`
- Section 1 : flux réseau complet Internet → Freebox NAT → Apache → Domoticz
- Section 1bis : point d'entrée externe + table NAT + section certificat (Let's Encrypt, challenge DNS-01, renouvellement auto)

#### T2.2 — `README.md`
- Schéma global : ajout Freebox + URL publique `https://domatique.freeboxos.fr:38243/`
- Table accès réseau : URL complète + NAT 38243→8243

#### T2.3 — `_docker/build_httpd/README.md`
- Section "Point d'entrée externe" avec flux NAT Freebox
- Schéma architecture mis à jour
- Section "Gestion du certificat TLS" : Let's Encrypt, procédure bootstrap DNS-01, renouvellement auto

---

## Risques et mitigations

| Risque | Mitigation |
|---|---|
| App Freebox non enregistrée → bootstrap échoue | Documenter explicitement comme prérequis avant démarrage |
| API Freebox indisponible lors du renouvellement | acme.sh retente toutes les 12h ; Let's Encrypt notifie par email 30j avant expiration |
| Apache démarre sans cert (1er boot) → erreur SSL | Procédure bootstrap séquentielle : acme.sh d'abord, puis stack complète |
| Renouvellement cert sans reload Apache | Watchtower ou restart manuel périodique ; fenêtre de 30j pour agir avant expiration |

