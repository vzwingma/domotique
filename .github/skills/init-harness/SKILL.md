---
name: init-harness
description: "Initialise le harnais multi-agents dans un projet (nouveau ou existant) : analyse du code, consignes projet par rôle et docs/ARCHITECTURE.md. Usage : /init-harness [type de projet ou consignes]."
---

# Initialisation du harnais multi-agents

Consignes de l'utilisateur (optionnel) : $ARGUMENTS

> **Prérequis** : `.github/agents/` (5 profils), `.github/skills/`, `.github/PLANS.md`,
> `docs/ARCHITECTURE.template.md` et `docs/adr/ADR-TEMPLATE.md`.
> Absents → lister les fichiers manquants et s'arrêter.

## 1. Détecter l'état du projet

- **Nouveau** : pas de `.github/copilot-instructions.md` → générer les consignes depuis le code réel et les profils d'agents.
- **Existant** : `.github/copilot-instructions.md` présent → **conserver** ses sections projet, ne remplacer que les
  sections génériques (agents, workflow, plans) si elles ne correspondent plus aux profils et aux procédures.
- **Ancien format** : fichiers `.github/instructions/*.instructions.md` présents → reprendre leurs valeurs
  dans les conventions par rôle (étape 4), puis signaler à 👤 que ces fichiers peuvent être retirés.
- **Plans dans `.github/plans/`** (ancien emplacement) → proposer leur migration vers `docs/plans/` et
  mettre à jour les liens. Dans ce dépôt, `docs/plans/` est déjà l'emplacement de référence.

## 2. Analyser le projet

Identifier, **depuis le code réel** (jamais d'hypothèse) :
- structure (dossiers principaux), langage(s), framework(s), type de projet, plateformes cibles ;
- gestion d'état, couches, patterns architecturaux ;
- conventions observées : nommage, imports, style, gestion d'erreurs, tests ;
- commandes : build, lint, tests (manifestes, Makefile, scripts CI).

Sources utiles : `README.md`, manifestes de dépendances, config lint/format, CI, `CONTRIBUTING.md`,
`docs/` existants.

## 3. Générer ou mettre à jour `.github/copilot-instructions.md`

1. Décrire le projet, ses sources de vérité et ses commandes réellement disponibles.
2. Conserver les règles métier valides si le fichier existe déjà.
3. Aligner les références agents, workflow et plans sur les fichiers présents.

## 4. Remplir les conventions par rôle

Créer ou mettre à jour un fichier d'instructions par rôle à partir des profils d'agents et du code :
`orchestrator`, `architect`, `dev`, `qa`, `doc` → `.github/instructions/<rôle>.instructions.md`.

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

- [ ] `.github/copilot-instructions.md` créé ou fusionné, contexte projet vérifié
- [ ] Consignes des 5 rôles créées ou mises à jour depuis les profils et le code
- [ ] Commandes build/lint/test réelles renseignées
- [ ] `docs/ARCHITECTURE.md` et `docs/adr/` présents
- [ ] Aucune référence à un fichier inexistant
- [ ] Langue française pour le texte narratif

Après toute modification de la source `.github/`, régénérer la projection avec
`scripts/sync-claude-to-github.ps1`, puis contrôler avec `-Check` et `scripts/check-harness.ps1`.
