# AGENTS.md - JidoLiveDashboard

## Project Overview

JidoLiveDashboard provides real-time monitoring and debugging tools for the Jido ecosystem, built on Phoenix LiveView and LiveDashboard.

## Common Commands

```bash
mix test                  # Run tests
mix quality               # Run all quality checks
mix format                # Format code
mix docs                  # Generate documentation
mix coveralls.html        # Generate coverage report
```

## Project Structure

```
jido_live_dashboard/
├── lib/
│   ├── jido_live_dashboard.ex           # Main module
│   └── jido_live_dashboard/
│       ├── application.ex               # Application supervision
│       └── pages/                        # LiveDashboard pages
│           ├── home.ex                   # Home page
│           ├── agents.ex                 # Agents monitoring
│           └── actions.ex                # Actions monitoring
├── test/
│   ├── support/                          # Test helpers
│   └── jido_live_dashboard_test.exs
└── config/
    ├── config.exs
    ├── dev.exs
    └── test.exs
```

## Code Style

- Follow standard Elixir conventions
- Use `@moduledoc` for all public modules
- Use `@doc` for all public functions
- Keep line length to 120 characters

## Testing

- Tests are in `test/` directory
- Test helpers go in `test/support/`
- Run `mix test` to execute tests

## Git Commit Guidelines

- Use conventional commit format: `type(scope): description`
- Never add "ampcode" as a contributor
