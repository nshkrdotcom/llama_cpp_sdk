# Boot Spec

## Purpose

`LlamaCppEx.BootSpec` is the canonical launch contract for the backend.
Raw caller input is normalized once, and all later layers consume the typed
spec instead of re-reading arbitrary option maps.

## Supported Fields

The first release normalizes these fields:

- `binary_path`
- `launcher_args`
- `model`
- `alias`
- `model_identity`
- `host`
- `port`
- `api_prefix`
- `ctx_size`
- `gpu_layers`
- `threads`
- `threads_batch`
- `parallel`
- `flash_attn`
- `embeddings`
- `api_key`
- `api_key_file`
- `timeout_seconds`
- `threads_http`
- `pooling`
- `ready_timeout_ms`
- `readiness_interval_ms`
- `health_interval_ms`
- `stop_timeout_ms`
- `execution_surface`
- `environment`
- `extra_args`
- `metadata`

`execution_surface` is intentionally narrow in the first release:
only `:local_subprocess` is accepted.

## Derived Fields

Normalization also derives endpoint-facing fields:

- `root_url`
- `base_url`
- `health_url`
- `headers`

That keeps endpoint publication deterministic and avoids re-deriving URLs in
multiple modules.
`headers` are derived from either `api_key` or the contents of `api_key_file`
so the published endpoint remains directly usable by northbound clients.

## Instance Identity

`BootSpec.instance_key/1` includes the fields that materially affect runtime
identity and reuse, including:

- model identity
- host and port
- flag-bearing launch knobs
- execution surface
- environment and extra args

Additive metadata does not affect the instance key.

## Unsupported In The First Release

The first release rejects Unix-socket hosts and rejects non-local execution
surfaces such as `:ssh_exec`.
Those are additive future paths, not hidden partial support.
