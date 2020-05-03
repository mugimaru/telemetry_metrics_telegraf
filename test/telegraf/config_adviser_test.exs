defmodule TelemetryMetricsTelegraf.Telegraf.ConfigAdviserTest do
  use ExUnit.Case, async: true

  import Telemetry.Metrics
  alias TelemetryMetricsTelegraf.Telegraf.ConfigAdviser

  test "renders telegraf aggregation config" do
    metrics = [
      summary("a.value"),
      counter("b.value"),
      last_value("c.value"),
      sum("d.value"),
      distribution("e.value", buckets: [0.0, 10.0, 25.0])
    ]

    assert %{
             aggregators: %{
               basicstats: basicstats,
               final: [%{drop_original: true, namepass: ["c"], period: "30s"}],
               histogram: [
                 %{
                   config: [%{buckets: [0.0, 10.0, 25.0], measurement_name: "e"}],
                   cumulative: true,
                   drop_original: true,
                   period: "30s",
                   reset: true
                 }
               ]
             }
           } = ConfigAdviser.render(metrics, []) |> Toml.decode!(keys: :atoms)

    assert Enum.sort([
             %{drop_original: true, namepass: ["a"], period: "30s"},
             %{drop_original: true, namepass: ["b"], period: "30s", stats: ["count"]},
             %{drop_original: true, namepass: ["d"], period: "30s", stats: ["sum"]}
           ]) == Enum.sort(basicstats)
  end

  test "summary aggregators are grouped by aggregation period" do
    metrics = [
      summary("aa.value"),
      summary("ab.value", reporter_options: [period: "1m"]),
      summary("ac.value", reporter_options: [period: "1m"])
    ]

    assert %{aggregators: %{basicstats: basicstats}} =
             ConfigAdviser.render(metrics, []) |> Toml.decode!(keys: :atoms)

    assert Enum.sort([
             %{drop_original: true, namepass: ["aa"], period: "30s"},
             %{drop_original: true, namepass: ["ab", "ac"], period: "1m"}
           ]) == Enum.sort(basicstats)
  end

  test "does not list measurements with the same name twice" do
    metrics = [
      summary("aa.foo_duration"),
      summary("aa.bar_duration")
    ]

    assert %{
             aggregators: %{
               basicstats: [
                 %{drop_original: true, namepass: ["aa"], period: "30s"}
               ]
             }
           } ==
             ConfigAdviser.render(metrics, []) |> Toml.decode!(keys: :atoms)
  end

  test "allows to configure default period" do
    metrics = [
      counter("a.value"),
      counter("b.value", reporter_options: [period: "1m"])
    ]

    opts = [period: "45s"]

    assert %{aggregators: %{basicstats: basicstats}} =
             ConfigAdviser.render(metrics, opts)
             |> Toml.decode!(keys: :atoms)

    assert Enum.sort([
             %{drop_original: true, namepass: ["b"], period: "1m", stats: ["count"]},
             %{drop_original: true, namepass: ["a"], period: "45s", stats: ["count"]}
           ]) == Enum.sort(basicstats)
  end

  test "allows to configure default stats list for summary aggregator" do
    metrics = [summary("a.value")]
    opts = [summary_stats: [:count, :max]]

    assert %{aggregators: %{basicstats: [%{stats: ["count", "max"]}]}} =
             ConfigAdviser.render(metrics, opts) |> Toml.decode!(keys: :atoms)
  end

  test "allows to set histogram options" do
    metrics = [
      distribution("a.value",
        buckets: [0.0, 10.0],
        reporter_options: [histogram_reset: true]
      ),
      distribution("b.value",
        buckets: [0.0, 10.0],
        reporter_options: [period: "1m", histogram_cumulative: true]
      )
    ]

    opts = [histogram_cumulative: false, histogram_reset: false]

    assert %{aggregators: %{histogram: histogram}} =
             ConfigAdviser.render(metrics, opts) |> Toml.decode!(keys: :atoms)

    assert Enum.sort([
             %{
               config: [%{buckets: [0.0, 10.0], measurement_name: "a"}],
               cumulative: false,
               drop_original: true,
               period: "30s",
               reset: true
             },
             %{
               config: [%{buckets: [0.0, 10.0], measurement_name: "b"}],
               cumulative: true,
               drop_original: true,
               period: "1m",
               reset: false
             }
           ]) == histogram
  end
end
