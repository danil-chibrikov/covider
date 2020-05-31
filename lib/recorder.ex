defmodule Covider do
  @moduledoc false

  require Logger
  use Tesla, only: ~w(get)a
  alias Covider.ClickhouseBulk

  plug(Tesla.Middleware.Headers, [{"content-type", "text/csv"}])

  def record_data(:all) do
    get_covid(:all)
    |> check_data
  end
  def record_data(date) do
    get_covid(date)
    |> check_data
  end

  def check_data(:error), do: {:error, :csv_request}
  def check_data([]), do: {:ok, :csv_empty}
  def check_data([_ | _] = items), do: ClickhouseBulk.insert(items)

  def get_covid(date) do
    get!(
      "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv",
      query: []
    )
    |> case do
      %{status: 200, body: ""} ->
        []

      %{status: 200, body: body} ->
        convert(body)
        |> filter_by_date(date)

      %{status: status, headers: headers, body: body, url: url} ->
        Logger.error("#{__MODULE__}: #{url} -> #{status} / headers: #{inspect(headers)}, body: #{body}")
        []
    end
  rescue
    error ->
      Logger.error("#{__MODULE__}: error: #{inspect(error)}")
      :error
  end

  defp convert(body) do
    NimbleCSV.RFC4180.parse_string(body, [separator: ",", escape: "\""])
    |> Enum.reduce([], fn
      [date, country, state, fips, cases, deaths], acc ->
        elem = {
          Date.from_iso8601!(date),
          URI.encode_www_form(country),
          URI.encode_www_form(state),
          to_int(fips),
          to_int(cases),
          to_int(deaths)
        }

        [elem | acc]

      _, acc ->
        acc
    end)
  end

  defp filter_by_date(data, :all), do: data
  defp filter_by_date(data, date) do
    Enum.reduce(data, [], fn
      {item_date, _, _, _, _, _} = item, acc ->
        case Date.compare(date, item_date) do
          :gt -> acc
          _   -> [item | acc]
        end
    end)
  end

  defp to_int(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error   -> 0
    end
  end
end
