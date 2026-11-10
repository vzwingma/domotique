---
description: "Conventions projet domotique pour ⚫ MAINa : sources de vérité, plans dans docs/plans, gates et délégations adaptées à dzVents, Tydom et Docker. Prioritaire sur le générique."
applyTo: "**"
---

# Conventions projet — domotique (orchestration)

> Domotique résidentielle basée sur Domoticz/dzVents, bridge Tydom, intégrations Freebox et déploiement Docker.

## Contexte à vérifier avant délégation

- `README.md`, `docs/ARCHITECTURE.md`, ADR existants (`docs/adr/`)
- `.github/copilot-instructions.md`, `.github/instructions/` et `docs/plans/README.md`
- Pour un changement dzVents : `docs/RETROCONCEPTION_dzVents.md`; pour roadmap/refactor : `.github/tasks/todo/PLAN_ACTIONS_dzVents.md`
- Pour toute décision dzVents : `domoticz/scripts/dzVents/global_data.lua`; `Config_check.lua` pour prérequis Domoticz

## Règles d'orchestration propres au projet

- Plan d'Action persistant dans `docs/plans/` pour toute initiative de code orchestrée, sauf dispense explicite du 👤.
- Toute création ou changement de statut global du plan met à jour `docs/plans/README.md` dans le même lot.
- ADR majeur dans `docs/adr/NNN-titre-court.md`, rédigé par DOCly à partir du contenu ARCos.
- Consulter 🟠 ARCos pour toute décision d'architecture ou changement structurel.
- Gates #0 → #4 obligatoires; décisions consignées dans le journal des gates du plan. Pas de transition sans GO explicite.
- Ne pas lancer DOCly avant validation des tests (Gate #3), sauf rédaction d'un ADR `Proposée` demandée entre Gate #0 et Gate #1.
- En dzVents, préserver `scenePhase` via l'événement `Scene Phase`, les IDs Tydom via `TYDOM_DEVICES`, et la traçabilité `uuid`.

## Contenu des délégations

### Vers 🟠 ARCos
Inclure besoin, contraintes Domoticz/dzVents/Node.js/Docker pertinentes, couches impactées, exigences non fonctionnelles, liens d'architecture, sources de vérité et ADR pertinents.
Attendu : au moins deux options, avantages/inconvénients/risques/impacts/effort, recommandation et besoin d'ADR.

### Vers 🔵 DEVon
Inclure phase validée, fichiers cibles, comportement attendu, contraintes métier, interdiction d'élargir le scope et vérifications réellement disponibles (ex. `npm test --prefix tydom-bridge` ou validation statique/runtime dzVents).
Attendu : code focalisé, fichiers modifiés, hypothèses et preuves de vérification.

### Vers 🟢 QALvin
Inclure changements DEVon, cas nominaux, nil/vides, erreurs HTTP et limites, flux cross-scripts, commandes ciblées et contrôles runtime disponibles.
Attendu : tests/contrôles réalisés, résultats, couverture si mesurable, régressions et limites d'environnement.

### Vers 🟣 DOCly
Inclure changements validés après Gate #3, décisions ADR, fichiers documentaires concernés (`README.md`, `docs/ARCHITECTURE.md`, `docs/scenarios.puml`, README composants) et plans/ADR concernés.
Attendu : documentation synchronisée sans réécriture inutile, liens cohérents et ADR si décision majeure.

## Ce que MAINa ne fait pas

- Coder, tester ou documenter à la place des agents (sauf tâche triviale explicitement demandée).
- Décider une architecture majeure sans ARCos ni validation 👤.
- Clôturer une initiative sans validation 👤 des livrables.
- Inventer des conventions absentes du code ou de la documentation.
