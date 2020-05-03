defmodule TelemetryMetricsTelegraf.AppConfig do
  @default_config [
    period: "30s",
    histogram_reset: true,
    histogram_cumulative: true,
    summary_stats: nil
  ]

  @moduledoc ~s"""
  `TelemetryMetricsTelegraf` application configuration.

  ## Configuration options
  * `:period` - aggregation period (default: #{inspect(@default_config[:period])})
  * `:histogram_reset` - histogram aggregator `reset` option (default: #{
    inspect(@default_config[:histogram_reset])
  })
  * `:histogram_cumulative` - histogram aggregator `cumulative` option (default: #{
    inspect(@default_config[:histogram_cumulative])
  })
  * `:summary_stats` - stats list for summary metric (basicstats aggregator). In context of this option `nil` means "all stats" (default: #{
    inspect(@default_config[:summary_stats])
  })

  See [telegraf aggregators repo](https://github.com/influxdata/telegraf/tree/master/plugins/aggregators) for more details.

  ## Example configuration

      # config/config.exs
      config :telemetry_metrics_telegraf,
        summary_stats: [:count, :mean],
        period: "1m"
  """

  @spec app_config :: keyword
  def app_config do
    Keyword.merge(@default_config, Application.get_all_env(:telemetry_metrics_telegraf))
  end
end
