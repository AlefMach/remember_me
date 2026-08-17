defmodule RememberMeTelemetryHandler do
  def handle(event, measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, measurements, metadata})
  end
end

defmodule RememberMeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  test "can disable RememberMe logs through application config" do
    previous_value = Application.get_env(:remember_me, :log_enabled)
    Application.put_env(:remember_me, :log_enabled, false)

    on_exit(fn ->
      if is_nil(previous_value),
        do: Application.delete_env(:remember_me, :log_enabled),
        else: Application.put_env(:remember_me, :log_enabled, previous_value)
    end)

    assert capture_log(fn -> RememberMe.guard("quiet-message", "hello", sec: 1) end) == ""
  end

  test "deletes a value manually" do
    assert :ok = RememberMe.guard("message-to-delete", "hello", sec: 1)
    assert "hello" = RememberMe.find_value("message-to-delete")

    assert :ok = RememberMe.delete_value("message-to-delete")
    assert is_nil(RememberMe.find_value("message-to-delete"))
  end

  test "lists active keys" do
    assert :ok = RememberMe.guard("list-key-b", "second", sec: 5)
    assert :ok = RememberMe.guard("list-key-a", "first", sec: 5)

    assert ["list-key-a", "list-key-b"] =
             RememberMe.list_keys()
             |> Enum.filter(&(&1 in ["list-key-a", "list-key-b"]))

    RememberMe.delete_value("list-key-a")
    RememberMe.delete_value("list-key-b")
  end

  test "updates TTL without changing the stored value and emits telemetry" do
    handler_id = "remember-me-ttl-test-#{System.unique_integer([:positive])}"
    test_pid = self()

    :ok =
      :telemetry.attach(
        handler_id,
        [:remember_me, :memory, :ttl_updated],
        &RememberMeTelemetryHandler.handle/4,
        test_pid
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert :ok = RememberMe.guard("ttl-message", "kept", sec: 1)
    assert :ok = RememberMe.update_ttl("ttl-message", sec: 2)

    assert_receive {:telemetry_event, [:remember_me, :memory, :ttl_updated], %{ttl_ms: 2_000},
                    %{key: "ttl-message"}}

    Process.sleep(1_100)
    assert "kept" = RememberMe.find_value("ttl-message")
    assert :ok = RememberMe.delete_value("ttl-message")
  end

  test "returns not found when updating the TTL of an absent key" do
    assert {:error, :not_found} = RememberMe.update_ttl("absent-key", sec: 1)
  end

  test "replacing a value keeps the most recent expiration" do
    assert :ok = RememberMe.guard("replacement", "old", sec: 1)
    Process.sleep(500)
    assert :ok = RememberMe.guard("replacement", "new", sec: 2)

    Process.sleep(700)
    assert "new" = RememberMe.find_value("replacement")
  end

  test "exec_func uses the documented default repeat" do
    test_pid = self()

    assert :ok = RememberMe.exec_func(fn -> send(test_pid, :executed) end, sec: 1)
    assert_receive :executed, 1_500
  end
end
