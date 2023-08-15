defmodule RememberMe do
  @moduledoc """
  RememberMe is a robust but simple state memory machine organizer. you can assimilate it like a Redis, but the difference is that you can schedule and define the number of times a function will be executed and of course save any values ​​from an assimilated key.

  ## Installation

  RememberMe can be installed by adding it as a dependency in your `mix.exs`
  file:

  ```elixir
  defp deps do
    [
      {:remember_me, "~> 0.0.1"}
    ]
  end

  ## Examples
    iex> RememberMe.guard("text_deleted", %{"user" => "Foo", "text" => "A any message"}, min: 2)
    :ok

    iex> RememberMe.find_value("text_deleted")
    %{
      "user" => "Foo",
      "text" => "A any message"
    }

    iex> RememberMe.exec_func(fn -> IO.puts "Hello World!" end, [sec: 10, repeat: 3])
    :ok
    Hello World!

    20:13:59.336 [info] Started execute function
    Hello World!
    Hello World!
    20:14:29.342 [info] Finish Execute function
    iex>


    Important to note that if no opts are passed, the default value for time will be 3 minutes and the repeat will default to 1 time.
  """
  alias RememberMe.Utils.DetectTime
  alias RememberMe.Jobs.{Information, InformationJob, ScheduleJob}

  @spec validate_params_guard(String.t(), any(), Atom) ::
          {:__block__ | {:., [], [:andalso | :erlang, ...]}, [],
           [{:= | {any, any, any}, list, [...]}, ...]}
  defguard validate_params_guard(name_state, value, opts)
           when is_binary(name_state) and not is_function(value) and is_list(opts)

  @spec validate_params_fun(any, any) ::
          {:__block__ | {:., [], [:andalso | :erlang, ...]}, [],
           [{:= | {any, any, any}, list, [...]}, ...]}
  defguard validate_params_fun(value, opts)
           when is_function(value) and is_list(opts)

  @doc """
  Will save a value in RAM memory with a key to get it later

  ## Parameters

    - name_state: String that represents the name of the key.
    - value: Any value
    - opts: Sets a time to stay in memory, can be sec, min or hour - default: 3 minutes

  ## Examples

      iex> RememberMe.guard("text_deleted", %{"user" => "Foo", "text" => "A any message"}, min: 2)
      :ok

      iex> RememberMe.guard("text_deleted", %{"user" => "Foo", "text" => "Another message"}, min: 2)
      :ok


  Note that if you pass a key equal to the previous one to the guard(), it will simply replace the value with the current value.
  """
  @spec guard(binary, any(), keyword) :: :ignore | {:error, any} | :ok
  def guard(name_state, value, opts \\ []) when validate_params_guard(name_state, value, opts) do
    time = DetectTime.time(opts)

    params_gen = %{
      time: time,
      name_state: name_state
    }

    case InformationJob.start_link(params_gen) do
      {:ok, _} ->
        Information.guard_value(name_state, value)
        :ok

      err ->
        err
    end
  end

  @doc """
  Will get value saved in memory from key

  ## Parameters

    - name_state: String that represents the name of the key.

  ## Examples

    iex> RememberMe.find_value("text_deleted")
    %{
      "user" => "Foo",
      "text" => "A any message"
    }
  """
  @spec find_value(binary) :: any
  def find_value(name_state) when is_binary(name_state), do: Information.get_value(name_state)

  @doc """
  will queue a specified amount of functions in memory to be executed in the given time

  ## Parameters

    - fun: Function that will executed
    - opts: Sets a time to stay in memory, can be sec, min or hour - default: 3 minutes and defines the number of times the function should be repeated, default is 1

  ## Examples

    iex> RememberMe.exec_func(fn -> IO.puts "Hello World!" end, [sec: 10, repeat: 3])
    :ok
    Hello World!

    20:13:59.336 [info] Started execute function
    Hello World!
    Hello World!
    20:14:29.342 [info] Finish Execute function
    iex>
  """
  @spec exec_func(fun, maybe_improper_list) :: :ignore | :ok | {:error, any}
  def exec_func(fun, opts \\ []) when validate_params_fun(fun, opts) do
    time =
      opts
      |> Keyword.delete(:repeat)
      |> DetectTime.time()

    repeat = get_repeat(opts)

    params = %{
      fun: fun,
      time: time,
      repeat: repeat
    }

    case ScheduleJob.start_link(params) do
      {:ok, _} ->
        :ok

      err ->
        err
    end
  end

  defp get_repeat(opts) do
    repeat =
      opts
      |> Keyword.delete(:sec)
      |> Keyword.delete(:min)
      |> Keyword.delete(:hour)

    case repeat do
      [] ->
        1

      _ ->
        Keyword.get(repeat, :repeat)
    end
  end
end
