# Rapport de complétion — Plan 010, Phase 0 (prérequis, ADR, incertitudes)

**Date :** 2026-11-25
**Statut :** ✅ Complétée
**Plan :** [`../010_linky_suites.plan.md`](../010_linky_suites.plan.md)

> Aucune sortie brute n'est recopiée (les réponses `getdevices` contiennent le PRM) : résultats booléens uniquement.

## Tâches

| Tâche | Agent | Résultat | Preuve |
|---|---|---|---|
| T0.1 | 👤 | ✅ | `gh pr view 232 --repo vzwingma/domotique` → `MERGED` ; `gh pr view 2 --repo vzwingma/DomoticzLinky` → `MERGED` ; `master` à jour (domotique `f59f011`, fork `b90ea14`) ; tag `v2.6.1` = `f3df2584ab398110eefe8d65df1b83d9a9d95395` |
| T0.2 | ⚫ MAINa | ✅ | Plan `🔄 En cours`, index `EN COURS`, branche `ci/linky_fork_pin` depuis `master` |
| T0.3 | 🟣 DOCly | ✅ | [`docs/adr/007-plugins-domoticz-provenance-epinglee.md`](../../adr/007-plugins-domoticz-provenance-epinglee.md) en `Proposée` |
| T0.4 | 👤 | ✅ | Voir ci-dessous |

## Incertitudes U1-U3 (Domoticz 2026.4, build 18630)

| Id | Hypothèse | Résultat | Conséquence |
|---|---|---|---|
| U1 | `Touch()` rafraîchit `LastUpdate` (~50 s) | ✅ Confirmé (2 appels à ~2 min d'intervalle : `LastUpdate` avancé de < 1 min, valeurs de compteur identiques) | `lastUpdate` mesure la vivacité du plugin ; seuil 36 h = plugin arrêté |
| U2 | `HaveTimeout` exposé, `false` en nominal | ✅ Confirmé | `timedOut` dzVents utilisable pour « pas de donnée Enedis > 1,5 j » |
| U3 | `onNotification` du module enregistre un canal de notification | ❌ Infirmé (aucun canal « Linky » dans Paramètres > Notifications) | Sans impact sur D1a (`onCommand` reste nécessaire) |

## Constat additionnel

- Le device de production s'appelle exactement **`Linky`** (le PRM n'apparaît que dans `ID` et `Description`) ; matériel `HardwareName` = `Linky`. Le préfixe `'Linky '` (avec espace) de l'annexe § 4.3 ne le trouverait pas → T2.1 ajusté : `DEVICE_LINKY_PREFIX = 'Linky'`. Aucun autre device « Linky… » (👤).
- `Mode2` = 7 (D11 → backlog) ; `Mode3` jamais activé en production (pas de rotation des jetons).

## Suite

Gate #1 — validation du plan ajusté et de l'ADR 007.
