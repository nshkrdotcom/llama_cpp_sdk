defmodule LlamaCppSdk.GovernedAuthorityTest do
  use ExUnit.Case, async: false

  alias ExecutionPlane.Command
  alias LlamaCppSdk.{Backend, BootSpec, CommandBuilder, GovernedAuthority}

  setup do
    original_api_key = System.get_env("LLAMA_CPP_SDK_API_KEY")
    original_model = System.get_env("LLAMA_CPP_SDK_MODEL")
    original_cache = System.get_env("LLAMA_CPP_SDK_CACHE")

    on_exit(fn ->
      restore_env("LLAMA_CPP_SDK_API_KEY", original_api_key)
      restore_env("LLAMA_CPP_SDK_MODEL", original_model)
      restore_env("LLAMA_CPP_SDK_CACHE", original_cache)
    end)

    :ok
  end

  test "governed boot spec uses authority materialization instead of env values" do
    System.put_env("LLAMA_CPP_SDK_API_KEY", "env-token")
    System.put_env("LLAMA_CPP_SDK_MODEL", "/env/model.gguf")
    System.put_env("LLAMA_CPP_SDK_CACHE", "/env/cache")

    assert {:ok, spec} = BootSpec.new(governed_authority: authority())

    assert spec.model == "/governed/model.gguf"
    assert spec.alias == "governed-model"
    assert spec.model_identity == "model-config://llama/governed"
    assert spec.host == "127.0.0.1"
    assert spec.port == 18_080
    assert spec.api_key == "governed-token"
    assert spec.headers == %{"authorization" => "Bearer governed-token"}
    assert spec.environment == %{"LLAMA_CACHE" => "/governed/cache"}
    refute inspect(spec) =~ "env-token"
    refute inspect(spec) =~ "/env/model.gguf"
    refute inspect(spec) =~ "/env/cache"

    assert spec.execution_surface[:surface_kind] == :local_subprocess
    assert spec.execution_surface[:target_id] == "target://local/llama"
    assert spec.execution_surface[:surface_ref] == "endpoint://local/llama"
    assert spec.execution_surface[:lease_ref] == "attach-grant://local/llama"

    assert spec.metadata[:governed_authority_refs] == %{
             attach_grant_ref: "attach-grant://local/llama",
             credential_lease_ref: "credential-lease://local/llama",
             credential_ref: "credential://local/llama",
             endpoint_ref: "endpoint://local/llama",
             model_account_ref: "model-account://local/llama/governed",
             model_config_ref: "model-config://llama/governed",
             operation_policy_ref: "operation-policy://local/llama/read",
             provider_account_ref: "provider-account://tenant/local-llama",
             redaction_ref: "redaction://local/llama",
             service_identity_ref: "service-identity://llama-server/local",
             target_posture_ref: "target-posture://local/llama/no-egress",
             target_ref: "target://local/llama"
           }

    refute inspect(spec.metadata) =~ "governed-token"
  end

  test "governed authority distinguishes local endpoint service from provider account" do
    authority = authority()
    refs = GovernedAuthority.refs(authority)

    assert refs.endpoint_ref == "endpoint://local/llama"
    assert refs.service_identity_ref == "service-identity://llama-server/local"
    assert refs.provider_account_ref == "provider-account://tenant/local-llama"
    assert refs.model_account_ref == "model-account://local/llama/governed"
    assert refs.target_posture_ref == "target-posture://local/llama/no-egress"
    refute refs.endpoint_ref == refs.provider_account_ref
    refute refs.service_identity_ref == refs.provider_account_ref

    assert {:error, {:identity_ref_collision, :service_identity_ref, :provider_account_ref}} =
             authority_attrs(service_identity_ref: "provider-account://tenant/local-llama")
             |> GovernedAuthority.new()
  end

  test "governed boot spec rejects unmanaged auth model attach and process env fields" do
    rejected_fields = [
      api_key: "direct-token",
      api_key_file: "/tmp/direct-token",
      environment: %{"LLAMA_SECRET" => "direct-env"},
      execution_surface: [surface_kind: :local_subprocess, target_id: "direct-target"],
      model: "/direct/model.gguf",
      alias: "direct-model",
      model_identity: "direct-identity",
      host: "0.0.0.0",
      port: 18_181,
      api_prefix: "/direct",
      headers: %{"authorization" => "Bearer direct-token"}
    ]

    Enum.each(rejected_fields, fn {field, value} ->
      attrs =
        [governed_authority: authority()]
        |> Keyword.put(field, value)

      assert {:error, {:unmanaged_governed_boot_field, ^field}} = BootSpec.new(attrs)
    end)
  end

  test "governed command receives authority materialized process env" do
    spec = BootSpec.new!(governed_authority: authority())

    assert %Command{env: env, args: args} = CommandBuilder.command(spec)

    assert env == %{"LLAMA_CACHE" => "/governed/cache"}
    assert "--api-key" in args
    assert "governed-token" in args
  end

  test "backend event logs redact governed credentials and materialized env values" do
    spec = BootSpec.new!(governed_authority: authority())
    state = %{boot_spec: spec, recent_events: [], ready_hint?: false, stderr: ""}

    {:pending, stderr_state} =
      Backend.handle_transport_event(
        {:stderr, "token governed-token cache /governed/cache still booting"},
        state
      )

    {:pending, stdout_state} =
      Backend.handle_transport_event(
        {:message, "server is ready with governed-token and /governed/cache"},
        stderr_state
      )

    refute stderr_state.stderr =~ "governed-token"
    refute stderr_state.stderr =~ "/governed/cache"
    refute inspect(stdout_state.recent_events) =~ "governed-token"
    refute inspect(stdout_state.recent_events) =~ "/governed/cache"
    assert stderr_state.stderr =~ "[REDACTED]"
    assert inspect(stdout_state.recent_events) =~ "[REDACTED]"
    assert stdout_state.ready_hint?
  end

  defp authority(overrides \\ []) do
    overrides
    |> authority_attrs()
    |> GovernedAuthority.new!()
  end

  defp authority_attrs(overrides) do
    [
      endpoint_ref: "endpoint://local/llama",
      service_identity_ref: "service-identity://llama-server/local",
      model_config_ref: "model-config://llama/governed",
      provider_account_ref: "provider-account://tenant/local-llama",
      model_account_ref: "model-account://local/llama/governed",
      target_ref: "target://local/llama",
      target_posture_ref: "target-posture://local/llama/no-egress",
      attach_grant_ref: "attach-grant://local/llama",
      credential_ref: "credential://local/llama",
      credential_lease_ref: "credential-lease://local/llama",
      operation_policy_ref: "operation-policy://local/llama/read",
      redaction_ref: "redaction://local/llama",
      model: "/governed/model.gguf",
      alias: "governed-model",
      model_identity: "model-config://llama/governed",
      host: "127.0.0.1",
      port: 18_080,
      api_key: "governed-token",
      api_prefix: "",
      environment: %{"LLAMA_CACHE" => "/governed/cache"}
    ]
    |> Keyword.merge(overrides)
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
