# Readiness And Health

## Readiness Policy

`llama_cpp_sdk` owns readiness above the transport seam.

The current readiness loop is intentionally simple and truthful:

1. launch the subprocess through `execution_plane`
2. observe stdout and stderr for operator-useful signals
3. confirm TCP reachability on the configured host and port
4. confirm HTTP readiness on `/health` or `/v1/models`
5. publish the endpoint only after the HTTP surface is actually reachable

This package does not trust process spawn alone as readiness.

## Health Policy

After publication, health is polled continuously:

- `200` on `/health` is treated as healthy unless the body says `degraded`
- `502`, `503`, and `504` are treated as degraded
- `/health` fallback to `/v1/models` keeps the first release honest when only
  the OpenAI-compatible surface is present
- transport or probe failure is surfaced northbound as `unavailable`

## Failure Semantics

The first release has explicit failure paths:

- process exit before readiness -> typed backend exit error
- readiness never achieved -> readiness timeout
- health degradation after publication -> runtime remains published but marked
  degraded

That keeps the service-runtime truth separate from request execution truth.

## Stop Strategy

The backend stop strategy for `:spawned` uses the transport capabilities that
exist today:

1. send `interrupt`
2. wait for disconnect until `stop_timeout_ms`
3. force-close if the process stays alive

The package does not pretend it has a stronger stop contract than the shared
transport can actually enforce.

Lease reuse, attachability, and endpoint publication remain above this package
in `self_hosted_inference_core`.
