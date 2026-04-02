defmodule LlamaCppEx.BootSpecTest do
  use ExUnit.Case, async: true

  alias ExternalRuntimeTransport.Command
  alias LlamaCppEx.{BootSpec, CommandBuilder}

  test "normalizes a boot spec into endpoint-ready defaults" do
    assert {:ok, spec} =
             BootSpec.new(
               model: "/models/Qwen3-14B-Instruct-Q4_K_M.gguf",
               port: 8091,
               ctx_size: 8_192,
               gpu_layers: "all",
               threads: 6,
               parallel: 2,
               flash_attn: true,
               embeddings: true,
               api_key: "local-token",
               api_prefix: "/llama",
               environment: %{"LLAMA_CACHE" => "/tmp/llama-cache"},
               metadata: %{deployment: :test}
             )

    assert spec.binary_path == "llama-server"
    assert spec.launcher_args == []
    assert spec.model == "/models/Qwen3-14B-Instruct-Q4_K_M.gguf"
    assert spec.alias == "Qwen3-14B-Instruct-Q4_K_M"
    assert spec.model_identity == "Qwen3-14B-Instruct-Q4_K_M"
    assert spec.host == "127.0.0.1"
    assert spec.port == 8091
    assert spec.gpu_layers == :all
    assert spec.flash_attn == :on
    assert spec.execution_surface == [surface_kind: :local_subprocess]
    assert spec.root_url == "http://127.0.0.1:8091"
    assert spec.base_url == "http://127.0.0.1:8091/llama/v1"
    assert spec.health_url == "http://127.0.0.1:8091/health"
    assert spec.headers == %{"authorization" => "Bearer local-token"}
    assert spec.environment["LLAMA_CACHE"] == "/tmp/llama-cache"
  end

  test "renders the normalized boot spec into a llama-server command" do
    spec =
      BootSpec.new!(
        binary_path: "llama-server",
        model: "/models/demo.gguf",
        alias: "demo-model",
        host: "0.0.0.0",
        port: 8088,
        ctx_size: 16_384,
        gpu_layers: 99,
        threads: 8,
        threads_batch: 4,
        parallel: 3,
        flash_attn: :auto,
        embeddings: true,
        api_key: "fixture-token",
        api_prefix: "/proxy",
        timeout_seconds: 120,
        extra_args: ["--verbose", "--no-webui"],
        environment: %{"LLAMA_CACHE" => "/var/lib/llama-cache"}
      )

    assert %Command{command: "llama-server", args: args, env: env} = CommandBuilder.command(spec)

    assert args == [
             "--model",
             "/models/demo.gguf",
             "--alias",
             "demo-model",
             "--host",
             "0.0.0.0",
             "--port",
             "8088",
             "--ctx-size",
             "16384",
             "--gpu-layers",
             "99",
             "--threads",
             "8",
             "--threads-batch",
             "4",
             "--parallel",
             "3",
             "--flash-attn",
             "auto",
             "--embedding",
             "--api-key",
             "fixture-token",
             "--api-prefix",
             "/proxy",
             "--timeout",
             "120",
             "--verbose",
             "--no-webui"
           ]

    assert env["LLAMA_CACHE"] == "/var/lib/llama-cache"
  end

  test "instance keys stay stable across additive metadata changes" do
    first =
      BootSpec.new!(
        model: "/models/demo.gguf",
        alias: "demo-model",
        port: 8092,
        metadata: %{deployment: :a}
      )

    second =
      BootSpec.new!(
        model: "/models/demo.gguf",
        alias: "demo-model",
        port: 8092,
        metadata: %{deployment: :b}
      )

    third =
      BootSpec.new!(
        model: "/models/demo.gguf",
        alias: "demo-model",
        port: 8093,
        metadata: %{deployment: :a}
      )

    assert BootSpec.instance_key(first) == BootSpec.instance_key(second)
    refute BootSpec.instance_key(first) == BootSpec.instance_key(third)
  end

  test "rejects unix socket hosts for the first HTTP endpoint release" do
    assert {:error, {:unsupported_host, "/tmp/llama.sock"}} =
             BootSpec.new(model: "/models/demo.gguf", host: "/tmp/llama.sock")
  end
end
