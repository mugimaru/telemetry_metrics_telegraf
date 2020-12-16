defmodule TelemetryMetricsTelegrafTest do
  use ExUnit.Case, async: true
  doctest TelemetryMetricsTelegraf

  import Telemetry.Metrics
  import Hammox

  setup :set_mox_from_context
  setup :verify_on_exit!

  defp proxy_adapter_writes(writes_expected) do
    parent = self()
    ref = make_ref()

    Mock.Adapter
    |> Hammox.expect(:init, fn [] -> :none end)
    |> Hammox.expect(
      :write,
      writes_expected,
      fn name, tags, fields, :none -> send(parent, {ref, name, tags, fields}) end
    )

    ref
  end

  test "reports metrics to configured adapter" do
    ref = proxy_adapter_writes(2)

    TelemetryMetricsTelegraf.start_link(
      adapter: Mock.Adapter,
      metrics: [
        summary("foo.bar.count", tags: [:tag1]),
        counter("foo.baz.duration", tags: [:tag2])
      ]
    )

    :telemetry.execute([:foo, :bar], %{count: 1}, %{tag1: "t1"})
    :telemetry.execute([:foo, :baz], %{duration: 10}, %{tag2: "t2"})

    assert_received {^ref, "foo.bar", %{tag1: "t1"}, %{count: 1}}
    assert_received {^ref, "foo.baz", %{tag2: "t2"}, %{duration: 10}}
  end

  test "does not allow to configure metrics of different types with duplicate names" do
    metrics = [
      summary("foo.bar.count"),
      counter("foo.bar.count")
    ]

    assert_raise TelemetryMetricsTelegraf.ConfigurationError,
                 ~r/foo\.bar was previously defined with/,
                 fn ->
                   TelemetryMetricsTelegraf.init({metrics, {Mock.Adapter, []}, []})
                 end
  end

  test "merges measurements by name" do
    ref = proxy_adapter_writes(1)

    TelemetryMetricsTelegraf.start_link(
      adapter: Mock.Adapter,
      metrics: [
        summary("foo.bar.count", tags: [:tag]),
        summary("foo.bar.duration", tags: [:tag])
      ]
    )

    tags = %{tag: "tag_value"}
    measurements = %{count: 1, duration: 10}

    :telemetry.execute([:foo, :bar], measurements, tags)
    assert_received {^ref, "foo.bar", ^tags, ^measurements}
  end

  test "allows to configure multiple metrics for an event" do
    ref = proxy_adapter_writes(2)

    TelemetryMetricsTelegraf.start_link(
      adapter: Mock.Adapter,
      metrics: [
        summary("foo.bar.count", tags: [:tag]),
        distribution("foo.bar_histogram.duration",
          event_name: [:foo, :bar],
          buckets: [0.0, 50.0],
          tags: [:tag]
        )
      ]
    )

    tags = %{tag: "tag_value"}
    measurements = %{count: 1, duration: 10}

    :telemetry.execute([:foo, :bar], measurements, tags)
    assert_received {^ref, "foo.bar", ^tags, summary_measurements}
    assert_received {^ref, "foo.bar_histogram", ^tags, distribution_measurements}

    assert summary_measurements == Map.take(measurements, [:count])
    assert distribution_measurements == Map.take(measurements, [:duration])
  end

  test "detaches telemetry listeners on termination" do
    metrics = [summary("foo.bar.count")]

    expect(Mock.Adapter, :init, & &1)

    assert {:ok, pid} =
             TelemetryMetricsTelegraf.start_link(adapter: Mock.Adapter, metrics: metrics)

    assert [%{id: {TelemetryMetricsTelegraf, _, ^pid}}] = :telemetry.list_handlers([:foo, :bar])
    GenServer.stop(pid)
    assert [] = :telemetry.list_handlers([:foo, :bar])
  end
end
