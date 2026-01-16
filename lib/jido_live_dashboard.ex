defmodule JidoLiveDashboard do
  @moduledoc """
  JidoLiveDashboard provides real-time monitoring and debugging tools for the Jido ecosystem.

  It integrates with Phoenix LiveView and LiveDashboard to provide custom pages for monitoring
  Jido agents, actions, and execution state.

  ## Features

  - Monitor active agents and their state
  - Track action execution metrics
  - Real-time performance metrics
  - Custom dashboard pages for Jido-specific monitoring

  ## Installation

  Add to your `mix.exs`:

      {:jido_live_dashboard, "~> 0.1.0"}

  ## Usage

  Add to your Phoenix router:

      import Phoenix.LiveDashboard.Router

      scope "/" do
        pipe_through :browser
        live_dashboard "/dashboard",
          additional_pages: [
            jido_agents: JidoLiveDashboard.Pages.Agents,
            jido_actions: JidoLiveDashboard.Pages.Actions
          ]
      end
  """

  @doc """
  Get the version of JidoLiveDashboard.
  """
  @spec version() :: String.t()
  def version do
    "0.1.0"
  end
end
