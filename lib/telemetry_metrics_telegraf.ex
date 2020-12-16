defmodule TelemetryMetricsTelegraf do
  @moduledoc """
  InfluxDB reporter for `Telemetry.Metrics`.

  `TelemetryMetricsTelegraf`:
  * uses all except last dot-separated segments of metric name as influxdb measurement name ("foo.bar.duration" -> "foo.bar")
  * uses the last name segment or `:field_name` reporter option as field key ("foo.bar.duration" -> "duration")
  * reports metrics with the same measurement name as a single influxdb measurement (with multiple fields)
  * uses adapters to provide flexibility in influxdb client choice (see spec at `TelemetryMetricsTelegraf.Writer`)

  For example, metrics definition
      [
        summary("app.repo.query.decode_time", tags: [:source])
        summary("app.repo.query.total_time", tags: [:source])
      ]

  for event

      :telemetry.execute([:app, :repo, :query], %{total_time: 100, decode_time: 30}, %{source: "users"})

  yields

        app.repo.query,source="users" total_time=100,decode_time=30

  influxdb measurement.

  ## Configuration options

  Refer to `TelemetryMetricsTelegraf.AppConfig` for the complete list of available configuration options.

  Options can be set:

  * as metric repoter options
  ```
  summary("foo.value", reporter_options: [period: "1m"])
  ```
  * as reporter process options
  ```
  TelemetryMetricsTelegraf.star_link(
    metrics: metrics(),
    adapter: adapter(),
    period: "45s"
  )
  ```
  * as application config

  ```
  # config/config.exs
  config :telemetry_metrics_telegraf, period: "50s"
  ```

  """

  use GenServer
  require Logger

  alias TelemetryMetricsTelegraf.Utils

  @type adapter :: {TelemetryMetricsTelegraf.Writer.t(), any}
  @type args ::
          keyword(
            {:adapter, TelemetryMetricsTelegraf.Writer.t() | adapter()}
            | {:metrics, [Telemetry.Metrics.t()]}
            | {atom, any}
          )

  @spec start_link(args()) :: {:error, any} | {:ok, pid}
  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])

    {{adapter_mod, adapter_opts}, opts} =
      case Keyword.pop(opts, :adapter) do
        {nil, _opts} ->
          raise ArgumentError, "the :adapter option is required by #{inspect(__MODULE__)}"

        {{adapter_mod, adapter_opts}, opts} ->
          {{adapter_mod, adapter_mod.init(adapter_opts)}, opts}

        {adapter_mod, opts} ->
          {{adapter_mod, adapter_mod.init([])}, opts}
      end

    {metrics, opts} =
      case Keyword.pop(opts, :metrics) do
        {metrics, opts} when is_list(metrics) ->
          {metrics, opts}

        _ ->
          raise(ArgumentError, "the :metrics option is required by #{inspect(__MODULE__)}")
      end

    GenServer.start_link(__MODULE__, {metrics, {adapter_mod, adapter_opts}, opts}, server_opts)
  end

  @impl GenServer
  @spec init({[Telemetry.Metrics.t()], adapter(), keyword()}) :: {:ok, [any]}
  def init({metrics, adapter, _opts}) do
    Process.flag(:trap_exit, true)
    groups = Enum.group_by(metrics, & &1.event_name)

    for {event, metrics} <- groups do
      id = {__MODULE__, event, self()}

      :telemetry.attach(
        id,
        event,
        &handle_event/4,
        {adapter, group_metrics_by_name!(metrics)}
      )
    end

    {:ok, Map.keys(groups)}
  end

  @impl GenServer
  def terminate(_, events) do
    for event <- events do
      :telemetry.detach({__MODULE__, event, self()})
    end

    :ok
  end

  defp handle_event(_event_name, measurements, metadata, {{adapter_mod, adapter_opts}, metrics}) do
    for {measurement, metrics} <- metrics do
      {tags, fields} =
        Enum.reduce(metrics, {%{}, %{}}, fn metric, {tags, fields} ->
          {Map.merge(tags, extract_tags(metric, metadata)),
           Map.put(fields, field_name(metric), extract_measurement(metric, measurements))}
        end)

      adapter_mod.write(measurement, tags, fields, adapter_opts)
    end
  rescue
    e ->
      Logger.error(fn ->
        "#{inspect(e)} #{Enum.map(__STACKTRACE__, &inspect/1) |> Enum.join(" ")}"
      end)

      {:error, e}
  end

  defp extract_measurement(metric, measurements) do
    case metric.measurement do
      fun when is_function(fun, 1) -> fun.(measurements)
      key -> measurements[key]
    end
  end

  defp field_name(metric) do
    cond do
      field = metric.reporter_options[:field_name] ->
        field

      is_atom(metric.measurement) ->
        metric.measurement

      is_function(metric.measurement, 1) ->
        List.last(metric.name)
    end
  end

  defp extract_tags(metric, metadata) do
    tag_values = metric.tag_values.(metadata)
    Map.take(tag_values, metric.tags)
  end

  defp group_metrics_by_name!(metrics) do
    Enum.reduce(metrics, %{}, fn new_metric, acc ->
      name = Utils.measurement_name(new_metric)
      validate_group!(name, acc[name], new_metric)

      Map.put(acc, name, [new_metric | Map.get(acc, name, [])])
    end)
  end

  @named_group_uniqueness_keys [:buckets, :tags, :__struct__, :reporter_options]
  defp validate_group!(_group_name, nil, _new_metric), do: :ok

  defp validate_group!(group_name, metrics, new_metric) do
    new_metric_params = Map.take(new_metric, @named_group_uniqueness_keys)

    Enum.each(metrics, fn metric ->
      metric_params = Map.take(metric, @named_group_uniqueness_keys)

      if new_metric_params != metric_params do
        raise(
          TelemetryMetricsTelegraf.ConfigurationError,
          """
          Metrics with the same name must share #{inspect(@named_group_uniqueness_keys)} attributes. \
          #{group_name} was previously defined with \
          #{inspect(metric_params)} and #{inspect(new_metric_params)} breaks the contract.\
          """
        )
      end
    end)

    :ok
  end
end
