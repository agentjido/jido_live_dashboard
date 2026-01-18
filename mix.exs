defmodule JidoLiveDashboard.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/agentjido/jido_live_dashboard"
  @description "Live dashboard for monitoring Jido ecosystem in real-time"

  def vsn do
    @version
  end

  def project do
    [
      app: :jido_live_dashboard,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Docs
      name: "Jido Live Dashboard",
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),

      # Dialyzer
      dialyzer: [
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {JidoLiveDashboard.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      api_reference: false,
      source_ref: "v#{@version}",
      source_url: @source_url,
      authors: ["Mike Hostetler <mike.hostetler@gmail.com>"],
      extras: [
        {"README.md", title: "Home"},
        {"CHANGELOG.md", title: "Changelog"},
        {"LICENSE", title: "Apache 2.0 License"}
      ],
      extra_section: "Guides",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Mike Hostetler"],
      licenses: ["Apache-2.0"],
      links: %{
        "Documentation" => "https://hexdocs.pm/jido_live_dashboard",
        "GitHub" => @source_url,
        "Website" => "https://agentjido.xyz"
      }
    ]
  end

  defp jido_dep(app, rel_path, hex_req, extra_opts \\ []) do
    path = Path.expand(rel_path, __DIR__)

    if File.dir?(path) and File.exists?(Path.join(path, "mix.exs")) do
      {app, Keyword.merge([path: rel_path, override: true], extra_opts)}
    else
      {app, hex_req, extra_opts}
    end
    |> case do
      {app, opts} when is_list(opts) -> {app, opts}
      {app, req, opts} -> {app, req, opts}
    end
  end

  defp deps do
    [
      jido_dep(:jido, "../jido", "~> 1.0"),
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:telemetry_metrics, "~> 1.1"},
      {:jason, "~> 1.4"},

      # Development & Test Dependencies
      {:git_ops, "~> 2.9", only: :dev, runtime: false},
      {:git_hooks, "~> 0.8", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.21", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.3", only: [:dev, :test]},
      {:expublish, "~> 2.7", only: [:dev], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test",
      q: ["quality"],
      quality: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --min-priority higher",
        "doctor --raise",
        "dialyzer"
      ]
    ]
  end
end
