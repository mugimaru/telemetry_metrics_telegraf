defmodule TelemetryMetricsTelegraf.Telegraf.ConfigAdviser do
  @moduledoc """
  Generates telegraf aggregators config from `Telemetry.Metrics` definitions.

  * `Telemetry.Metrics.Distribution` - [histogram](https://github.com/influxdata/telegraf/tree/master/plugins/aggregators/histogram).
  * `Telemetry.Metrics.LastValue` - [final](https://github.com/influxdata/telegraf/tree/master/plugins/aggregators/final).
  * `Telemetry.Metrics.Summary` - [basicstats](https://github.com/influxdata/telegraf/tree/master/plugins/aggregators/basicstats). A list of stats can be configured via `:summary_stats` option.
  * `Telemetry.Metrics.Sum` - [basicstats](https://github.com/influxdata/telegraf/tree/master/plugins/aggregators/basicstats) with `stats = ["sum"]`.
  * `Telemetry.Metrics.Counter` - [basicstats](https://github.com/influxdata/telegraf/tree/master/plugins/aggregators/basicstats) with `stats = ["count"]`.

  ## Usage

      TelemetryMetricsTelegraf.Telegraf.ConfigAdviser.render(MyAppWeb.Telemetry.metrics(), [])
  """

  alias TelemetryMetricsTelegraf.Telegraf.ConfigTemplates

  import TelemetryMetricsTelegraf.AppConfig, only: [app_config: 0]

  import TelemetryMetricsTelegraf.Utils,
    only: [fetch_option!: 2, fetch_options!: 2, measurement_name: 1]

  @spec render([Telemetry.Metrics.t()], keyword()) :: String.t()
  @doc """
  Renders telegraf aggregations config from `Telemetry.Metrics` definitions list.

      TelemetryMetricsTelegraf.Telegraf.ConfigAdviser.render(MyAppWeb.Telemetry.metrics(), [])

  See `TelemetryMetricsTelegraf.AppConfig` for a list of supported options.
  """
  def render(metrics, opts) do
    metrics
    |> Enum.group_by(fn m -> m.__struct__ end)
    |> Enum.flat_map(fn {metric_type, metrics} -> render_group(metric_type, metrics, opts) end)
    |> Enum.join("\n")
  end

  defp render_group(Telemetry.Metrics.Summary, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.basicstats_aggeregator(measurements,
        period: period,
        stats: fetch_option!(:summary_stats, [opts, app_config()])
      )
    end
  end

  defp render_group(Telemetry.Metrics.Counter, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.basicstats_aggeregator(measurements, period: period, stats: [:count])
    end
  end

  defp render_group(Telemetry.Metrics.Sum, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.basicstats_aggeregator(measurements, period: period, stats: [:sum])
    end
  end

  defp render_group(Telemetry.Metrics.LastValue, metrics, opts) do
    for {period, measurements} <- group_measurements_by_period(metrics, opts) do
      ConfigTemplates.final_aggeregator(measurements, period: period)
    end
  end

  defp render_group(Telemetry.Metrics.Distribution, metrics, global_opts) do
    options_keys = [:period, :histogram_reset, :histogram_cumulative]

    metrics
    |> Enum.group_by(&Keyword.take(&1.reporter_options, options_keys))
    |> Enum.map(fn {repoter_opts, metrics} ->
      histogram_opts = fetch_options!(options_keys, [repoter_opts, global_opts, app_config()])

      metrics
      |> Enum.map(&{measurement_name(&1), distribution_metric_buckets(&1)})
      |> Enum.uniq()
      |> ConfigTemplates.histogram_aggregator(histogram_opts)
    end)
  end

  defp render_group(metric_type, metrics, opts) do
    ConfigTemplates.unknown_metric_type(metric_type, metrics, opts)
  end

  defp group_measurements_by_period(metrics, opts) do
    metrics
    |> Enum.group_by(&fetch_option!(:period, [&1.reporter_options, opts, app_config()]))
    |> Enum.into(%{}, fn {period, metrics} ->
      measurements = metrics |> Enum.map(&measurement_name/1) |> Enum.uniq()

      {period, measurements}
    end)
  end

  defp distribution_metric_buckets(%Telemetry.Metrics.Distribution{} = metric) do
    Map.get_lazy(metric, :buckets, fn -> Keyword.get(metric.reporter_options, :buckets, []) end)
  end
end
