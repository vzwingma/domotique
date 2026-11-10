---
name: qalvin
description: "Active 🟢 QALvin (QA / tests) sur la demande de l'utilisateur. Déclenché par `/qalvin` ou `/qalvin : [prompt]`."
---

# Skill : Activation QALvin

1. Extraire `[prompt]` : texte après `:` (ou après le nom du skill). Vide → demander : « Quel composant, service ou phase tester ? »
2. Invoquer l'agent **QALvin** avec ce prompt tel quel, sans reformulation.
3. Ne pas faire le travail soi-même.
4. Relayer les résultats (tests, couverture, échecs) à l'utilisateur.

Référence rôle complet : [`.github/agents/Qalvin.agent.md`](../../agents/Qalvin.agent.md)
