defmodule TelemetryMetricsTelegraf.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemetry_metrics_telegraf,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      preferred_cli_env: [check: :test],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      check: [
        "compile --force --warnings-as-errors",
        "format --check-formatted",
        "test --trace",
        "credo --strict"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry_metrics, "~> 0.4"},
      {:hammox, "~> 0.2", only: [:test]},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
