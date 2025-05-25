defmodule ExAlias.Core do
  @moduledoc """
  Functional core for alias operations without process state.

  This module provides pure functions for managing command aliases,
  making it suitable for library usage without requiring GenServer supervision.

  ## Example usage

      # Load aliases from file
      aliases = ExAlias.Core.load_aliases("/path/to/aliases.json")

      # Define a new alias
      {:ok, updated_aliases} = ExAlias.Core.define_alias(aliases, "ll", ["ls", "-la"])

      # Expand an alias
      {:ok, commands} = ExAlias.Core.expand_alias(updated_aliases, "ll")
      # => {:ok, ["ls", "-la"]}

      # Save aliases
      :ok = ExAlias.Core.save_aliases(updated_aliases, "/path/to/aliases.json")
  """

  alias ExAlias.Error

  @type aliases :: %{binary() => [binary()]}

  @doc """
  Load aliases from a file path.

  Returns an empty map if the file doesn't exist or cannot be parsed.

  ## Parameters
  - `path` - File path to aliases JSON file

  ## Returns
  Map of aliases or empty map if file doesn't exist.
  """
  @spec load_aliases(binary()) :: aliases()
  def load_aliases(path) do
    if File.exists?(path) do
      case File.read(path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, aliases} when is_map(aliases) ->
              # Convert string keys to strings if needed
              Map.new(aliases, fn {k, v} -> {to_string(k), v} end)

            _ ->
              %{}
          end

        _ ->
          %{}
      end
    else
      %{}
    end
  end

  @doc """
  Save aliases to a file path.

  Creates the directory if it doesn't exist.

  ## Parameters
  - `aliases` - Map of aliases
  - `path` - File path to save to

  ## Returns
  :ok on success, {:error, reason} on failure.
  """
  @spec save_aliases(aliases(), binary()) :: :ok | {:error, term()}
  def save_aliases(aliases, path) do
    dir = Path.dirname(path)

    # Ensure directory exists
    case File.mkdir_p(dir) do
      :ok ->
        # Write aliases
        content = Jason.encode!(aliases, pretty: true)
        File.write(path, content)

      error ->
        error
    end
  end

  @doc """
  Define a new alias.

  Validates the alias name and commands before adding.

  ## Parameters
  - `aliases` - Current aliases map
  - `name` - Alias name
  - `commands` - List of commands for the alias

  ## Returns
  {:ok, updated_aliases} on success, {:error, reason} on failure.

  ## Examples

      iex> aliases = %{}
      iex> {:ok, aliases} = ExAlias.Core.define_alias(aliases, "gs", ["git", "status"])
      iex> aliases
      %{"gs" => ["git", "status"]}

  ## Errors

  - `{:validation_error, {:name, "cannot be empty"}}` - Empty name
  - `{:validation_error, {:name, "cannot contain spaces"}}` - Name with spaces
  - `{:validation_error, {:name, "cannot override built-in command 'X'"}}` - Reserved name
  - `{:validation_error, {:commands, "cannot be empty"}}` - Empty commands
  - `{:validation_error, {:commands, "must all be strings"}}` - Non-string commands
  """
  @spec define_alias(aliases(), binary(), [binary()]) :: 
    {:ok, aliases()} | {:error, term()}
  def define_alias(aliases, name, commands) when is_binary(name) and is_list(commands) do
    # Validate alias name
    cond do
      String.length(name) == 0 ->
        Error.validation_error(:name, "cannot be empty")

      String.contains?(name, " ") ->
        Error.validation_error(:name, "cannot contain spaces")

      is_reserved_command?(name) ->
        Error.validation_error(:name, "cannot override built-in command '#{name}'")

      true ->
        # Validate commands
        case validate_commands(commands) do
          :ok ->
            updated_aliases = Map.put(aliases, name, commands)
            {:ok, updated_aliases}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Remove an alias.

  ## Parameters
  - `aliases` - Current aliases map
  - `name` - Alias name to remove

  ## Returns
  {:ok, updated_aliases} on success, {:error, :not_found} if alias doesn't exist.
  """
  @spec remove_alias(aliases(), binary()) :: {:ok, aliases()} | {:error, :not_found}
  def remove_alias(aliases, name) do
    if Map.has_key?(aliases, name) do
      updated_aliases = Map.delete(aliases, name)
      {:ok, updated_aliases}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Get an alias by name.

  ## Parameters
  - `aliases` - Current aliases map
  - `name` - Alias name

  ## Returns
  {:ok, commands} on success, {:error, :not_found} if alias doesn't exist.
  """
  @spec get_alias(aliases(), binary()) :: {:ok, [binary()]} | {:error, :not_found}
  def get_alias(aliases, name) do
    case Map.get(aliases, name) do
      nil -> {:error, :not_found}
      commands -> {:ok, commands}
    end
  end

  @doc """
  List all aliases.

  ## Parameters
  - `aliases` - Current aliases map

  ## Returns
  Map of all aliases.
  """
  @spec list_aliases(aliases()) :: aliases()
  def list_aliases(aliases) do
    aliases
  end

  @doc """
  Expand an alias to its commands, handling recursive expansion.

  Supports nested aliases and detects circular references.

  ## Parameters
  - `aliases` - Current aliases map
  - `name` - Alias name to expand

  ## Returns
  {:ok, expanded_commands} on success, {:error, :not_found} if alias doesn't exist.

  ## Examples

      iex> aliases = %{"gs" => ["git", "status"], "gss" => ["gs", "-s"]}
      iex> ExAlias.Core.expand_alias(aliases, "gss")
      {:ok, ["git", "status", "-s"]}

  ## Circular Reference Handling

  If a circular reference is detected, expansion stops and returns the
  command that would create the loop:

      iex> aliases = %{"a" => ["b"], "b" => ["a"]}
      iex> ExAlias.Core.expand_alias(aliases, "a")
      {:ok, ["a"]}
  """
  @spec expand_alias(aliases(), binary()) :: {:ok, [binary()]} | {:error, :not_found}
  def expand_alias(aliases, name) do
    case Map.get(aliases, name) do
      nil ->
        {:error, :not_found}

      commands ->
        expanded = expand_commands(commands, aliases, [name])
        {:ok, expanded}
    end
  end

  @doc """
  Check if a command is an alias.

  ## Parameters
  - `aliases` - Current aliases map
  - `name` - Command name to check

  ## Returns
  Boolean indicating if the name is an alias.
  """
  @spec is_alias?(aliases(), binary()) :: boolean()
  def is_alias?(aliases, name) do
    Map.has_key?(aliases, name)
  end

  # Private helper functions

  @reserved_commands [
    "help", "clear", "history", "new", "save", "load", "sessions", "config",
    "servers", "discover", "connect", "disconnect", "tools", "tool",
    "resources", "resource", "prompts", "prompt", "backend", "models",
    "alias", "aliases", "unalias", "cost", "export", "exit", "quit"
  ]

  defp is_reserved_command?(name) do
    Enum.member?(@reserved_commands, name)
  end

  defp validate_commands(commands) do
    cond do
      length(commands) == 0 ->
        Error.validation_error(:commands, "cannot be empty")

      Enum.any?(commands, &(not is_binary(&1))) ->
        Error.validation_error(:commands, "must all be strings")

      true ->
        :ok
    end
  end

  defp expand_commands(commands, aliases, visited) do
    Enum.flat_map(commands, fn cmd ->
      # Split command to check if first part is an alias
      case String.split(cmd, " ", parts: 2) do
        [alias_name] ->
          if alias_name in visited do
            # Circular reference detected, return as-is
            [cmd]
          else
            case Map.get(aliases, alias_name) do
              nil ->
                # Not an alias, keep as is
                [cmd]

              alias_commands ->
                # Recursively expand
                expand_commands(alias_commands, aliases, [alias_name | visited])
            end
          end

        [alias_name, args] ->
          if alias_name in visited do
            # Circular reference detected, return as-is
            [cmd]
          else
            case Map.get(aliases, alias_name) do
              nil ->
                # Not an alias, keep as is
                [cmd]

              alias_commands ->
                # Recursively expand and append args to each command
                expanded = expand_commands(alias_commands, aliases, [alias_name | visited])
                Enum.map(expanded, fn expanded_cmd -> "#{expanded_cmd} #{args}" end)
            end
          end

        _ ->
          # Not a command, keep as is
          [cmd]
      end
    end)
  end
end