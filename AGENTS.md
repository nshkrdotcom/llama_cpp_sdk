# Repository Guidelines

## Project Structure
- `lib/` contains public `LlamaCppSdk` modules and backend runtime adapters.
- `test/` contains ExUnit coverage.
- `guides/`, `examples/`, `README.md`, and `CHANGELOG.md` must stay aligned with runtime and dependency behavior.
- `doc/` is generated output and should not be edited.

## Execution Plane Stack
- `llama_cpp_sdk` consumes `self_hosted_inference_core` for service-runtime semantics and should not expose lower process mechanics directly.
- Keep `self_hosted_inference_core` and `execution_plane` dependency
  resolution publish-aware: local path deps for sibling development, Hex
  constraints for release builds.
- Local sibling development uses `../execution_plane/core/execution_plane` for
  `:execution_plane` and `../execution_plane/runtimes/execution_plane_process`
  for the process lane. Do not point `:execution_plane` at the sibling repo
  root; that root is the non-published Blitz workspace project.
- `llama_cpp_sdk` is not in the Weld consumer set. Do not add a Weld
  dependency, Weld task, or Weld Credo check as part of Phase 2 cleanup.

## Dependency Sources

- Cross-repo dependency selection belongs in
  `build_support/dependency_sources.config.exs` and is consumed through the
  canonical `build_support/dependency_sources.exs` helper.
- Machine-local dependency overrides belong in `.dependency_sources.local.exs`.
  Keep that file untracked.
- Dependency source selection must not read environment variables.

## Runtime Environment

- Runtime application code under `lib/**` must not call direct OS environment
  APIs such as `System.get_env/1`, `System.fetch_env/1`,
  `System.fetch_env!/1`, `System.put_env/2`, `System.delete_env/1`, or
  `System.get_env/0`.
- Deployment environment reads belong at OTP boot boundaries such as
  `config/runtime.exs` or a `Config.Provider`. Runtime modules should receive
  explicit options or materialized application config.

## Gates
- Run `mix format`.
- Run `mix compile --warnings-as-errors`.
- Run `mix test`.
- Run `mix credo --strict`.
- Run `mix dialyzer`.
- Run `mix docs --warnings-as-errors`.
