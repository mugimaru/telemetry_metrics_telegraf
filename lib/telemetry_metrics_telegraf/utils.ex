defmodule TelemetryMetricsTelegraf.Utils do
  @moduledoc false

  def measurement_name(%{name: name}), do: measurement_name(name)

  def measurement_name(name) do
    name
    |> List.delete_at(-1)
    |> Enum.join(".")
  end
end
