# AgentSync: Unified Agent Document Management

**Keep your multiple agent documents in sync across repositories — without the overhead.**

---

## 🚀 Basic Specs

### Core Purpose

Synchronize multiple agent documentation files (e.g., `CLAUDE.md`, `GEMINI.md`) in a project to **one canonical document** (`AGENT_GUIDE.md`) using **hard links**. This ensures:

- All agent files are **always identical** to the main guide.
- Editing any agent file updates the **single source of truth**.
- No duplication, no drift, no merge conflicts.

### Key Features

| Feature                | Description                                                                 |
| ---------------------- | --------------------------------------------------------------------------- |
| **Hard Link Sync**     | Uses filesystem hard links (not symlinks) for atomic, safe synchronization. |
| **TOML Configuration** | Simple `.agent-sync.toml` config for agent mapping and grouping.            |
| **Project-Aware CLI**  | Run commands from any subdirectory — automatically detects project root.    |
| **System-Level Index** | List all managed projects system-wide with `agent-sync status --all`.       |

---

## 📂 Configuration (`.agent-sync.toml`)

```toml
[core]
main_guide = "AGENT_GUIDE.md"

[agents]
claude  = "CLAUDE.md"
crush   = "CRUSH.md"
gemini  = "GEMINI.md"
qwen    = "QWEN.md"
copilot = "COPILOT.md"
```

---

## 🛠️ Basic Commands

### In a Project Directory

```bash
# Initialize agent files in a new project
agent-sync init

# Add a new agent file (creates hard link)
agent-sync add copilot "COPILOT.md"

# Repair all agent files in 'default' group
agent-sync repair

# Check status of all agent links
agent-sync status
```

### From Anywhere (System-Level)

```bash
# List all agent-sync managed projects
agent-sync status --all

# Show usage information
agent-sync help
```

---

## 🔧 Design Principles

- **Single Source of Truth**: `AGENT_GUIDE.md` is the **only** real file. All agent files are hard links to it.
- **Edit Transparency**: Developers can edit `CLAUDE.md` directly — changes are instantly reflected everywhere.
- **Failure Recovery**: If an agent file is overwritten (not a link), `repair` merges content back into `AGENT_GUIDE.md` and restores the link.
- **OCaml-Native**: Built with OCaml, using `Unix.link` for reliability and `to.ml` for TOML parsing.
