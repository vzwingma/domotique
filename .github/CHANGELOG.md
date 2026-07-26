# Agents — Historique des versions

> Ce fichier centralise l'historique des changements de tous les agents.
> Chaque agent référence ce fichier à la place du bloc inline `> **Changements...`.

---

## ⚫ MAINa

- **v1.0** : Création nouvel agent maitre-orchestrateur. Point d'entrée principal, support `/help` et `@MAINa /help`, orchestration stricte ARCos → DEVon → QALvin → DOCly avec validations humaines entre phases.
- **v1.1** : Renommage commande `/help` → `/maina-help`. Création Skill `maina-help` (applyTo: **) pour aide orchestration. Version MAINa passe à v1.1.

---

## 🟠 ARCos

- **v2.0 → v2.1** : Migration wiki → `/docs`. Ajout responsabilité ADR dans `docs/adr/`.
- **v2.1 → v2.2** : Ajout lecture obligatoire `docs/ARCHITECTURE.md` au démarrage.
- **v2.2 → v2.3** : Index plans simplifié (sans phases) + màj obligatoire `.github/plans/README.md` lors changement statut plan.
- **v2.3 → v2.4** : Ajout étape obligatoire présentation ≥2 solutions avec analyse avantages/inconvénients/risques/impacts + recommandation, avant décision humaine.
- **v2.4 → v2.5** : Extraction procédures Plans Action et /fleet en skills partagés (`.github/skills/`). Sections AP et /fleet réduites aux spécificités ARCos (orchestration, création plan).
- **v2.5 → v2.6** : Alignement sur nouvelle arborescence vrais skills (`.github/skills/<nom>/SKILL.md`).
- **v2.6 → v2.7** : Ajout skill `adr-writing` (`.github/skills/adr-writing/SKILL.md`). ARCos prépare contenu ADR, DOCly rédige fichier. Référence explicite skill après accord humain sur solution.
- **v2.7 → v2.8** : Ajout interdictions opérations destructives.
- **v2.8 → v2.9** : Ajout règle absolue respect `.copilotignore`.
- **v2.9 → v2.10** : Migration vers Sonnet 4.6 pour capacités planification/architecture améliorées.
- **v2.10 → v3.0** : Ajout instruction globale activation/usage du skill `caveman` et compression des consignes.
- **v3.0 → v3.1** : Suppression instruction globale caveman (déplacée vers skill `caveman-default`, `applyTo: "**"`). Évite chargements multiples par session.
- **v3.1 → v4.0** : Sync depuis OpenCode v4.0. Corps mis à jour. Frontmatter Copilot conservé (model, tools). Chemins `.github/` conservés.
- **v4.0 → v4.1** : Externalisation changelog dans ce fichier. Réduction taille agent ~2KB.
- **v4.1 → v4.2** : Descriptions frontmatter raccourcies. Relations inter-agents externalisées vers `.github/README.md`.
- **v4.2 → v4.3** : ARCos recentré sur architecture/planification. MAINa devient point d'entrée orchestration.

---

## 🔵 DEVon

- **v1.9 → v2.0** : Ajout instruction parallélisation avec /fleet.
- **v2.0 → v2.1** : Ajout règle synchro obligatoire `.github/plans/README.md` (index plans + statut global uniquement).
- **v2.1 → v2.2** : Extraction procédures Plans Action et /fleet en skills partagés (`.github/skills/`). Section AP réduite aux spécificités DEVon.
- **v2.2 → v2.3** : Alignement sur nouvelle arborescence vrais skills (`.github/skills/<nom>/SKILL.md`).
- **v2.3 → v2.4** : Ajout interdictions opérations destructives.
- **v2.4 → v2.5** : Ajout règle absolue respect `.copilotignore`.
- **v2.5 → v2.6** : Confirmation modèle Claude Sonnet 4.6 pour développement optimal.
- **v2.6 → v3.0** : Ajout instruction globale activation/usage du skill `caveman` et compression des consignes.
- **v3.0 → v3.1** : Suppression instruction globale caveman (déplacée vers skill `caveman-default`, `applyTo: "**"`). Évite chargements multiples par session.
- **v3.1 → v4.0** : Sync depuis OpenCode v4.0. Corps mis à jour. Frontmatter Copilot conservé (model, tools). Chemins `.github/` conservés.
- **v4.0 → v4.1** : Externalisation changelog dans ce fichier. Réduction taille agent ~2KB.
- **v4.1 → v4.2** : Description réduite. Delegation gardee concise ; workflow global deplace vers `.github/README.md`.

---

## 🟢 QALvin

- **v1.9 → v2.0** : Ajout instruction parallélisation avec /fleet.
- **v2.1 → v2.2** : Déplacement validations QA spécifiques projet vers `.github/instructions/qa.instructions.md`.
- **v2.2 → v2.3** : Ajout synchronisation obligatoire `.github/plans/README.md` lors changements statut plan.
- **v2.3 → v2.4** : Extraction procédures Plans d'Action et /fleet en skills partagés (`.github/skills/`). Section AP réduite aux spécificités QALvin.
- **v2.4 → v2.5** : Alignement sur nouvelle arborescence vrais skills (`.github/skills/<nom>/SKILL.md`).
- **v2.5 → v2.6** : Ajout interdictions opérations destructives.
- **v2.6 → v2.7** : Ajout règle absolue respect `.copilotignore`.
- **v2.7 → v2.8** : Migration vers Claude Haiku 4.5 pour exécution rapide efficace tests.
- **v2.8 → v3.0** : Ajout instruction globale activation/usage du skill `caveman` et compression des consignes.
- **v3.0 → v3.1** : Suppression instruction globale caveman (déplacée vers skill `caveman-default`, `applyTo: "**"`). Évite chargements multiples par session.
- **v3.1 → v4.0** : Sync depuis OpenCode v4.0. Corps mis à jour. Frontmatter Copilot conservé (model, tools). Chemins `.github/` conservés.
- **v4.0 → v4.1** : Externalisation changelog dans ce fichier. Réduction taille agent ~2KB.
- **v4.1 → v4.2** : Description réduite. Section relations retiree au profit de `.github/README.md`.

---

## 🟣 DOCly

- **v2.0 → v2.1** : Migration wiki → `/docs`. Ajout `docs/ARCHITECTURE.md` obligatoire + `docs/adr/`.
- **v2.1 → v2.2** : Ajout règle maintenance `.github/plans/README.md` (index plans + statut global seulement).
- **v2.2 → v2.3** : Extraction procédures Plans d'Action + /fleet en skills partagés (`.github/skills/`). Section AP réduite aux spécificités DOCly.
- **v2.3 → v2.4** : Alignement nouvelle arbo vrais skills (`.github/skills/<nom>/SKILL.md`).
- **v2.4 → v2.5** : Ajout interdictions opérations destructives.
- **v2.5 → v2.6** : Ajout règle absolue respect `.copilotignore`.
- **v2.6 → v2.7** : Migration vers Claude Sonnet 4.6 pour amélioration qualité doc.
- **v2.7 → v3.0** : Ajout instruction globale activation/usage du skill `caveman` et compression des consignes.
- **v3.0 → v3.1** : Suppression instruction globale caveman (déplacée vers skill `caveman-default`, `applyTo: "**"`). Évite chargements multiples par session.
- **v3.1 → v4.0** : Sync depuis OpenCode v4.0. Corps mis à jour. Frontmatter Copilot conservé (model, tools). Chemins `.github/` conservés.
- **v4.0 → v4.1** : Externalisation changelog dans ce fichier. Réduction taille agent ~2KB.
- **v4.1 → v4.2** : Description réduite. Vue transverse centralisee dans `.github/README.md`.
