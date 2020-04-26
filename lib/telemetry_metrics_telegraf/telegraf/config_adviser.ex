defmodule TelemetryMetricsTelegraf.Telegraf.ConfigAdviser do
  @moduledoc """
  Generates telegraf aggregators config from `Telemetry.Metrics` definitions.
  """

  alias TelemetryMetricsTelegraf.Telegraf.ConfigTemplates
  alias TelemetryMetricsTelegraf.Utils

  @spec config_for([Telemetry.Metrics.t()], keyword()) :: String.t()
  def config_for(metrics, opts) do
    metrics
    |> Enum.group_by(fn m -> m.__struct__ end)
    |> Enum.flat_map(fn {metric_type, metrics} -> render_group(metric_type, metrics, opts) end)
    |> Enum.join("\n")
  end

  defp render_group(Telemetry.Metrics.Summary, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.basicstats_aggeregator({period, measurements}, [])
    end
  end

  defp render_group(Telemetry.Metrics.Counter, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.basicstats_aggeregator({period, measurements}, stats: [:count])
    end
  end

  defp render_group(Telemetry.Metrics.Sum, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.basicstats_aggeregator({period, measurements}, stats: [:sum])
    end
  end

  defp render_group(Telemetry.Metrics.LastValue, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.final_aggeregator({period, measurements}, [])
    end
  end

  defp render_group(Telemetry.Metrics.Distribution, metrics, opts) do
    default_period = Keyword.get(opts, :period, "30s")

    metrics
    |> Enum.group_by(&Keyword.get(&1.reporter_options, :period, default_period))
    |> Enum.map(fn {period, metrics} ->
      measurements_with_buckets =
        metrics
        |> Enum.map(&{Utils.measurement_name(&1), &1.buckets})
        |> Enum.uniq()

      ConfigTemplates.histogram_aggregator(period, measurements_with_buckets, opts)
    end)
  end

  defp render_group(metric_type, metrics, opts) do
    ConfigTemplates.unknown_metric_type(metric_type, metrics, opts)
  end

  defp group_measurements_by_period(metrics, opts) do
    default_period = Keyword.get(opts, :period, "30s")

    metrics
    |> Enum.group_by(&Keyword.get(&1.reporter_options, :period, default_period))
    |> Enum.into(%{}, fn {period, metrics} ->
      measurements = metrics |> Enum.map(&Utils.measurement_name/1) |> Enum.uniq()

      {period, measurements}
    end)
  end
end
