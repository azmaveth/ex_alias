defmodule ExAliasTest do
  use ExUnit.Case

  setup do
    # Create a temporary directory for test files
    tmp_dir = System.tmp_dir!()
    test_dir = Path.join(tmp_dir, "ex_alias_test_#{:os.system_time(:nanosecond)}")
    File.mkdir_p!(test_dir)
    aliases_path = Path.join(test_dir, "aliases.json")

    # Stop any existing ExAlias process
    case Process.whereis(ExAlias) do
      nil -> :ok
      pid -> GenServer.stop(pid, :normal, 100)
    end

    # Start the GenServer with default name
    {:ok, pid} = ExAlias.start_link(path: aliases_path)

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
      File.rm_rf!(test_dir)
    end)

    {:ok, pid: pid, path: aliases_path}
  end

  describe "define_alias/2" do
    test "defines a simple alias" do
      assert :ok = ExAlias.define_alias("gs", ["git", "status"])
      assert {:ok, ["git", "status"]} = ExAlias.get_alias("gs")
    end

    test "defines an alias with multiple commands" do
      assert :ok = ExAlias.define_alias("deploy", ["git pull", "mix deps.get", "mix test"])
      assert {:ok, ["git pull", "mix deps.get", "mix test"]} = ExAlias.get_alias("deploy")
    end

    test "returns error for empty name" do
      assert {:error, {:validation_error, {:name, "cannot be empty"}}} = 
        ExAlias.define_alias("", ["echo"])
    end

    test "returns error for name with spaces" do
      assert {:error, {:validation_error, {:name, "cannot contain spaces"}}} = 
        ExAlias.define_alias("my alias", ["echo"])
    end

    test "returns error for reserved command" do
      assert {:error, {:validation_error, {:name, "cannot override built-in command 'help'"}}} = 
        ExAlias.define_alias("help", ["echo"])
    end

    test "returns error for empty commands" do
      assert {:error, {:validation_error, {:commands, "cannot be empty"}}} = 
        ExAlias.define_alias("empty", [])
    end

    test "returns error for non-string commands" do
      assert {:error, {:validation_error, {:commands, "must all be strings"}}} = 
        ExAlias.define_alias("bad", ["echo", 123])
    end
  end

  describe "remove_alias/1" do
    test "removes an existing alias" do
      :ok = ExAlias.define_alias("temp", ["echo", "temp"])
      assert :ok = ExAlias.remove_alias("temp")
      assert {:error, :not_found} = ExAlias.get_alias("temp")
    end

    test "returns error when alias doesn't exist" do
      assert {:error, :not_found} = ExAlias.remove_alias("nonexistent")
    end
  end

  describe "list_aliases/0" do
    test "returns empty list when no aliases defined" do
      assert [] = ExAlias.list_aliases()
    end

    test "returns sorted list of aliases" do
      :ok = ExAlias.define_alias("zz", ["sleep"])
      :ok = ExAlias.define_alias("aa", ["echo", "first"])
      :ok = ExAlias.define_alias("mm", ["echo", "middle"])

      aliases = ExAlias.list_aliases()
      assert length(aliases) == 3
      assert [%{name: "aa"}, %{name: "mm"}, %{name: "zz"}] = aliases
    end
  end

  describe "expand_alias/1" do
    test "expands simple alias" do
      :ok = ExAlias.define_alias("gs", ["git", "status"])
      assert {:ok, ["git", "status"]} = ExAlias.expand_alias("gs")
    end

    test "expands nested aliases" do
      :ok = ExAlias.define_alias("g", ["git"])
      :ok = ExAlias.define_alias("gs", ["g", "status"])
      assert {:ok, ["git", "status"]} = ExAlias.expand_alias("gs")
    end

    test "handles circular references" do
      :ok = ExAlias.define_alias("a", ["b"])
      :ok = ExAlias.define_alias("b", ["c"])
      :ok = ExAlias.define_alias("c", ["a"])
      
      assert {:ok, ["a"]} = ExAlias.expand_alias("a")
    end

    test "expands with arguments" do
      :ok = ExAlias.define_alias("gc", ["git", "commit"])
      :ok = ExAlias.define_alias("gcm", ["gc", "-m"])
      assert {:ok, ["git", "commit", "-m"]} = ExAlias.expand_alias("gcm")
    end

    test "returns error for undefined alias" do
      assert {:error, :not_found} = ExAlias.expand_alias("undefined")
    end
  end

  describe "is_alias?/1" do
    test "returns true for existing alias" do
      :ok = ExAlias.define_alias("test", ["echo"])
      assert ExAlias.is_alias?("test")
    end

    test "returns false for non-existent alias" do
      refute ExAlias.is_alias?("nonexistent")
    end
  end

  describe "persistence" do
    test "aliases persist after save", %{path: path} do
      :ok = ExAlias.define_alias("persist", ["echo", "saved"])
      ExAlias.save_aliases()
      
      # Give it time to save
      Process.sleep(100)
      
      # Load directly from file
      aliases = ExAlias.Core.load_aliases(path)
      assert {:ok, ["echo", "saved"]} = ExAlias.Core.get_alias(aliases, "persist")
    end
  end
end