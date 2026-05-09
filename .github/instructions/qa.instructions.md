---
description: Specificites projet domotique pour l'agent QUALvin (qa)
applyTo: "**"
---

# Specificites projet - domotique (QA)

## Workflow

1. Recuperer les todos *-qa dont les dependances sont done.
2. Passer le todo en in_progress.
3. Executer la validation fonctionnelle dzVents (nominal + erreurs + non-regression).
4. Passer le todo en done si valide, sinon blocked avec diagnostic precis.

## Strategie QA reelle (dzVents)

Le depot ne fournit pas une suite unitaire Lua standardisee pour dzVents. La QA s'appuie donc sur:
- verification de coherence statique du script (triggers, effets de bord, guards)
- validation runtime via logs Domoticz
- verification des flux cross-scripts (events/customEvents/httpResponses)
- non-regression des regles DEV-1, DEV-2, DEV-4, DEV-5

## Cas a couvrir systematiquement

- Cas nominal: le script fait l'action attendue et ecrit des logs coherents.
- Cas vide/nil: aucune concatenation dangereuse, pas de crash.
- Cas erreur integration:
  - timeout/connexion
  - erreurs HTTP 4xx et 5xx
  - retries bornes quand prevu
- Cas coherence metier:
  - scenePhase coherente (incluant Inconnue au boot)
  - realignement groupes correct dans les deux sens
  - etat Domoticz aligne avec etat Tydom reel

## Points de controle obligatoires

- Triggers declaratifs corrects: timer/devices/customEvents/httpResponses/system.
- Conservation de la tracabilite uuid.
- Respect des helpers centralises (global_data.lua).
- Aucune reference hard-codee a un ID Tydom.
- Si polling change: mettre a jour et verifier Health_check_dzVents.lua.

## Exemples de commandes utiles (selon environnement)

```bash
# depuis _docker/
docker compose -f domotique-compose.yml up -d

docker compose -f domotique-compose.yml logs -f domoticz

docker compose -f domotique-compose.yml logs -f tydom-bridge
```

## Ce que tu ne fais pas

- Ne pas modifier les scripts de production hors corrections QA explicitement demandees.
- Ne pas mettre a jour la documentation (role DOCly).
- Ne pas prendre de decision architecturale sans validation ARCos.

## Regle index des plans

- .github/plans/README.md est un index plans + statut global uniquement.
- Si la livraison QA entraine un changement de statut global de plan, synchroniser cet index dans le meme changement.
