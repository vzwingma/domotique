# 📚 GitHub OpenCode Agents & Templates — Dépôt Transverse

Ce sous-arbre `.opencode/` contient les **artefacts OpenCode réutilisables** du dépôt : agents, skills, prompts, templates d'instructions et plans d'action.

Il sert de point d'entree pour comprendre **qui fait quoi**, **comment les agents se coordonnent** et **quels fichiers copier ou maintenir** sans surcharger chaque `*.agent.md`.

---

## 📂 Structure

```
.opencode/
├── agents/                              # 5 agents OpenCode generiques
│   ├── Maina.agent.md                   # Maitre orchestrateur
│   ├── Arcos.agent.md                   # Planification / architecture
│   ├── Devon.agent.md                   # Implementation
│   ├── Qalvin.agent.md                  # Tests
│   └── Docly.agent.md                   # Documentation
├── instructions/                        # Templates d'instructions par role
├── prompts/                             # Prompts d'initialisation / mise a jour
├── skills/                              # Procedures partagees auto-chargees
├── plans/                               # Plans d'Action et rapports
├── CHANGELOG.md                         # Historique des versions des agents
├── PLANS.md                             # Guide des Plans d'Action
├── README.md                            # Ce fichier
├── copilot-instructions.md              # Instructions de ce depot transverse
└── copilot-instructions.template.md     # Template a copier dans les projets
```

---

## 🚀 Quick Start : reutiliser le sous-arbre `.opencode/`

### Etape 1 : Copier les artefacts utiles

Selon le projet cible, copier :

- `.opencode/agents/`
- `.opencode/skills/`
- `.opencode/instructions/`
- `.opencode/prompts/`
- `.opencode/PLANS.md`
- `.opencode/copilot-instructions.template.md`

### Etape 2 : Initialiser les instructions projet

Utiliser le prompt `init-copilot-instructions` pour generer les fichiers d'instructions adaptes au projet consommateur.

### Etape 3 : Utiliser les agents

Les agents peuvent ensuite etre invoques selon le besoin :

- `MAINa` pour orchestrer workflow complet
- `ARCos` pour concevoir et planifier
- `DEVon` pour implementer
- `QALvin` pour tester
- `DOCly` pour documenter

---

## 📖 Fichiers cles

### Agents (`.opencode/agents/`)

| Agent | Role | Quand l'utiliser |
|---|---|---|
| **Maina.agent.md** (⚫ MAINa) | Maitre orchestrateur | "`/maina-help`", "`@MAINa /maina-help`", "orchestrer workflow complet" |
| **Arcos.agent.md** (🟠 ARC) | Planificateur / architecte | "Conçois une architecture pour..." |
| **Devon.agent.md** (🔵 DEV) | Implementateur | "Implémente cette fonctionnalité" |
| **Qalvin.agent.md** (🟢 QUAL) | QA / tests | "Écris des tests pour..." |
| **Docly.agent.md** (🟣 DOC) | Documentation | "Mets à jour la documentation" |

Les agents restent focalises sur leurs instructions runtime. La vue transverse et la coordination sont documentees ici pour eviter la duplication.

### Instructions (`.opencode/instructions/`)

| Fichier | Role |
|---|---|
| `architect.instructions.md` | Conventions architecture / SQL handoff |
| `dev.instructions.md` | Stack technique, versions, conventions de code |
| `qa.instructions.md` | Framework de test, commandes CI, cas a couvrir |
| `doc.instructions.md` | Cibles documentaires et conventions de doc |

### Prompts (`.opencode/prompts/`)

| Prompt | Utilisation |
|---|---|
| `init-copilot-instructions.prompt.md` | Initialiser les instructions OpenCode dans un projet |
| `update-copilot-instructions.prompt.md` | Auditer et mettre a jour les instructions |
| `migrate-to-template.prompt.md` | Migrer un projet vers le format template transverse |

### Plans et gouvernance

| Fichier | Role |
|---|---|
| `PLANS.md` | Guide complet de creation / execution des Plans d'Action |
| `plans/README.md` | Index des plans et statut global |
| `CHANGELOG.md` | Historique de version des 5 agents |

---

## 🤝 Relations entre agents

Le workflow cible reste simple et strict :

1. 👤 **Developpeur humain** cadre le besoin et valide chaque livrable cle.
2. ⚫ **MAINa** orchestre sequence et delegations.
3. 🟠 **ARCos** conçoit la solution, compare les options et cree le plan.
4. ✅ **Validation humaine** du plan.
5. 🔵 **DEVon** implemente selon le plan valide.
6. ✅ **Validation humaine** du code.
7. 🟢 **QALvin** ecrit et execute les tests.
8. ✅ **Validation humaine** des tests.
9. 🟣 **DOCly** synchronise la documentation.
10. ✅ **Validation humaine** finale.

Relations de passage :

- `MAINa` → `ARCos` → `DEVon` → `QALvin` → `DOCly`
- `DEVon` → `QALvin`, puis `DOCly`
- `QALvin` → `DOCly`
- chaque etape importante revient vers le 👤 Developpeur humain pour validation

> Les agents n'ont plus besoin de porter chacun ce schema ; ils pointent vers ce README.

---

## 🎯 Workflow typique

```
1. Besoin cadre par le developpeur humain
   ↓
2. MAINa orchestre et mandate ARCos
   ↓
3. Validation humaine plan
   ↓
4. DEVon implemente
   ↓
5. Validation humaine code
   ↓
6. QALvin valide par les tests
   ↓
7. Validation humaine tests
   ↓
8. DOCly met a jour la documentation
   ↓
9. Validation humaine finale
   ↓
10. Phase suivante / cloture du plan
```

Pour les details de phases, de rapports et de dependances, voir `PLANS.md`.

---

## ✅ Checklist de maintenance

- Modifier un agent => incrementer sa version dans le frontmatter
- Reporter la modification dans `CHANGELOG.md`
- Synchroniser les versions dans `copilot-instructions.md` et `copilot-instructions.template.md`
- Mettre a jour `plans/README.md` a chaque nouveau Plan d'Action
- Garder ce README comme source de verite pour la coordination transverse `.opencode/`

---

## 📚 Ressources

- `README.md` racine : presentation generale du depot
- `docs/ARCHITECTURE.md` : architecture transverse globale
- `.opencode/PLANS.md` : format et execution des Plans d'Action
- `.opencode/copilot-instructions.md` : instructions detaillees du depot OpenCode
