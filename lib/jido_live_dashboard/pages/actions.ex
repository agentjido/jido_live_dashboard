defmodule JidoLiveDashboard.Pages.Actions do
  @moduledoc """
  Dashboard page for monitoring Jido action executions.

  Displays execution metrics, performance data, and action statistics.
  """

  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_session, _opts) do
    {:ok, "Actions"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="phx-dashboard-header">
      <h1>Jido Actions</h1>
      <p class="text-gray-600">Monitor action executions and performance</p>
    </div>

    <div class="bg-white rounded-lg shadow p-6 m-4">
      <p class="text-gray-600">
        Action execution monitoring coming soon. This page will display:
      </p>
      <ul class="list-disc list-inside mt-4 space-y-2 text-gray-600">
        <li>Recent action executions</li>
        <li>Success/failure rates</li>
        <li>Execution time metrics</li>
        <li>Error tracking and analysis</li>
        <li>Performance graphs</li>
      </ul>
    </div>
    """
  end
end
