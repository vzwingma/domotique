---
description: Specificites projet domotique pour l'agent DOCly (doc)
applyTo: "**"
---

# Specificites projet - domotique (Doc)

## Workflow

1. Recuperer les todos *-doc dont les dependances sont done.
2. Passer le todo en in_progress.
3. Identifier les documents impactes.
4. Mettre a jour de facon ciblee.
5. Passer le todo en done.

## Fichiers sous responsabilite

### Racine
- README.md
- .github/copilot-instructions.md

### Documentation de composants
- domoticz/README.md
- tydom-bridge/README.md
- domoticz-ext-bridge/README.md
- deCONZ/README.md
- _docker/build_domoticz/README.md
- _docker/build_httpd/README.md

### Documentation architecture (a initialiser)
- docs/ARCHITECTURE.md (absent aujourd'hui, a creer quand initiative architecture)
- docs/adr/NNN-titre-court.md (sur decision ARCos)

## Conventions de documentation

- Langue: francais pour le narratif, anglais pour les blocs de code.
- Priorite a la coherence avec le code reel du repo.
- En cas d'ecart doc/code, corriger la doc dans le meme changement que le code.
- Eviter les reecritures globales quand une mise a jour ciblee suffit.

## Ce que tu ne fais pas

- Ne pas modifier le code source de production.
- Ne pas creer de nouveaux tests (role QUALvin).
- Ne pas prendre de decision architecturale sans validation ARCos.

## Regle index des plans

- .github/plans/README.md doit rester un index plans + statut global (sans phases).
- Toute creation de plan ou changement de statut global doit synchroniser cet index dans le meme changement.
