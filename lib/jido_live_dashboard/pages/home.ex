defmodule JidoLiveDashboard.Pages.Home do
  @moduledoc """
  Home page for Jido Live Dashboard.

  Provides an overview of the Jido ecosystem including system information,
  active agents, and recent action executions.
  """

  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_session, _opts) do
    {:ok, "Jido"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="phx-dashboard-header">
      <h1>Jido Live Dashboard</h1>
      <p class="text-gray-600">Real-time monitoring for the Jido ecosystem</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4">
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">System Info</h2>
        <div class="space-y-2 text-sm">
          <div>
            <span class="text-gray-600">Elixir Version:</span>
            <span class="font-mono"><%= System.version() %></span>
          </div>
          <div>
            <span class="text-gray-600">OTP Version:</span>
            <span class="font-mono"><%= :erlang.system_info(:otp_release) |> to_string() %></span>
          </div>
          <div>
            <span class="text-gray-600">Node:</span>
            <span class="font-mono"><%= node() %></span>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Dashboard Info</h2>
        <div class="space-y-2 text-sm">
          <div>
            <span class="text-gray-600">Version:</span>
            <span class="font-mono"><%= JidoLiveDashboard.version() %></span>
          </div>
          <div>
            <span class="text-gray-600">Status:</span>
            <span class="inline-block bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-semibold">
              Ready
            </span>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Available Pages</h2>
        <ul class="space-y-2 text-sm">
          <li>→ Dashboard Home</li>
          <li>→ Agents (coming soon)</li>
          <li>→ Actions (coming soon)</li>
        </ul>
      </div>
    </div>
    """
  end
end
