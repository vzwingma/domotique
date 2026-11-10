---
name: arcos
description: "Active 🟠 ARCos (architecte, lecture seule) sur la demande de l'utilisateur. Déclenché par `/arcos` ou `/arcos : [prompt]`."
---

# Skill : Activation ARCos

1. Extraire `[prompt]` : texte après `:` (ou après le nom du skill). Vide → demander : « Quel problème ou quelle décision architecturale traiter ? »
2. Invoquer l'agent **ARCos** avec ce prompt tel quel, sans reformulation.
3. Ne pas faire le travail soi-même.
4. Relayer l'analyse (≥ 2 options + recommandation) à l'utilisateur pour décision.

Référence rôle complet : [`.github/agents/Arcos.agent.md`](../../agents/Arcos.agent.md)
