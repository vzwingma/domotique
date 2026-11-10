# ADR 006 — Tydom bridge : Node 26 ARM64 avec configuration OpenSSL legacy dédiée

---

**Date :** 2026-11-10  
**Statut :** Acceptée
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Le conteneur `tydom-bridge` est passé sur un NAS Asustor AS1102T (hôte `aarch64`, noyau 4.9.119, Docker 29.6.2),
déployé par une stack Portainer GitOps qui suit `master`. L'image d'origine tournait en Node 16.20.2 ARM32
(`linux/arm/v7`, Debian 10), une version de Node qui n'est plus maintenue. L'objectif est de passer en Node 26 slim natif `linux/arm64`.

Contraintes constatées :
- Node 26 ARM64 demande officiellement un noyau ≥ 4.18. Celui du NAS ne peut pas être mis à jour : la configuration reste hors support,
  même si elle fonctionne.
- Node 26 embarque OpenSSL 3.5. La box Tydom locale exige la **renégociation TLS legacy** (`ERR_SSL_UNSAFE_LEGACY_RENEGOTIATION_DISABLED`),
  et son certificat auto-signé a une **clé de moins de 1024 bits** (`EE certificate key too weak`, y compris avec `SECLEVEL=1`).
  Node 16 tolérait ces deux points ; Node 26 les refuse par défaut, d'où des `fetch failed` en boucle.
- Renovate a monté `tydom-client` de 0.13.4 à 0.16.1 pendant la migration. La version 0.15.1 avait été rejetée (No-Go).

## Décision

**Nous avons décidé de** publier `vzwingmadomatic/domoticz-tydom:latest` en image unique `linux/arm64`
basée sur `node:26.13.0-bookworm-slim` (épinglée par digest), avec `tydom-client@0.16.1`.
L'image génère au build un fichier OpenSSL dédié (`OPENSSL_CONF=/usr/local/etc/tydom-openssl.cnf`,
section `nodejs_conf`, `Options = UnsafeLegacyRenegotiation`, `CipherString = DEFAULT:@SECLEVEL=0`).
Le Compose NAS suit `latest` avec `platform: linux/arm64`.

## Alternatives Considérées

### Option 1 : Node 26 ARM64 + configuration OpenSSL legacy limitée au conteneur Tydom ✅ Retenue

- **Avantages** : runtime maintenu ; image native ARM64 sans émulation ; aucun changement de code applicatif ;
  l'affaiblissement TLS reste confiné à ce conteneur et la CI vérifie que la configuration est bien présente.
- **Inconvénients** : TLS fortement affaibli (renégociation non sûre, clés faibles acceptées) pour tout le processus ;
  noyau NAS hors support officiel Node 26.

### Option 2 : conserver l'image Node 16 ARM32

- **Avantages** : fonctionne sans configuration TLS particulière.
- **Inconvénients** : Node 16 n'est plus maintenu ; image ARM32 sur un hôte ARM64 ; sans correctifs de sécurité.
- **Raison du rejet** : contraire à l'objectif de migration ; l'image reste le point de retour arrière.

### Option 3 : Node 26 avec configuration OpenSSL par défaut (ou correctif côté code via les options TLS de `tydom-client`)

- **Avantages** : pas d'affaiblissement global d'OpenSSL.
- **Inconvénients** : avec la configuration par défaut, la connexion à la box échoue. `tydom-client` 0.16.1 utilise le `fetch` natif,
  et n'expose pas les options TLS nécessaires. Il faudrait forker ou patcher la librairie.
- **Raison du rejet** : non fonctionnel en l'état ; trop d'effort et de maintenance pour un gain limité sur le réseau local.

### Option 4 : `SECLEVEL=1` au lieu de 0

- **Avantages** : affaiblissement moindre.
- **Raison du rejet** : testé sur le NAS, toujours `EE certificate key too weak`.

## Conséquences

### Positives
- Bridge opérationnel en Node 26 ARM64 avec `tydom-client@0.16.1`, fonctionnement confirmé le 2026-11-10
  par l'utilisateur sur le NAS avec la box réelle.
- La CI construit et vérifie l'image hors réseau : `arm64`, Node 26, version de `tydom-client` égale à `package.json`,
  configuration OpenSSL présente. Seul `master` publie `latest`.

### Négatives / Compromis
- Sécurité TLS du conteneur Tydom réduite (renégociation legacy, clés faibles, certificat non vérifié via
  `NODE_TLS_REJECT_UNAUTHORIZED=0`). Acceptable car le flux reste sur le LAN. Ne pas réutiliser cette image pour d'autres flux.
- Noyau 4.9 hors support officiel : surveiller le comportement après chaque montée de Node.
- `latest` ne contient plus l'image ARM32 et l'image de rollback locale a été supprimée le 2026-11-10 après validation :
  aucun retour vers Node 16 n'est plus possible directement. Un incident se corrige en avant : nouvelle publication `master`, ou retour à une image Node 26 précédente si elle a été conservée sous un tag local.
- Le Compose NAS suivant `latest` sans digest, chaque déploiement demande un pull explicite de l'image Tydom.

### Neutres
- Piège documenté : Node ne lit que la section `nodejs_conf` du fichier `OPENSSL_CONF` (`openssl_conf` n'est lue qu'avec `--openssl-shared-config`).

## Mise en œuvre

- **Fichiers impactés** : `_docker/build_tydom/Dockerfile`, `_docker/build_tydom/openssl.cnf`, `.github/workflows/build-tydom.yml`,
  `_docker/envs/nas/domotique-compose.yml`, `tydom-bridge/package.json`, `tydom-bridge/package-lock.json`.
- **Tâches de suivi** : requalifier avec la box réelle toute montée de version de `tydom-client` ou de Node (et de leurs majeures OpenSSL) ;
  avant chaque pull de `latest` sur le NAS, conserver l'image en cours sous un tag local de retour arrière.
- **Date d'effet** : 2026-11-10 (PR #225 à #227).

## Références

- Plan d'Action associé : [`docs/plans/007_tydom_node26_arm64.plan.md`](../plans/007_tydom_node26_arm64.plan.md)
- [Image Docker tydom-bridge](../../_docker/build_tydom/README.md)
- [Node.js — prérequis de plateforme (BUILDING.md v26.x)](https://github.com/nodejs/node/blob/v26.x/BUILDING.md)
- [Node.js — option `--openssl-shared-config`](https://nodejs.org/api/cli.html#--openssl-shared-config)
