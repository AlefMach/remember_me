# Changelog

RememberMe is a robust but simple state memory machine organizer. It operates similar to Redis, but with the added capability to schedule and define the number of times a function will be executed, and of course, save any values associated with an assimilated key.

## [0.0.3] - 2026-08-17

## Unreleased

### Added

- `RememberMe.delete_value/1` to remove a stored value before its expiration.
- `:log_enabled` configuration to disable RememberMe logs.
- `RememberMe.list_keys/0` and `RememberMe.update_ttl/2` for memory management.
- Telemetry events for memory and scheduled-function lifecycle metrics.

### Changed

- Structured lifecycle logs for memory and scheduled functions, without logging stored values.
- Scheduled functions now use the documented default of one repetition.

### Fixed

- Replacing a key now cancels its former expiration timer, so the old timer cannot delete the new value.
- Scheduled function workers stop after their final execution.

## [0.0.2] - 2023-12-02

### Added

----

### Changed

 - Improve functions for indentify some errors, as time not detected and no has key :repeat

### Deprecated

### Removed

### Fixed

### Security

## [0.0.1] - 2023-12-02

- initial release
