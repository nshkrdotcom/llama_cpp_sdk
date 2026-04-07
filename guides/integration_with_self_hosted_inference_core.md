# Kernel Integration

## Registration

`llama_cpp_sdk` registers its internal backend implementation with
`self_hosted_inference_core`.

You can register explicitly:

```elixir
:ok = LlamaCppSdk.register_backend()
```

The application also registers the backend at startup when the package is used
as a dependency.

## Public Flow

The normal flow is:

1. build or normalize a `BootSpec`
2. build a `ConsumerManifest`
3. call `LlamaCppSdk.resolve_endpoint/3` or let
   `SelfHostedInferenceCore.ensure_endpoint/4` derive the `InstanceSpec`
4. pass the resulting `EndpointDescriptor` northbound to the control plane
5. let `req_llm` execute requests against `endpoint.base_url` with the
   published headers

## Example

```elixir
consumer =
  SelfHostedInferenceCore.ConsumerManifest.new!(
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
  LlamaCppSdk.resolve_endpoint(
    %{
      model: "/models/qwen.gguf",
      alias: "qwen",
      host: "127.0.0.1",
      port: 8080
    },
    consumer,
    owner_ref: "run-123",
    ttl_ms: 30_000
  )
```

## What Stays Out Of Scope

`llama_cpp_sdk` integrates with the kernel without re-owning:

- transport internals
- request execution
- OpenAI payload parsing
- durable control-plane truth

The published endpoint descriptor carries authorization headers derived from
`api_key` or `api_key_file`, but request execution still stays northbound in
`req_llm`.
