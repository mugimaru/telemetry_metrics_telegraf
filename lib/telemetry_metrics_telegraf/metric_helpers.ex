defmodule TelemetryMetricsTelegraf.MetricHelpers do
  @moduledoc """
  Provides wrappers for `Telemetry.Metrics` metric definition helpers.

  With influxdb we can define measurements with multiple values, for example,
  instead of separate influxdb measurements for `ecto.repo.query.total_time` and `ecto.repo.query.decode_time`
  we'd prefer to have `ecto.repo.query` influxdb measurement with `total_time` and `decode_time` as values.

  `TelemetryMetricsTelegraf` merges metrics with the same name and different measurements into single influxdb measurement.

  In order to define such metrics with `Telemetry.Metrics` helpers we must write something like:

      [
        summary("ecto.repo.query", event_name: [:ecto, :repo, :query], measurement: :total_time, tags: [:source]),
        summary("ecto.repo.query", event_name: [:ecto, :repo, :query], measurement: :decode_time, tags: [:source])
      ]

  with `TelemetryMetricsTelegraf.MetricHelpers` we can reduce an amount of boilerplate and rewrite this as:

      [
        telegraf_summary("ecto.repo.query", :total_time, tags: [:source]),
        telegraf_summary("ecto.repo.query", :decode_time, tags: [:source])
      ]

  which yields an identical result.
  """

  alias Telemetry.Metrics

  @spec telegraf_summary(Metrics.metric_name(), Metrics.measurement(), keyword()) ::
          Metrics.Summary.t()
  def telegraf_summary(name, measurement, opts \\ []) do
    {name, options} = telegraf_metric(name, measurement, opts)
    Metrics.summary(name, options)
  end

  @spec telegraf_distribution(Metrics.metric_name(), Metrics.measurement(), keyword()) ::
          Metrics.Distribution.t()
  def telegraf_distribution(name, measurement, opts \\ []) do
    {name, options} = telegraf_metric(name, measurement, opts)
    Metrics.distribution(name, options)
  end

  @spec telegraf_counter(Metrics.metric_name(), Metrics.measurement(), keyword()) ::
          Metrics.Counter.t()
  def telegraf_counter(name, measurement, opts \\ []) do
    {name, options} = telegraf_metric(name, measurement, opts)
    Metrics.counter(name, options)
  end

  @spec telegraf_sum(Metrics.metric_name(), Metrics.measurement(), keyword()) ::
          Metrics.Sum.t()
  def telegraf_sum(name, measurement, opts \\ []) do
    {name, options} = telegraf_metric(name, measurement, opts)
    Metrics.sum(name, options)
  end

  @spec telegraf_last_value(Metrics.metric_name(), Metrics.measurement(), keyword()) ::
          Metrics.LastValue.t()
  def telegraf_last_value(name, measurement, opts \\ []) do
    {name, options} = telegraf_metric(name, measurement, opts)
    Metrics.last_value(name, options)
  end

  defp telegraf_metric(name, measurement, opts) when is_binary(name) do
    name
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
    |> telegraf_metric(measurement, opts)
  end

  defp telegraf_metric(event_name, measurement, opts) do
    opts = Keyword.merge([measurement: measurement, event_name: event_name], opts)

    {event_name, opts}
  end
end
