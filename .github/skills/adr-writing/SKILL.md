---
description: "Skill — Procédure de rédaction d'un Architecture Decision Record (ADR) après accord ARCos + humain. Appliqué automatiquement."
applyTo: "**"
---

# Skill : Rédaction d'un Architecture Decision Record (ADR)

> Ce skill décrit la **procédure standard** pour créer un ADR après qu'une décision architecturale a été prise conjointement par 🟠 ARCos et le 👤 Développeur humain.
> **Qui fait quoi :** ARCos prépare le contenu, 🟣 DOCly rédige toujours le fichier.
> Modèle à utiliser : `docs/adr/ADR-TEMPLATE.md`

---

## Quand créer un ADR

Un ADR **doit** être créé immédiatement après que le 👤 Développeur humain a validé la solution choisie (étape 3 de la méthodologie ARCos), pour les décisions qui :

- Introduisent une **nouvelle technologie ou bibliothèque** dans le projet
- Définissent un **nouveau pattern architectural** (couche, service, état global, routing…)
- Modifient une **convention existante** de façon structurelle
- Impliquent un **choix de sécurité** ou de conformité
- Résultent d'une **comparaison explicite de solutions** (l'analyse est déjà produite par ARCos)

> 💡 Si la décision est triviale ou locale (ex: renommer une variable, ajouter un champ), **ne pas créer d'ADR**.

---

## Nommage et emplacement

| Élément | Convention |
|---|---|
| **Dossier** | `docs/adr/` |
| **Nom de fichier** | `NNN-titre-court.md` (ex: `003-choix-librairie-ui.md`) |
| **Numéro** | Séquentiel à 3 chiffres, à partir du dernier ADR existant + 1 |
| **Titre** | Kebab-case, court, décrivant la décision (pas le problème) |

Pour trouver le prochain numéro : lister les fichiers dans `docs/adr/` et prendre le numéro suivant.

---

## Qui fait quoi

| Rôle | Responsabilité |
|---|---|
| 🟠 **ARCos** | Prépare le contenu de l'ADR : contexte, décision, alternatives (issues de l'analyse comparative), conséquences, mise en œuvre |
| 🟣 **DOCly** | Rédige le fichier ADR dans `docs/adr/` à partir du contenu fourni par ARCos |

**ARCos ne crée jamais le fichier ADR lui-même.** Il produit le contenu structuré et délègue à DOCly.

---

## Procédure ARCos — Préparer le contenu de l'ADR

Après la décision humaine, ARCos produit un bloc de délégation à DOCly structuré ainsi :

```markdown
## 📋 Contenu ADR à rédiger

**Fichier cible :** `docs/adr/NNN-titre-court.md`
**Date :** [AAAA-MM-JJ]
**Statut :** Acceptée

### Contexte
[Reprendre le problème posé au départ : situation actuelle, contraintes,
pourquoi une décision est nécessaire ici.]

### Décision
Nous avons décidé de [DÉCISION RETENUE, en une phrase directe].

### Alternatives Considérées
*(Reprendre directement l'analyse comparative présentée à l'humain)*

**Option 1 : [Nom — retenue ✅]**
- Avantages : [...]
- Inconvénients : [...]

**Option 2 : [Nom]**
- Avantages : [...]
- Inconvénients : [...]
- Raison du rejet : [...]

### Conséquences
- Positives : [...]
- Négatives / Compromis : [...]
- Neutres : [ex: mise à jour de docs/ARCHITECTURE.md requise]

### Mise en œuvre
- Fichiers impactés : [...]
- Tâches de suivi : [DEVon — ..., QUALvin — ...]
- Date d'effet : [ex: à partir de la Phase N du plan]

### Références
- Plan d'Action associé : `.github/plans/NNN_nom.plan.md` (si applicable)
```

---

## Procédure DOCly — Rédiger le fichier ADR

Quand ARCos délègue la rédaction d'un ADR :

1. **Lire le contenu fourni** par ARCos (bloc ci-dessus)
2. **Déterminer le numéro** : lister `docs/adr/` et prendre le numéro suivant
3. **Créer le fichier** `docs/adr/NNN-titre-court.md` à partir du template `docs/adr/ADR-TEMPLATE.md`
4. **Remplir chaque section** avec le contenu fourni par ARCos
5. **Ne pas interpréter** : recopier fidèlement les décisions et alternatives fournies

---

## Checklist qualité d'un bon ADR

- [ ] Le contexte explique **pourquoi** une décision était nécessaire
- [ ] La décision est énoncée en **une phrase directe** ("Nous avons décidé de…")
- [ ] Au moins **2 alternatives** sont documentées avec raison de rejet
- [ ] Les conséquences incluent des **points négatifs** (pas que positifs)
- [ ] La mise en œuvre liste les **fichiers et tâches de suivi** concrètes
- [ ] Le statut est `Acceptée` (jamais laissé vide ou `Proposée` sauf exception)
- [ ] Le numéro est séquentiel et le nom en kebab-case

---

## Exemple de prompt de délégation ARCos → DOCly

```
🟣 DOCly, merci de rédiger l'ADR suivant dans docs/adr/ :

[Coller ici le bloc "Contenu ADR à rédiger" produit par ARCos]

Modèle à utiliser : docs/adr/ADR-TEMPLATE.md
```

---

## Références

- 📄 Template ADR : `docs/adr/ADR-TEMPLATE.md`
- 📁 Dossier des ADR : `docs/adr/`
- 📋 Guide Plans d'Action : `.github/PLANS.md`
