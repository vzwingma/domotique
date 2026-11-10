---
name: docly
description: "Active 🟣 DOCly (documentation) sur la demande de l'utilisateur. Déclenché par `/docly` ou `/docly : [prompt]`."
---

# Skill : Activation DOCly

1. Extraire `[prompt]` : texte après `:` (ou après le nom du skill). Vide → demander : « Quels changements documenter ? »
2. Invoquer l'agent **DOCly** avec ce prompt tel quel, sans reformulation.
3. Ne pas faire le travail soi-même.
4. Relayer le résultat (fichiers modifiés) à l'utilisateur.

Référence rôle complet : [`.github/agents/Docly.agent.md`](../../agents/Docly.agent.md)
