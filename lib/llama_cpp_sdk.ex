defmodule LlamaCppSdk do
  @moduledoc """
  `llama.cpp` backend package for `self_hosted_inference_core`.

  This package normalizes `llama-server` boot specs, renders launch flags,
  probes readiness and health, and publishes OpenAI-compatible endpoint
  descriptors through the self-hosted runtime kernel.
  """

  alias LlamaCppSdk.{Backend, BootSpec}
  alias SelfHostedInferenceCore.{BackendManifest, ConsumerManifest, InstanceSpec}

  @type metadata :: %{
          app: atom(),
          backend: atom(),
          version: String.t()
        }

  @doc """
  Returns package metadata.

  ## Examples

      iex> LlamaCppSdk.backend_id()
      :llama_cpp_sdk

  """
  @spec metadata() :: metadata()
  def metadata do
    %{
      app: :llama_cpp_sdk,
      backend: backend_id(),
      version: version()
    }
  end

  @doc """
  Returns the backend identifier published to `self_hosted_inference_core`.
  """
  @spec backend_id() :: :llama_cpp_sdk
  def backend_id, do: :llama_cpp_sdk

  @doc """
  Returns the current package version.
  """
  @spec version() :: String.t()
  def version do
    case Application.spec(:llama_cpp_sdk, :vsn) do
      nil -> "0.1.0"
      version -> to_string(version)
    end
  end

  @doc """
  Registers the `llama.cpp` backend with `self_hosted_inference_core`.
  """
  @spec register_backend() :: :ok | {:error, term()}
  def register_backend do
    SelfHostedInferenceCore.register_backend(Backend)
  end

  @doc """
  Unregisters the backend from `self_hosted_inference_core`.
  """
  @spec unregister_backend() :: :ok
  def unregister_backend do
    SelfHostedInferenceCore.unregister_backend(backend_id())
  end

  @doc """
  Returns the backend manifest published northbound.
  """
  @spec manifest() :: BackendManifest.t()
  def manifest, do: Backend.manifest()

  @doc """
  Normalizes a raw boot spec into `%LlamaCppSdk.BootSpec{}`.
  """
  @spec boot_spec(BootSpec.t() | keyword() | map()) :: {:ok, BootSpec.t()} | {:error, term()}
  def boot_spec(%BootSpec{} = spec), do: {:ok, spec}
  def boot_spec(attrs) when is_list(attrs) or is_map(attrs), do: BootSpec.new(attrs)

  @doc """
  Normalizes a raw boot spec and raises on invalid input.
  """
  @spec boot_spec!(BootSpec.t() | keyword() | map()) :: BootSpec.t()
  def boot_spec!(%BootSpec{} = spec), do: spec
  def boot_spec!(attrs), do: BootSpec.new!(attrs)

  @doc """
  Builds the `SelfHostedInferenceCore.InstanceSpec` for this backend.
  """
  @spec instance_spec(BootSpec.t() | keyword() | map()) ::
          {:ok, InstanceSpec.t()} | {:error, term()}
  def instance_spec(spec_or_attrs) do
    with {:ok, %BootSpec{} = spec} <- boot_spec(spec_or_attrs) do
      {:ok,
       InstanceSpec.new!(
         backend: backend_id(),
         startup_kind: :spawned,
         execution_surface: spec.execution_surface,
         backend_options: %{boot_spec: spec},
         metadata: spec.metadata
       )}
    end
  end

  @doc """
  Ensures a `:spawned` runtime instance for the given boot spec.
  """
  @spec ensure_instance(BootSpec.t() | keyword() | map(), keyword()) ::
          {:ok, SelfHostedInferenceCore.ensure_result()} | {:error, term()}
  def ensure_instance(spec_or_attrs, opts \\ []) do
    with {:ok, %InstanceSpec{} = instance_spec} <- instance_spec(spec_or_attrs) do
      SelfHostedInferenceCore.ensure_instance(instance_spec, opts)
    end
  end

  @doc """
  Resolves an endpoint for a compatible consumer through the shared kernel.
  """
  @spec resolve_endpoint(BootSpec.t() | keyword() | map(), ConsumerManifest.t(), keyword()) ::
          {:ok, SelfHostedInferenceCore.resolve_result()} | {:error, term()}
  def resolve_endpoint(spec_or_attrs, %ConsumerManifest{} = consumer_manifest, opts \\ []) do
    with {:ok, %InstanceSpec{} = instance_spec} <- instance_spec(spec_or_attrs) do
      SelfHostedInferenceCore.resolve_endpoint(instance_spec, consumer_manifest, opts)
    end
  end

  @doc """
  Returns backend compatibility for a consumer manifest.
  """
  @spec compatibility(ConsumerManifest.t()) :: SelfHostedInferenceCore.CompatibilityResult.t()
  def compatibility(%ConsumerManifest{} = consumer_manifest) do
    SelfHostedInferenceCore.compatibility(backend_id(), consumer_manifest)
  end

  @doc """
  Publishes the current endpoint descriptor for an instance.
  """
  @spec publish_endpoint(String.t()) ::
          {:ok, SelfHostedInferenceCore.EndpointDescriptor.t()} | {:error, term()}
  def publish_endpoint(instance_id) when is_binary(instance_id) do
    SelfHostedInferenceCore.publish_endpoint(instance_id)
  end
end
