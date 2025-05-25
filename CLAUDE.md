# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Version Management

### When to Bump Versions
- **Patch version (0.x.Y)**: Bug fixes, documentation updates, minor improvements
- **Minor version (0.X.0)**: New features, non-breaking API changes
- **Major version (X.0.0)**: Breaking API changes (after 1.0.0 release)

### Version Update Checklist
1. Update version in `mix.exs`
2. Update CHANGELOG.md with:
   - Version number and date
   - Added/Changed/Fixed/Removed sections
   - **BREAKING:** prefix for any breaking changes
3. Commit with message: `chore: bump version to X.Y.Z`

### CHANGELOG Format
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality
- **BREAKING:** API changes that break compatibility

### Fixed
- Bug fixes

### Removed
- Removed features
- **BREAKING:** Removed APIs
```

## Project Overview

ExAlias is an Elixir library for managing command aliases programmatically. It provides functionality to:
- Define and manage command aliases (e.g., `ll` → `ls -la`)
- Support nested alias expansion with recursive resolution
- Append arguments to expanded aliases
- Persist aliases to disk in JSON format
- Validate aliases to prevent circular references and reserved command conflicts

## Development Commands

```bash
# Run tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/ex_alias_test.exs

# Run tests matching a pattern
mix test --only describe:"add_alias/2"

# Format code
mix format

# Run static analysis
mix credo

# Run dialyzer for type checking
mix dialyzer

# Interactive console
iex -S mix

# Build documentation
mix docs

# Install dependencies
mix deps.get
```

## Architecture

### Core Components

1. **ExAlias** (lib/ex_alias.ex) - Main public API module providing:
   - `define_alias/2` - Define new aliases
   - `remove_alias/1` - Remove existing aliases
   - `expand_alias/1` - Expand alias to its commands
   - `get_alias/1` - Get alias definition
   - `list_aliases/0` - List all defined aliases
   - `is_alias?/1` - Check if a command is an alias
   - `save_aliases/0` - Save aliases to disk (automatic after changes)

2. **ExAlias.Core** (lib/ex_alias/core.ex) - Internal implementation:
   - State management using Agent
   - Alias validation and circular dependency detection
   - Command expansion with placeholder support
   - JSON persistence handling

3. **ExAlias.Error** (lib/ex_alias/error.ex) - Custom error types:
   - Validation errors for invalid aliases
   - Circular dependency errors
   - Reserved command conflicts

### Key Design Patterns

- **GenServer-based State**: Uses Elixir GenServer for concurrent state management
- **Recursive Expansion**: Supports nested alias expansion (e.g., `gp` → `git push` where `g` → `git`)
- **Argument Appending**: Arguments provided to aliases are appended to expanded commands
- **Validation Pipeline**: Checks for circular references and reserved commands before adding aliases
- **Functional Core**: Pure functional implementation in ExAlias.Core for library usage

### Storage

Aliases are persisted to `~/.config/ex_alias/aliases.json` by default. The file path can be configured via the `:aliases_path` application environment variable.

## Testing Approach

- Unit tests use ExUnit with descriptive `describe` blocks
- Tests focus on public API behavior
- File system operations are tested with temporary directories
- Edge cases include circular dependencies, nested expansions, and error handling