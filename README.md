# JidoLiveDashboard

Real-time monitoring and debugging tools for the [Jido](https://github.com/agentjido/jido) agent ecosystem, built on Phoenix LiveView and LiveDashboard.

## Features

- **Discovery** - Browse discovered Actions, Agents, Skills, Sensors, and Demos from your catalog
- **Runtime** - Monitor live AgentServer processes, WorkerPools, and InstanceManagers
- **Traces** - View telemetry events with trace_id/span_id correlation for debugging signal flows
- **Overview** - System health dashboard with component counts and buffer statistics

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:jido_live_dashboard, "~> 0.1.0"}
  ]
end
```

## Usage

### Quick Setup

Add all Jido pages to your Phoenix router:

```elixir
import Phoenix.LiveDashboard.Router

scope "/" do
  pipe_through :browser
  live_dashboard "/dashboard",
    additional_pages: JidoLiveDashboard.pages()
end
```

### Individual Pages

Or add specific pages:

```elixir
live_dashboard "/dashboard",
  additional_pages: [
    jido: JidoLiveDashboard.Pages.Home,
    jido_discovery: JidoLiveDashboard.Pages.Discovery,
    jido_runtime: JidoLiveDashboard.Pages.Runtime,
    jido_traces: JidoLiveDashboard.Pages.Traces
  ]
```

## Configuration

Optional configuration for enhanced runtime monitoring:

```elixir
config :jido_live_dashboard,
  # Max events in trace buffer (default: 500)
  trace_buffer_size: 1000,
  
  # Runtime introspection config
  runtime: [
    # Jido instances to monitor
    instances: [MyApp.Jido],
    
    # Worker pools per instance
    worker_pools: %{
      MyApp.Jido => [:fast_search, :planner]
    },
    
    # Instance managers to monitor
    instance_managers: [:sessions, :rooms]
  ]
```

## Pages

### Home (Overview)

The home page provides a quick system health overview:

- Jido runtime status
- Discovery catalog component counts
- Running AgentServer count
- Trace buffer statistics

### Discovery

Browse the Jido.Discovery catalog:

- Filter by component type (Actions, Agents, Skills, Sensors, Demos)
- View metadata including name, module, category, tags, and description
- Catalog refresh timestamp

### Runtime

Monitor live Jido processes:

- **AgentServers** - All running agent processes with PID, ID, module, and status
- **WorkerPools** - Pool status showing available/checked-out workers (requires config)
- **InstanceManagers** - Keyed singleton registries with active counts (requires config)

### Traces

Debug signal flows with telemetry event logging:

- Recent events table with time, event type, agent ID, and duration
- Filter by trace_id to see correlated events
- Drill into trace details to see span hierarchy
- Clear buffer functionality

## Telemetry Events

The TraceBuffer automatically captures these Jido telemetry events:

- `[:jido, :agent_server, :signal, :start|:stop|:exception]`
- `[:jido, :agent_server, :directive, :start|:stop|:exception]`
- `[:jido, :agent, :cmd, :start|:stop|:exception]`
- `[:jido, :agent, :strategy, :init|:cmd, :start|:stop]`

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.
