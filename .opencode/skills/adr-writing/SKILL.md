---
name: "adr-writing"
description: "Skill — Procédure de rédaction d'un Architecture Decision Record (ADR) après accord ARCos + humain. Appliqué automatiquement."
---

# Skill : Rédaction d'un Architecture Decision Record (ADR)

> Skill décrit procédure standard créer ADR après décision archi validée 🟠 ARCos + 👤 Développeur humain.
> **Qui fait quoi :** ARCos prépare contenu, 🟣 DOCly écrit fichier.
> Template : `docs/adr/ADR-TEMPLATE.md`

---

## Quand créer un ADR

ADR **doit** être créé immédiatement après validation solution choisie par 👤 Développeur humain (étape 3 méthodologie ARCos), pour décisions qui :

- Introduisent **nouvelle techno ou lib** dans projet
- Définissent **nouveau pattern archi** (couche, service, état global, routing…)
- Modifient **convention existante** structurellement
- Impliquent **choix sécurité** ou conformité
- Résultent d'une **comparaison explicite de solutions** (analyse déjà produite par ARCos)

> 💡 Décision triviale ou locale (ex : renommer variable, ajouter champ) → **pas d'ADR**.

---

## Nommage et emplacement

| Élément | Convention |
|---|---|
| **Dossier** | `docs/adr/` |
| **Nom de fichier** | `NNN-titre-court.md` (ex: `003-choix-librairie-ui.md`) |
| **Numéro** | Séquentiel 3 chiffres, dernier ADR existant + 1 |
| **Titre** | Kebab-case, court, décrit décision (pas problème) |

Trouver prochain numéro : lister fichiers `docs/adr/`, prendre suivant.

---

## Qui fait quoi

| Rôle | Responsabilité |
|---|---|
| 🟠 **ARCos** | Prépare contenu ADR : contexte, décision, alternatives (depuis analyse comparative), conséquences, mise en œuvre |
| 🟣 **DOCly** | Rédige fichier ADR dans `docs/adr/` depuis contenu fourni par ARCos |

**ARCos ne crée jamais le fichier ADR lui-même.** Produit contenu structuré, délègue à DOCly.

---

## Procédure ARCos — Préparer le contenu de l'ADR

Après décision humaine, ARCos produit bloc de délégation à DOCly structuré ainsi :

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
- Tâches de suivi : [DEVon — ..., QALvin — ...]
- Date d'effet : [ex: à partir de la Phase N du plan]

### Références
- Plan d'Action associé : `.opencode/plans/NNN_nom.plan.md` (si applicable)
```

---

## Procédure DOCly — Rédiger le fichier ADR

Quand ARCos délègue rédaction ADR :

1. **Lire contenu fourni** par ARCos (bloc ci-dessus)
2. **Déterminer numéro** : lister `docs/adr/`, prendre suivant
3. **Créer fichier** `docs/adr/NNN-titre-court.md` depuis template `docs/adr/ADR-TEMPLATE.md`
4. **Remplir chaque section** avec contenu fourni par ARCos
5. **Ne pas interpréter** : recopier fidèlement décisions et alternatives fournies

---

## Checklist qualité d'un bon ADR

- [ ] Contexte explique **pourquoi** décision nécessaire
- [ ] Décision énoncée en **une phrase directe** ("Nous avons décidé de…")
- [ ] Au moins **2 alternatives** documentées avec raison rejet
- [ ] Conséquences incluent **points négatifs** (pas seulement positifs)
- [ ] Mise en œuvre liste **fichiers et tâches de suivi** concrètes
- [ ] Statut est `Acceptée` (jamais vide ou `Proposée` sauf exception)
- [ ] Numéro séquentiel et nom kebab-case

---

## Exemple de prompt de délégation ARCos → DOCly

```
🟣 DOCly, rédiges ADR suivant dans docs/adr/ :

[Coller ici bloc "Contenu ADR à rédiger" produit par ARCos]

Modèle utilisé : docs/adr/ADR-TEMPLATE.md
```

---

## Références

- 📄 Template ADR : `docs/adr/ADR-TEMPLATE.md`
- 📁 Dossier des ADR : `docs/adr/`
- 📋 Guide Plans d'Action : `.opencode/PLANS.md`