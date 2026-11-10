# 📚 GitHub Copilot Agents & Templates — Dépôt Transverse

Ce sous-arbre `.github/` contient les **artefacts Copilot réutilisables** du dépôt : agents, skills (procédures, conventions projet, commandes), hooks et settings. Les Plans d'Action vivent dans `docs/plans/` (hors du chemin protégé `.github/`, ADR 004).

Il sert de point d'entree pour comprendre **qui fait quoi**, **comment les agents se coordonnent** et **quels fichiers copier ou maintenir** sans surcharger chaque `*.agent.md`.

## 🎯 Cible Copilot vérifiée

La projection vérifiée de ce dépôt cible **GitHub Copilot CLI uniquement**. Versions observées pendant AP 006 :
`1.0.99-0`, puis `1.0.99-1`. VS Code et cloud agent sont hors périmètre ; aucune parité ni support n'est
annoncé pour ces surfaces.

`.github/` reste la source unique. La projection Copilot est générée par
`scripts/sync-claude-to-github.ps1` (`-Check` vérifie l'absence de dérive, génération idempotente). Le mapping
`scripts/copilot-mapping.psd1` dérive les outils du frontmatter Copilot : `Read` → `read`, `Grep`/`Glob` →
`search`, `WebFetch`/`WebSearch` → `web`, `Edit`/`Write` → `edit`, `Bash` → `execute`, `TodoWrite` → `todo`,
`Agent` → `agent`. `AskUserQuestion`, `SendMessage` et `Skill` sont signalés puis non projetés.

ARCos est projeté en lecture seule (`[read, search, web]`). Les alias source donnent `opus` →
`claude-opus-5.5` et `sonnet` → `claude-sonnet-5.5`. Un modèle inconnu provoque un avertissement, un repli
sur le modèle par défaut et un code de sortie nul : risque de faux succès à contrôler.

La CLI peut lire `.github/skills/` et `.github/skills/` ; `.github/` l'emporte en cas de nom identique. Le
chargement se fait selon la pertinence, non de façon déterministe ; chaque profil généré demande explicitement
le chargement de ses skills. Les conventions sont projetées vers
`.github/instructions/<role>.instructions.template.md`.

---

## 📂 Structure

```
.github/
├── agents/                              # 5 agents Copilot generiques
│   ├── Maina.agent.md                   # Maitre orchestrateur
│   ├── Arcos.agent.md                   # Architecture (consulté par MAINa)
│   ├── Devon.agent.md                   # Implementation
│   ├── Qalvin.agent.md                  # Tests
│   └── Docly.agent.md                   # Documentation
├── skills/                              # 18 skills : procédures, conventions, commandes
├── CHANGELOG.md                         # Historique des versions des agents
├── PLANS.md                             # Guide des Plans d'Action
├── README.md                            # Ce fichier
├── copilot-instructions.md              # Instructions de ce depot transverse
└── copilot-instructions.template.md     # Template a copier dans les projets
```


---

## 🚀 Quick Start : reutiliser le sous-arbre `.github/`

### Etape 1 : Copier les artefacts utiles

Selon le projet cible, copier :

- `.github/agents/`
- `.github/skills/`
- `.github/PLANS.md`
- `.github/copilot-instructions.template.md`

### Etape 2 : Initialiser les instructions projet

Lancer `/init-harness` : analyse du code, génération de `copilot-instructions.md`, remplissage des conventions par rôle (`conventions-<rôle>`).

### Etape 3 : Utiliser les agents

Les agents peuvent ensuite etre invoques selon le besoin :

- `MAINa` pour orchestrer workflow complet
- `ARCos` pour analyser les options et concevoir (lecture seule)
- `DEVon` pour implementer
- `QALvin` pour tester
- `DOCly` pour documenter

---

## 📖 Fichiers cles

### Agents (`.github/agents/`)

| Agent | Role | Quand l'utiliser |
|---|---|---|
| **Maina.agent.md** (⚫ MAINa) | Maitre orchestrateur + créateur Plan d'Action | "`/maina-help`", "`@MAINa /maina-help`", "orchestrer workflow complet" |
| **Arcos.agent.md** (🟠 ARC) | Expert architecture consulté par MAINa | "Analyse les options pour...", "Conçois architecture pour..." |
| **Devon.agent.md** (🔵 DEV) | Implementateur | "Implémente cette fonctionnalité" |
| **Qalvin.agent.md** (🟢 QUAL) | QA / tests | "Écris des tests pour..." |
| **Docly.agent.md** (🟣 DOC) | Documentation | "Mets à jour la documentation" |

Les agents restent focalises sur leurs instructions runtime. La vue transverse et la coordination sont documentees ici pour eviter la duplication.

### Instructions projet (`.github/instructions/`)

Un fichier par rôle (`orchestrator`, `architect`, `dev`, `qa`, `doc`) : `<rôle>.instructions.md`, créé depuis `<rôle>.instructions.template.md` via `/init-harness`.

### Commandes (`.github/skills/`)

| Commande | Utilisation |
|---|---|
| `/init-harness` | Initialiser le harnais dans un projet (nouveau ou existant) |
| `/update-harness` | Auditer et mettre à jour copilot-instructions.md + conventions depuis le code |
| `/maina-help` | Aide workflow MAINa |
| `/maina`, `/arcos`, `/devon`, `/qalvin`, `/docly` | Activer un agent sur une demande |

### Plans et gouvernance

| Fichier | Role |
|---|---|
| `PLANS.md` | Guide complet de creation / execution des Plans d'Action |
| `docs/plans/README.md` | Index des plans et statut global |
| `CHANGELOG.md` | Historique de version des 5 agents |

---

## 🤝 Relations entre agents

Le workflow cible reste simple et strict :

1. 👤 **Developpeur humain** cadre le besoin et valide chaque livrable cle.
2. ⚫ **MAINa** orchestre sequence, delegations et cree le Plan d'Action.
3. 🟠 **ARCos** analyse les options, compare les solutions et fournit recommandation à MAINa.
4. ✅ **Validation humaine** du choix de solution.
5. ⚫ **MAINa** cree le Plan d'Action et le soumet.
6. ✅ **Validation humaine** du plan.
7. 🔵 **DEVon** implemente selon le plan valide.
8. ✅ **Validation humaine** du code.
9. 🟢 **QALvin** ecrit et execute les tests.
10. ✅ **Validation humaine** des tests.
11. 🟣 **DOCly** synchronise la documentation.
12. ✅ **Validation humaine** finale.

Relations de passage :

- `MAINa` sollicite `ARCos` (analyse solutions) → `MAINa` crée plan → `DEVon` → `QALvin` → `DOCly`
- `DEVon` → `QALvin`, puis `DOCly`
- `QALvin` → `DOCly`
- chaque etape importante revient vers le 👤 Developpeur humain pour validation

> Les agents n'ont plus besoin de porter chacun ce schema ; ils pointent vers ce README.

---

## 🎯 Workflow typique

```
1. Besoin cadre par le developpeur humain
   ↓
2. MAINa orchestre et consulte ARCos (analyse solutions)
   ↓
3. Validation humaine (choix solution)
   ↓
4. MAINa cree Plan d'Action
   ↓
5. Validation humaine plan
   ↓
6. DEVon implemente
   ↓
7. Validation humaine code
   ↓
8. QALvin valide par les tests
   ↓
9. Validation humaine tests
   ↓
10. DOCly met a jour la documentation
    ↓
11. Validation humaine finale
    ↓
12. Phase suivante / cloture du plan
```

Pour les details de phases, de rapports et de dependances, voir `PLANS.md`.

---

## ✅ Checklist de maintenance

- Modifier un agent → incrémenter sa ligne `> **Version**` (corps de l'agent) + entrée `CHANGELOG.md`
- Version reportée uniquement dans `docs/ARCHITECTURE.md` (table des agents) — vérifiée par `scripts/check-harness.ps1`
- Mettre à jour `docs/plans/README.md` à chaque nouveau Plan d'Action
- Garder ce README comme source de vérité pour la coordination transverse

### Contrat observé côté GitHub Copilot CLI

La CLI charge les skills selon pertinence, sans sélection déterministe par rôle. Les profils générés portent
donc une consigne explicite de chargement. Les comportements de garde, d'exclusion et de frontière de rôle
restent des comportements observés dans les scénarios AP 006, pas des protections natives garanties par la CLI.
<!-- /copilot-only

---

## 📚 Ressources

- `README.md` racine : presentation generale du depot
- `docs/ARCHITECTURE.md` : architecture transverse globale
- `.github/PLANS.md` : format et execution des Plans d'Action
- `.github/copilot-instructions.md` : instructions detaillees du depot Copilot
