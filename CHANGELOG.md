# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic
Versioning.

## [0.1.0] - 2026-04-01

### Added

- Built `llama_cpp_ex` into the first concrete backend for the self-hosted
  inference stack.
- Added `LlamaCppEx.BootSpec` for `llama-server` boot-spec normalization.
- Added command rendering for the installed `llama-server` CLI surface.
- Added readiness and health probes above `external_runtime_transport`.
- Added backend manifest publication and endpoint resolution through
  `self_hosted_inference_core`.
- Added a spawned-endpoint example and fixture coverage for readiness, failure,
  health, and stop semantics.
- Added HexDocs guides for architecture, boot spec, readiness, and kernel
  integration.
