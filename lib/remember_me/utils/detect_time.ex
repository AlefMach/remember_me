defmodule RememberMe.Utils.DetectTime do
  @moduledoc false

  defmodule KeyError do
    @moduledoc false
    defexception message: "The argument in opts must be one of these [sec: 60, min: 60, hour: 1]"
  end

  @spec time(keyword) :: non_neg_integer
  def time(opts) when length(opts) == 1 do
    key =
      opts
      |> Keyword.keys()
      |> Enum.at(0)

    case key do
      :sec ->
        :timer.seconds(Keyword.get(opts, key))

      :min ->
        :timer.minutes(Keyword.get(opts, key))

      :hour ->
        :timer.hours(Keyword.get(opts, key))

      _ -> raise KeyError
    end
  end

  def time(_opts), do: :timer.minutes(3)
end
