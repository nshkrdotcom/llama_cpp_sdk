defmodule LlamaCppSdk.BackendIntegrationTest do
  use ExUnit.Case, async: false

  @socket_capable? (case :gen_tcp.listen(0, [
                           :binary,
                           packet: :raw,
                           active: false,
                           reuseaddr: true
                         ]) do
                      {:ok, socket} ->
                        :ok = :gen_tcp.close(socket)
                        true

                      {:error, :eperm} ->
                        false

                      {:error, _reason} ->
                        true
                    end)

  if not @socket_capable? do
    @moduletag skip: "requires a socket-capable environment for spawned backend integration"
  end

  alias SelfHostedInferenceCore.{
    BackendManifest,
    ConsumerManifest,
    EndpointDescriptor,
    LeaseRef
  }

  alias LlamaCppSdk.TestSupport.FakeLlamaServerFixture

  setup do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    start_core_supervisor()

    _ = SelfHostedInferenceCore.stop_all_instances()
    _ = LlamaCppSdk.unregister_backend()

    :ok = LlamaCppSdk.register_backend()

    on_exit(fn ->
      _ = SelfHostedInferenceCore.stop_all_instances()
      _ = LlamaCppSdk.unregister_backend()
    end)

    :ok
  end

  test "registers a backend manifest and publishes a spawned endpoint through the kernel" do
    fixture = FakeLlamaServerFixture.new!()

    on_exit(fn ->
      FakeLlamaServerFixture.cleanup(fixture)
    end)

    attrs =
      FakeLlamaServerFixture.boot_attrs(
        fixture,
        alias: "fixture-qwen",
        api_prefix: "/managed",
        api_key: "fixture-token",
        embeddings: true,
        metadata: %{fixture: :ready}
      )

    assert {:ok, resolution} =
             LlamaCppSdk.resolve_endpoint(
               attrs,
               req_llm_consumer(),
               owner_ref: "run-123",
               ttl_ms: 5_000
             )

    assert {:ok, %BackendManifest{} = manifest} =
             SelfHostedInferenceCore.fetch_backend_manifest(:llama_cpp_sdk)

    assert manifest.backend == :llama_cpp_sdk
    assert manifest.runtime_kind == :service
    assert manifest.startup_kind == :spawned
    assert manifest.management_modes == [:jido_managed]
    assert manifest.supported_surfaces == [:local_subprocess]

    assert %EndpointDescriptor{
             runtime_kind: :service,
             management_mode: :jido_managed,
             target_class: :self_hosted_endpoint,
             protocol: :openai_chat_completions,
             provider_identity: :llama_cpp_sdk,
             model_identity: "fixture-qwen",
             source_runtime: :llama_cpp_sdk,
             base_url: "http://127.0.0.1:" <> _rest
           } = resolution.endpoint

    assert resolution.endpoint.base_url == "http://127.0.0.1:#{fixture.port}/managed/v1"
    assert resolution.endpoint.headers == %{"authorization" => "Bearer fixture-token"}
    assert resolution.instance.startup_kind == :spawned
    assert resolution.instance.health_status == :healthy
    assert %LeaseRef{} = resolution.lease
    refute resolution.reused?

    assert {:ok, published} =
             SelfHostedInferenceCore.publish_endpoint(resolution.instance.instance_id)

    assert published.base_url == resolution.endpoint.base_url
    assert published.lease_ref == nil

    args_path = FakeLlamaServerFixture.args_path(fixture)

    assert {:ok, args_json} =
             wait_until(fn ->
               if File.exists?(args_path) do
                 {:ok, File.read!(args_path)}
               else
                 :retry
               end
             end)

    assert args_json =~ "\"port\": #{fixture.port}"
    assert args_json =~ "\"api_prefix\": \"/managed\""
    assert args_json =~ "\"alias\": \"fixture-qwen\""

    assert {:ok, 200, completion_body} =
             post_json(
               resolution.endpoint.base_url <> "/chat/completions",
               %{
                 model: "fixture-qwen",
                 messages: [%{role: "user", content: "phase 4 contract"}],
                 stream: false
               },
               resolution.endpoint.headers
             )

    assert completion_body["choices"] |> List.first() |> get_in(["message", "content"]) ==
             "Fake llama response: phase 4 contract"

    assert {:ok, 200, stream_body} =
             post_sse(
               resolution.endpoint.base_url <> "/chat/completions",
               %{
                 model: "fixture-qwen",
                 messages: [%{role: "user", content: "phase 4 streaming contract"}],
                 stream: true
               },
               resolution.endpoint.headers
             )

    assert streamed_text_from_sse(stream_body) ==
             "Fake llama response: phase 4 streaming contract"

    assert stream_body =~ "[DONE]"
  end

  test "tracks degraded health after endpoint publication" do
    fixture = FakeLlamaServerFixture.new!()

    on_exit(fn ->
      FakeLlamaServerFixture.cleanup(fixture)
    end)

    assert {:ok, resolution} =
             LlamaCppSdk.resolve_endpoint(
               FakeLlamaServerFixture.boot_attrs(fixture),
               req_llm_consumer(),
               owner_ref: "health-owner",
               ttl_ms: 5_000
             )

    :ok = FakeLlamaServerFixture.set_health(fixture, :degraded)

    assert {:ok, snapshot} =
             wait_until(fn ->
               case SelfHostedInferenceCore.lookup_instance(resolution.instance.instance_id) do
                 {:ok, %{health_status: :degraded} = instance} -> {:ok, instance}
                 _other -> :retry
               end
             end)

    assert snapshot.health_status == :degraded
  end

  @tag capture_log: true
  test "surfaces early process exit before readiness as a typed backend error" do
    fixture = FakeLlamaServerFixture.new!()

    on_exit(fn ->
      FakeLlamaServerFixture.cleanup(fixture)
    end)

    attrs =
      FakeLlamaServerFixture.boot_attrs(
        fixture,
        mode: "exit_before_ready",
        ready_timeout_ms: 500
      )

    assert {:error, {:llama_server_exit, %{status: :exit, code: 17}}} =
             LlamaCppSdk.ensure_instance(attrs, await_timeout_ms: 2_000)
  end

  @tag capture_log: true
  test "surfaces readiness timeouts when the process never binds an endpoint" do
    fixture = FakeLlamaServerFixture.new!()

    on_exit(fn ->
      FakeLlamaServerFixture.cleanup(fixture)
    end)

    attrs =
      FakeLlamaServerFixture.boot_attrs(
        fixture,
        mode: "never_ready",
        ready_timeout_ms: 150
      )

    assert {:error, :readiness_timeout} =
             LlamaCppSdk.ensure_instance(attrs, await_timeout_ms: 2_000)
  end

  test "uses the backend stop strategy when the runtime is stopped" do
    fixture = FakeLlamaServerFixture.new!()

    on_exit(fn ->
      FakeLlamaServerFixture.cleanup(fixture)
    end)

    assert {:ok, resolution} =
             LlamaCppSdk.resolve_endpoint(
               FakeLlamaServerFixture.boot_attrs(fixture),
               req_llm_consumer(),
               owner_ref: "stop-owner",
               ttl_ms: 5_000
             )

    assert :ok = SelfHostedInferenceCore.stop_instance(resolution.instance.instance_id)

    assert {:ok, signal_body} =
             wait_until(fn ->
               signal_path = FakeLlamaServerFixture.signal_path(fixture)

               if File.exists?(signal_path) do
                 {:ok, File.read!(signal_path)}
               else
                 :retry
               end
             end)

    assert signal_body =~ "SIGINT"
  end

  defp req_llm_consumer do
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
  end

  defp wait_until(fun, attempts \\ 120)

  defp wait_until(_fun, 0), do: flunk("timed out waiting for integration condition")

  defp wait_until(fun, attempts) do
    case fun.() do
      {:ok, value} ->
        {:ok, value}

      :retry ->
        Process.sleep(25)
        wait_until(fun, attempts - 1)
    end
  end

  defp streamed_text_from_sse(body) when is_binary(body) do
    body
    |> String.split("\n\n", trim: true)
    |> Enum.reduce("", fn frame, acc -> acc <> sse_frame_text(frame) end)
  end

  defp sse_frame_text(frame) do
    frame
    |> String.trim()
    |> decode_sse_frame()
    |> Map.get("content", "")
  end

  defp decode_sse_frame("data: [DONE]"), do: %{}

  defp decode_sse_frame("data: " <> json) do
    case Jason.decode(json) do
      {:ok, %{"choices" => [%{"delta" => delta}]}} -> delta
      _other -> %{}
    end
  end

  defp decode_sse_frame(_frame), do: %{}

  defp start_core_supervisor do
    case Process.whereis(SelfHostedInferenceCore.Supervisor) do
      nil ->
        {:ok, _pid} = SelfHostedInferenceCore.Application.start(:normal, [])
        :ok

      _pid ->
        :ok
    end
  end

  defp post_json(url, payload, headers) do
    request_headers =
      headers
      |> Enum.map(fn {key, value} -> {String.to_charlist(key), String.to_charlist(value)} end)

    request =
      {String.to_charlist(url), request_headers, ~c"application/json", Jason.encode!(payload)}

    case :httpc.request(:post, request, [], body_format: :binary) do
      {:ok, {{_, status, _}, _response_headers, body}} ->
        {:ok, status, Jason.decode!(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp post_sse(url, payload, headers) do
    request_headers =
      headers
      |> Enum.map(fn {key, value} -> {String.to_charlist(key), String.to_charlist(value)} end)

    request =
      {String.to_charlist(url), request_headers, ~c"application/json", Jason.encode!(payload)}

    case :httpc.request(:post, request, [], body_format: :binary) do
      {:ok, {{_, status, _}, _response_headers, body}} ->
        {:ok, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
