defmodule JidoLiveDashboard.Pages.Home do
  @moduledoc """
  Home page for Jido Live Dashboard.

  Provides an overview of the Jido ecosystem including:
  - System status (is Jido running?)
  - Discovery catalog summary
  - Runtime process counts
  - Trace buffer statistics
  """

  use Phoenix.LiveDashboard.PageBuilder

  alias JidoLiveDashboard.Runtime
  alias JidoLiveDashboard.TraceBuffer

  @impl true
  def menu_link(_session, _opts) do
    {:ok, "Jido"}
  end

  @impl true
  def render(assigns) do
    jido_running = Runtime.jido_running?()
    discovery = get_discovery_summary()
    agents = get_agent_count()
    traces = get_trace_stats()

    assigns =
      assigns
      |> Map.put(:jido_running, jido_running)
      |> Map.put(:discovery, discovery)
      |> Map.put(:agent_count, agents)
      |> Map.put(:traces, traces)

    ~H"""
    <div class="phx-dashboard-header">
      <h1>Jido Live Dashboard</h1>
      <p class="text-gray-600">Real-time monitoring for the Jido ecosystem</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 p-4">
      <!-- System Status -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">System Status</h2>
        <div class="space-y-2 text-sm">
          <div class="flex justify-between items-center">
            <span class="text-gray-600">Jido Runtime:</span>
            <%= if @jido_running do %>
              <span class="inline-block bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-semibold">
                Running
              </span>
            <% else %>
              <span class="inline-block bg-red-100 text-red-800 px-2 py-1 rounded text-xs font-semibold">
                Not Running
              </span>
            <% end %>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600">Dashboard:</span>
            <span class="font-mono text-xs"><%= JidoLiveDashboard.version() %></span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600">Node:</span>
            <span class="font-mono text-xs truncate max-w-[120px]"><%= node() %></span>
          </div>
        </div>
      </div>

      <!-- Discovery Summary -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Discovery Catalog</h2>
        <%= if @discovery do %>
          <div class="space-y-1 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600">Actions:</span>
              <span class="font-semibold"><%= @discovery.actions %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600">Agents:</span>
              <span class="font-semibold"><%= @discovery.agents %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600">Plugins:</span>
              <span class="font-semibold"><%= @discovery.plugins %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600">Sensors:</span>
              <span class="font-semibold"><%= @discovery.sensors %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600">Demos:</span>
              <span class="font-semibold"><%= @discovery.demos %></span>
            </div>
          </div>
        <% else %>
          <p class="text-gray-500 text-sm">Discovery not initialized</p>
        <% end %>
      </div>

      <!-- Runtime Agents -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Running Agents</h2>
        <div class="text-center">
          <span class="text-4xl font-bold text-blue-600"><%= @agent_count %></span>
          <p class="text-gray-600 text-sm mt-1">AgentServer processes</p>
        </div>
      </div>

      <!-- Trace Buffer -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Trace Buffer</h2>
        <div class="space-y-1 text-sm">
          <div class="flex justify-between">
            <span class="text-gray-600">Events:</span>
            <span class="font-semibold"><%= @traces.count %> / <%= @traces.max_size %></span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600">Unique Traces:</span>
            <span class="font-semibold"><%= @traces.trace_count %></span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600">Memory:</span>
            <span class="font-mono text-xs"><%= format_bytes(@traces.memory_bytes) %></span>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Links -->
    <div class="p-4">
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Dashboard Pages</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
          <div class="border rounded p-4">
            <h3 class="font-semibold text-blue-600">Discovery</h3>
            <p class="text-gray-600 mt-1">Browse Actions, Agents, Plugins, and Sensors in your catalog</p>
          </div>
          <div class="border rounded p-4">
            <h3 class="font-semibold text-blue-600">Runtime</h3>
            <p class="text-gray-600 mt-1">Monitor live AgentServer processes and pool status</p>
          </div>
          <div class="border rounded p-4">
            <h3 class="font-semibold text-blue-600">Traces</h3>
            <p class="text-gray-600 mt-1">View recent telemetry events and trace correlation</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_discovery_summary do
    case Runtime.discovery_summary() do
      {:ok, summary} -> summary
      {:error, _} -> nil
    end
  end

  defp get_agent_count do
    case Runtime.list_agent_servers() do
      {:ok, agents} -> length(agents)
      _ -> 0
    end
  end

  defp get_trace_stats do
    case TraceBuffer.stats() do
      {:ok, stats} -> stats
      _ -> %{count: 0, max_size: 0, trace_count: 0, memory_bytes: 0}
    end
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"
end
