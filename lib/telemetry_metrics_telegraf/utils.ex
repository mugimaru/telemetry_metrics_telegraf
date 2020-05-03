defmodule TelemetryMetricsTelegraf.Utils do
  @moduledoc false

  def measurement_name(%{name: name}), do: measurement_name(name)

  def measurement_name(name) do
    name
    |> List.delete_at(-1)
    |> Enum.join(".")
  end

  @spec fetch_option!(atom, [keyword()]) :: any
  def fetch_option!(key, []) do
    raise KeyError, "option #{inspect(key)} not found"
  end

  def fetch_option!(key, [kw | rest_kw]) do
    case Keyword.fetch(kw, key) do
      {:ok, value} ->
        value

      :error ->
        fetch_option!(key, rest_kw)
    end
  end

  @spec fetch_options!([atom], [keyword()]) :: any
  def fetch_options!(keys, sources) do
    Enum.map(keys, &{&1, fetch_option!(&1, sources)})
  end
end
