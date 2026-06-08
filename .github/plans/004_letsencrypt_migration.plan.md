# Plan d'Action 004 — Migration certificat TLS vers Let's Encrypt

**Statut :** COMPLÉTÉ  
**Date :** 2026-06-08

---

## Objectif Global

Remplacer le certificat TLS auto-signé embarqué dans l'image Docker `httpd-proxy` par un certificat **Let's Encrypt** signé par une CA publique, géré automatiquement via un container `certbot` dans la stack Docker Compose.

**Motivations :**
- Supprimer les avertissements navigateur liés au certificat auto-signé
- Automatiser le renouvellement (actuellement 100% manuel + rebuild image)
- Aligner la pratique avec les standards de sécurité TLS modernes

---

## Décision architecturale

Voir [ADR-002](`docs/adr/002-letsencrypt-certificat-proxy-httpd.md`).

**Solution retenue :** Container `certbot/certbot` dans la stack Compose (webroot HTTP-01), certificats stockés sur le Pi via bind-mount.

---

## Prérequis hors code (actions manuelles)

| Action | Responsable | Statut |
|---|---|---|
| Ouvrir NAT Freebox : port 80 public → port 80 Pi | 👤 Développeur humain | À faire |
| Créer répertoires `/home/pi/appli/letsencrypt` et `certbot-www` | 👤 Développeur humain | À faire |
| Exécuter procédure bootstrap certbot (1ère émission) | 👤 Développeur humain | À faire |

> Procédure bootstrap détaillée dans `_docker/build_httpd/README.md` — section "Bootstrap — 1ère installation".

---

## Phase 1 — Implémentation

**Agent :** 🔵 DEVon  
**Statut :** ✅ Complété

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

## Phase 2 — Documentation

**Agent :** 🟣 DOCly  
**Statut :** ✅ Complété

### Tâches

#### T2.1 — `docs/ARCHITECTURE.md`
- Section 1 : flux réseau complet Internet → Freebox NAT → Apache → Domoticz
- Section 1bis : point d'entrée externe + table NAT + section certificat (Let's Encrypt, challenge HTTP-01, renouvellement auto)

#### T2.2 — `README.md`
- Schéma global : ajout Freebox + URL publique `https://domatique.freeboxos.fr:38243/`
- Table accès réseau : URL complète + NAT 38243→8243

#### T2.3 — `_docker/build_httpd/README.md`
- Section "Point d'entrée externe" avec flux NAT Freebox
- Schéma architecture mis à jour
- Section "Gestion du certificat TLS" : Let's Encrypt, procédure bootstrap 4 étapes, renouvellement auto

---

## Risques et mitigations

| Risque | Mitigation |
|---|---|
| Port 80 non ouvert sur Freebox → bootstrap échoue | Documenter explicitement comme prérequis avant démarrage |
| Apache démarre sans cert (1er boot) → erreur SSL | Procédure bootstrap séquentielle : httpd d'abord port 80 seulement, puis certbot, puis stack complète |
| Renouvellement échoue (port 80 fermé) | Certbot retente toutes les 12h ; Let's Encrypt notifie par email 30j avant expiration |
| `freeboxos.fr` = DNS Free, pas de DNS-01 possible | Challenge HTTP-01 retenu ; DNS-01 explicitement écarté (pas d'API DNS Free) |
