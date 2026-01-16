# JidoLiveDashboard Usage Rules

## Overview

JidoLiveDashboard provides real-time monitoring for the Jido ecosystem via Phoenix LiveDashboard.

## Installation

```elixir
def deps do
  [{:jido_live_dashboard, "~> 0.1.0"}]
end
```

## Router Configuration

```elixir
import Phoenix.LiveDashboard.Router

scope "/" do
  pipe_through :browser
  
  live_dashboard "/dashboard",
    additional_pages: [
      jido_home: JidoLiveDashboard.Pages.Home,
      jido_agents: JidoLiveDashboard.Pages.Agents,
      jido_actions: JidoLiveDashboard.Pages.Actions
    ]
end
```

## Available Pages

- `JidoLiveDashboard.Pages.Home` - System overview
- `JidoLiveDashboard.Pages.Agents` - Agent monitoring
- `JidoLiveDashboard.Pages.Actions` - Action execution metrics

## Best Practices

1. Add dashboard behind authentication in production
2. Use telemetry for custom metrics
3. Configure refresh intervals as needed
