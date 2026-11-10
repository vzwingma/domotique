# 🏗️ Architecture — [NOM_DU_PROJET]

> **Template** : Ce fichier est un template à copier dans `docs/ARCHITECTURE.md` de votre projet.  
> Remplacer les placeholders `[...]` par les valeurs réelles. Compléter les sections progressivement au fur et à mesure du développement.  
> Les sections marquées **⚠️ À COMPLÉTER** sont prioritaires au démarrage.

---

## 🎯 Vue d'ensemble

**[NOM_DU_PROJET]** est [DESCRIPTION_COURTE : 1-2 phrases décrivant ce que fait le projet et pour qui].

| Propriété | Valeur |
|---|---|
| **Type** | [frontend / backend / fullstack / mobile / CLI / lib / API] |
| **Stack principale** | [ex: React 18 + TypeScript, Spring Boot 3, Python FastAPI, etc.] |
| **Plateforme cible** | [web / iOS / Android / desktop / serveur / etc.] |
| **Cible Copilot vérifiée** | [GitHub Copilot CLI uniquement si vérifiée ; sinon « non vérifiée »] |
| **Langue UI** | [Français / Anglais / etc.] |
| **Statut** | [En développement / Stable / Legacy / En maintenance] |

---

## 🏢 Architecture Globale ⚠️ À COMPLÉTER

> Décrire les grandes couches et leur rôle. Exemple ci-dessous pour un projet React + API.

```
[NOM_DU_PROJET]
├── [COUCHE_UI]           # [Description : ex. Composants React, pages, écrans]
├── [COUCHE_ETAT]         # [Description : ex. Contextes, stores, état global]
├── [COUCHE_SERVICE]      # [Description : ex. Appels HTTP, logique métier]
├── [COUCHE_MODELES]      # [Description : ex. Interfaces TypeScript, entités]
└── [COUCHE_UTILS]        # [Description : ex. Helpers, constantes, config]
```

### Flux de données principal

```
[ACTEUR_ENTRANT]
    → [COUCHE_1 : ex. Composant UI]
    → [COUCHE_2 : ex. Service HTTP]  
    → [SYSTEME_EXTERNE : ex. API Backend / BDD]
    ← [retour]
```

---

## 📂 Structure des Dossiers ⚠️ À COMPLÉTER

```
[RACINE_PROJET]/
├── [DOSSIER_PRINCIPAL]/              # [Description]
│   ├── [SOUS_DOSSIER_1]/             # [Description]
│   ├── [SOUS_DOSSIER_2]/             # [Description]
│   └── [SOUS_DOSSIER_3]/             # [Description]
├── docs/                             # Documentation versionnée
│   ├── ARCHITECTURE.md               # Ce fichier
│   └── adr/                          # Architecture Decision Records
├── [DOSSIER_TESTS]/                  # [Description]
└── [FICHIERS_CONFIG]                 # [ex: package.json, pyproject.toml, etc.]
```

---

## 🔧 Stack Technique

### Dépendances principales

| Catégorie | Librairie / Framework | Version | Rôle |
|---|---|---|---|
| [ex: Framework UI] | [ex: React] | [ex: 18.x] | [ex: Rendu composants] |
| [ex: Langage] | [ex: TypeScript] | [ex: 5.x] | [ex: Typage statique] |
| [ex: Tests] | [ex: Jest] | [ex: 29.x] | [ex: Tests unitaires] |
| [ex: Build] | [ex: Vite] | [ex: 5.x] | [ex: Bundler] |

> ⚠️ Maintenir ce tableau à jour à chaque montée de version majeure.

### Variables d'environnement

| Variable | Description | Exemple |
|---|---|---|
| `[NOM_VAR_1]` | [Description] | `[valeur_exemple]` |
| `[NOM_VAR_2]` | [Description] | `[valeur_exemple]` |

---

## 🔄 Intégrations Externes

> Lister les systèmes externes avec lesquels le projet communique.

| Système | Type | URL / Endpoint | Authentification |
|---|---|---|---|
| [ex: API Backend] | [REST / GraphQL / WebSocket] | `[URL_BASE]` | [ex: JWT Bearer] |
| [ex: BDD] | [PostgreSQL / MongoDB / etc.] | `[connexion]` | [ex: SSL + mdp] |

---

## 🔐 Sécurité

> ⚠️ À COMPLÉTER — Décrire les mécanismes de sécurité en place.

- **Authentification** : [ex: OAuth2 via [PROVIDER], tokens JWT avec refresh]
- **Autorisation** : [ex: RBAC avec rôles USER / ADMIN]
- **Données sensibles** : [ex: Jamais de token en localStorage, toujours httpOnly cookie]
- **Validation entrées** : [ex: Zod côté client, Bean Validation côté serveur]

---

## 🧪 Tests

| Type | Framework | Emplacement | Couverture cible |
|---|---|---|---|
| Unitaires | [ex: Jest + RTL] | `[ex: src/**/*.test.ts]` | ≥80% |
| [Intégration] | [ex: Supertest] | `[ex: tests/integration/]` | [ex: ≥60%] |
| [E2E] | [ex: Playwright] | `[ex: e2e/]` | [ex: Scénarios critiques] |

Commande pour lancer les tests : `[COMMANDE_TEST]`  
Rapport de couverture : `[CHEMIN_RAPPORT_COVERAGE]`

---

## 📐 Conventions et Patterns

> Résumé des conventions clés — pour le détail, voir `.claude/CLAUDE.md` et les conventions par rôle.
> Si GitHub Copilot CLI est vérifiée, la projection est générée vers `.github/` ; ne pas déduire de parité
> pour VS Code ou cloud agent sans preuves propres.

- **Nommage fichiers** : [ex: `*.component.tsx`, `*.service.ts`, `*.test.ts`]
- **Nommage variables** : [ex: camelCase pour variables, PascalCase pour composants]
- **Gestion d'état** : [ex: Context API uniquement, pas de Redux]
- **Appels HTTP** : [ex: Toujours via `ClientHTTP.service.ts`, jamais `fetch` directement]
- **Gestion erreurs** : [ex: Toujours catcher les erreurs HTTP, afficher un toast utilisateur]

---

## 🗺️ Décisions Architecturales (ADR)

> Les décisions architecturales majeures sont documentées dans `docs/adr/`.  
> Format : `docs/adr/NNN-titre-court.md`

| # | Décision | Statut | Date |
|---|---|---|---|
| [001] | [ex: Choix de React vs Vue] | [Acceptée / Dépréciée / Remplacée] | [AAAA-MM-JJ] |
| [002] | [ex: Authentification OAuth2] | [Acceptée] | [AAAA-MM-JJ] |

> 💡 Chaque nouvelle décision architecturale majeure doit faire l'objet d'un ADR. Voir `docs/adr/` pour les détails.

---

## 📈 Performance

> ⚠️ À COMPLÉTER si pertinent — Documenter les optimisations et contraintes de performance.

- [ex: Pagination obligatoire sur toutes les listes > 50 éléments]
- [ex: `useMemo` pour les calculs dérivés coûteux dans les composants]
- [ex: Images optimisées via [OUTIL], formats WebP en priorité]

---

## 🚀 Déploiement

| Environnement | URL | Déclencheur |
|---|---|---|
| Développement | `[URL_DEV]` | [ex: Push sur `develop`] |
| Staging | `[URL_STAGING]` | [ex: PR vers `main`] |
| Production | `[URL_PROD]` | [ex: Tag `v*`] |

Pipeline CI/CD : [ex: GitHub Actions — voir `.github/workflows/`]

---

## 📝 Historique des Versions

> Ajouter une entrée à chaque version livrée (en tête de liste).

| Version | Date | Changements majeurs |
|---|---|---|
| [ex: v1.0.0] | [AAAA-MM-JJ] | [ex: Version initiale] |

---

## 🔗 Ressources

- **README** : [`README.md`](../README.md)
- **Instructions des agents** : [`.claude/CLAUDE.md`](../.claude/CLAUDE.md) (Copilot CLI : `.github/copilot-instructions.md`)
- **Plans d'Action** : [`docs/plans/`](plans/)
- **ADRs** : [`docs/adr/`](./adr/)
- [**[LIEN_EXTERNE_1]**]([URL]) : [Description]
