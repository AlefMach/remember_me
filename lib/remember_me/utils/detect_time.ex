defmodule RememberMe.Utils.DetectTime do
  @moduledoc false

  defmodule KeyError do
    @moduledoc false
    defexception message: "The argument in opts must be one of these [sec: n, min: x, hour: z]"
  end

  @spec time(keyword()) :: pos_integer()
  def time(opts) when is_list(opts) do
    time_options = Keyword.take(opts, [:sec, :min, :hour])

    case time_options do
      [] -> :timer.minutes(3)
      [{:sec, value}] -> to_milliseconds(value, &:timer.seconds/1)
      [{:min, value}] -> to_milliseconds(value, &:timer.minutes/1)
      [{:hour, value}] -> to_milliseconds(value, &:timer.hours/1)
      _ -> raise KeyError
    end
  end

  defp to_milliseconds(value, converter) when is_integer(value) and value > 0,
    do: converter.(value)

  defp to_milliseconds(_value, _converter),
    do: raise(ArgumentError, "time must be a positive integer")
end
