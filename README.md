<p align="center">
  <img src="assets/llama_cpp_ex.svg" alt="llama_cpp_ex logo" width="200" height="200" />
</p>

<p align="center">
  <a href="https://hex.pm/packages/llama_cpp_ex">
    <img src="https://img.shields.io/hexpm/v/llama_cpp_ex.svg" alt="Hex version" />
  </a>
  <a href="https://hexdocs.pm/llama_cpp_ex">
    <img src="https://img.shields.io/badge/hexdocs-llama__cpp__ex-blue.svg" alt="HexDocs" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License" />
  </a>
</p>

# LlamaCppEx

`llama_cpp_ex` is the first concrete backend package for the self-hosted
inference stack:

```text
external_runtime_transport
  -> self_hosted_inference_core
  -> llama_cpp_ex
  -> req_llm through published EndpointDescriptor values
```

It owns the `llama-server` specifics that do not belong in the shared kernel:

- boot-spec normalization
- `llama-server` flag rendering
- readiness and health probes
- stop semantics for a spawned service
- backend manifest publication
- OpenAI-compatible endpoint descriptor production

It does not parse OpenAI payloads, token streams, or inference responses.
Those stay northbound in `req_llm` and the calling control plane.

## Current Release Boundary

The first backend release is intentionally narrow and truthful:

- supported startup kind: `:spawned`
- supported execution surface: `:local_subprocess`
- published protocol: `:openai_chat_completions`
- northbound integration: `self_hosted_inference_core`
- `:ssh_exec` story: documented as a future additive path once remote model-path
  semantics, readiness reachability, and shutdown guarantees are verified

## Installation

Add the package to your dependency list:

```elixir
def deps do
  [
    {:llama_cpp_ex, "~> 0.1.0"}
  ]
end
```

`llama_cpp_ex` depends on `self_hosted_inference_core`, which in turn depends
on `external_runtime_transport`.

## Quick Start

Resolve a spawned endpoint through the shared kernel:

```elixir
alias LlamaCppEx
alias SelfHostedInferenceCore.ConsumerManifest

consumer =
  ConsumerManifest.new!(
    consumer: :jido_integration_req_llm,
    accepted_runtime_kinds: [:service],
    accepted_management_modes: [:jido_managed],
    accepted_protocols: [:openai_chat_completions],
    required_capabilities: %{streaming?: true},
    optional_capabilities: %{tool_calling?: :unknown},
    constraints: %{startup_kind: :spawned},
    metadata: %{}
  )

{:ok, resolution} =
  LlamaCppEx.resolve_endpoint(
    %{
      model: "/models/qwen3-14b-instruct.gguf",
      alias: "qwen3-14b-instruct",
      host: "127.0.0.1",
      port: 8080,
      ctx_size: 8_192,
      gpu_layers: :all,
      threads: 8,
      parallel: 2,
      flash_attn: :auto
    },
    consumer,
    owner_ref: "run-123",
    ttl_ms: 30_000
  )

resolution.endpoint.base_url
resolution.lease.lease_ref
```

The backend normalizes the boot spec, registers itself with
`self_hosted_inference_core`, and publishes an endpoint descriptor once the
service is actually ready.

## Supported Boot Fields

The first release supports normalized fields for the installed
`llama-server` CLI surface:

- `binary_path`
- `launcher_args`
- `model`
- `alias`
- `host`
- `port`
- `ctx_size`
- `gpu_layers`
- `threads`
- `threads_batch`
- `parallel`
- `flash_attn`
- `embeddings`
- `api_key`
- `api_key_file`
- `api_prefix`
- `timeout_seconds`
- `threads_http`
- `pooling`
- `environment`
- `extra_args`

See [`guides/boot_spec.md`](guides/boot_spec.md) for the full contract.

## Readiness And Health

Readiness is owned here, above the transport seam:

1. launch the spawned process via `external_runtime_transport`
2. probe TCP reachability on the requested host and port
3. probe HTTP availability on `/health` or `/v1/models`
4. publish the endpoint only after readiness succeeds

Health continues to poll after publication so the shared kernel can expose
`healthy`, `degraded`, or `unavailable` runtime truth.

## Examples And Guides

- [`guides/architecture.md`](guides/architecture.md)
- [`guides/readiness_and_health.md`](guides/readiness_and_health.md)
- [`guides/integration_with_self_hosted_inference_core.md`](guides/integration_with_self_hosted_inference_core.md)
- [`examples/README.md`](examples/README.md)

## Development

Run the normal quality checks from the repo root when your environment allows
Mix to create its local coordination socket:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
MIX_ENV=test mix credo --strict
MIX_ENV=dev mix dialyzer
mix docs
```

## License

This repository is released under the MIT License. See `LICENSE` for the
canonical license text and `CHANGELOG.md` for release history.
