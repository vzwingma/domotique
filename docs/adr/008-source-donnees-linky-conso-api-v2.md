# ADR 008 — Plugin Linky : source de données Conso API (Enedis Mesure synchrone V2) derrière une couche source sélectionnable, proxy Russandol conservé en repli

---

**Date :** 2026-11-25  
**Statut :** Acceptée (Gate #1 du plan 011, 2026-11-27)
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Le plugin Domoticz Linky (fork `vzwingma/DomoticzLinky` v2.7.0, fichier `plugin.py`, embarqué dans l'image `vzwingmadomatic/domoticz` par épinglage de SHA — [ADR 007](./007-plugins-domoticz-provenance-epinglee.md) —
et exécuté par Domoticz sur le NAS) récupère la courbe de charge 30 min et la puissance maximale journalière
via le **proxy tiers Russandol** (`Device-Flow-Proxy-Server`, OAuth2 Device Flow, `enedis.domoticz.russandol.pro`).
Ce proxy détient le contrat Enedis Data Connect et appelle l'API Enedis **Metering Data v5**.

Éléments de cadrage :

- **Panne du proxy** : depuis le 24/11/2026, il renvoie HTTP 500 sur toute route qui touche sa base de données.
  Tests `curl` du 2026-11-25 : les routes sans base répondent des 400 corrects ; `/device/code` et `/device/token` répondent 500 avec un `client_id` valide comme avec un `client_id` bidon ;
  le bac à sable `opensrcdev.alwaysdata.net` répond 200. Des 502 avaient été observés du 21 au 23/11.
  L'incident relève de l'hébergeur, hors de notre contrôle ; le dépôt du proxy est **inactif depuis 02/2026**.
- **Fin de l'API v5** : Enedis a publié le 28/09/2026 l'« **API Mesure synchrone V2** », qui remplace Metering Data v5.
  La fin de v5 est annoncée « à partir de septembre 2026 », sans date de coupure effective (v5 répondait encore le 22/11).
  Le format de réponse V2 est **entièrement différent**. Le proxy Russandol n'a, selon toute vraisemblance (dépôt inactif), pas été migré : même rétabli, il cessera de fonctionner à la coupure de v5.
- **Contrainte d'accès** : un particulier ne peut pas contracter Data Connect (réservé aux entités disposant d'un SIRET) : le passage par un intermédiaire est obligatoire.

Une décision est donc nécessaire : le plugin dépend aujourd'hui d'un service en panne, dont l'API sous-jacente est en fin de vie.

Issues liées : [vzwingma/DomoticzLinky#1](https://github.com/vzwingma/DomoticzLinky/issues/1),
upstream [guillaumezin/DomoticzLinky#258](https://github.com/guillaumezin/DomoticzLinky/issues/258) et [#259](https://github.com/guillaumezin/DomoticzLinky/issues/259).

---

## Décision

**Nous avons décidé** d'alimenter le plugin Linky via **Conso API** (`conso.boris.sh`), qui expose l'API Enedis Mesure synchrone V2 avec un jeton personnel (Bearer),
derrière une **couche source sélectionnable** dans le plugin. Le proxy Russandol (v5) est conservé en **repli** jusqu'à la coupure de v5, puis retiré.
La version du fork est **3.0.0** (paramètres du matériel modifiés).

Précisions :

- **Jeton** : stocké dans le paramètre matériel Domoticz `Password` (masqué dans l'interface), en clair dans `domoticz.db` comme les jetons OAuth actuels
  (risque S3 déjà accepté) ; **masqué dans les logs**.
- **Pas de Device Flow** en mode Conso API.
- **Pas de récupération de la production** (pas d'installation solaire) en mode Conso API.
- **Pas de rattrapage d'historique** : un trou de données est accepté.
- **Cadence** : 1 cycle par jour avec décalage aléatoire, **au plus 3 requêtes par jour et par PRM, retries compris** (compteur persisté), une seule nouvelle tentative différée de quelques heures, jamais de requêtes en boucle ni en parallèle, historique complet étalé sur plusieurs jours (au plus un lot de 365 j par jour) ; en-tête `User-Agent` identifiant le projet (exigence de Conso API). Motif : blocage automatique de l'IP, durable et sans recours, en cas d'abus.
- **Cœur du plugin conservé** (cache, HC/HP, devices `Linky <PRM>` et leur historique) grâce à un **adaptateur** qui convertit la réponse V2 vers la forme interne actuelle.
- **Format V2** : établi en Phase 0 ([rapport](../plans/011_reports/PHASE_0_CONTRAT_CONSO_API_V2.md)) — pas 15 min en W horodaté en fin d'intervalle, courbe ≤ 7 j par requête, puissance max par lots de 365 j ; jeton valable 3 ans.

---

## Alternatives Considérées

### Option 1 : Conso API (`conso.boris.sh`) derrière une couche source sélectionnable, Russandol en repli ✅ Retenue

- **Avantages** : contourne la panne du proxy Russandol ; réalise la migration vers l'API V2 ; réutilise le cœur du plugin (cache, HC/HP, devices et historique conservés) ;
  la source est interchangeable (Conso API, Russandol, et éventuellement une future source locale) ; le jeton est personnel et révocable.
- **Inconvénients** : dépendance à un service tiers gratuit maintenu par un seul développeur ; jeton longue durée en clair dans `domoticz.db` ;
  quotas partagés ; nécessite un adaptateur V2 → forme interne et une reconfiguration du matériel (version 3.0.0).

### Option 2 (A) : Rester sur le proxy Russandol

- **Avantages** : aucun changement de code ni de configuration.
- **Inconvénients** : service en panne (HTTP 500 depuis le 24/11/2026), dépôt inactif depuis 02/2026, pas de migration vers l'API V2.
- **Raison du rejet** : en panne et condamné par la fin de v5 ; conservé uniquement comme **repli** jusqu'à la coupure de v5.

### Option 3 (B') : MyElectricalData (conteneur + MQTT)

- **Avantages** : solution existante, plus riche que le seul plugin.
- **Inconvénients** : fait doublon avec Conso API ; migration vers V2 non vérifiée ; remplace le plugin au lieu de le faire évoluer.
- **Raison du rejet** : même rôle d'intermédiaire que Conso API, avec un coût d'intégration plus élevé (conteneur supplémentaire, MQTT) et une compatibilité V2 non démontrée.

### Option 4 (C) : Devenir client Enedis Data Connect et héberger le proxy

- **Avantages** : maîtrise complète de la chaîne.
- **Inconvénients** : exige un SIRET et un contrat Data Connect ; domaine public nécessaire (le plan 004 est bloqué faute de domaine) ; maintenance d'un proxy OAuth.
- **Raison du rejet** : disproportionné pour un usage domestique.

### Option 5 (D) : Lecture locale TIC (module LiXee ZLinky_TIC sur deCONZ)

- **Avantages** : temps réel, sans cloud.
- **Inconvénients** : matériel payant (écarté par 👤 pour l'instant) ; pas d'historique ni de courbe validée par Enedis.
- **Raison du rejet** : coût matériel et absence d'historique ; **reste une option future**, que la couche source sélectionnable permettrait d'accueillir.

### Option 6 (E) : Scraping de l'espace client Enedis

- **Avantages** : aucun intermédiaire contractuel.
- **Inconvénients** : non officiel, contraire aux CGU, fragile.
- **Raison du rejet** : risque juridique et instabilité.

---

## Conséquences

### Positives
- La panne du proxy Russandol est contournée.
- La migration vers l'API Enedis Mesure synchrone V2 est faite.
- Le cœur du plugin est réutilisé : cache, HC/HP, devices `Linky <PRM>` et leur historique sont conservés.
- La source de données est interchangeable.

### Négatives / Compromis
- Dépendance à un service tiers gratuit, maintenu par un seul développeur.
- Jeton longue durée en clair dans `domoticz.db` (révocable dans l'espace Enedis « partage de mes données »). La durée de vie du jeton n'est pas documentée.
- Quotas partagés (5 requêtes/s, 10 000 requêtes/h) et risque de blocage IP en cas d'abus.
- Version **incompatible** 3.0.0 : reconfiguration du matériel nécessaire.
- En mode Conso API : pas de production, pas de rattrapage d'historique (un trou de données est accepté).
- Budget d'appels strict : une panne prolongée côté Enedis/Conso API se traduit par un trou de données (pas de relance agressive).

### Neutres
- Documentation à mettre à jour : `readme` et `RETROCONCEPTION` du fork, `CHANGELOG`, `docs/ARCHITECTURE.md` § 5.4.

---

## Mise en œuvre

Voir le plan d'action [`docs/plans/011_linky_source_conso_api_v2.plan.md`](../plans/011_linky_source_conso_api_v2.plan.md) :

- **P0** — investigation du contrat V2 avec 👤 ✅ ([rapport](../plans/011_reports/PHASE_0_CONTRAT_CONSO_API_V2.md)) ;
- **P1** — implémentation dans le fork (🔵 DEVon) ✅ ([PR fork #5](https://github.com/vzwingma/DomoticzLinky/pull/5), fusionnée, `37249a9`) ;
- **P2** — tests (🟢 QALvin) ✅ ;
- **P3** — documentation (🟣 DOCly) ✅ (readme, rétrodoc § 17, CHANGELOG du fork ; `docs/ARCHITECTURE.md` § 5.4) ;
- **P4** — livraison v3.0.0, montée de version du pin dans `domotique` selon l'[ADR 007](./007-plugins-domoticz-provenance-epinglee.md), validation en production.

- **Fichiers impactés** : `plugin.py`, `readme` et `docs/RETROCONCEPTION.md` du fork `vzwingma/DomoticzLinky` ; `CHANGELOG` du fork ;
  `.github/workflows/build-domoticz.yml` (pin du SHA du tag `v3.0.0`) et `docs/ARCHITECTURE.md` § 5.4 dans `domotique`.
- **Tâches de suivi** : voir les phases ci-dessus ; ADR passée à `Acceptée` au Gate #1 (2026-11-27).
- **Vocabulaire** : dans le plugin et sa documentation, l'ancienne source (proxy tiers Russandol, API Enedis v5) s'affiche **« Legacy »** (valeur du paramètre `legacy`, `russandol` accepté). Le nom du proxy n'est conservé que dans cet ADR, qui date la décision.
- **Date d'effet** : à partir de la livraison de la version 3.0.0 du fork (phase P4 du plan 011).

---

## Références

- Plan d'Action associé : [`docs/plans/011_linky_source_conso_api_v2.plan.md`](../plans/011_linky_source_conso_api_v2.plan.md)
- [ADR 007](./007-plugins-domoticz-provenance-epinglee.md) — provenance épinglée du plugin Linky (mécanique de montée de version)
- [Architecture — § 5.4 Plugins Python Domoticz (Linky, deCONZ)](../ARCHITECTURE.md#54-plugins-python-domoticz-linky-deconz)
- Issues : [vzwingma/DomoticzLinky#1](https://github.com/vzwingma/DomoticzLinky/issues/1) · [guillaumezin/DomoticzLinky#258](https://github.com/guillaumezin/DomoticzLinky/issues/258) · [guillaumezin/DomoticzLinky#259](https://github.com/guillaumezin/DomoticzLinky/issues/259)
- [Fork `vzwingma/DomoticzLinky`](https://github.com/vzwingma/DomoticzLinky)
- Conso API : `conso.boris.sh`
