defmodule RememberMe.Jobs.Information do
  @moduledoc false

  use GenServer

  alias RememberMe.{Logging, Telemetry}

  @type entry :: {any(), reference(), reference()}
  @type state :: %{values: %{optional(binary()) => entry()}}

  def start_link(_arg), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @spec put_value(binary(), any(), non_neg_integer()) :: :ok
  def put_value(name_state, value, ttl),
    do: GenServer.call(__MODULE__, {:put, name_state, value, ttl})

  @spec get_value(binary()) :: any()
  def get_value(name_state), do: GenServer.call(__MODULE__, {:get, name_state})

  @spec delete_info(binary()) :: :ok
  def delete_info(name_state), do: GenServer.call(__MODULE__, {:delete, name_state})

  @spec keys() :: [binary()]
  def keys, do: GenServer.call(__MODULE__, :keys)

  @spec update_ttl(binary(), pos_integer()) :: :ok | {:error, :not_found}
  def update_ttl(name_state, ttl), do: GenServer.call(__MODULE__, {:update_ttl, name_state, ttl})

  @impl true
  def init(_arg), do: {:ok, %{values: %{}}}

  @impl true
  def handle_call({:put, name_state, value, ttl}, _from, state) do
    cancel_timer(state.values[name_state])
    token = make_ref()
    timer_ref = Process.send_after(self(), {:expire, name_state, token}, ttl)
    values = Map.put(state.values, name_state, {value, timer_ref, token})

    Logging.info("memory_saved", key: name_state, ttl_ms: ttl)
    Telemetry.execute([:memory, :saved], %{ttl_ms: ttl}, %{key: name_state})
    {:reply, :ok, %{state | values: values}}
  end

  def handle_call({:get, name_state}, _from, state) do
    value = state.values |> Map.get(name_state) |> value_from_entry()
    {:reply, value, state}
  end

  def handle_call({:delete, name_state}, _from, state) do
    case Map.pop(state.values, name_state) do
      {nil, values} ->
        {:reply, :ok, %{state | values: values}}

      {entry, values} ->
        cancel_timer(entry)
        Logging.info("memory_deleted", key: name_state, reason: :manual)
        Telemetry.execute([:memory, :deleted], %{count: 1}, %{key: name_state, reason: :manual})
        {:reply, :ok, %{state | values: values}}
    end
  end

  def handle_call(:keys, _from, state) do
    {:reply, state.values |> Map.keys() |> Enum.sort(), state}
  end

  def handle_call({:update_ttl, name_state, ttl}, _from, state) do
    case Map.get(state.values, name_state) do
      nil ->
        {:reply, {:error, :not_found}, state}

      {value, _timer_ref, _token} = entry ->
        cancel_timer(entry)
        token = make_ref()
        timer_ref = Process.send_after(self(), {:expire, name_state, token}, ttl)
        values = Map.put(state.values, name_state, {value, timer_ref, token})

        Logging.info("memory_ttl_updated", key: name_state, ttl_ms: ttl)
        Telemetry.execute([:memory, :ttl_updated], %{ttl_ms: ttl}, %{key: name_state})
        {:reply, :ok, %{state | values: values}}
    end
  end

  @impl true
  def handle_info({:expire, name_state, token}, state) do
    case Map.get(state.values, name_state) do
      {_value, _timer_ref, ^token} ->
        values = Map.delete(state.values, name_state)
        Logging.info("memory_deleted", key: name_state, reason: :expired)
        Telemetry.execute([:memory, :deleted], %{count: 1}, %{key: name_state, reason: :expired})
        {:noreply, %{state | values: values}}

      _ ->
        # A newer value for this key was stored after this timer was queued.
        {:noreply, state}
    end
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer({_value, timer_ref, _token}), do: Process.cancel_timer(timer_ref)

  defp value_from_entry(nil), do: nil
  defp value_from_entry({value, _timer_ref, _token}), do: value
end
