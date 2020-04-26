defmodule TelemetryMetricsTelegraf.MetricHelpersTest do
  use ExUnit.Case, async: true

  import TelemetryMetricsTelegraf.MetricHelpers
  import Telemetry.Metrics

  test ".telegraf_summary/3" do
    assert telegraf_summary("foo.bar", :value) ==
             summary("foo.bar", event_name: [:foo, :bar], measurement: :value)
  end

  test ".telegraf_counter/3" do
    assert telegraf_counter("foo.bar", :value) ==
             counter("foo.bar", event_name: [:foo, :bar], measurement: :value)
  end

  test ".telegraf_distribution/3" do
    assert telegraf_distribution("foo.bar", :value, buckets: [0.0, 50.0]) ==
             distribution("foo.bar",
               event_name: [:foo, :bar],
               measurement: :value,
               buckets: [0.0, 50.0]
             )
  end

  test ".telegraf_sum/3" do
    assert telegraf_sum("foo.bar", :value) ==
             sum("foo.bar", event_name: [:foo, :bar], measurement: :value)
  end

  test ".telegraf_last_value/3" do
    assert telegraf_last_value("foo.bar", :value) ==
             last_value("foo.bar", event_name: [:foo, :bar], measurement: :value)
  end
end
