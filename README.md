# AgentSync

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![OCaml](https://img.shields.io/badge/OCaml-5.0+-blue.svg)](https://ocaml.org)
[![Build Status](https://img.shields.io/badge/Build-Passing-green.svg)](https://github.com/gowaylee/agent-sync)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg)](https://github.com/gowaylee/agent-sync/pulls)

**Keep your multiple AI agent documentation files in sync across repositories — without the overhead.**

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development](#development)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Overview

AgentSync is a command-line tool built with OCaml that synchronizes multiple AI agent documentation files (e.g., `CLAUDE.md`, `GEMINI.md`) to a single canonical document (`AGENT_GUIDE.md`) using **symbolic links**. This ensures all agent files remain identical without duplication or drift.

### Problem It Solves

When working with multiple AI agents (Claude, Gemini, Copilot, etc.), developers often need to maintain separate documentation files for each agent. This leads to:

- **Content drift**: Files become inconsistent over time
- **Duplication**: Same content maintained in multiple places
- **Merge conflicts**: Manual synchronization is error-prone
- **Maintenance overhead**: Updates must be applied to multiple files

### Solution

AgentSync solves these problems by:

- **Single source of truth**: Only `AGENT_GUIDE.md` contains actual content
- **Symbolic link synchronization**: All agent files are symbolic links to the main guide
- **Atomic updates**: Changes to any agent file instantly reflect everywhere
- **Automatic recovery**: Detects and repairs broken links with content merging

## Features

| Feature                            | Description                                                                    |
| ---------------------------------- | ------------------------------------------------------------------------------ |
| **Symbolic Link Synchronization**  | Uses filesystem symbolic links for atomic, safe, and efficient synchronization |
| **System-wide Project Registry**   | JSON-based registry for tracking all agent-sync projects across the system     |
| **Automatic Project Registration** | Projects are automatically registered during init and repair operations        |
| **TOML Configuration**             | Simple, human-readable `.agent-sync.toml` configuration file                   |
| **Project-Aware CLI**              | Run commands from any subdirectory — automatically detects project root        |
| **Comprehensive Link Status**      | Detailed link verification and reporting for all agent files                   |
| **Atomic Operations**              | Safe operations with proper error handling and rollback capabilities           |
| **Cross-Platform**                 | Works on Linux, macOS, and other Unix-like systems                             |
| **Minimal Dependencies**           | Lightweight implementation with few runtime dependencies                       |
| **Type-Safe**                      | Built with OCaml for reliability and performance                               |

## Installation

### Prerequisites

- **OCaml** (5.0 or higher)
- **Dune** build system
- **OPAM** package manager
- Unix-like operating system (Linux, macOS, etc.)

### From Source

```bash
# Clone the repository
git clone https://github.com/gowaylee/agent-sync.git
cd agent-sync

# Install dependencies
opam install dune cmdliner toml yojson ounit2

# Build the project
dune build

# Run tests
dune runtest

# Install locally
dune install
```

### Verify Installation

```bash
# Check if agent-sync is installed
agent-sync --version

# Show help information
agent-sync help
```

## Quick Start

### 1. Initialize a New Project

```bash
# Navigate to your project directory
cd /path/to/your/project

# Initialize agent-sync configuration
agent-sync init
```

This creates:

- `.agent-sync.toml` configuration file
- `AGENT_GUIDE.md` (empty template)
- Sets up the project for agent file management
- Automatically registers the project in the system-wide registry

### 2. Add Agent Files

```bash
# Add Claude agent documentation
agent-sync add claude "CLAUDE.md"

# Add Gemini agent documentation
agent-sync add gemini "GEMINI.md"

# Add multiple agents at once
agent-sync add copilot "COPILOT.md"
agent-sync add qwen "QWEN.md"
```

### 3. Verify Setup

```bash
# Check the status of all agent links
agent-sync status

# Expected output:
# Project: /path/to/your/project
# Main guide: AGENT_GUIDE.md
# Configured agents:
#   claude -> CLAUDE.md [✓ Linked (target: AGENT_GUIDE.md)]
#   gemini -> GEMINI.md [✓ Linked (target: AGENT_GUIDE.md)]
#   copilot -> COPILOT.md [✓ Linked (target: AGENT_GUIDE.md)]
#   qwen -> QWEN.md [✓ Linked (target: AGENT_GUIDE.md)]
```

### 4. Use Your Agent Files

```bash
# Edit any agent file - changes reflect everywhere
echo "# Project Overview" > CLAUDE.md

# Verify all files are identical
cat CLAUDE.md GEMINI.md AGENT_GUIDE.md

# Check system-wide project registry
agent-sync status --all
```

## Configuration

### Configuration File Structure

AgentSync uses a TOML configuration file named `.agent-sync.toml` in your project root:

```toml
[core]
main_guide = "AGENT_GUIDE.md"

[agents]
claude = "CLAUDE.md"
gemini = "GEMINI.md"
copilot = "COPILOT.md"
qwen = "QWEN.md"
crush = "CRUSH.md"
```

### Configuration Options

| Section    | Option         | Description                         | Required |
| ---------- | -------------- | ----------------------------------- | -------- |
| `[core]`   | `main_guide`   | Path to the main guide file         | Yes      |
| `[agents]` | `<agent_name>` | Mapping from agent name to filename | Yes      |

### Example Configurations

#### Basic Setup

```toml
[core]
main_guide = "AGENT_GUIDE.md"

[agents]
claude = "CLAUDE.md"
gemini = "GEMINI.md"
```

#### Multiple Agent Types

```toml
[core]
main_guide = "AGENT_GUIDE.md"

[agents]
claude = "CLAUDE.md"
gemini = "GEMINI.md"
copilot = "COPILOT.md"
qwen = "QWEN.md"
crush = "CRUSH.md"
chatgpt = "CHATGPT.md"
```

#### Custom File Locations

```toml
[core]
main_guide = "docs/AGENT_GUIDE.md"

[agents]
claude = "docs/agents/CLAUDE.md"
gemini = "docs/agents/GEMINI.md"
copilot = "docs/agents/COPILOT.md"
```

## Usage

### Commands Reference

#### `agent-sync init`

Initialize a new AgentSync project.

```bash
# Initialize in current directory
agent-sync init
```

#### `agent-sync add`

Add a new agent file mapping.

```bash
# Add a new agent
agent-sync add <agent_name> <filename>

# Examples
agent-sync add claude "CLAUDE.md"
agent-sync add gemini "docs/GEMINI.md"
```

#### `agent-sync status`

Show current project status and agent link status.

```bash
# Show current project status
agent-sync status

# Show all registered projects system-wide
agent-sync status --all
```

#### `agent-sync repair`

Repair broken agent file links with content merging.

```bash
# Repair all agent files
agent-sync repair
```

#### `agent-sync help`

Show usage information and command help.

```bash
# Show general help
agent-sync help
```

### Common Workflows

#### Setting Up a New Project

```bash
# 1. Navigate to project
cd my-new-project

# 2. Initialize AgentSync (automatically registers project)
agent-sync init

# 3. Add required agents
agent-sync add claude "CLAUDE.md"
agent-sync add gemini "GEMINI.md"
agent-sync add copilot "COPILOT.md"

# 4. Verify setup
agent-sync status

# 5. Start using your agent files
echo "# My Project" > AGENT_GUIDE.md

# 6. Check system-wide registry
agent-sync status --all
```

#### Recovering from Broken Links

```bash
# Check status
agent-sync status

# If links are broken, repair them (also registers project)
agent-sync repair

# Verify repair
agent-sync status

# Confirm project is in registry
agent-sync status --all
```

#### Managing Multiple Projects

```bash
# List all registered projects with validation status
agent-sync status --all

# Work on specific project
cd /path/to/project
agent-sync status

# Repair specific project (automatically registers in registry)
cd /path/to/project
agent-sync repair
```

## Development

### Development Environment Setup

```bash
# Clone the repository
git clone https://github.com/gowaylee/agent-sync.git
cd agent-sync

# Create local OPAM switch
opam switch create . 5.0.0 --deps-only

# Build the project
dune build

# Run tests
dune runtest

# Install locally for development
dune install
```

### Building and Testing

```bash
# Build the project
dune build

# Run all tests
dune runtest

# Run specific test
dune exec ./test/test_agent_sync.exe

# Format code
ocamlformat -i lib/*.ml test/*.ml

# Type check
dune build @check

# Generate documentation
dune build @doc
```

### Code Style and Guidelines

#### Formatting

- Use `ocamlformat` with Jane Street profile
- Format before committing: `ocamlformat -i lib/*.ml test/*.ml`
- Use `.ocamlformat` configuration file

#### Naming Conventions

- **Modules**: `PascalCase` (e.g., `Config`, `LinkManager`)
- **Functions**: `snake_case` (e.g., `load_config`, `create_link`)
- **Variables**: `snake_case`
- **Constants**: `UPPER_SNAKE_CASE`

#### Error Handling

- Use `Result` type for operations that can fail
- Pattern match on results explicitly
- Provide meaningful error messages

### Testing

Tests are located in the `test/` directory and use the OUnit2 framework:

```bash
# Run all tests
dune runtest

# Run specific test file
dune exec ./test/test_config_load.exe

# Run test with verbose output
dune runtest --verbose
```

## Architecture

### Core Modules

| Module          | Description           | Key Responsibilities                            |
| --------------- | --------------------- | ----------------------------------------------- |
| **Config**      | `lib/config.ml`       | TOML configuration parsing and validation       |
| **Project**     | `lib/project.ml`      | Project detection and root directory management |
| **CLI**         | `lib/cli.ml`          | Command-line interface and command dispatch     |
| **LinkManager** | `lib/link_manager.ml` | Symbolic link operations and content merging    |
| **Registry**    | `lib/registry.ml`     | System-wide project indexing and tracking       |

### Data Flow

```
User Input → CLI → Config/Project → LinkManager → Filesystem Operations
     ↓
Registry ← Project Registration → System-wide Tracking
     ↓
Error Handling ← Result Types ← All Modules
```

### Design Principles

- **Single Source of Truth**: `AGENT_GUIDE.md` is the only real file
- **Atomic Operations**: Use symbolic links for filesystem-level atomicity
- **Error Recovery**: Graceful handling of broken links and conflicts
- **System-wide Tracking**: Automatic project registration and registry management
- **Type Safety**: Leverage OCaml's type system for reliability
- **Minimal Dependencies**: Keep runtime dependencies lightweight

### Dependencies

- **Runtime**: `cmdliner`, `toml`, `yojson`, `unix`
- **Development**: `dune`, `ocaml`, `ounit2`
- **Build**: OCaml build system with Dune

## Contributing

We welcome contributions! Please follow these guidelines:

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Follow the code style guidelines
5. Add tests for new functionality
6. Ensure all tests pass: `dune runtest`
7. Submit a pull request

### Pull Request Process

1. **Description**: Clearly describe the changes and why they're needed
2. **Testing**: Include how you tested your changes
3. **Documentation**: Update documentation if needed
4. **Format**: Ensure code is properly formatted
5. **Review**: Address review comments promptly

### Development Guidelines

- **Code Style**: Follow existing conventions and use `ocamlformat`
- **Testing**: Add tests for new features and bug fixes
- **Documentation**: Update relevant documentation
- **Breaking Changes**: Clearly document any breaking changes
- **Performance**: Consider performance implications of changes

### Reporting Issues

When reporting bugs or suggesting features:

1. Use the GitHub issue tracker
2. Provide clear, reproducible examples
3. Include your environment information
4. Check for existing issues first

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

This project depends on the following libraries:

- **cmdliner**: Command-line parsing
- **toml**: TOML configuration parsing
- **yojson**: JSON processing
- **ounit2**: Unit testing framework

Each library has its own license terms.

## Support

### Getting Help

- **Documentation**: Read this README and project documentation
- **Issues**: Report bugs and request features on [GitHub Issues](https://github.com/gowaylee/agent-sync/issues)

### Version Information

- **Current Version**: Check with `agent-sync --version`
- **Compatibility**: OCaml 5.0+ on Unix-like systems
- **Updates**: Follow the repository for updates and announcements

### Community

- **Contributors**: See the [contributor list](https://github.com/gowaylee/agent-sync/contributors)
- **Stars**: If you find this project useful, please consider giving it a star ⭐
- **Share**: Help spread the word about AgentSync

---

**AgentSync** - Keeping your AI agent documentation in sync, one symbolic link at a time.
