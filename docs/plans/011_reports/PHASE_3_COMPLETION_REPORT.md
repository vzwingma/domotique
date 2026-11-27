# Plan 011 — Phase 3 : documentation (rapport)

**Date :** 2026-11-27 · **Statut :** ✅ Terminée — Phase 4 (livraison) à démarrer

## Livrables

| Tâche | Dépôt | Fichier | Contenu |
|---|---|---|---|
| T3.1 | `DomoticzLinky` (PR #5, fusionnée `37249a9`) | `readme.md` | Section « Source des données (v3.0.0) » : Conso API vs Legacy ; configuration pas à pas (consentement conso.boris.sh, PRM, jeton 3 ans, révocation) ; quota d'appels ; **migration depuis 2.x** ; paramètres `Address` / `Username` / `Password` ; libellés `Mode3` ; dépannage (jeton invalide, budget atteint, tentative différée) ; mention EN |
| T3.1 | `DomoticzLinky` | `docs/RETROCONCEPTION.md` | Nouveau § 17 « Source Conso API » (sélection, requêtes, adaptateur V2, budget, tests) ; renvois § 2.2, 3, 6, 7.1, 10 ; risques S10 (jeton) et S11 (blocage d'IP) ; D10 atténué, D13 clos ; glossaire |
| T3.1 | `DomoticzLinky` | `CHANGELOG.md` | Entrée 3.0.0 : ajouté, modifié, supprimé (bac à sable, faux clients), sécurité |
| T3.2 | `domotique` | `docs/ARCHITECTURE.md` § 5.4 | Sources Conso API / Legacy, adaptateur, quota, migration v2.x → v3.0.0, persistance |
| T3.2 | `domotique` | ADR 008 | Liens de mise en œuvre (P0-P3 faits), note de vocabulaire « Legacy » |

## Vérifications

- Ancres du readme contrôlées (aucun lien interne cassé hormis une ancre anglaise préexistante).
- Plus aucune occurrence de « Russandol » dans l'affichage du plugin (hors hôte technique du proxy et alias `russandol` de compatibilité) ; l'ADR 008 la conserve comme historique de décision.
- `docs/ARCHITECTURE.md` : pin Linky **toujours v2.7.0** (la montée vers v3.0.0 relève de la Phase 4, T4.1).

## Points ouverts pour la Phase 4

- Tag `v3.0.0` sur le commit de merge du fork (`37249a9`), puis pin `build-domoticz.yml` (SHA + `# v3.0.0`) ; mettre à jour la ligne « Source embarquée » de l'ARCHITECTURE § 5.4.
- Reconfiguration du matériel en production (👤) : source Conso API, PRM, jeton.
