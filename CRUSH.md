# AgentSync Development Guide

## Project Overview

AgentSync is a CLI tool built with OCaml that synchronizes multiple agent documentation files (e.g., `CLAUDE.md`, `GEMINI.md`) to a single canonical document (`AGENT_GUIDE.md`) using hard links. This ensures all agent files remain identical without duplication or drift.

Key features:

- Hard link synchronization for atomic, safe updates
- TOML configuration via `.agent-sync.toml`
- Project-aware CLI that detects project root automatically
- System-level project indexing and management

## Build Commands

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
- **Project** (`lib/project.ml`): Project detection and root directory management.
- **CLI** (`lib/cli.ml`): Command-line interface providing init, add, status, repair, and help commands.
- **LinkManager** (`lib/link_manager.ml`): Manages hard link creation and synchronization between agent files and the main guide.
- **Registry** (`lib/registry.ml`): System-wide project indexing and tracking.

### Dependencies

- `cmdliner`: Command-line argument parsing
- `toml`: TOML configuration file parsing
- `yojson`: JSON processing
- `ounit2`: Unit testing framework
- `unix`: Unix system calls for hard link operations

## Code Style Guidelines

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

### Dependencies

- Core libraries: `cmdliner`, `toml`, `yojson`, `ounit2`, `unix`
- Follow Dune build system conventions
- Use explicit module declarations in dune files

### Testing

- Place tests in `test/` directory
- Use `dune runtest` to run all tests
- Test both success and error cases
- Use OUnit2 framework with `temp_file_with_content` and `cleanup_test_file` helpers

Tests are written using OUnit2 framework. Test files:

- `test/test_agent_sync.ml`: Main test runner
- `test/test_config_load.ml`: Configuration loading tests
- `test/test_project.ml`: Project detection tests

Test pattern:

- Create temporary test files with `temp_file_with_content`
- Test both success and error cases
- Clean up test files with `cleanup_test_file`

## Current Status

The project is in active development with:

- Complete configuration module with comprehensive error handling and save functionality
- Complete project detection and root directory management module with validation
- Complete CLI module with full command-line interface and error handling
- Placeholder modules for link management and registry (not yet implemented)
- Fully functional main executable in `bin/main.ml`
- Test suite covering configuration loading and project detection

### Implementation Status

- **Config** (`lib/config.ml`): ✅ Complete - TOML configuration parsing, validation, and save functionality
- **Project** (`lib/project.ml`): ✅ Complete - Project detection, root directory management, and configuration validation
- **CLI** (`lib/cli.ml`): ✅ Complete - Full command-line interface with init, add, status, repair, and help commands
- **LinkManager** (`lib/link_manager.ml`): ❌ Not implemented - Empty placeholder
- **Registry** (`lib/registry.ml`): ❌ Not implemented - Empty placeholder
- **Main executable** (`bin/main.ml`): ✅ Complete - Proper CLI entry point with command dispatch

### Test Coverage

- `test/test_config_load.ml`: ✅ Comprehensive configuration tests (9 test cases covering all error scenarios)
- `test/test_project.ml`: ✅ Project detection tests (1 test case for directory detection)
- `test/test_agent_sync.ml`: ✅ Main test runner (aggregates all test suites)

### Key Files

- `README.md`: Project overview and usage instructions
- `CRUSH.md`: Development guide with coding standards
- `dune-project`: Project configuration
- `agent-sync.opam`: Package dependencies and metadata
- `lib/config.ml`: Complete configuration management implementation
- `lib/project.ml`: Project detection and root directory management
- `lib/cli.ml`: Complete command-line interface implementation
- `bin/main.ml`: Main executable entry point
- `test/test_config_load.ml`: Comprehensive configuration tests
- `test/test_project.ml`: Project detection tests

## Configuration Structure

Configuration is stored in `.agent-sync.toml`:

```toml
[core]
main_guide = "AGENT_GUIDE.md"

[agents]
claude = "CLAUDE.md"
crush = "CRUSH.md"
gemini = "GEMINI.md"
```

### CLI Commands

The tool provides the following commands:

- `init`: Initialize a new agent-sync project in the current directory
- `add <agent> <filename>`: Add a new agent file mapping to the configuration
- `status`: Show current project status and configured agents
- `status --all`: Show all projects (requires Registry module - not implemented)
- `repair`: Repair broken agent file links (requires LinkManager module - not implemented)
- `help`: Show usage information

All commands include proper error handling and user-friendly error messages.

## Development Workflow

1. Make changes to source files in `lib/`
2. Add tests in `test/` directory following the existing OUnit2 pattern
3. Format code with `ocamlformat -i lib/*.ml test/*.ml`
4. Run tests with `dune runtest`
5. Build with `dune build`
