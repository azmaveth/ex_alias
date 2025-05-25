# ExAlias

[![Hex.pm](https://img.shields.io/hexpm/v/ex_alias.svg)](https://hex.pm/packages/ex_alias)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/ex_alias)
[![License](https://img.shields.io/github/license/azmaveth/ex_alias.svg)](https://github.com/azmaveth/ex_alias/blob/master/LICENSE)

A flexible command alias system for Elixir applications with recursive expansion and circular reference detection.

> ⚠️ **Alpha Software**: This project is currently in alpha stage (v0.1.0).
> The API is unstable and may change significantly before v1.0 release.

## Features

- **Command Aliasing**: Define shortcuts for frequently used commands
- **Nested Expansion**: Aliases can reference other aliases with automatic recursive resolution
- **Argument Appending**: Pass arguments to aliased commands
- **Circular Reference Detection**: Prevents infinite loops in alias definitions
- **Reserved Command Protection**: Safeguards against overriding built-in commands
- **JSON Persistence**: Automatically saves and loads aliases from disk
- **GenServer Integration**: Thread-safe state management with supervision support
- **Functional Core**: Pure functional API available for library usage

## Installation

Add `ex_alias` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_alias, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Using the GenServer Interface

```elixir
# Start the alias server
{:ok, _pid} = ExAlias.start_link()

# Define a simple alias
:ok = ExAlias.define_alias("gs", ["git", "status"])

# Define an alias with multiple commands
:ok = ExAlias.define_alias("deploy", ["git pull", "mix deps.get", "mix test"])

# Use nested aliases
:ok = ExAlias.define_alias("g", ["git"])
:ok = ExAlias.define_alias("gp", ["g", "push"])

# Expand an alias
{:ok, ["git", "status"]} = ExAlias.expand_alias("gs")
{:ok, ["git", "push"]} = ExAlias.expand_alias("gp")

# List all aliases
aliases = ExAlias.list_aliases()
# => [
#      %{name: "g", commands: ["git"]},
#      %{name: "gp", commands: ["g", "push"]},
#      %{name: "gs", commands: ["git", "status"]}
#    ]

# Remove an alias
:ok = ExAlias.remove_alias("gs")
```

### Using the Functional Core

For library usage without GenServer:

```elixir
# Start with empty aliases
aliases = %{}

# Define aliases
{:ok, aliases} = ExAlias.Core.define_alias(aliases, "ll", ["ls", "-la"])
{:ok, aliases} = ExAlias.Core.define_alias(aliases, "la", ["ls", "-a"])

# Expand aliases
{:ok, ["ls", "-la"]} = ExAlias.Core.expand_alias(aliases, "ll")

# Save to disk
:ok = ExAlias.Core.save_aliases(aliases, "/path/to/aliases.json")

# Load from disk
loaded_aliases = ExAlias.Core.load_aliases("/path/to/aliases.json")
```

## Configuration

By default, aliases are stored in `~/.config/ex_alias/aliases.json`. You can customize this:

```elixir
# Specify a custom path
{:ok, _pid} = ExAlias.start_link(path: "/custom/path/aliases.json")

# Or use a path provider module
{:ok, _pid} = ExAlias.start_link(path_provider: MyPathProvider)
```

## Advanced Usage

### Nested Alias Expansion

Aliases can reference other aliases, which are automatically expanded:

```elixir
ExAlias.define_alias("g", ["git"])
ExAlias.define_alias("gs", ["g", "status"])
ExAlias.define_alias("gss", ["gs", "-s"])

{:ok, ["git", "status", "-s"]} = ExAlias.expand_alias("gss")
```

### Argument Appending

Arguments passed to an alias are appended to the expanded command:

```elixir
ExAlias.define_alias("g", ["git"])

# When used as "g status -s", expands to ["git", "status", "-s"]
{:ok, ["git", "status -s"]} = ExAlias.expand_alias("g")
```

### Error Handling

The library provides detailed error messages:

```elixir
# Empty alias name
{:error, {:validation_error, {:name, "cannot be empty"}}} = 
  ExAlias.define_alias("", ["command"])

# Reserved command
{:error, {:validation_error, {:name, "cannot override built-in command 'help'"}}} = 
  ExAlias.define_alias("help", ["my-help"])

# Circular references are prevented during expansion
ExAlias.define_alias("a", ["b"])
ExAlias.define_alias("b", ["a"])
{:ok, ["a"]} = ExAlias.expand_alias("a")  # Stops at circular reference
```

## API Reference

### ExAlias (GenServer Interface)

- `start_link/1` - Start the alias server
- `define_alias/2` - Define a new alias
- `remove_alias/1` - Remove an alias
- `get_alias/1` - Get alias definition
- `expand_alias/1` - Expand alias to commands
- `list_aliases/0` - List all aliases
- `is_alias?/1` - Check if command is an alias
- `save_aliases/0` - Manually trigger save to disk

### ExAlias.Core (Functional Interface)

- `define_alias/3` - Add alias to aliases map
- `remove_alias/2` - Remove alias from map
- `get_alias/2` - Get alias from map
- `expand_alias/2` - Expand alias with recursive resolution
- `list_aliases/1` - Get all aliases
- `is_alias?/2` - Check if command exists in map
- `load_aliases/1` - Load aliases from file
- `save_aliases/2` - Save aliases to file

## Reserved Commands

The following commands cannot be used as alias names:
- `help`, `clear`, `history`, `new`, `save`, `load`
- `sessions`, `config`, `servers`, `discover`, `connect`, `disconnect`
- `tools`, `tool`, `resources`, `resource`, `prompts`, `prompt`
- `backend`, `models`, `alias`, `aliases`, `unalias`
- `cost`, `export`, `exit`, `quit`

## Development

```bash
# Run tests
mix test

# Run tests with coverage
mix test --cover

# Format code
mix format

# Run static analysis
mix credo

# Generate documentation
mix docs
```

## Roadmap

See [TASKS.md](TASKS.md) for planned features and improvements.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Elixir](https://elixir-lang.org/)
- JSON handling via [Jason](https://github.com/michalmuskala/jason)
- Documentation with [ExDoc](https://github.com/elixir-lang/ex_doc)