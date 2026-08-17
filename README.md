# RememberMe

![RememberMe logo](logo.jpg)

RememberMe is a small in-memory store and delayed-function scheduler for Elixir applications. Store a value under a string key with a TTL, retrieve or manage it while it is alive, and schedule a zero-arity function to run at a fixed interval.

It is useful for short-lived, process-local application state—not as a replacement for a persistent database or a distributed cache.

## Contents

- [Installation](#installation)
- [Memory with TTL](#memory-with-ttl)
- [Scheduling functions](#scheduling-functions)
- [Time options and validation](#time-options-and-validation)
- [Logging](#logging)
- [Telemetry](#telemetry)
- [Notes and limitations](#notes-and-limitations)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add `remember_me` to your dependencies:

```elixir
defp deps do
  [
    {:remember_me, "~> 1.0.4"}
  ]
end
```

Then fetch dependencies:

```sh
mix deps.get
```

RememberMe starts with your application; no manual process setup is required.

## Memory with TTL

### Store and retrieve a value

`guard/3` stores any non-function value under a string key. A subsequent call with the same key replaces both the value and its expiration timer.

```elixir
RememberMe.guard("deleted_message", %{"author" => "Foo", "body" => "Hello"}, min: 2)
# => :ok

RememberMe.find_value("deleted_message")
# => %{"author" => "Foo", "body" => "Hello"}
```

The value is returned as `nil` when the key is absent or has expired. If no time option is supplied, the TTL is three minutes.

### Delete a value early

```elixir
RememberMe.delete_value("deleted_message")
# => :ok
```

Deleting a missing key is safe and also returns `:ok`.

### List keys

```elixir
RememberMe.list_keys()
# => ["deleted_message"]
```

`list_keys/0` returns all active keys in alphabetical order.

### Extend or replace the TTL

`update_ttl/2` changes only a key's expiration; its stored value remains untouched.

```elixir
RememberMe.update_ttl("deleted_message", min: 5)
# => :ok

RememberMe.update_ttl("missing_key", sec: 10)
# => {:error, :not_found}
```

## Scheduling functions

`exec_func/2` runs a zero-arity function after the chosen interval. Set `:repeat` to run it again at the same interval; it defaults to `1`.

```elixir
RememberMe.exec_func(
  fn -> IO.puts("Hello, world!") end,
  sec: 10,
  repeat: 3
)
# => :ok
```

The function above runs after 10 seconds, then twice more at 10-second intervals. A function that raises is logged and reported through telemetry; later scheduled runs still continue.

## Time options and validation

The APIs that accept a time (`guard/3`, `update_ttl/2`, and `exec_func/2`) accept one of the following keyword options:

| Option | Meaning | Example |
| --- | --- | --- |
| `:sec` | seconds | `sec: 30` |
| `:min` | minutes | `min: 5` |
| `:hour` | hours | `hour: 1` |

Time values must be positive integers. Provide at most one time option; omitting it uses the three-minute default. For `exec_func/2`, `:repeat` must be a positive integer.

## Logging

RememberMe logs memory saves, deletions, TTL updates, and scheduled-function lifecycle events. Log metadata includes operational data such as a key, TTL, interval, repeat count, and expiration reason; stored values are never logged.

To disable its logs, add the following to `config/config.exs`:

```elixir
config :remember_me, log_enabled: false
```

## Telemetry

RememberMe emits standard `:telemetry` events. Stored values are never included in metadata.

| Event | Measurements | Metadata |
| --- | --- | --- |
| `[:remember_me, :memory, :saved]` | `ttl_ms` | `key` |
| `[:remember_me, :memory, :ttl_updated]` | `ttl_ms` | `key` |
| `[:remember_me, :memory, :deleted]` | `count` | `key`, `reason` (`:manual` or `:expired`) |
| `[:remember_me, :schedule, :scheduled]` | `interval_ms` | `repeat` |
| `[:remember_me, :schedule, :execution, :started]` | `count` | `remaining` |
| `[:remember_me, :schedule, :execution, :failed]` | `count` | `remaining`, `error` |
| `[:remember_me, :schedule, :completed]` | `count` | — |

Attach handlers with `:telemetry.attach/4` or your preferred telemetry integration.

## Notes and limitations

- Values live only in RAM on the current Erlang node. They are lost when the application stops and are not shared between nodes.
- Expiration and scheduled execution are best-effort timers; they are intended for application-level timing, not durable job processing.
- Keys must be strings, and scheduled functions must have arity zero.

## Contributing

Issues and pull requests are welcome at [AlefMach/remember_me](https://github.com/AlefMach/remember_me).

## License

Released under the [MIT License](LICENSE).
