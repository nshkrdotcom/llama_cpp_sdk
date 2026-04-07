defmodule LlamaCppSdk.Backend do
  @moduledoc false

  alias ExternalRuntimeTransport.ProcessExit
  alias SelfHostedInferenceCore.Backend, as: BackendBehaviour
  alias SelfHostedInferenceCore.Backend.{StartupPlan, TransportPlan}
  alias SelfHostedInferenceCore.{BackendManifest, InstanceSpec}

  alias LlamaCppSdk.{BootSpec, CommandBuilder, Probes, StopStrategy}

  @behaviour BackendBehaviour

  @impl BackendBehaviour
  def backend_id, do: :llama_cpp_sdk

  @impl BackendBehaviour
  def manifest do
    BackendManifest.new!(
      backend: backend_id(),
      runtime_kind: :service,
      management_modes: [:jido_managed],
      startup_kind: :spawned,
      protocols: [:openai_chat_completions],
      capabilities: %{
        streaming?: true,
        tool_calling?: :unknown,
        embeddings?: :unknown
      },
      supported_surfaces: [:local_subprocess],
      resource_profile: %{
        scheduler: :none,
        placement: :model_dependent,
        gpu: :optional
      },
      metadata: %{
        package: :llama_cpp_sdk,
        ssh_exec: :future_additive
      }
    )
  end

  @impl BackendBehaviour
  def startup_plan(%InstanceSpec{} = spec) do
    with {:ok, %BootSpec{} = boot_spec} <- boot_spec_from_instance_spec(spec) do
      {:ok,
       %StartupPlan{
         backend: backend_id(),
         instance_key: BootSpec.instance_key(boot_spec),
         startup_kind: :spawned,
         management_mode: :jido_managed,
         transport: %TransportPlan{
           command: CommandBuilder.command(boot_spec),
           execution_surface: boot_spec.execution_surface,
           stdout_mode: :line,
           stdin_mode: :raw,
           pty?: false
         },
         ready_timeout_ms: boot_spec.ready_timeout_ms,
         readiness_interval_ms: boot_spec.readiness_interval_ms,
         health_interval_ms: boot_spec.health_interval_ms,
         endpoint_template: %{
           protocol: :openai_chat_completions,
           headers: boot_spec.headers,
           provider_identity: :llama_cpp_sdk,
           model_identity: boot_spec.model_identity,
           source_runtime: :llama_cpp_sdk,
           capabilities: endpoint_capabilities(boot_spec),
           metadata: endpoint_metadata(boot_spec)
         },
         backend_state: %{
           boot_spec: boot_spec,
           recent_events: [],
           ready_hint?: false,
           stderr: ""
         },
         metadata: %{
           boot_spec: endpoint_metadata(boot_spec)
         }
       }}
    end
  end

  @impl BackendBehaviour
  def handle_transport_event({:message, line}, state) when is_binary(line) do
    state =
      state
      |> put_recent_event({:stdout, line})
      |> maybe_mark_ready_hint(line)

    {:pending, state}
  end

  def handle_transport_event({:stderr, chunk}, state) do
    chunk = IO.iodata_to_binary(chunk)

    {:pending,
     state
     |> put_recent_event({:stderr, chunk})
     |> Map.update!(:stderr, &truncate_tail(&1 <> chunk))}
  end

  def handle_transport_event({:data, chunk}, state) do
    {:pending, put_recent_event(state, {:data, IO.iodata_to_binary(chunk)})}
  end

  def handle_transport_event({:error, reason}, state) do
    {:stop, {:llama_server_transport_error, reason}, state}
  end

  def handle_transport_event({:exit, %ProcessExit{} = exit}, state) do
    {:stop,
     {:llama_server_exit,
      %{
        status: exit.status,
        code: exit.code,
        signal: exit.signal,
        reason: exit.reason,
        stderr: if(exit.stderr in [nil, ""], do: state.stderr, else: exit.stderr)
      }}, put_recent_event(state, {:exit, exit})}
  end

  @impl BackendBehaviour
  def probe_readiness(%{boot_spec: %BootSpec{} = boot_spec} = state) do
    if Probes.ready?(boot_spec) do
      {:ready, endpoint_fields(boot_spec, state), state}
    else
      {:pending, state}
    end
  end

  @impl BackendBehaviour
  def health_check(%{boot_spec: %BootSpec{} = boot_spec} = state) do
    {:ok, health_status} = Probes.health_status(boot_spec)
    {:ok, health_status, %{health_url: boot_spec.health_url}, state}
  end

  @impl BackendBehaviour
  def shutdown(%{boot_spec: %BootSpec{} = boot_spec}, transport_pid) do
    StopStrategy.shutdown(transport_pid, boot_spec.stop_timeout_ms)
  end

  defp boot_spec_from_instance_spec(%InstanceSpec{
         backend_options: %{boot_spec: %BootSpec{} = boot_spec}
       }) do
    {:ok, boot_spec}
  end

  defp boot_spec_from_instance_spec(%InstanceSpec{
         backend_options: %{boot_spec: attrs},
         execution_surface: execution_surface
       })
       when is_map(attrs) or is_list(attrs) do
    attrs
    |> Map.new()
    |> Map.put_new(:execution_surface, execution_surface)
    |> BootSpec.new()
  end

  defp boot_spec_from_instance_spec(%InstanceSpec{
         backend_options: backend_options,
         execution_surface: execution_surface
       })
       when is_map(backend_options) do
    backend_options
    |> Map.put_new(:execution_surface, execution_surface)
    |> BootSpec.new()
  end

  defp endpoint_capabilities(%BootSpec{} = boot_spec) do
    %{
      streaming?: true,
      tool_calling?: :unknown,
      embeddings?: boot_spec.embeddings
    }
  end

  defp endpoint_metadata(%BootSpec{} = boot_spec) do
    %{
      binary_path: boot_spec.binary_path,
      host: boot_spec.host,
      port: boot_spec.port,
      api_prefix: boot_spec.api_prefix,
      execution_surface: surface_kind(boot_spec.execution_surface)
    }
  end

  defp endpoint_fields(%BootSpec{} = boot_spec, state) do
    %{
      base_url: boot_spec.base_url,
      source_runtime_ref: boot_spec.root_url,
      health_ref: boot_spec.health_url,
      boundary_ref: boundary_ref(boot_spec.execution_surface),
      metadata:
        Map.merge(endpoint_metadata(boot_spec), %{
          readiness_hint?: state.ready_hint?
        })
    }
  end

  defp maybe_mark_ready_hint(state, line) do
    if readiness_line?(line) do
      Map.put(state, :ready_hint?, true)
    else
      state
    end
  end

  defp readiness_line?(line) do
    line =
      line
      |> String.downcase()
      |> String.trim()

    String.contains?(line, "listening") or
      String.contains?(line, "server is ready") or
      String.starts_with?(line, "ready ")
  end

  defp boundary_ref(%ExternalRuntimeTransport.ExecutionSurface{} = surface) do
    surface.surface_ref || surface.target_id
  end

  defp boundary_ref(surface) when is_list(surface) do
    Keyword.get(surface, :surface_ref) || Keyword.get(surface, :target_id)
  end

  defp surface_kind(%ExternalRuntimeTransport.ExecutionSurface{} = surface),
    do: surface.surface_kind

  defp surface_kind(surface) when is_list(surface),
    do: Keyword.get(surface, :surface_kind, :local_subprocess)

  defp put_recent_event(state, event) do
    update_in(state.recent_events, fn recent_events ->
      [event | recent_events]
      |> Enum.take(10)
    end)
  end

  defp truncate_tail(text) do
    if byte_size(text) > 4_096 do
      binary_part(text, byte_size(text) - 4_096, 4_096)
    else
      text
    end
  end
end
