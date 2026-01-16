defmodule JidoLiveDashboard.Pages.Agents do
  @moduledoc """
  Dashboard page for monitoring Jido agents.

  Displays active agents, their state, and execution metrics.
  """

  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_session, _opts) do
    {:ok, "Agents"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="phx-dashboard-header">
      <h1>Jido Agents</h1>
      <p class="text-gray-600">Monitor active agents and their state</p>
    </div>

    <div class="bg-white rounded-lg shadow p-6 m-4">
      <p class="text-gray-600">
        Agent monitoring coming soon. This page will display:
      </p>
      <ul class="list-disc list-inside mt-4 space-y-2 text-gray-600">
        <li>Active agent processes</li>
        <li>Agent lifecycle state</li>
        <li>Memory usage per agent</li>
        <li>Current action execution</li>
        <li>Agent configuration</li>
      </ul>
    </div>
    """
  end
end
