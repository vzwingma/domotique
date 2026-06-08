---
name: "adr-writing"
description: "Skill — Procédure de rédaction d'un Architecture Decision Record (ADR) après accord ARCos + humain. Appliqué automatiquement."
---

# Skill : Rédaction d'un Architecture Decision Record (ADR)

> Skill describe standard procedure create ADR after architectural decision made by 🟠 ARCos + 👤 Developer human.
> **Who do what:** ARCos prepare content, 🟣 DOCly always write file.
> Template use: `docs/adr/ADR-TEMPLATE.md`

---

## Quand créer un ADR

ADR **must** be created immediately after 👤 Developer human validate chosen solution (step 3 ARCos methodology), for decisions that:

- Introduce **new tech or library** in project
- Define **new architectural pattern** (layer, service, global state, routing…)
- Modify **existing convention** structurally
- Involve **security choice** or compliance
- Result from **explicit solution comparison** (analysis already produced by ARCos)

> 💡 If decision trivial or local (ex: rename variable, add field), **no ADR**.

---

## Nommage et emplacement

| Élément | Convention |
|---|---|
| **Dossier** | `docs/adr/` |
| **Nom de fichier** | `NNN-titre-court.md` (ex: `003-choix-librairie-ui.md`) |
| **Numéro** | Sequential 3 digits, from last existing ADR + 1 |
| **Titre** | Kebab-case, short, describe decision (not problem) |

Find next number: list files in `docs/adr/` take next number.

---

## Qui fait quoi

| Rôle | Responsabilité |
|---|---|
| 🟠 **ARCos** | Prepare ADR content: context, decision, alternatives (from comparative analysis), consequences, implementation |
| 🟣 **DOCly** | Write ADR file in `docs/adr/` from content provided by ARCos |

**ARCos never create ADR file itself.** Produce structured content, delegate to DOCly.

---

## Procédure ARCos — Préparer le contenu de l'ADR

After human decision, ARCos produce delegation block to DOCly structured thus:

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

When ARCos delegate ADR writing:

1. **Read content provided** by ARCos (block above)
2. **Determine number**: list `docs/adr/` take next number
3. **Create file** `docs/adr/NNN-titre-court.md` from template `docs/adr/ADR-TEMPLATE.md`
4. **Fill each section** with content provided by ARCos
5. **No interpret**: copy faithfully decisions and alternatives provided

---

## Checklist qualité d'un bon ADR

- [ ] Context explain **why** decision needed
- [ ] Decision stated in **one direct sentence** ("Nous avons décidé de…")
- [ ] At least **2 alternatives** documented with rejection reason
- [ ] Consequences include **negative points** (not only positive)
- [ ] Implementation list **files and follow-up tasks** concrete
- [ ] Status is `Acceptée` (never empty or `Proposée` except exception)
- [ ] Number sequential and name kebab-case

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