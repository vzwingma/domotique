# ADR 005 — Plans dans `docs/plans/` et consignes projet actives

---

**Date :** 2026-11-10
**Statut :** Acceptée
**Décideurs :** 🟠 ARCos + 👤 Développeur humain

---

## Contexte

Les fichiers de consignes projet `*.instructions.template.md` coexistent avec les consignes actives chargées par les agents; les versions divergent et les modifications récentes des modèles ne sont donc pas appliquées de façon cohérente. Le rôle orchestrateur n'a pas encore de fichier d'instructions actif.

Les plans existants (001 à 007), leurs rapports et leur index résident sous `.github/plans/`, tandis que les procédures générales et les références d'ADR désignent `docs/plans/`. Cette incohérence multiplie les chemins et rend certains liens inexacts.

## Décision

**Nous avons décidé de** fusionner les consignes projet des modèles dans les fichiers actifs `.md` sans perdre les règles métier valides, de créer le fichier actif d'orchestration, et d'établir `docs/plans/` comme emplacement unique des plans, rapports et index.

Les modèles génériques réutilisables de plan, rapport de phase, handoff, ADR et architecture restent des modèles et conservent leurs noms explicites.

## Alternatives considérées

### Option A : remplacer les consignes actives par les modèles

- **Avantages** : migration mécanique et rapide.
- **Inconvénients** : risque de perte de consignes domotique spécifiques, notamment les règles de non-régression dzVents.
- **Raison du rejet** : écraser les fichiers actifs ne garantit pas la conservation de tout le contexte métier utile.

### Option B : fusionner les contenus et migrer les plans ✅ Retenue

- **Avantages** : une source active cohérente par rôle, préservation des règles projet, chemin de plans unique aligné sur les procédures.
- **Inconvénients** : fusion manuelle à vérifier, liens relatifs à corriger et références à mettre à jour dans plusieurs documents.

### Option C : conserver les deux variantes de consignes

- **Avantages** : pas de fusion immédiate et compatibilité avec les mécanismes génériques de modèles.
- **Inconvénients** : risque durable de divergence et incertitude sur la source à modifier.
- **Raison du rejet** : ne répond pas à la demande de consignes actives affinées et ne résout pas l'incohérence de chemin des plans.

## Conséquences

### Positives

- Les agents utilisent les consignes projet enrichies et cohérentes.
- Les plans, rapports et index ont un emplacement unique sous `docs/plans/`.
- Les modèles génériques restent disponibles pour de futures initialisations.

### Négatives / compromis

- Les références relatives des plans déplacés et plusieurs documents doivent être corrigés.
- Les consignes actives deviennent la source de vérité; toute évolution future doit les modifier directement plutôt que maintenir des copies divergentes.
- La migration documentaire nécessite une vérification statique exhaustive des liens et chemins.

### Neutres

- `.github/PLANS.md`, `docs/ARCHITECTURE.md`, les instructions d'agents et plusieurs skills/prompts doivent être alignés.
- Le contenu des consignes doit conserver les règles domotiques valides, notamment les invariants de scène, Tydom, groupes et logs.

## Mise en œuvre

- **Fichiers impactés** : `.github/copilot-instructions.md`, `.github/instructions/`, `.github/agents/`, `.github/README.md`, `.github/PLANS.md`, `.github/skills/`, `.github/prompts/`, `docs/plans/`, `docs/adr/`, `docs/ARCHITECTURE.md`.
- **Tâches de suivi** : 🟣 DOCly — fusionner les consignes et déplacer les plans; 🟢 QALvin — vérifier les liens, chemins et règles préservées; 🟣 DOCly — corriger les constats et synchroniser la clôture.
- **Date d'effet** : après validation du plan 008 au Gate #1.

## Références

- Plan d'Action associé : [`docs/plans/008_harmonisation-templates-et-plans.plan.md`](../plans/008_harmonisation-templates-et-plans.plan.md)
- ADR 004 : [`004-httpd-cert-persistence.md`](./004-httpd-cert-persistence.md)
