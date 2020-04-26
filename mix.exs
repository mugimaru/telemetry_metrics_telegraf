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

  defp deps do
    [
      {:telemetry_metrics, "~> 0.4"},
      {:hammox, "~> 0.2", only: [:test]},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
