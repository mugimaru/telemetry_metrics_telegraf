defmodule TelemetryMetricsTelegraf.Writer do
  @moduledoc """
  `TelemetryMetricsTelegraf` writer specification.

  ## Example

  Define an adapter:

      defmodule PutsAdapter do
        @behaviour TelemetryMetricsTelegraf.Writer

        @impl true
        def init(device \\ :stdio) do
          device
        end

        @impl true
        def write(measurement_name, tags, fields, device) do
          IO.puts(device, Enum.join([measurement_name, inspect(tags), inspect(fields), " "]))
        end
      end

  Configure `TelemetryMetricsTelegraf` to use it:

      TelemetryMetricsTelegraf.start_link(metrics: AppTelemetry.metrics(), adapter: {PutsAdapter, :stderr})
  """
  @type t :: module()
  @type writer_opts :: any

  @callback init(writer_opts) :: writer_opts
  @callback write(measurement_name :: String.t(), tags :: map, values :: map, writer_opts) :: any
end
