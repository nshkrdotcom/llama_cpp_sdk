Mix.Task.run("app.start")

defmodule LlamaCppEx.Examples.Support do
  @moduledoc false

  def new_fixture! do
    port = free_port()

    state_dir =
      Path.join(
        System.tmp_dir!(),
        "llama_cpp_ex_example_#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(state_dir)
    File.write!(Path.join(state_dir, "health.txt"), "healthy")

    %{
      port: port,
      state_dir: state_dir,
      python: System.find_executable("python3") || raise("python3 executable not found"),
      script: Path.expand("support/fake_llama_server.py", __DIR__)
    }
  end

  def cleanup!(%{state_dir: state_dir}) do
    File.rm_rf!(state_dir)
  end

  defp free_port do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, packet: :raw, active: false, reuseaddr: true])
    {:ok, port} = :inet.port(socket)
    :ok = :gen_tcp.close(socket)
    port
  end
end

alias LlamaCppEx.Examples.Support
alias SelfHostedInferenceCore.ConsumerManifest

fixture = Support.new_fixture!()

consumer =
  ConsumerManifest.new!(
    consumer: :jido_integration_req_llm,
    accepted_runtime_kinds: [:service],
    accepted_management_modes: [:jido_managed],
    accepted_protocols: [:openai_chat_completions],
    required_capabilities: %{streaming?: true},
    optional_capabilities: %{tool_calling?: :unknown},
    constraints: %{startup_kind: :spawned},
    metadata: %{example: true}
  )

try do
  {:ok, resolution} =
    LlamaCppEx.resolve_endpoint(
      %{
        binary_path: fixture.python,
        launcher_args: [fixture.script],
        model: "/models/example.gguf",
        alias: "example-model",
        host: "127.0.0.1",
        port: fixture.port,
        api_key: "example-token",
        environment: %{
          "LLAMA_CPP_EX_FAKE_MODE" => "ready",
          "LLAMA_CPP_EX_FAKE_STATE_DIR" => fixture.state_dir
        }
      },
      consumer,
      owner_ref: "example-owner",
      ttl_ms: 30_000
    )

  IO.puts("Instance:         #{resolution.instance.instance_id}")
  IO.puts("Endpoint:         #{resolution.endpoint.base_url}")
  IO.puts("Management mode:  #{inspect(resolution.endpoint.management_mode)}")
  IO.puts("Lease ref:        #{resolution.lease.lease_ref}")
  IO.puts("Compatibility:    #{inspect(resolution.compatibility.reason)}")
after
  Support.cleanup!(fixture)
end
