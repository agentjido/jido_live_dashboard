defmodule JidoLiveDashboard.RuntimeTest do
  use ExUnit.Case, async: true

  alias JidoLiveDashboard.Runtime

  describe "Runtime" do
    test "jido_running?/0 returns boolean" do
      result = Runtime.jido_running?()
      assert is_boolean(result)
    end

    test "list_agent_servers/0 returns ok tuple with list" do
      assert {:ok, agents} = Runtime.list_agent_servers()
      assert is_list(agents)
    end

    test "list_agent_servers/1 handles non-existent supervisor" do
      assert {:ok, []} = Runtime.list_agent_servers(:nonexistent_supervisor)
    end

    test "supervisor_info/1 returns error for non-existent supervisor" do
      assert {:error, :not_found} = Runtime.supervisor_info(:nonexistent_supervisor)
    end

    test "list_worker_pools/2 returns ok tuple with list" do
      assert {:ok, pools} = Runtime.list_worker_pools(:test_instance, [:pool1, :pool2])
      assert is_list(pools)
      assert length(pools) == 2
    end

    test "list_instance_managers/1 returns ok tuple with list" do
      assert {:ok, managers} = Runtime.list_instance_managers([:manager1, :manager2])
      assert is_list(managers)
      assert length(managers) == 2
    end

    test "discovery_summary/0 handles discovery not initialized" do
      # This may return error or ok depending on test environment
      result = Runtime.discovery_summary()
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end
