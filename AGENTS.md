# AGENTS.md - JidoLiveDashboard

## Project Overview

JidoLiveDashboard provides real-time monitoring and debugging tools for the Jido ecosystem, built on Phoenix LiveView and LiveDashboard.

## Common Commands

```bash
mix test                  # Run tests
mix compile --warnings-as-errors  # Compile with strict warnings
mix format                # Format code
mix credo --min-priority higher  # Lint code
mix docs                  # Generate documentation
```

## Project Structure

```
jido_live_dashboard/
├── lib/
│   ├── jido_live_dashboard.ex           # Main module, pages() helper
│   └── jido_live_dashboard/
│       ├── application.ex               # Application supervision (starts TraceBuffer)
│       ├── runtime.ex                   # Runtime introspection (agents, pools, managers)
│       ├── trace_buffer.ex              # ETS ring buffer for telemetry events
│       └── pages/                       # LiveDashboard pages
│           ├── home.ex                  # Overview page
│           ├── discovery.ex             # Discovery catalog browser
│           ├── runtime.ex               # Live process monitoring
│           └── traces.ex                # Telemetry event viewer
├── test/
│   ├── support/                         # Test helpers
│   ├── jido_live_dashboard_test.exs
│   └── jido_live_dashboard/
│       ├── trace_buffer_test.exs
│       └── runtime_test.exs
└── config/
    ├── config.exs
    ├── dev.exs
    └── test.exs
```

## Architecture

### Pages

| Page | Purpose | Data Source |
|------|---------|-------------|
| Home | System overview | Discovery + Runtime + TraceBuffer |
| Discovery | Browse catalog | `Jido.Discovery` |
| Runtime | Live processes | `DynamicSupervisor`, `Jido.AgentServer` |
| Traces | Telemetry events | `JidoLiveDashboard.TraceBuffer` |

### Key Modules

- **TraceBuffer** - GenServer with ETS ring buffer that attaches to Jido telemetry events
- **Runtime** - Introspection helpers for querying Jido infrastructure
- **Pages** - Phoenix.LiveDashboard.PageBuilder implementations

## Code Style

- Follow standard Elixir conventions
- Use `@moduledoc` for all public modules
- Use `@doc` and `@spec` for all public functions
- Handle errors gracefully - supervisors/processes may not exist
- Use HEEx templates for page rendering

## Testing

- Tests are in `test/` directory
- Test helpers go in `test/support/`
- TraceBuffer tests use `async: false` (shared ETS table)
- Runtime tests handle missing Jido infrastructure gracefully

## Git Commit Guidelines

- Use conventional commit format: `type(scope): description`
- Never add "ampcode" as a contributor
