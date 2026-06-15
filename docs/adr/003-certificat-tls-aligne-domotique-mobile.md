# ADR 003 — Certificat TLS aligné sur Domoticz mobile

**Date :** 2026-06-15  
**Statut :** Acceptée  
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

L'application mobile `domotique-mobile` valide le certificat HTTPS de Domoticz à partir d'un PEM exporté depuis le serveur, puis vérifie le hostname configuré dans le plugin SSL. Le serveur HTTPD générait jusqu'ici un certificat auto-signé avec `CN=domoticz`, ce qui ne correspond pas au domaine utilisé par le mobile (`domatique.freeboxos.fr`).

Cette divergence provoquait un échec de validation côté client, alors que le certificat lui-même restait le bon objet de confiance.

---

## Décision

**Nous avons décidé de** générer le certificat auto-signé HTTPD avec `CN` et `subjectAltName` alignés sur le hostname public `domatique.freeboxos.fr`, puis d'exporter ce même certificat PEM dans `domotique-mobile`.

---

## Alternatives Considérées

### Option 1 : Un seul certificat auto-signé aligné sur le domaine public ✅ Retenue

- **Avantages** : comportement simple, hostname cohérent, export PEM identique côté mobile, validation TLS standard compatible.
- **Inconvénients** : tout changement de hostname impose une régénération du certificat et un nouvel export côté mobile.

### Option 2 : Conserver `CN=domoticz` et assouplir le client mobile

- **Avantages** : pas de changement serveur immédiat.
- **Inconvénients** : fragilise la validation TLS et maintient une divergence entre serveur et client.
- **Raison du rejet** : le client doit faire confiance à un identifiant cohérent, pas à un contournement spécifique.

### Option 3 : Certificats distincts pour navigateur et mobile

- **Avantages** : flexibilité théorique.
- **Inconvénients** : complexité opérationnelle, risque de désynchronisation, documentation plus fragile.
- **Raison du rejet** : inutile pour un proxy unique exposé sur un hostname unique.

---

## Conséquences

### Positives
- Le certificat servi par HTTPD correspond au hostname attendu par le mobile.
- Le même PEM peut être exporté et utilisé comme trust anchor dans l'app Android.
- La vérification TLS reste standard, sans règle spéciale par client.

### Négatives / Compromis
- Un changement de domaine implique une régénération du certificat et une mise à jour du bundle mobile.

### Neutres
- Le certificat reste auto-signé, donc l'avertissement navigateur disparaît toujours seulement si la chaîne de confiance est explicitement installée.

---

## Mise en œuvre

- **Fichiers impactés** :
  - `_docker/build_httpd/Dockerfile`
  - `.github/workflows/build-httpd.yml`
  - `_docker/build_httpd/README.md`
  - `README.md`
- **Tâches de suivi** :
  - re-exporter `domoticz.crt` dans `domotique-mobile/assets/certificates/`
  - vérifier que `DomoticzSSLHelper.java` pointe toujours vers `domatique.freeboxos.fr`
- **Date d'effet** : 2026-06-15

---

## Références

- [Plan d'Action 005 — Alignement TLS HTTPD / Domoticz mobile](../../.github/plans/005_tls_httpd_mobile_alignment.plan.md)
- [`_docker/build_httpd/README.md`](../../_docker/build_httpd/README.md)
- [`domotique-mobile/plugins/withNetworkSecurity.js`](https://github.com/vzwingma/domotique-mobile/blob/main/plugins/withNetworkSecurity.js)
