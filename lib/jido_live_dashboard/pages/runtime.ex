defmodule JidoLiveDashboard.Pages.Runtime do
  @moduledoc """
  Runtime page for monitoring live Jido processes.

  Displays running AgentServer processes, WorkerPool status,
  and InstanceManager statistics.
  """

  use Phoenix.LiveDashboard.PageBuilder

  alias JidoLiveDashboard.Runtime

  @impl true
  def menu_link(_session, _opts) do
    {:ok, "Runtime"}
  end

  @impl true
  def render(assigns) do
    jido_running = Runtime.jido_running?()
    {:ok, agents} = Runtime.list_agent_servers()
    supervisor_info = get_supervisor_info()

    # Get configured pools and managers from application config
    config = Application.get_env(:jido_live_dashboard, :runtime, [])
    instances = Keyword.get(config, :instances, [])
    pool_config = Keyword.get(config, :worker_pools, %{})
    manager_names = Keyword.get(config, :instance_managers, [])

    pools = get_pools(instances, pool_config)
    managers = get_managers(manager_names)

    assigns =
      assigns
      |> Map.put(:jido_running, jido_running)
      |> Map.put(:agents, agents)
      |> Map.put(:supervisor_info, supervisor_info)
      |> Map.put(:pools, pools)
      |> Map.put(:managers, managers)
      |> Map.put(:selected_agent, nil)

    ~H"""
    <div class="phx-dashboard-header">
      <h1>Jido Runtime</h1>
      <p class="text-gray-600">Monitor live Jido processes</p>
    </div>

    <!-- Status Banner -->
    <div class={"px-4 py-2 text-sm #{if @jido_running, do: "bg-green-50 text-green-700", else: "bg-red-50 text-red-700"}"}>
      <%= if @jido_running do %>
        ✓ Jido runtime is active
        <%= if @supervisor_info do %>
          <span class="mx-2">|</span>
          Supervisor: <%= @supervisor_info.child_count %> children
        <% end %>
      <% else %>
        ✗ Jido runtime is not running. Start Jido in your application supervisor.
      <% end %>
    </div>

    <div class="p-4 space-y-6">
      <!-- Agent Servers Section -->
      <div class="bg-white shadow rounded-lg overflow-hidden">
        <div class="px-4 py-3 bg-gray-50 border-b">
          <h2 class="text-lg font-semibold">AgentServer Processes</h2>
          <p class="text-sm text-gray-500">Running agent instances managed by Jido.AgentSupervisor</p>
        </div>

        <%= if length(@agents) > 0 do %>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">PID</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Module</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for agent <- @agents do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 whitespace-nowrap">
                    <code class="text-xs bg-gray-100 px-1 py-0.5 rounded"><%= inspect(agent.pid) %></code>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-900">
                    <%= agent.id || "—" %>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                    <%= if agent.module, do: inspect(agent.module), else: "—" %>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <%= if agent.alive do %>
                      <span class="inline-block bg-green-100 text-green-800 text-xs px-2 py-0.5 rounded">
                        alive
                      </span>
                    <% else %>
                      <span class="inline-block bg-red-100 text-red-800 text-xs px-2 py-0.5 rounded">
                        dead
                      </span>
                    <% end %>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm">
                    <button
                      phx-click="inspect_agent"
                      phx-value-pid={inspect(agent.pid)}
                      class="text-blue-600 hover:text-blue-800"
                    >
                      Inspect
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% else %>
          <div class="p-8 text-center text-gray-500">
            <p>No AgentServer processes running.</p>
            <p class="text-sm mt-1">Start agents with <code class="bg-gray-100 px-1">Jido.AgentServer.start/1</code></p>
          </div>
        <% end %>
      </div>

      <!-- Worker Pools Section -->
      <%= if length(@pools) > 0 do %>
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <div class="px-4 py-3 bg-gray-50 border-b">
            <h2 class="text-lg font-semibold">Worker Pools</h2>
            <p class="text-sm text-gray-500">Poolboy-managed agent pools</p>
          </div>

          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Pool</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">State</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Available</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Checked Out</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Overflow</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for pool <- @pools do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 whitespace-nowrap font-medium text-gray-900">
                    <%= pool.name %>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <span class={"inline-block text-xs px-2 py-0.5 rounded #{pool_state_class(pool.state)}"}>
                      <%= pool.state %>
                    </span>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                    <%= pool.available %>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                    <%= pool.checked_out %>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                    <%= pool.overflow %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>

      <!-- Instance Managers Section -->
      <%= if length(@managers) > 0 do %>
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <div class="px-4 py-3 bg-gray-50 border-b">
            <h2 class="text-lg font-semibold">Instance Managers</h2>
            <p class="text-sm text-gray-500">Keyed singleton registries</p>
          </div>

          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Manager</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Active Instances</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sample Keys</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for manager <- @managers do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 whitespace-nowrap font-medium text-gray-900">
                    <%= manager.name %>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm">
                    <span class="font-semibold text-blue-600"><%= manager.count %></span>
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-500">
                    <%= if length(manager.keys) > 0 do %>
                      <%= manager.keys |> Enum.take(3) |> Enum.map(&inspect/1) |> Enum.join(", ") %>
                      <%= if length(manager.keys) > 3, do: "..." %>
                    <% else %>
                      <span class="text-gray-400">—</span>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>

      <!-- Configuration Help -->
      <%= if length(@pools) == 0 and length(@managers) == 0 do %>
        <div class="bg-blue-50 rounded-lg p-4">
          <h3 class="text-sm font-semibold text-blue-800">Configuration</h3>
          <p class="text-sm text-blue-600 mt-1">
            To display WorkerPools and InstanceManagers, add configuration:
          </p>
          <pre class="mt-2 text-xs bg-blue-100 p-2 rounded overflow-x-auto"><code><%= config_example() %></code></pre>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_supervisor_info do
    case Runtime.supervisor_info(Jido.AgentSupervisor) do
      {:ok, info} -> info
      {:error, _} -> nil
    end
  end

  defp get_pools(instances, pool_config) when map_size(pool_config) > 0 do
    Enum.flat_map(instances, fn instance ->
      pool_names = Map.get(pool_config, instance, [])

      case Runtime.list_worker_pools(instance, pool_names) do
        {:ok, pools} -> pools
        _ -> []
      end
    end)
  end

  defp get_pools(_, _), do: []

  defp get_managers(manager_names) when length(manager_names) > 0 do
    case Runtime.list_instance_managers(manager_names) do
      {:ok, managers} -> managers
      _ -> []
    end
  end

  defp get_managers(_), do: []

  defp pool_state_class(:ready), do: "bg-green-100 text-green-800"
  defp pool_state_class(:full), do: "bg-yellow-100 text-yellow-800"
  defp pool_state_class(:overflow), do: "bg-orange-100 text-orange-800"
  defp pool_state_class(:error), do: "bg-red-100 text-red-800"
  defp pool_state_class(_), do: "bg-gray-100 text-gray-800"

  defp config_example do
    """
    config :jido_live_dashboard, :runtime,
      instances: [MyApp.Jido],
      worker_pools: %{MyApp.Jido => [:fast_search, :planner]},
      instance_managers: [:sessions, :rooms]
    """
  end
end
