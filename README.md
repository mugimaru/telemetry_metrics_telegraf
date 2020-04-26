# TelemetryMetricsTelegraf
[![Build Status](https://travis-ci.com/mugimaru73/telemetry_metrics_telegraf.svg?token=XqLiJkbfAM2pqzZCdHyr&branch=master)](https://travis-ci.com/mugimaru73/telemetry_metrics_telegraf)

[InfluxDB](https://www.influxdata.com/) reporter for [Telemetry.Metrics](https://github.com/beam-telemetry/telemetry_metrics).
The core idea of this implementation is to avoid any in-memory aggregation and let [telegraf](https://www.influxdata.com/time-series-platform/telegraf) do the heavy lifting.

## TODO
* [x] implement client-agnostic reporter
* [ ] provide an ability to generate telegraf aggregations config from telemetry metrics
* [ ] configure CI
* [ ] publish to hex.pm
* [ ] publish docs
