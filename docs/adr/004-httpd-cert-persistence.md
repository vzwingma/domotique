# ADR 004 — Certificat HTTPD persistant hors image

**Date :** 2026-06-16  
**Statut :** Acceptée  
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Le proxy HTTPD générait un certificat auto-signé pendant le build Docker. Chaque rebuild changeait donc l'empreinte TLS, ce qui cassait la confiance côté `domotique-mobile` et obligeait à revalider ou reconstruire le client.

L'objectif est de conserver un certificat stable entre les rebuilds de l'image, sans introduire de dépendance à un rebuild mobile.

---

## Décision

**Nous avons décidé de** sortir le couple clé/certificat de l'image et de le persister dans un volume Docker nommé monté sur `/usr/local/apache2/conf/ssl_conf`, avec génération au premier démarrage seulement.

---

## Alternatives Considérées

### Option 1 : Certificat persistant dans un volume Docker nommé ✅ Retenue

- **Avantages** : empreinte TLS stable entre rebuilds, changement minimal, rotation contrôlée, pas de rebuild mobile.
- **Inconvénients** : gestion explicite du volume pour régénérer le certificat.

### Option 2 : Certificat régénéré à chaque build

- **Avantages** : simple à coder.
- **Inconvénients** : casse la confiance client à chaque rebuild.
- **Raison du rejet** : incompatible avec l'usage mobile existant.

### Option 3 : Certificat public ACME / Let's Encrypt

- **Avantages** : meilleure UX TLS.
- **Inconvénients** : dépend d'une infra DNS et d'un domaine compatible.
- **Raison du rejet** : hors de portée immédiate de l'environnement courant.

---

## Conséquences

### Positives
- Les rebuilds de l'image HTTPD ne changent plus la confiance TLS côté mobile.
- La rotation du certificat devient une opération d'exploitation, pas un effet de bord du build.
- Le flux de confiance reste simple et reproductible.

### Négatives / Compromis
- Le volume Docker doit être conservé pour garder le certificat.
- Une suppression du volume provoque une nouvelle empreinte TLS.

### Neutres
- Le certificat reste auto-signé.
- La configuration `httpd.conf` continue de porter le hostname public du proxy.

---

## Mise en œuvre

- **Fichiers impactés** :
  - `_docker/build_httpd/Dockerfile`
  - `_docker/build_httpd/httpd-cert-init.sh`
  - `_docker/domotique-compose.yml`
  - `_docker/build_httpd/README.md`
- **Tâches de suivi** :
  - DOCly — documenter la rotation manuelle du volume
  - QALvin — vérifier que l'empreinte TLS reste stable entre deux rebuilds
- **Date d'effet** : 2026-06-16

---

## Références

- [Plan d'Action 006 — Persistance du certificat HTTPD](../../.github/plans/006_httpd_cert_persistence.plan.md)
- [`_docker/build_httpd/README.md`](../../_docker/build_httpd/README.md)
