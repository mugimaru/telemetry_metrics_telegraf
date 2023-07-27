defmodule TelemetryMetricsTelegraf.Adapters.InstreamV2 do
  @moduledoc """
  Writer adapter for 2+ versions [Instream](https://hex.pm/packages/instream).

  ## Options

  * `:connection` - `Instream` connection module, required;
  * `:log` - controls instream queries logging, default - `false`;

  ## Example

      # instream connection
      defmodule MyApp.MyConnection do
        use Instream.Connection, otp_app: :my_app
      end

      # telemetry metrics supervisor
      defmodule MyApp.Telemetry do
        use Supervisor
        import Telemetry.Metrics

        def start_link(arg) do
          Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
        end

        @impl true
        def init(_arg) do
          children = [
            {TelemetryMetricsTelegraf,
            metrics: metrics(),
            adapter: {TelemetryMetricsTelegraf.Adapters.Instream, [connection: MyApp.MyConnection]}}
          ]

          Supervisor.init(children, strategy: :one_for_one)
        end

        def metrics do
          [
            # ...
          ]
        end
      end
  """

  @behaviour TelemetryMetricsTelegraf.Writer

  @type options :: [{:connection, module()}, {:log, boolean()}]

  @impl TelemetryMetricsTelegraf.Writer
  @spec init(options()) :: options()
  def init(opts) do
    [
      connection: Keyword.fetch!(opts, :connection),
      log: Keyword.get(opts, :log, false)
    ]
  end

  @impl TelemetryMetricsTelegraf.Writer
  def write(measurement_name, tags, fields, opts) do
    opts[:connection].write(
      %{measurement: measurement_name, fields: fields, tags: tags},
      log: opts[:log]
    )
  end
end
