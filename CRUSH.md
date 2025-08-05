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

# Run single test (when implemented)
dune exec ./test/test_agent_sync.exe

# Format code
ocamlformat -i lib/*.ml test/*.ml

# Type check
dune build @check

# Install locally
dune install
```

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
- Core libraries: `cmdliner`, `toml`, `yojson`, `unix`
- Follow Dune build system conventions
- Use explicit module declarations in dune files

### Testing
- Place tests in `test/` directory
- Use `dune runtest` to run all tests
- Test both success and error cases