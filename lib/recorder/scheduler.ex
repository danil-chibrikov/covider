defmodule Covider.Scheduler do
  @moduledoc false

  use GenServer
  require Logger

  alias Covider

  @day 24 * 60 * 60 * 1000

  ## GenServer

  def start_link(opts) do
    Logger.info("#{inspect(__MODULE__)} started")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    send(self(), :record)
    {:ok, %{}}
  end

  def handle_info(:record, state) do
    yesterday =
      Date.utc_today()
      |> Date.add(-1)

    Logger.info("#{inspect(__MODULE__)}: record covid data, date: #{yesterday}")

    try do
      case Covider.record_data(yesterday) do
        {:ok, _}    ->
          Logger.info("#{inspect(__MODULE__)}: record was successful")

        {:error, reason} ->
          Logger.info("#{inspect(__MODULE__)}: record failed, reason: #{inspect(reason)}")
      end
    rescue
      reason ->
        Logger.error(inspect(reason))
    end

    Process.send_after(self(), :daily, @day)

    {:noreply, state}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
