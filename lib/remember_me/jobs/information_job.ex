defmodule RememberMe.Jobs.InformationJob do
  @moduledoc false

  use GenServer

  require Logger

  alias RememberMe.Jobs.Information

  def start_link(params), do: GenServer.start_link(__MODULE__, params)

  @impl true
  @spec init(Map) :: {:ok, any}
  def init(state) do
    time = state.time

    # Schedule work to be performed on start
    schedule_work(time)

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    name_state = state.name_state
    Information.delete_info(name_state)

    Logger.info("Info name_state: #{name_state} deleted")

    {:noreply, state}
  end

  defp schedule_work(time), do: Process.send_after(self(), :work, time)
end
