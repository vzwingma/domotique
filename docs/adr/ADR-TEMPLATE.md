# ADR NNN — [Titre court de la décision]

> **Template** : Copier ce fichier dans `docs/adr/NNN-titre-court.md`.  
> Format de nommage : `NNN` = numéro à 3 chiffres (ex: `001`, `042`), titre en kebab-case.

---

**Date :** [AAAA-MM-JJ]  
**Statut :** [Proposée / Acceptée / Rejetée / Dépréciée / Remplacée par ADR-NNN]
**Décideurs :** [🟠 ARCos + 👤 Développeur humain]

---

## Contexte

> Décrire la situation actuelle et pourquoi une décision est nécessaire.  
> Inclure les contraintes techniques, métier ou d'équipe qui influencent le choix.

[Description du problème ou du besoin qui nécessite cette décision architecturale.]

---

## Décision

> Énoncer clairement la décision prise, en une ou deux phrases directes.

**Nous avons décidé de** [DÉCISION].

---

## Alternatives Considérées

> Lister les options qui ont été évaluées avant de prendre la décision.

### Option 1 : [Nom de l'alternative retenue] ✅ Retenue

- **Avantages** : [ex. réduit le couplage entre scripts dzVents et intégrations externes]
- **Inconvénients** : [ex. nécessite de centraliser les mappings dans `global_data.lua`]

### Option 2 : [Nom de l'alternative]

- **Avantages** : [...]
- **Inconvénients** : [...]
- **Raison du rejet** : [...]

### Option 3 : [Nom de l'alternative]

- **Avantages** : [...]
- **Inconvénients** : [...]
- **Raison du rejet** : [...]

---

## Conséquences

### Positives
- [ex. améliore la cohérence de `scenePhase` entre les scènes et leurs consommateurs]
- [ex. conserve les IDs Tydom dans `TYDOM_DEVICES`]

### Négatives / Compromis
- [ex. nécessite de mettre à jour plusieurs scripts dzVents et de valider les flux croisés]
- [ex. impose une coordination avec le bridge ou la configuration Docker]

### Neutres
- [ex. implique de mettre à jour `docs/ARCHITECTURE.md` ou `docs/scenarios.puml`]

---

## Mise en œuvre

> Décrire comment cette décision est appliquée concrètement dans le projet.

- **Fichiers impactés** : [ex. `domoticz/scripts/dzVents/`, `_docker/`]
- **Tâches de suivi** : [ex. DEVon — adapter les scripts consommateurs de `Scene Phase`]
- **Date d'effet** : [ex: À partir de la version v2.0]

---

## Références

- [Lien vers la documentation officielle, RFC, article, ou plan d'action associé]
- Plan d'Action associé : `docs/plans/NNN_nom.plan.md`
