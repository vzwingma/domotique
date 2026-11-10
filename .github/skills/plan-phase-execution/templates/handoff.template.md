# Bloc handoff — fin de réponse de chaque agent exécutant

Chaque agent (🟠 ARCos, 🔵 DEVon, 🟢 QALvin, 🟣 DOCly) termine sa réponse par ce bloc, rempli.
⚫ MAINa s'en sert pour contrôler les preuves et conduire le gate (skill `gate-protocol`).

```yaml
handoff:
  plan: docs/plans/<NO>_<slug>.plan.md
  phase: <N>
  agent: <ARCos | DEVon | QALvin | DOCly>
  tasks: [T<N>.1, T<N>.2]
  status: done            # done | partial | blocked
  report: docs/plans/<NO>_reports/PHASE_<N>_COMPLETION_REPORT.md
  files:                  # créés / modifiés
    - path: domoticz/scripts/dzVents/Device_Example.lua
      change: "description brève du changement"
  criteria:               # critères d'acceptation des tâches
    - id: T<N>.1
      met: true
      evidence: "commande et résultat réels; pour dzVents, préciser si preuve statique ou runtime"
  evidence:               # commandes lancées et résultats
    - command: "npm test --prefix tydom-bridge"
      result: "résultat réel, ou indiquer non exécuté/non applicable"
  risks:                  # écarts au plan, dettes, hypothèses
    - "hypothèse : l'API renvoie 404 (non 204) si vide — à confirmer"
  questions: []           # ❓ Questions pour 👤 (posées par MAINa au gate)
  next: "Gate #2 puis 🟢 QALvin — T<N+1>.1 à T<N+1>.3"
```

Règles :
- `status: blocked` → `risks` explique le blocage et `questions` dit ce qu'il faut décider.
- Pas de preuve → critère `met: false`, jamais `true` « par défaut ».
- Agent en lecture seule (ARCos) : `files` vide, `report` = contenu rendu à MAINa.
- Utiliser `docs/plans/`; ne pas prétendre qu'une suite Lua ou une mesure de couverture existe si elle n'a pas été exécutée.
