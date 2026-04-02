# Examples

## `:spawned` Endpoint Publication Demo

`spawned_endpoint_demo.exs` launches the backend against an honest fake
`llama-server` fixture and prints the endpoint descriptor that would be handed
northbound to `jido_integration` or another consumer.

The example is truthful about what it demonstrates:

- the runtime path is really `:spawned`
- the endpoint publication contract is the real
  `SelfHostedInferenceCore.EndpointDescriptor`
- the fixture avoids requiring a local model download or a live `llama-server`
  binary for the demo

Run it with:

```bash
mix run examples/spawned_endpoint_demo.exs
```
