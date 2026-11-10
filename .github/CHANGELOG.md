# Agents — Historique des versions

> Ce fichier centralise l'historique des changements de tous les agents.
> Chaque agent référence ce fichier à la place du bloc inline `> **Changements...`.

---

## AP 006 — 2026-10-15

- Documentation alignée sur la projection vérifiée vers GitHub Copilot CLI uniquement.
- Limites observées, mapping des outils/modèles, chargement des skills, contrôles, packages et scénarios
  documentés ; aucune version d'agent modifiée.

---

## ⚫ MAINa

- **v1.0** : Création nouvel agent maitre-orchestrateur. Point d'entrée principal, support `/help` et `@MAINa /help`, orchestration stricte ARCos → DEVon → QALvin → DOCly avec validations humaines entre phases.
- **v1.1** : Renommage commande `/help` → `/maina-help`. Création Skill `maina-help` (applyTo: **) pour aide orchestration. Version MAINa passe à v1.1.
- **v1.2** : MAINa prend responsabilité création Plan d'Action (skill plan-creation). Peut consulter ARCos (et autres agents) pour analyse solutions + recommandation avant rédiger le plan. ARCos redevient expert consulté — ne crée plus le plan. Workflow mis à jour : consultation ARCos → MAINa produit plan en mode PLAN → validation humaine obligatoire → implémentation.
- **v1.2 → v1.3** : Bloc sécurité allégé — opérations destructives + `.copilotignore` externalisés vers skills `safety-rules` et `copilotignore` (`applyTo: **`). Règle MAINa-spécifique (pas de clôture sans validations 👤) conservée.
- **v1.3 → v1.4** : Ajout lecture `.github/instructions/orchestrator.instructions.md` au démarrage pour appliquer les spécificités projet MAINa.
- **v1.4 → v1.5** (AP 005 P2-P8) : Frontmatter natif (`model: opus`, `tools` explicites dont `AskUserQuestion`/`Agent`/`SendMessage`, `skills: [plan-creation]`, `color`) ; retrait `applyTo`/`agents`. Conçu pour tourner en **agent principal** de session : un sous-agent n'a pas `AskUserQuestion` → gates impossibles. Gates numérotés #0→#4 et consignés dans le « Journal des gates » ; questions des sous-agents relayées via section `❓ Questions pour 👤` ; plus de parallélisation entre phases séparées par un gate. Version sortie de la description. P3 : préchargement skill `conventions-orchestrator` (remplace la lecture de `.github/instructions/orchestrator.instructions.md`). P5 : skill `gate-protocol` préchargé (preuves par gate, revue `/code-review` + `/security-review` avant Gate #2, GO/AJUSTER/STOP, journal) ; délégations exigeant le bloc `handoff` ; ADR `Proposée` avant Gate #1, `Acceptée` au GO. P8 : Plans d'Action dans `docs/plans/` (ADR 004).

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
- **v4.3 → v4.4** : Retrait responsabilité création Plan d'Action. MAINa crée le plan après consultation ARCos. ARCos = expert archi consulté, exécute tâches T*.* assignées. Section "Créer et Exécuter un Plan d'Action" remplacée par "Exécuter les tâches assignées".
- **v4.4 → v4.5** : Suppression contradictions résiduelles du modèle pré-MAINa (création WBS, orchestration inter-agents, « format sortie = plan »). ARCos recentré sur analyse & conception : propose un découpage candidat en entrée, MAINa crée et orchestre le Plan d'Action.
- **v4.5 → v4.6** : Suppression des blocs inline « opérations destructives » + « `.copilotignore` » (désormais couverts par skills `safety-rules` + `copilotignore`, `applyTo: **`). Remplacés par un rappel d'une ligne.
- **v4.6 → v4.7** : Élagage (214 → ~110 lignes) — fusion des 5 restatements du workflow (Coordination/Séquencement/Points contrôle/Cas limites), suppression des sections « Découpage travail » + « Tâches DEVon/QALvin/DOCly » du format de sortie (résidu du modèle créateur-de-plan). Corps aligné sur le frontmatter : ARCos = analyse + conception + découpage candidat en entrée à MAINa. Workflow global renvoyé à `.github/README.md` (source unique).
- **v4.7 → v4.8** (AP 005 P2-P8) : Frontmatter natif (`model: opus`, `effort: high`, outils **lecture seule** `Read, Grep, Glob, WebFetch, WebSearch, Skill`, `skills: [adr-writing, plan-phase-execution]`) ; retrait `applyTo`/`agents`. Pas de `memory` (activerait Write/Edit). Pas d'échange direct avec 👤 : questions + point de décision rendus à MAINa (Gate #0). Rapport de phase rendu à MAINa qui l'écrit. P3 : préchargement skill `conventions-architect` (remplace la lecture de `.github/instructions/architect.instructions.md`), section parallélisation → skill `parallel-guide`. P5 : bloc `handoff` en fin de réponse. P8 : Plans d'Action dans `docs/plans/` (ADR 004).

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
- **v4.2 → v4.3** : Suppression des blocs inline « opérations destructives » + « `.copilotignore` » (couverts par skills `safety-rules` + `copilotignore`, `applyTo: **`).
- **v4.3 → v4.4** (AP 005 P2-P5) : Frontmatter natif (`model: sonnet`, `tools: Read, Edit, Write, Bash, Grep, Glob, TodoWrite, Skill`, `skills: [plan-phase-execution]`) ; retrait `applyTo`/`agents`. Tâches reçues du Plan d'Action (MAINa) ; preuve exigée (build + lint + tests existants) ; relais DOCly après Gate #3 uniquement ; questions via `❓ Questions pour 👤`. P3 : préchargement skill `conventions-dev` (remplace la lecture de `.github/instructions/dev.instructions.md`), section parallélisation → skill `parallel-guide`. P5 : relais via bloc `handoff` (preuves build/lint/tests).

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
- **v4.2 → v4.3** : Suppression des blocs inline « opérations destructives » + « `.copilotignore` » (couverts par skills `safety-rules` + `copilotignore`, `applyTo: **`).
- **v4.3 → v4.4** : Agent rendu stack-neutre — React/Jest retirés du corps générique au profit de principes de test framework-agnostiques. Concret React/Testing Library conservé en exemples/placeholders dans `qa.instructions.template.md`.
- **v4.4 → v4.5** (AP 005 P2-P5) : Frontmatter natif (`model: sonnet`, `tools: Read, Edit, Write, Bash, Grep, Glob, TodoWrite, Skill`, `skills: [plan-phase-execution]`) ; retrait `applyTo`/`agents`. Intervient après Gate #2, relais DOCly après Gate #3 ; questions via `❓ Questions pour 👤` ; séparateur parasite retiré. P3 : préchargement skill `conventions-qa` (remplace la lecture de `.github/instructions/qa.instructions.md`), section parallélisation → skill `parallel-guide`. P5 : preuves obligatoires (résultats, couverture vs seuil, détection de régression) + bloc `handoff`.

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
- **v4.2 → v4.3** : Suppression des blocs inline « opérations destructives » + « `.copilotignore` » (couverts par skills `safety-rules` + `copilotignore`, `applyTo: **`).
- **v4.3 → v4.4** (AP 005 P2-P5) : Frontmatter natif (`model: sonnet`, `tools: Read, Edit, Write, Grep, Glob, Skill`, `skills: [plan-phase-execution, adr-writing]`) ; retrait `applyTo`/`agents`. Intervient après Gate #3 ; questions via `❓ Questions pour 👤`. P3 : préchargement skill `conventions-doc` (remplace la lecture de `.github/instructions/doc.instructions.md`), section parallélisation → skill `parallel-guide`. P5 : bloc `handoff` ; exception : rédaction ADR `Proposée` entre Gate #0 et Gate #1.
