defmodule TelemetryMetricsTelegraf.Telegraf.ConfigTemplates do
  @moduledoc "Telegraf toml configuration templates."

  @spec basicstats_aggeregator({period :: String.t(), [String.t()]}, keyword) :: String.t()
  def basicstats_aggeregator({period, measurements}, opts) do
    stats =
      if stats = opts[:stats] do
        "\nstats = [" <> (stats |> Enum.map(&~s["#{&1}"]) |> Enum.join(", ")) <> "]"
      else
        ""
      end

    ~s"""
    [[aggregators.basicstats]]
    period = "#{period}"
    drop_original = true#{stats}
    namepass = #{render_namepass(measurements)}
    """
  end

  @spec final_aggeregator({period :: String.t(), [String.t()]}, keyword) :: String.t()
  def final_aggeregator({period, measurements}, _opts) do
    ~s"""
    [[aggregators.final]]
    period = "#{period}"
    drop_original = true
    namepass = #{render_namepass(measurements)}
    """
  end

  @spec histogram_aggregator(
          period :: String.t(),
          [{measurement_name :: String.t(), buckets :: [float]}],
          keyword
        ) :: String.t()
  def histogram_aggregator(period, measurements_with_buckets, opts) do
    ~s"""
    [[aggregators.histogram]]
    period = "#{period}"
    drop_original = true
    reset = #{Keyword.get(opts, :reset, true)}
    cumulative = #{Keyword.get(opts, :cumulative, true)}
    #{measurements_with_buckets |> Enum.map(&histogram_config/1) |> Enum.join("\n")}
    """
  end

  @spec histogram_config({measurement_name :: String.t(), buckets :: [float]}) :: String.t()
  def histogram_config({measurement_name, buckets}) do
    ~s"""
      [[aggregators.histogram.config]]
        buckets = #{"[" <> (buckets |> Enum.map(&to_string/1) |> Enum.join(", ")) <> "]"}
        measurement_name = "#{measurement_name}"
    """
  end

  @spec unknown_metric_type(module, [Telemetry.Metrics.t()], keyword()) :: String.t()
  def unknown_metric_type(metric_type, metrics, _opts) do
    "# renderer for #{Macro.to_string(metric_type)} is not implemented\n# #{inspect(metrics)} will pass unchanged"
  end

  defp render_namepass(measurements) do
    items =
      measurements
      |> Enum.sort()
      |> Enum.map(&~s[  "#{&1}"])
      |> Enum.join(",\n")

    "[\n" <> items <> "\n]"
  end
end
