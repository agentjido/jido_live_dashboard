# Contributing to JidoLiveDashboard

Thank you for your interest in contributing to JidoLiveDashboard!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Install dependencies: `mix deps.get`
4. Run tests: `mix test`
5. Run quality checks: `mix quality`

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Ensure all tests pass: `mix test`
4. Ensure quality checks pass: `mix quality`
5. Commit using conventional commit format
6. Push and create a pull request

## Commit Message Format

We use conventional commits:

```
type(scope): description

[optional body]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, no code change
- `refactor`: Code change, no fix or feature
- `perf`: Performance improvement
- `test`: Adding/fixing tests
- `chore`: Maintenance, deps, tooling

## Code Style

- Run `mix format` before committing
- Follow Elixir standard conventions
- Keep line length to 120 characters
- Add `@moduledoc` and `@doc` for public APIs

## Testing

- Add tests for new features
- Maintain test coverage above 80%
- Run `mix coveralls.html` to check coverage

## Questions?

Open an issue for any questions or concerns.
