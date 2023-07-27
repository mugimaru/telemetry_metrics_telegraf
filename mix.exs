defmodule TelemetryMetricsTelegraf.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemetry_metrics_telegraf,
      version: "0.4.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      preferred_cli_env: [check: :test],
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    case System.get_env("DIALYZER_PLT_FILE") do
      nil ->
        []

      file ->
        [plt_file: {:no_warn, file}]
    end
  end

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

  defp docs do
    [
      main: "TelemetryMetricsTelegraf",
      source_url: "https://github.com/mugimaru73/telemetry_metrics_telegraf",
      nest_modules_by_prefix: [
        TelemetryMetricsTelegraf.Adapters,
        TelemetryMetricsTelegraf.Telegraf
      ]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/mugimaru73/telemetry_metrics_telegraf"}
    ]
  end

  defp description do
    """
    Telemetry.Metrics telegraf reporter.
    """
  end

  defp deps do
    [
      {:telemetry_metrics, "~> 0.4 or ~> 1.0"},
      {:ex_doc, "~> 0.21", only: [:dev, :docs], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test, :dialyzer], runtime: false},
      {:hammox, "~> 0.2", only: [:test]},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:toml, "~> 0.6.1", only: [:dev, :test]}
    ]
  end
end
