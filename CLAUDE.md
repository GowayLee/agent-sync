# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AgentSync is a CLI tool built with OCaml that synchronizes multiple agent documentation files (e.g., `CLAUDE.md`, `GEMINI.md`) to a single canonical document (`AGENT_GUIDE.md`) using hard links. This ensures all agent files remain identical without duplication or drift.

## Build System

This project uses Dune build system. Key commands:

```bash
# Build the project
dune build

# Run tests
dune runtest

# Run single test
dune exec ./test/test_agent_sync.exe

# Format code
ocamlformat -i lib/*.ml test/*.ml

# Type check
dune build @check

# Install locally
dune install
```

## Architecture

### Core Modules

- **Config** (`lib/config.ml`): Handles TOML configuration parsing and validation. Manages agent file mappings and project settings.
- **LinkManager** (`lib/link_manager.ml`): Manages hard link creation and synchronization between agent files and the main guide.
- **Project** (`lib/project.ml`): Project detection and root directory management.
- **Registry** (`lib/registry.ml`): System-wide project indexing and tracking.

### Dependencies

- `cmdliner`: Command-line argument parsing
- `toml`: TOML configuration file parsing
- `yojson`: JSON processing
- `ounit2`: Unit testing framework
- `unix`: Unix system calls for hard link operations

### Configuration

Configuration is stored in `.agent-sync.toml` with structure:

```toml
[core]
main_guide = "AGENT_GUIDE.md"

[agents]
claude = "CLAUDE.md"
crush = "CRUSH.md"
gemini = "GEMINI.md"
```

## Development Workflow

1. Make changes to source files in `lib/`
2. Add tests in `test/` directory following the existing OUnit2 pattern
3. Format code with `ocamlformat -i lib/*.ml test/*.ml`
4. Run tests with `dune runtest`
5. Build with `dune build`

## Testing

Tests are written using OUnit2 framework. Test files:

- `test/test_agent_sync.ml`: Main test runner
- `test/test_config_load.ml`: Configuration loading tests

Test pattern:

- Create temporary test files with `temp_file_with_content`
- Test both success and error cases
- Clean up test files with `cleanup_test_file`

## Code Style

### Formatting

- Use `.ocamlformat` with `profile=janestreet`
- Format before committing: `ocamlformat -i lib/*.ml test/*.ml`

### Naming Conventions

- Modules: `PascalCase` (e.g., `Config`, `LinkManager`)
- Functions: `snake_case` (e.g., `load_config`, `create_link`)
- Variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`

### Types

- Type definitions: `t` for main type, descriptive names for others
- Records: `snake_case` fields
- Variants: `PascalCase` constructors

### Error Handling

- Use `Result` type for operations that can fail
- Pattern match on results explicitly
- Provide meaningful error messages

### Module Structure

- Each file should have a module with the same name as the file
- Use `module M = struct ... end` pattern
- Keep modules focused and single-purpose

## Current Status

The project is in early development with:

- Complete configuration module with comprehensive error handling
- Complete project detection and root directory management module
- Placeholder modules for link management and registry (not yet implemented)
- Basic "Hello World" executable in `bin/main.ml`
- Test suite covering configuration loading and project detection

### Implementation Status

- **Config** (`lib/config.ml`): ✅ Complete - TOML configuration parsing and validation
- **Project** (`lib/project.ml`): ✅ Complete - Project detection and root directory management
- **LinkManager** (`lib/link_manager.ml`): ❌ Not implemented - Empty placeholder
- **Registry** (`lib/registry.ml`): ❌ Not implemented - Empty placeholder
- **Main executable** (`bin/main.ml`): ⚠️ Basic - Only prints "Hello World"

### Test Coverage

- `test/test_config_load.ml`: ✅ Comprehensive configuration tests
- `test/test_project.ml`: ✅ Project detection tests
- `test/test_agent_sync.ml`: ✅ Main test runner

## Key Files

- `README.md`: Project overview and usage instructions
- `CRUSH.md`: Development guide with coding standards
- `dune-project`: Project configuration
- `agent-sync.opam`: Package dependencies and metadata
- `lib/config.ml`: Complete configuration management implementation
- `test/test_config_load.ml`: Comprehensive configuration tests

