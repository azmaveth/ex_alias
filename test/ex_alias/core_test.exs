defmodule ExAlias.CoreTest do
  use ExUnit.Case
  doctest ExAlias.Core

  alias ExAlias.Core

  setup do
    # Start with empty aliases
    {:ok, aliases: %{}}
  end

  describe "define_alias/3" do
    test "defines a simple alias", %{aliases: aliases} do
      assert {:ok, aliases} = Core.define_alias(aliases, "gs", ["git", "status"])
      assert aliases == %{"gs" => ["git", "status"]}
    end

    test "overwrites existing alias", %{aliases: aliases} do
      {:ok, aliases} = Core.define_alias(aliases, "gs", ["git", "status"])
      assert {:ok, aliases} = Core.define_alias(aliases, "gs", ["git", "status", "-s"])
      assert aliases == %{"gs" => ["git", "status", "-s"]}
    end

    test "validates empty name", %{aliases: aliases} do
      assert {:error, {:validation_error, {:name, "cannot be empty"}}} = 
        Core.define_alias(aliases, "", ["echo"])
    end

    test "validates name with spaces", %{aliases: aliases} do
      assert {:error, {:validation_error, {:name, "cannot contain spaces"}}} = 
        Core.define_alias(aliases, "my alias", ["echo"])
    end

    test "validates reserved commands", %{aliases: aliases} do
      reserved = ["help", "clear", "exit", "quit", "alias", "config"]
      
      for cmd <- reserved do
        assert {:error, {:validation_error, {:name, _}}} = 
          Core.define_alias(aliases, cmd, ["echo"])
      end
    end

    test "validates empty commands", %{aliases: aliases} do
      assert {:error, {:validation_error, {:commands, "cannot be empty"}}} = 
        Core.define_alias(aliases, "empty", [])
    end

    test "validates non-string commands", %{aliases: aliases} do
      assert {:error, {:validation_error, {:commands, "must all be strings"}}} = 
        Core.define_alias(aliases, "bad", ["echo", 123])
    end
  end

  describe "remove_alias/2" do
    test "removes existing alias" do
      aliases = %{"gs" => ["git", "status"], "gp" => ["git", "push"]}
      assert {:ok, aliases} = Core.remove_alias(aliases, "gs")
      assert aliases == %{"gp" => ["git", "push"]}
    end

    test "returns error for non-existent alias", %{aliases: aliases} do
      assert {:error, :not_found} = Core.remove_alias(aliases, "nonexistent")
    end
  end

  describe "get_alias/2" do
    test "gets existing alias" do
      aliases = %{"gs" => ["git", "status"]}
      assert {:ok, ["git", "status"]} = Core.get_alias(aliases, "gs")
    end

    test "returns error for non-existent alias", %{aliases: aliases} do
      assert {:error, :not_found} = Core.get_alias(aliases, "nonexistent")
    end
  end

  describe "list_aliases/1" do
    test "returns all aliases" do
      aliases = %{"gs" => ["git", "status"], "gp" => ["git", "push"]}
      assert Core.list_aliases(aliases) == aliases
    end

    test "returns empty map when no aliases", %{aliases: aliases} do
      assert Core.list_aliases(aliases) == %{}
    end
  end

  describe "expand_alias/2" do
    test "expands simple alias" do
      aliases = %{"gs" => ["git", "status"]}
      assert {:ok, ["git", "status"]} = Core.expand_alias(aliases, "gs")
    end

    test "expands nested aliases" do
      aliases = %{
        "g" => ["git"],
        "gs" => ["g", "status"],
        "gss" => ["gs", "-s"]
      }
      assert {:ok, ["git", "status", "-s"]} = Core.expand_alias(aliases, "gss")
    end

    test "expands with arguments preserved" do
      aliases = %{
        "gc" => ["git", "commit"],
        "gcm" => ["gc", "-m"]
      }
      assert {:ok, ["git", "commit", "-m"]} = Core.expand_alias(aliases, "gcm")
    end

    test "handles arguments passed to aliases" do
      aliases = %{
        "g" => ["git"],
        "gs" => ["g status"]
      }
      assert {:ok, ["git status"]} = Core.expand_alias(aliases, "gs")
    end

    test "stops expansion on circular reference" do
      aliases = %{
        "a" => ["b"],
        "b" => ["c"],
        "c" => ["a"]
      }
      assert {:ok, ["a"]} = Core.expand_alias(aliases, "a")
    end

    test "handles self-referencing alias" do
      aliases = %{"loop" => ["loop"]}
      assert {:ok, ["loop"]} = Core.expand_alias(aliases, "loop")
    end

    test "expands complex command sequences" do
      aliases = %{
        "pull" => ["git", "pull"],
        "deps" => ["mix", "deps.get"],
        "test" => ["mix", "test"],
        "deploy" => ["pull", "deps", "test"]
      }
      assert {:ok, ["git", "pull", "mix", "deps.get", "mix", "test"]} = 
        Core.expand_alias(aliases, "deploy")
    end

    test "returns error for undefined alias", %{aliases: aliases} do
      assert {:error, :not_found} = Core.expand_alias(aliases, "undefined")
    end
  end

  describe "is_alias?/2" do
    test "returns true for existing alias" do
      aliases = %{"gs" => ["git", "status"]}
      assert Core.is_alias?(aliases, "gs")
    end

    test "returns false for non-existent alias", %{aliases: aliases} do
      refute Core.is_alias?(aliases, "nonexistent")
    end
  end

  describe "load_aliases/1 and save_aliases/2" do
    test "saves and loads aliases" do
      tmp_dir = System.tmp_dir!()
      path = Path.join(tmp_dir, "test_aliases_#{:os.system_time()}.json")
      
      aliases = %{"gs" => ["git", "status"], "gp" => ["git", "push"]}
      assert :ok = Core.save_aliases(aliases, path)
      
      loaded = Core.load_aliases(path)
      assert loaded == aliases
      
      # Cleanup
      File.rm!(path)
    end

    test "loads empty map for non-existent file" do
      path = "/tmp/definitely_does_not_exist_#{:os.system_time()}.json"
      assert Core.load_aliases(path) == %{}
    end

    test "loads empty map for invalid JSON" do
      tmp_dir = System.tmp_dir!()
      path = Path.join(tmp_dir, "invalid_#{:os.system_time()}.json")
      File.write!(path, "not json")
      
      assert Core.load_aliases(path) == %{}
      
      # Cleanup
      File.rm!(path)
    end

    test "creates directory when saving" do
      tmp_dir = System.tmp_dir!()
      nested_dir = Path.join([tmp_dir, "ex_alias_test_#{:os.system_time()}", "nested"])
      path = Path.join(nested_dir, "aliases.json")
      
      aliases = %{"test" => ["echo"]}
      assert :ok = Core.save_aliases(aliases, path)
      assert File.exists?(path)
      
      # Cleanup
      File.rm_rf!(Path.dirname(nested_dir))
    end
  end
end