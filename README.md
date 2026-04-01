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

`llama_cpp_ex` is a barebones Elixir project intended to become a clean
integration surface for `llama.cpp` workflows, local model execution, and
future interoperability with the broader nshkr AI SDK ecosystem.

The repository is intentionally minimal at this stage. It establishes the
package structure, project metadata, documentation shape, release notes, and
branding assets needed to grow into a production-quality library without
carrying scaffold noise forward.

## Scope

- Elixir-first wrapper surface for local `llama.cpp` experimentation
- Repository and package metadata suitable for Hex and HexDocs publication
- Brand assets and documentation primitives for downstream SDK alignment
- A conservative baseline that can evolve without early architectural debt

## Installation

Add `llama_cpp_ex` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:llama_cpp_ex, "~> 0.1.0"}
  ]
end
```

## Development

Run the standard local checks from the repository root:

```bash
mix format
mix test
```

## Documentation

HexDocs can be generated locally with:

```bash
mix docs
```

When published, documentation will be available at
<https://hexdocs.pm/llama_cpp_ex>.

## License

This repository is released under the MIT License. See `LICENSE` for the
canonical license text and `CHANGELOG.md` for release history.
