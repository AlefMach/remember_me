defmodule RememberMe.Jobs.ScheduleJob do
  @moduledoc false

  use GenServer

  require Logger

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
  def handle_info(:work, state), do: exec_job(state)

  defp schedule_work(time), do: Process.send_after(self(), :work, time)

  defp exec_job(state) when is_map(state) do
    time = state.time
    repeat = state.repeat
    fun = state.fun

    list_fun = Enum.map(1..repeat, fn _a -> fun end) ++ [time: time]

    current_fun = Enum.at(list_fun, 0)

    current_fun.()

    Logger.info("Started execute function")

    state =
      list_fun
      |> Enum.sort()
      |> Enum.drop(1)

    schedule_work(time)

    {:noreply, state}
  end

  defp exec_job(state) when is_list(state) do
    time = Keyword.get(state, :time)

    current_fun = Enum.at(state, 0)

    if is_function(current_fun) do
      current_fun.()

      state =
        state
        |> Enum.sort()
        |> Enum.drop(1)

      schedule_work(time)

      {:noreply, state}
    else
      Logger.info("Finish Execute function")
      {:noreply, []}
    end
  end
end
