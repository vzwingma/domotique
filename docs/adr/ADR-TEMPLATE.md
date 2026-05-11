# ADR NNN — [Titre court de la décision]

> **Template** : Copier ce fichier dans `docs/adr/NNN-titre-court.md`.  
> Format de nommage : `NNN` = numéro à 3 chiffres (ex: `001`, `042`), titre en kebab-case.

---

**Date :** [AAAA-MM-JJ]  
**Statut :** [Proposée / Acceptée / Dépréciée / Remplacée par ADR-NNN]  
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

- **Avantages** : [...]
- **Inconvénients** : [...]

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
- [ex: Simplifie la gestion d'état dans les composants]
- [ex: Réduit le couplage entre les couches]

### Négatives / Compromis
- [ex: Nécessite une migration des composants existants]
- [ex: Courbe d'apprentissage pour l'équipe]

### Neutres
- [ex: Implique de mettre à jour la documentation `docs/ARCHITECTURE.md`]

---

## Mise en œuvre

> Décrire comment cette décision est appliquée concrètement dans le projet.

- **Fichiers impactés** : [ex: `src/services/`, `src/contexts/`]
- **Tâches de suivi** : [ex: DEVon — refactoriser `ClientHTTP.service.ts`]
- **Date d'effet** : [ex: À partir de la version v2.0]

---

## Références

- [Lien vers la documentation officielle, RFC, article, ou plan d'action associé]
- [Plan d'Action associé : `.github/plans/NNN_nom.plan.md`]
