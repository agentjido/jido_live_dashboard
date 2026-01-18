defmodule JidoLiveDashboard.Pages.Discovery do
  @moduledoc """
  Discovery page for browsing the Jido component catalog.

  Displays all discovered Actions, Agents, Skills, Sensors, and Demos
  from the Jido.Discovery catalog with filtering and detail views.
  """

  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_session, _opts) do
    {:ok, "Discovery"}
  end

  @impl true
  def render(assigns) do
    # Get filter from params or default to :actions
    component_type = get_component_type(assigns)
    components = list_components(component_type)
    catalog_info = get_catalog_info()

    assigns =
      assigns
      |> Map.put(:component_type, component_type)
      |> Map.put(:components, components)
      |> Map.put(:catalog_info, catalog_info)

    ~H"""
    <div class="phx-dashboard-header">
      <h1>Jido Discovery Catalog</h1>
      <p class="text-gray-600">Browse discovered components in your system</p>
    </div>

    <!-- Catalog Info -->
    <%= if @catalog_info do %>
      <div class="px-4 py-2 bg-gray-50 border-b text-sm text-gray-600">
        Last updated: <%= format_datetime(@catalog_info.last_updated) %>
        <span class="mx-2">|</span>
        Total components: <%= @catalog_info.total %>
      </div>
    <% end %>

    <!-- Type Tabs -->
    <div class="border-b border-gray-200 px-4">
      <nav class="flex space-x-4" aria-label="Tabs">
        <%= for {type, label, count} <- component_tabs(@catalog_info) do %>
          <button
            phx-click="nav"
            phx-value-type={type}
            class={"px-3 py-2 text-sm font-medium border-b-2 #{if @component_type == type, do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
          >
            <%= label %> (<%= count %>)
          </button>
        <% end %>
      </nav>
    </div>

    <!-- Components Table -->
    <div class="p-4">
      <%= if length(@components) > 0 do %>
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Module</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tags</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for component <- @components do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 whitespace-nowrap">
                    <span class="font-medium text-gray-900"><%= component[:name] || "—" %></span>
                    <span class="text-xs text-gray-400 ml-2"><%= component[:slug] %></span>
                  </td>
                  <td class="px-4 py-3">
                    <code class="text-xs bg-gray-100 px-1 py-0.5 rounded"><%= inspect(component[:module]) %></code>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                    <%= component[:category] || "—" %>
                  </td>
                  <td class="px-4 py-3">
                    <%= if component[:tags] && length(component[:tags]) > 0 do %>
                      <div class="flex flex-wrap gap-1">
                        <%= for tag <- component[:tags] do %>
                          <span class="inline-block bg-blue-100 text-blue-800 text-xs px-2 py-0.5 rounded">
                            <%= tag %>
                          </span>
                        <% end %>
                      </div>
                    <% else %>
                      <span class="text-gray-400">—</span>
                    <% end %>
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-500 max-w-md truncate">
                    <%= component[:description] || "—" %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% else %>
        <div class="bg-white shadow rounded-lg p-8 text-center">
          <p class="text-gray-500">No <%= @component_type %> found in the catalog.</p>
          <p class="text-sm text-gray-400 mt-2">
            Make sure Jido.Discovery is initialized and components are loaded.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_component_type(assigns) do
    case assigns[:params]["type"] do
      "agents" -> :agents
      "skills" -> :skills
      "sensors" -> :sensors
      "demos" -> :demos
      _ -> :actions
    end
  end

  defp list_components(type) do
    case type do
      :actions -> Jido.Discovery.list_actions()
      :agents -> Jido.Discovery.list_agents()
      :skills -> Jido.Discovery.list_skills()
      :sensors -> Jido.Discovery.list_sensors()
      :demos -> Jido.Discovery.list_demos()
    end
  rescue
    _ -> []
  end

  defp get_catalog_info do
    case Jido.Discovery.catalog() do
      {:ok, catalog} ->
        components = catalog.components

        %{
          last_updated: catalog.last_updated,
          total:
            length(Map.get(components, :actions, [])) +
              length(Map.get(components, :agents, [])) +
              length(Map.get(components, :skills, [])) +
              length(Map.get(components, :sensors, [])) +
              length(Map.get(components, :demos, [])),
          actions: length(Map.get(components, :actions, [])),
          agents: length(Map.get(components, :agents, [])),
          skills: length(Map.get(components, :skills, [])),
          sensors: length(Map.get(components, :sensors, [])),
          demos: length(Map.get(components, :demos, []))
        }

      {:error, _} ->
        nil
    end
  rescue
    _ -> nil
  end

  defp component_tabs(nil) do
    [
      {:actions, "Actions", 0},
      {:agents, "Agents", 0},
      {:skills, "Skills", 0},
      {:sensors, "Sensors", 0},
      {:demos, "Demos", 0}
    ]
  end

  defp component_tabs(info) do
    [
      {:actions, "Actions", info.actions},
      {:agents, "Agents", info.agents},
      {:skills, "Skills", info.skills},
      {:sensors, "Sensors", info.sensors},
      {:demos, "Demos", info.demos}
    ]
  end

  defp format_datetime(nil), do: "—"

  defp format_datetime(dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")
  end
end
