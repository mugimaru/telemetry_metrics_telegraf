defmodule TelemetryMetricsTelegraf do
  @moduledoc """
  Documentation for TelemetryMetricsTelegraf.
  """

  use GenServer
  require Logger
  alias TelemetryMetricsTelegraf.Utils

  @type adapter :: {module(), any}
  @type args :: [{:adapter, module() | adapter()}, {:metrics, [Telemetry.Metrics.t()]}]

  @spec start_link(args()) :: {:error, any} | {:ok, pid}
  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])

    adapter =
      case opts[:adapter] do
        nil ->
          raise ArgumentError, "the :adapter option is required by #{inspect(__MODULE__)}"

        {mod, opts} ->
          {mod, mod.init(opts)}

        mod ->
          {mod, mod.init([])}
      end

    metrics =
      opts[:metrics] ||
        raise ArgumentError, "the :metrics option is required by #{inspect(__MODULE__)}"

    GenServer.start_link(__MODULE__, {metrics, adapter}, server_opts)
  end

  @impl GenServer
  @spec init({[Telemetry.Metrics.t()], adapter()}) :: {:ok, [any]}
  def init({metrics, adapter}) do
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
