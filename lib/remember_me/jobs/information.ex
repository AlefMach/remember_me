defmodule RememberMe.Jobs.Information do
  @moduledoc false

  use Agent

  def start_link(_arg) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_value(name_state) do
    Agent.get(__MODULE__, & &1[name_state])
  end

  def guard_value(name_state, params) do
    Agent.update(__MODULE__, &Map.put(&1, name_state, params))
  end

  def delete_info(name_state) do
    Agent.update(__MODULE__, &Map.delete(&1, name_state))
  end
end
