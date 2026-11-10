---
name: maina
description: "Active ⚫ MAINa (orchestrateur) sur le besoin de l'utilisateur. Déclenché par `/maina` ou `/maina : [prompt]`."
---

# Skill : Activation MAINa

1. Extraire `[prompt]` : texte après `:` (ou après le nom du skill). Vide → demander quel besoin traiter.
2. Invoquer l'agent **MAINa** avec ce prompt tel quel, sans reformulation.
3. Ne pas exécuter le travail soi-même — MAINa cadre, consulte ARCos, crée le Plan d'Action, délègue et impose les gates humains.
4. Relayer résultats et questions de MAINa à l'utilisateur.

Référence rôle complet : [`.github/agents/Maina.agent.md`](../../agents/Maina.agent.md)
