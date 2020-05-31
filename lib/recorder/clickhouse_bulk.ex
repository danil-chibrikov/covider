defmodule Covider.ClickhouseBulk do
  @moduledoc false

  require Logger
  use Tesla

  plug(Tesla.Middleware.JSON)

  def insert(items) do
    case daily_stat_map() do
      {:error, reason}  -> {:error, reason}
      {:ok, old_values} -> prepare_value(items, old_values)
    end
  end

  ## Helpers

  defp daily_stat do
    {base_url, database} = config()

    get(base_url,
      query: [
        database: database,
        query:
          """
          select
            date, country, state,
            sum(fips) as fips, sum(cases) as cases, sum(deaths) as deaths
          from covid
          group by
            date, country, state
          order by
            date, country, state
          FORMAT JSON
          """
      ]
    )
    |> case do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        res =
          Enum.map(data, fn %{
            "date" => date,
            "country" => country,
            "state" => state,
            "fips" => fips,
            "cases" => cases,
            "deaths" => deaths,
          } ->
            {
              Date.from_iso8601!(date),
              country,
              state,
              String.to_integer(fips),
              String.to_integer(cases),
              String.to_integer(deaths)
            }
          end)

        {:ok, res}

      {:ok, other} ->
        Logger.error("Get request return: #{inspect(other)}")
        {:error, other}

      {:error, reason} ->
        Logger.error("Error get request, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp daily_stat_map do
    case daily_stat() do
      {:ok, items} ->
        res =
          Map.new(items, fn {
            date,
            country,
            state,
            fips,
            cases,
            deaths
          } ->
            {{date, country, state}, {fips, cases, deaths}}
          end)

        {:ok, res}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prepare_value(items, old_values) do
    Enum.map(items, fn {
      date,
      country,
      state,
      fips,
      cases,
      deaths
    } = item ->
      key = {date, country, state}
      case old_values do
        %{^key => {old_fips, old_cases, old_deaths}} ->
          {
            date,
            country,
            state,
            fips - old_fips,
            cases - old_cases,
            deaths - old_deaths
          }
        _ ->
          item
      end
    end)
    |> Enum.filter(fn
      {_, _, _, 0, 0, 0} -> false
      _                  -> true
    end)
    |> do_insert()
  end

  def do_insert(items) do
    {base_url, database} = config()

    count_records = Enum.count(items)
    body =
      Stream.map(items, fn {
        date,
        country,
        state,
        fips,
        cases,
        deaths
      } ->
        """
        (
          '#{date}','#{country}','#{state}',
          #{fips},#{cases},#{deaths}
        )
        """
      end)
      |> Enum.join(",")

    params = [
      database: database,
      query: """
        insert into covid
        (date,country,state,fips,cases,deaths) values
      """
    ]

    post(
      base_url,
      body,
      query: params
    )
    |> case do
      {:ok, %{status: 200} = resp} ->
        Logger.info("recorded #{count_records}")
        {:ok, resp}

      {:ok, resp} ->
        Logger.error("error, reason: #{inspect(resp)}")
        {:error, resp}

      {:error, reason} ->
        Logger.error("error, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp config do
    %{hostname: hostname, port: port, database: database} =
      Application.get_env(:covider, Covider.Repo, []) |> Map.new()

    {"http://#{hostname}:#{port}/", database}
  end
end
