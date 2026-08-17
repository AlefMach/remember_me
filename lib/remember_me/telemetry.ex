defmodule RememberMe.Telemetry do
  @moduledoc false

  @spec execute([atom()], map(), map()) :: :ok
  def execute(event, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute([:remember_me | event], measurements, metadata)
  end
end
