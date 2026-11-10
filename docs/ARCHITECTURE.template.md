# Architecture — [NOM_DU_PROJET]

> Modèle à copier vers `docs/ARCHITECTURE.md`, puis à compléter depuis le code et la configuration réels.
> Supprimer ou adapter les sections non pertinentes; ne pas conserver d'exemples comme faits du projet.

---

## Vue d'ensemble

**[NOM_DU_PROJET]** est [description du système, de ses utilisateurs et de sa finalité].

| Propriété | Valeur |
|---|---|
| Type | [service / application / bibliothèque / infrastructure / autre] |
| Stack | [langages, frameworks et versions vérifiées] |
| Plateformes | [cibles vérifiées] |
| Statut | [développement / production / maintenance] |

## Architecture

Décrire les composants, leurs responsabilités et leurs dépendances. Remplacer le schéma par les éléments réels.

```text
[ACTEUR OU SYSTÈME SOURCE]
        ↓
[COMPOSANT / COUCHE 1]
        ↓
[COMPOSANT / COUCHE 2]
        ↓
[DÉPENDANCE OU SYSTÈME EXTERNE]
```

### Flux principaux

- **[Flux]** : [déclencheur, étapes, résultat et gestion des erreurs].
- **[Flux]** : [événements ou échanges entre composants].

### État et données

- Source de vérité : [stockage ou composant responsable].
- Cycle de vie : [création, mise à jour, restauration ou expiration].
- Contraintes de cohérence : [invariants à préserver].

## Structure du dépôt

```text
[RACINE]/
├── [DOSSIER_SOURCE]/       # [responsabilité]
├── [DOSSIER_TESTS]/        # [tests et outils]
├── docs/                   # documentation versionnée
│   ├── adr/                # décisions d'architecture
│   └── plans/              # plans d'action, rapports et index
└── [FICHIERS_CONFIG]/      # [configuration et outillage]
```

## Intégrations et contrats

| Composant | Sens du flux | Contrat / configuration | Risques ou contraintes |
|---|---|---|---|
| [Système externe] | [entrant / sortant / bidirectionnel] | [API, fichier ou source de vérité] | [authentification, disponibilité, cohérence] |

## Sécurité et exploitation

- Authentification et autorisation : [mécanismes vérifiés].
- Secrets et données sensibles : [stockage et règles de traitement].
- Réseau et déploiement : [composants, environnements et frontières].
- Journaux et corrélation : [format et identifiants de suivi].

## Tests et validation

| Composant | Commande ou vérification | Limites |
|---|---|---|
| [Composant] | `[COMMANDE]` | [ce que la vérification ne couvre pas] |

Ne déclarer une couverture, une validation runtime ou un succès de déploiement que si une preuve correspondante existe.

## Décisions d'architecture

Les décisions majeures sont consignées dans [`docs/adr/`](./adr/); les plans d'action et leur statut global sont indexés dans [`docs/plans/README.md`](./plans/README.md).

| ADR | Décision | Statut | Date |
|---|---|---|---|
| [NNN] | [Décision] | [Proposée / Acceptée / Rejetée / Remplacée] | [AAAA-MM-JJ] |
