defmodule TelemetryMetricsTelegrafTest do
  use ExUnit.Case, async: true
  doctest TelemetryMetricsTelegraf

  import Telemetry.Metrics
  import Hammox

  setup :set_mox_from_context
  setup :verify_on_exit!

  defp setup_expectaions_proxy() do
    parent = self()
    ref = make_ref()

    Mock.Adapter
    |> Hammox.expect(:init, fn [] -> :none end)
    |> Hammox.expect(:write, fn name, tags, fields, :none ->
      send(parent, {ref, name, tags, fields})
    end)

    ref
  end

  test "reports metrics to configured adapter" do
    ref = setup_expectaions_proxy()
    measurements = %{count: 1, duration: 10}
    metadata = %{tag1: "t"}

    metrics = [
      summary("foo.bar.count", tags: Map.keys(metadata)),
      summary("foo.bar.duration", tags: Map.keys(metadata))
    ]

    assert {:ok, _pid} =
             TelemetryMetricsTelegraf.start_link(adapter: Mock.Adapter, metrics: metrics)

    :telemetry.execute([:foo, :bar], measurements, metadata)
    assert_received {^ref, "foo.bar", ^metadata, ^measurements}
  end
end
