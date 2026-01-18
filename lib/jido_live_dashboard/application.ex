defmodule JidoLiveDashboard.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JidoLiveDashboard.TraceBuffer
    ]

    opts = [strategy: :one_for_one, name: JidoLiveDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
