defmodule TelemetryMetricsTelegraf.Utils do
  @moduledoc false

  def measurement_name(%{name: name}), do: measurement_name(name)
  def measurement_name(name), do: Enum.join(name, ".")
end
