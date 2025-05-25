defmodule ExAlias do
  @moduledoc """
  GenServer wrapper for alias management.

  This module provides a stateful GenServer interface for alias management.
  For stateless usage, see ExAlias.Core.

  The functional operations are delegated to ExAlias.Core, while this
  module handles process state management and supervision.

  ## Example

      # Start the alias server
      {:ok, _pid} = ExAlias.start_link()

      # Define an alias
      :ok = ExAlias.define_alias("gs", ["git", "status"])

      # Expand an alias
      {:ok, ["git", "status"]} = ExAlias.expand_alias("gs")

      # List all aliases
      aliases = ExAlias.list_aliases()
  """

  use GenServer

  alias ExAlias.Core

  # Client API

  @doc """
  Starts the alias server.

  ## Options

  - `:path` - Path to the aliases file (default: ~/.config/ex_alias/aliases.json)
  - `:path_provider` - Module that implements path resolution
  - `:name` - GenServer name (default: ExAlias)
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Define a new alias.

  ## Examples

      iex> ExAlias.define_alias("gs", ["git", "status"])
      :ok

      iex> ExAlias.define_alias("deploy", ["git pull", "mix deps.get", "mix test"])
      :ok
  """
  @spec define_alias(binary(), [binary()]) :: :ok | {:error, term()}
  def define_alias(name, commands) when is_binary(name) and is_list(commands) do
    GenServer.call(__MODULE__, {:define_alias, name, commands})
  end

  @doc """
  Remove an alias.

  ## Examples

      iex> ExAlias.remove_alias("gs")
      :ok

      iex> ExAlias.remove_alias("nonexistent")
      {:error, :not_found}
  """
  @spec remove_alias(binary()) :: :ok | {:error, term()}
  def remove_alias(name) do
    GenServer.call(__MODULE__, {:remove_alias, name})
  end

  @doc """
  Get alias definition.

  ## Examples

      iex> ExAlias.get_alias("gs")
      {:ok, ["git", "status"]}

      iex> ExAlias.get_alias("nonexistent")
      {:error, :not_found}
  """
  @spec get_alias(binary()) :: {:ok, [binary()]} | {:error, term()}
  def get_alias(name) do
    GenServer.call(__MODULE__, {:get_alias, name})
  end

  @doc """
  List all aliases.

  Returns a list of maps with `:name` and `:commands` keys, sorted by name.

  ## Examples

      iex> ExAlias.list_aliases()
      [
        %{name: "gs", commands: ["git", "status"]},
        %{name: "gp", commands: ["git", "push"]}
      ]
  """
  @spec list_aliases() :: [%{name: binary(), commands: [binary()]}]
  def list_aliases() do
    GenServer.call(__MODULE__, :list_aliases)
  end

  @doc """
  Expand an alias to its commands.

  Handles recursive expansion and circular reference detection.

  ## Examples

      iex> ExAlias.expand_alias("gs")
      {:ok, ["git", "status"]}

      iex> ExAlias.expand_alias("nonexistent")
      {:error, :not_found}
  """
  @spec expand_alias(binary()) :: {:ok, [binary()]} | {:error, term()}
  def expand_alias(name) do
    GenServer.call(__MODULE__, {:expand_alias, name})
  end

  @doc """
  Check if a command is an alias.

  ## Examples

      iex> ExAlias.is_alias?("gs")
      true

      iex> ExAlias.is_alias?("git")
      false
  """
  @spec is_alias?(binary()) :: boolean()
  def is_alias?(name) do
    case get_alias(name) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Save aliases to disk.

  This is automatically called after define_alias and remove_alias,
  but can be called manually if needed.
  """
  @spec save_aliases() :: :ok
  def save_aliases() do
    GenServer.cast(__MODULE__, :save_aliases)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    path = get_aliases_path(opts)

    state = %{
      aliases: Core.load_aliases(path),
      path: path
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:define_alias, name, commands}, _from, state) do
    case Core.define_alias(state.aliases, name, commands) do
      {:ok, updated_aliases} ->
        new_state = %{state | aliases: updated_aliases}

        # Save to disk asynchronously
        GenServer.cast(self(), :save_aliases)

        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:remove_alias, name}, _from, state) do
    case Core.remove_alias(state.aliases, name) do
      {:ok, updated_aliases} ->
        new_state = %{state | aliases: updated_aliases}

        # Save to disk asynchronously
        GenServer.cast(self(), :save_aliases)

        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get_alias, name}, _from, state) do
    result = Core.get_alias(state.aliases, name)
    {:reply, result, state}
  end

  def handle_call(:list_aliases, _from, state) do
    aliases = Core.list_aliases(state.aliases)

    formatted_aliases =
      aliases
      |> Enum.map(fn {name, commands} -> %{name: name, commands: commands} end)
      |> Enum.sort_by(& &1.name)

    {:reply, formatted_aliases, state}
  end

  def handle_call({:expand_alias, name}, _from, state) do
    result = Core.expand_alias(state.aliases, name)
    {:reply, result, state}
  end

  @impl true
  def handle_cast(:save_aliases, state) do
    Core.save_aliases(state.aliases, state.path)
    {:noreply, state}
  end

  # Private functions

  defp get_aliases_path(opts) do
    cond do
      path = Keyword.get(opts, :path) ->
        path

      provider = Keyword.get(opts, :path_provider) ->
        case provider.get_path(:aliases_file) do
          {:ok, path} -> path
          {:error, _} -> default_aliases_path()
        end

      true ->
        default_aliases_path()
    end
  end

  defp default_aliases_path do
    Path.expand("~/.config/ex_alias/aliases.json")
  end
end