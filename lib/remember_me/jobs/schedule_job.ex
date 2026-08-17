defmodule RememberMe.Jobs.ScheduleJob do
  @moduledoc false

  use GenServer

  alias RememberMe.{Logging, Telemetry}

  def start_link(params), do: GenServer.start_link(__MODULE__, params)

  @impl true
  @spec init(Map) :: {:ok, any}
  def init(state) do
    Logging.info("function_scheduled", interval_ms: state.time, repeat: state.repeat)

    Telemetry.execute([:schedule, :scheduled], %{interval_ms: state.time}, %{repeat: state.repeat})

    schedule_work(state.time)
    {:ok, Map.put(state, :remaining, state.repeat)}
  end

  @impl true
  def handle_info(:work, %{remaining: remaining} = state) do
    Logging.info("function_execution_started", remaining: remaining)
    Telemetry.execute([:schedule, :execution, :started], %{count: 1}, %{remaining: remaining})
    safely_execute(state.fun, remaining)

    if remaining == 1 do
      Logging.info("function_execution_completed")
      Telemetry.execute([:schedule, :completed], %{count: 1}, %{})
      {:stop, :normal, state}
    else
      schedule_work(state.time)
      {:noreply, %{state | remaining: remaining - 1}}
    end
  end

  defp schedule_work(time), do: Process.send_after(self(), :work, time)

  defp safely_execute(fun, remaining) do
    fun.()
  rescue
    exception ->
      Logging.error("function_execution_failed", error: Exception.message(exception))

      Telemetry.execute([:schedule, :execution, :failed], %{count: 1}, %{
        remaining: remaining,
        error: Exception.message(exception)
      })
  end
end
