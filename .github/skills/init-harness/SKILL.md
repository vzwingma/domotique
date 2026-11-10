---
name: init-harness
description: "Initialise le harnais multi-agents dans un projet (nouveau ou existant) : analyse du code, copilot-instructions.md depuis le template, conventions par rôle, docs/ARCHITECTURE.md. Usage : /init-harness [type de projet ou consignes]."
---

# Initialisation du harnais multi-agents

Consignes de l'utilisateur (optionnel) : $ARGUMENTS

> **Prérequis** (copiés depuis le dépôt transverse) : `.github/agents/` (5 agents), `.github/skills/`,
> `.github/PLANS.md`, `.github/copilot-instructions.template.md`,
> `docs/ARCHITECTURE.template.md`, `docs/adr/ADR-TEMPLATE.md`.
> Absents → lister les fichiers manquants et s'arrêter.

## 1. Détecter l'état du projet

- **Nouveau** : pas de `.github/copilot-instructions.md` → partir de `.github/copilot-instructions.template.md`.
- **Existant** : `.github/copilot-instructions.md` présent → **conserver** ses sections projet, ne remplacer que les
  sections génériques (agents, workflow, plans) par celles du template.
- **Ancien format** : fichiers `.github/instructions/*.instructions.md` présents → reprendre leurs valeurs
  dans les conventions par rôle (étape 4), puis signaler à 👤 que ces fichiers peuvent être retirés.
- **Plans dans `.github/plans/`** (ancien emplacement, chemin protégé : chaque écriture demande confirmation) →
  proposer `git mv .github/plans docs/plans` et mettre à jour les liens (ADR 004 du dépôt transverse).

## 2. Analyser le projet

Identifier, **depuis le code réel** (jamais d'hypothèse) :
- structure (dossiers principaux), langage(s), framework(s), type de projet, plateformes cibles ;
- gestion d'état, couches, patterns architecturaux ;
- conventions observées : nommage, imports, style, gestion d'erreurs, tests ;
- commandes : build, lint, tests (manifestes, Makefile, scripts CI).

Sources utiles : `README.md`, manifestes de dépendances, config lint/format, CI, `CONTRIBUTING.md`,
`docs/` existants.

## 3. Générer `.github/copilot-instructions.md`

1. Copier le template (ou fusionner, cas existant).
2. Remplacer chaque placeholder `[...]` par la valeur observée.
3. Supprimer les sections `[📌 SECTION À COMPLÉTER : …]` une fois remplies.
4. Conserver intactes les sections génériques (agents, workflow, plans d'action).

## 4. Remplir les conventions par rôle

Créer les fichiers d'instructions par rôle depuis les templates `.github/instructions/*.instructions.template.md` :
`orchestrator`, `architect`, `dev`, `qa`, `doc` → `.github/instructions/<rôle>.instructions.md` (sans `.template`),
puis remplir leurs placeholders avec les valeurs de l'étape 2.

La cible documentée est GitHub Copilot CLI uniquement ; VS Code et cloud agent sont hors périmètre. Les
skills CLI sont chargées selon pertinence, sans sélection déterministe par rôle. Les profils générés
portent donc une consigne explicite de chargement.

Valeur non déterminable depuis le code → conserver le placeholder et le signaler.


## 6. Documentation de base

- `docs/ARCHITECTURE.md` absent → le créer depuis `docs/ARCHITECTURE.template.md` et le remplir.
- `docs/adr/` absent → le créer avec `ADR-TEMPLATE.md`.
- `docs/plans/README.md` absent → créer l'index des plans (vide).

## 7. Livrer

Résumer : fichiers créés/modifiés, valeurs détectées (avec leur source), **placeholders restants**,
points à valider par 👤.

## ✅ Checklist

- [ ] `.github/copilot-instructions.md` créé ou fusionné, sections génériques intactes
- [ ] Conventions des 5 rôles remplies (placeholders restants listés)
- [ ] Commandes build/lint/test réelles renseignées
- [ ] `docs/ARCHITECTURE.md` et `docs/adr/` présents
- [ ] Aucune référence à un fichier inexistant
- [ ] Langue française pour le texte narratif

Après toute modification de la source `.github/`, régénérer la projection avec
`scripts/sync-claude-to-github.ps1`, puis contrôler avec `-Check` et `scripts/check-harness.ps1`.
