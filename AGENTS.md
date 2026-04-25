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

## Gates
- Run `mix format`.
- Run `mix compile --warnings-as-errors`.
- Run `mix test`.
- Run `mix credo --strict`.
- Run `mix dialyzer`.
- Run `mix docs --warnings-as-errors`.
