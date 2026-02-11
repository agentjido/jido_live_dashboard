defmodule JidoLiveDashboard do
  @moduledoc """
  JidoLiveDashboard provides real-time monitoring and debugging tools for the Jido ecosystem.

  It integrates with Phoenix LiveView and LiveDashboard to provide custom pages for monitoring
  Jido agents, actions, and execution state.

  ## Features

  - **Discovery** - Browse discovered Actions, Agents, Plugins, and Sensors
  - **Runtime** - Monitor live AgentServer processes and pool status
  - **Traces** - View telemetry events and trace correlation for debugging

  ## Installation

  Add to your `mix.exs`:

      {:jido_live_dashboard, "~> 0.1.0"}

  ## Usage

  Add to your Phoenix router:

      import Phoenix.LiveDashboard.Router

      scope "/" do
        pipe_through :browser
        live_dashboard "/dashboard",
          additional_pages: JidoLiveDashboard.pages()
      end

  Or add individual pages:

      live_dashboard "/dashboard",
        additional_pages: [
          jido: JidoLiveDashboard.Pages.Home,
          jido_discovery: JidoLiveDashboard.Pages.Discovery,
          jido_runtime: JidoLiveDashboard.Pages.Runtime,
          jido_traces: JidoLiveDashboard.Pages.Traces
        ]

  ## Configuration

  Optional configuration for runtime introspection:

      config :jido_live_dashboard,
        trace_buffer_size: 500,  # Max events in trace buffer
        runtime: [
          instances: [MyApp.Jido],  # Jido instances to monitor
          worker_pools: %{MyApp.Jido => [:fast_search, :planner]},
          instance_managers: [:sessions, :rooms]
        ]
  """

  @doc """
  Returns all dashboard pages for easy integration.

  ## Example

      live_dashboard "/dashboard",
        additional_pages: JidoLiveDashboard.pages()
  """
  @spec pages() :: keyword()
  def pages do
    [
      jido: JidoLiveDashboard.Pages.Home,
      jido_discovery: JidoLiveDashboard.Pages.Discovery,
      jido_runtime: JidoLiveDashboard.Pages.Runtime,
      jido_traces: JidoLiveDashboard.Pages.Traces
    ]
  end

  @doc """
  Get the version of JidoLiveDashboard.
  """
  @spec version() :: String.t()
  def version do
    "0.1.0"
  end
end
