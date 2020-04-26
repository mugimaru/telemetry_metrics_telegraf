defmodule TelemetryMetricsTelegraf.Adapters.Instream do
  @moduledoc """
  Writer adapter for [Instream](https://hex.pm/packages/instream).

  ## Options

  * `:connection` - `Instream` connection module, requeired;
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
            metrics: metrics(), adapter: {TelemetryMetricsTelegraf.Adapters.Instream, [connection: MyApp.MyConnection]}}
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
      %{
        points: [
          %{measurement: measurement_name, tags: tags, fields: fields}
        ]
      },
      log: opts[:log]
    )
  end
end
