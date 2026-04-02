# Architecture

## Role In The Stack

`llama_cpp_ex` is the provider-specific runtime kit for `llama.cpp` inside the
self-hosted inference stack.

```text
external_runtime_transport
  -> self_hosted_inference_core
  -> llama_cpp_ex
  -> req_llm consumers via published EndpointDescriptor values
```

The package owns the backend-specific service semantics that the shared kernel
must not guess:

- canonical boot-spec normalization
- `llama-server` flag rendering
- readiness probes
- health probes
- stop strategy for spawned services
- backend manifest details

## Boundary Rules

### `external_runtime_transport`

Transport remains below this package:

- subprocess start and shutdown mechanics
- stdout and stderr delivery
- interrupt and force-close behavior
- execution-surface routing

### `self_hosted_inference_core`

The shared kernel remains above this package:

- backend registry
- runtime instance reuse
- lease semantics
- compatibility calculation
- endpoint publication contracts

### `llama_cpp_ex`

This package sits between the two:

- it decides how `llama-server` should be launched
- it decides when the service is truly ready
- it decides how health should be interpreted
- it exposes honest backend capabilities northbound

## Current Topology

The first release supports one truthful runtime posture:

- startup kind: `:spawned`
- management mode: `:jido_managed`
- execution surface: `:local_subprocess`

`llama-server` can be launched remotely later, but `:ssh_exec` is not claimed
yet because remote path semantics, reachability, and shutdown guarantees still
need backend-specific verification.
