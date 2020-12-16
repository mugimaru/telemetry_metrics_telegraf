# TelemetryMetricsTelegraf
[![Build Status](https://travis-ci.com/mugimaru73/telemetry_metrics_telegraf.svg?token=XqLiJkbfAM2pqzZCdHyr&branch=master)](https://travis-ci.com/mugimaru73/telemetry_metrics_telegraf)
[![Hex](https://img.shields.io/hexpm/v/telemetry_metrics_telegraf.svg)](https://hex.pm/packages/telemetry_metrics_telegraf)
[![Hexdocs](https://img.shields.io/badge/hex-docs-blue.svg?style=flat)](https://hexdocs.pm/telemetry_metrics_telegraf)

[InfluxDB](https://www.influxdata.com/) reporter for [Telemetry.Metrics](https://github.com/beam-telemetry/telemetry_metrics).
The core idea of this implementation is to avoid any in-memory aggregation and let [telegraf](https://www.influxdata.com/time-series-platform/telegraf) do the heavy lifting.

## Installation

The package can be installed by adding `telemetry_metrics_telegraf` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telemetry_metrics_telegraf, "~> 0.1"}
  ]
end
```

See documentation at [hexdocs.pm](https://hexdocs.pm/telemetry_metrics_telegraf).

## Quickstart guide

Consider we have a freshly generated phoenix app with [telemetry module](https://github.com/phoenixframework/phoenix/blob/master/installer/templates/phx_web/telemetry.ex) and we want to use [instream](https://github.com/mneudert/instream) as our telegraf client.

Add telemetry_metrics_telegraf to the app telemetry supervision tree
```elixir
defmodule MyAppWeb.Telemetry do
  import Telemetry.Metrics

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      [
        {TelemetryMetricsTelegraf,
         metrics: metrics(),
         adapter:
           {TelemetryMetricsTelegraf.Adapters.Instream, [connection: MyApp.InstreamConnection]}}
      ]
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration"),

      # Database Metrics
      summary("my_app.repo.query.total_time", unit: {:native, :millisecond}, tags: [:source]),
      summary("my_app.repo.query.decode_time", unit: {:native, :millisecond}, tags: [:source]),
      summary("my_app.repo.query.query_time", unit: {:native, :millisecond}, tags: [:source]),
      summary("my_app.repo.query.queue_time", unit: {:native, :millisecond}, tags: [:source]),
      summary("my_app.repo.query.idle_time", unit: {:native, :millisecond}, tags: [:source]),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    []
  end
end
```

The configuration above emits following influxdb measurements on corresponding telemetry events

```
phoenix.endpoint.stop duration=42
my_app.repo.query,source="users" total_time=10,decode_time=1,query_time=2,
queue_time=3,idle_time=4
vm.memory total=100
vm.total_run_queue_lengths total=42,cpu=40,io=2
```

After you describe the telemetry supervision, you should append the aggregators config to your telegraf config.
You can render aggregators config by calling

```elixir
config_string = TelemetryConfigTelegraf.Telegraf.ConfigAdviser.render(MyAppWeb.Telemetry.metrics(), options_kw)
```

you will get something like this:

```
[[aggregators.basicstats]]
period = "30s"
drop_original = true
namepass = ["my_app.repo.query", "phoenix.endpoint.stop", "vm.memory", "vm.total_run_queue_lengths"]
```

Copy/paste received config into your telegraf configuration file.
If your final file looks like this, you're good to go.

```
  [agent]
  interval = "30s"
  round_interval = true
  metric_batch_size = 30000
  metric_buffer_limit = 1000000
  collection_jitter = "0s"
  flush_interval = "5s"
  flush_jitter = "2s"
  precision = ""
  debug = true
  quiet = false
  logfile = "${TELEGRAF_LOGFILE}"
  hostname = ""
  omit_hostname = true

  [[inputs.socket_listener]]
  service_address = "udp://:${TELEGRAF_UDP_PORT}"
  data_format = "influx"

  [[outputs.influxdb]]
  urls = ["${TELEGRAF_INFLUXDB_URL}"]
  database = "${TELEGRAF_INFLUXDB_DATABASE}"
  retention_policy = "${TELEGRAF_INFLUXDB_RP}"
  write_consistency = "any"
  timeout = "5s"
  username = "${TELEGRAF_INFLUXDB_USERNAME}"
  password = "${TELEGRAF_INFLUXDB_PASSWORD}"
  skip_database_creation = true

  [[aggregators.basicstats]]
  period = "30s"
  drop_original = true
  namepass = ["my_app.repo.query", "phoenix.endpoint.stop", "vm.memory", "vm.total_run_queue_lengths"]
```