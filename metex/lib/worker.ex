defmodule Metex.Worker do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  def get_stats(pid) do
    GenServer.call(pid, :get_stats)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:location, location}, _from, stats) do
    case temperate_of(location) do
      {:ok, temp} ->
        new_stats = update_stats(stats, location)
        {:reply, "#{temp}°C", new_stats}
      _ ->
        {:reply, :error, stats}
    end
  end

  ## Helper Functions

  defp temperate_of(location) do
    url_for(location) |> HTTPoison.get |> parse_response
  end

  def url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&APPID=#{apikey()}"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    {:ok, json} = body |> JSON.decode
    compute_temperature(json)
  end

  defp parse_response(_) do
    :error
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  def apikey do
    "2b062e1c1a8bbb45e3e20479614dfdde"
  end

  defp update_stats(old_stats, location) do
    case Map.has_key?(old_stats, location) do
      true ->
        Map.update!(old_stats, location, &(&1 + 1))
      false ->
        Map.put_new(old_stats, location, 1)
    end
  end

end