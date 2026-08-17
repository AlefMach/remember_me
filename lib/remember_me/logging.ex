defmodule RememberMe.Logging do
  @moduledoc false

  require Logger

  @spec info(String.t(), keyword()) :: :ok
  def info(message, metadata \\ []) do
    if enabled?(), do: Logger.info(message, metadata)
    :ok
  end

  @spec error(String.t(), keyword()) :: :ok
  def error(message, metadata \\ []) do
    if enabled?(), do: Logger.error(message, metadata)
    :ok
  end

  defp enabled?, do: Application.get_env(:remember_me, :log_enabled, true)
end
