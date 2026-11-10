---
name: devon
description: "Active 🔵 DEVon (développeur) sur la demande de l'utilisateur. Déclenché par `/devon` ou `/devon : [prompt]`."
---

# Skill : Activation DEVon

1. Extraire `[prompt]` : texte après `:` (ou après le nom du skill). Vide → demander : « Quelle fonctionnalité ou quelle tâche du Plan d'Action implémenter ? »
2. Invoquer l'agent **DEVon** avec ce prompt tel quel, sans reformulation.
3. Ne pas faire le travail soi-même.
4. Relayer le résultat (code produit, vérifications, blocages) à l'utilisateur.

Référence rôle complet : [`.github/agents/Devon.agent.md`](../../agents/Devon.agent.md)
