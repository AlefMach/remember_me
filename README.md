# RememberMe

![](logo.jpg#vitrinedev)

RememberMe is a robust but simple state memory machine organizer. It operates similar to Redis, but with the added capability to schedule and define the number of times a function will be executed, and of course, save any values associated with an assimilated key.

## Table of Contents
- Introduction
- Examples
- Installation
- Usage
- Contributing
- License

## Introduction

RememberMe is a utility module that provides an efficient and user-friendly way to manage state memory. It allows you to store and retrieve data using keys, schedule functions for execution, and more. It's particularly useful for scenarios where you need to handle state persistence and time-based function execution.

## Examples
### Storing Values
```elixir
# Store a value in memory with a key
RememberMe.guard("text_deleted", %{"user" => "Foo", "text" => "A any message"}, min: 2)
# Result: :ok
```

### Retrieving Values
```elixir
# Retrieve a previously stored value using the key
value = RememberMe.find_value("text_deleted")
# Result: %{"user" => "Foo", "text" => "A any message"}
```

### Deleting Values

```elixir
# Delete a value before its expiration
RememberMe.delete_value("text_deleted")
# Result: :ok
```

### Listing Active Keys and Updating Expiration

```elixir
RememberMe.list_keys()
# Result: ["text_deleted"]

# Keep the stored value and extend its expiration
RememberMe.update_ttl("text_deleted", min: 5)
# Result: :ok
```

## Scheduling Function Execution

Schedule a function for execution after a certain time

```elixir
RememberMe.exec_func(fn -> IO.puts "Hello World!" end, [sec: 10, repeat: 3])
# Result: :ok
# Output:
# Hello World!
# Hello World!
# ... (repeated three times)
```

## Installation

RememberMe can be installed by adding it as a dependency in your `mix.exs`
file:

```elixir
defp deps do
  [
    {:remember_me, "~> 0.0.2"}
  ]
end
```

After adding the dependency, run `mix deps.get`` to fetch and install it.

## Usage

RememberMe provides the following functions for managing memory and function execution:

### guard/3
This function stores a value in memory using a key and optional options for time duration.

```elixir
RememberMe.guard(name_state, value, opts \\ [])
```
- `name_state`: The key used to identify the stored value.
- `value`: The data you want to store.
- `opts`: Additional options (e.g., min, sec, hour) to define the time 
duration the value should be stored.

### find_value/1

This function retrieves a previously stored value from memory using a key.

```elixir
RememberMe.find_value(name_state)
```
- `name_state`: The key used to identify the stored value.

### delete_value/1

This function removes a value from memory before its configured expiration. It is
safe to call when the key does not exist.

```elixir
RememberMe.delete_value(name_state)
```

- `name_state`: The key used to identify the stored value.

### list_keys/0

Returns the active memory keys in alphabetical order.

### update_ttl/2

Changes a value's expiration without replacing it. It returns
`{:error, :not_found}` if the key does not exist.

```elixir
RememberMe.update_ttl(name_state, min: 5)
```

### exec_func/2

This function schedules a function for execution after a specified time and optionally defines the number of times the function should be repeated.

```elixir
RememberMe.exec_func(fun, opts \\ [])
```
- `fun`: The function you want to schedule for execution.
- `opts`: Additional options (e.g., min, sec, hour, repeat) to define the execution time and repetition count of the function.

For more information on available options and usage examples, refer to the Examples section above.

## Logging

The library logs memory saves and deletions, as well as scheduled-function lifecycle
events. Log metadata includes the key, expiration reason, interval, and repeat count;
stored values are intentionally not logged.

To disable all RememberMe logs, add this to your application's `config/config.exs`:

```elixir
config :remember_me, log_enabled: false
```

## Telemetry

RememberMe emits standard `:telemetry` events. Values stored in memory are never
included in event metadata.

| Event | Measurements | Metadata |
| --- | --- | --- |
| `[:remember_me, :memory, :saved]` | `ttl_ms` | `key` |
| `[:remember_me, :memory, :ttl_updated]` | `ttl_ms` | `key` |
| `[:remember_me, :memory, :deleted]` | `count` | `key`, `reason` |
| `[:remember_me, :schedule, :scheduled]` | `interval_ms` | `repeat` |
| `[:remember_me, :schedule, :execution, :started]` | `count` | `remaining` |
| `[:remember_me, :schedule, :execution, :failed]` | `count` | `remaining`, `error` |
| `[:remember_me, :schedule, :completed]` | `count` | — |

# Contributing
Contributions are welcome! If you encounter any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/AlefMach/remember_me).

# License
This project is licensed under the MIT License.
