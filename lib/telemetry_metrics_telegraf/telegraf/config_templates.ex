defmodule TelemetryMetricsTelegraf.Telegraf.ConfigTemplates do
  @moduledoc "Telegraf toml configuration templates."

  @type opts :: keyword({:period, String.t()})
  @type basicstats_opts :: keyword({:period, String.t()} | {:stats, [atom | String.t()]})
  @type hisogram_opts ::
          keyword(
            {:period, String.t()}
            | {:histogram_reset, boolean}
            | {:histogram_cumulative, boolean()}
          )

  @spec basicstats_aggeregator(measurements :: [String.t()], basicstats_opts) :: String.t()
  def basicstats_aggeregator(measurements, opts) do
    ~s"""
    [[aggregators.basicstats]]
    period = "#{opts[:period]}"
    drop_original = true#{basicstats_stats_list(opts[:stats])}
    namepass = #{render_namepass(measurements)}
    """
  end

  defp basicstats_stats_list(nil), do: ""

  defp basicstats_stats_list(stats) do
    "\nstats = " <> toml_list_of_string(stats)
  end

  @spec final_aggeregator([measurement :: String.t()], opts) :: String.t()
  def final_aggeregator(measurements, opts) do
    ~s"""
    [[aggregators.final]]
    period = "#{opts[:period]}"
    drop_original = true
    namepass = #{render_namepass(measurements)}
    """
  end

  @spec histogram_aggregator(
          [{measurement_name :: String.t(), buckets :: [float]}],
          hisogram_opts
        ) :: String.t()
  def histogram_aggregator(measurements_with_buckets, opts) do
    ~s"""
    [[aggregators.histogram]]
    period = "#{opts[:period]}"
    drop_original = true
    reset = #{opts[:histogram_reset]}
    cumulative = #{opts[:histogram_cumulative]}
    #{measurements_with_buckets |> Enum.map_join("\n", &histogram_config/1)}
    """
  end

  @spec histogram_config({measurement_name :: String.t(), buckets :: [float]}) :: String.t()
  def histogram_config({measurement_name, buckets}) do
    ~s"""
      [[aggregators.histogram.config]]
        buckets = #{"[" <> (buckets |> Enum.map_join(", ", &to_string/1)) <> "]"}
        measurement_name = "#{measurement_name}"
    """
  end

  @spec unknown_metric_type(module, [Telemetry.Metrics.t()], keyword()) :: String.t()
  def unknown_metric_type(metric_type, metrics, _opts) do
    "# renderer for #{Macro.to_string(metric_type)} is not implemented\n# #{inspect(metrics)} will pass unchanged"
  end

  defp render_namepass(measurements) do
    measurements
    |> Enum.sort()
    |> toml_list_of_string()
  end

  @inline_toml_list_max_items_length 100
  defp toml_list_of_string(list) do
    items = Enum.map(list, &~s["#{&1}"])

    if Enum.reduce(items, 0, &(&2 + String.length(&1))) > @inline_toml_list_max_items_length do
      "[\n" <> Enum.join(items, ",\n") <> "\n]"
    else
      "[" <> Enum.join(items, ", ") <> "]"
    end
  end
end
