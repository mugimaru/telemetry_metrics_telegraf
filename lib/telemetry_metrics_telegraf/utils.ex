defmodule TelemetryMetricsTelegraf.Utils do
  @moduledoc false
  def measurement_name_from_event_name(event_name), do: Enum.join(event_name, ".")
end
