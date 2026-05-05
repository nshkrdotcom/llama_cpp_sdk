# credo:disable-for-this-file Credo.Check.Warning.StructFieldAmount

defmodule LlamaCppSdk.GovernedAuthority do
  @moduledoc """
  Authority-selected local service materialization for governed llama.cpp runs.
  """

  @required_refs [
    :endpoint_ref,
    :service_identity_ref,
    :model_config_ref,
    :model_account_ref,
    :provider_account_ref,
    :target_ref,
    :target_posture_ref,
    :attach_grant_ref,
    :operation_policy_ref,
    :redaction_ref
  ]

  @optional_refs [
    :credential_ref,
    :credential_lease_ref
  ]

  @unmanaged_boot_fields [
    :api_key,
    :api_key_file,
    :headers,
    :environment,
    :execution_surface,
    :model,
    :alias,
    :model_identity,
    :host,
    :port,
    :api_prefix,
    :ctx_size,
    :gpu_layers,
    :threads,
    :threads_batch,
    :parallel,
    :flash_attn,
    :embeddings,
    :timeout_seconds,
    :threads_http,
    :pooling,
    :binary_path,
    :launcher_args,
    :extra_args,
    :metadata
  ]

  @surface_key_by_name %{
    "surface_kind" => :surface_kind,
    "transport_options" => :transport_options,
    "target_id" => :target_id,
    "lease_ref" => :lease_ref,
    "surface_ref" => :surface_ref,
    "boundary_class" => :boundary_class,
    "observability" => :observability
  }

  @enforce_keys @required_refs ++ [:model]
  defstruct endpoint_ref: nil,
            service_identity_ref: nil,
            model_config_ref: nil,
            model_account_ref: nil,
            provider_account_ref: nil,
            target_ref: nil,
            target_posture_ref: nil,
            attach_grant_ref: nil,
            operation_policy_ref: nil,
            redaction_ref: nil,
            credential_ref: nil,
            credential_lease_ref: nil,
            model: nil,
            alias: nil,
            model_identity: nil,
            host: "127.0.0.1",
            port: 8080,
            api_prefix: "",
            api_key: nil,
            api_key_file: nil,
            ctx_size: nil,
            gpu_layers: :auto,
            threads: nil,
            threads_batch: nil,
            parallel: nil,
            flash_attn: :auto,
            embeddings: false,
            timeout_seconds: nil,
            threads_http: nil,
            pooling: nil,
            binary_path: "llama-server",
            launcher_args: [],
            environment: %{},
            extra_args: [],
            execution_surface: nil,
            metadata: %{}

  @type t :: %__MODULE__{
          endpoint_ref: String.t(),
          service_identity_ref: String.t(),
          model_config_ref: String.t(),
          model_account_ref: String.t(),
          provider_account_ref: String.t(),
          target_ref: String.t(),
          target_posture_ref: String.t(),
          attach_grant_ref: String.t(),
          operation_policy_ref: String.t(),
          redaction_ref: String.t(),
          credential_ref: String.t() | nil,
          credential_lease_ref: String.t() | nil,
          model: String.t(),
          alias: String.t(),
          model_identity: String.t(),
          host: String.t(),
          port: pos_integer(),
          api_prefix: String.t(),
          api_key: String.t() | nil,
          api_key_file: String.t() | nil,
          ctx_size: pos_integer() | nil,
          gpu_layers: non_neg_integer() | :auto | :all,
          threads: pos_integer() | nil,
          threads_batch: pos_integer() | nil,
          parallel: pos_integer() | nil,
          flash_attn: :on | :off | :auto,
          embeddings: boolean(),
          timeout_seconds: pos_integer() | nil,
          threads_http: pos_integer() | nil,
          pooling: atom() | nil,
          binary_path: String.t(),
          launcher_args: [String.t()],
          environment: %{optional(String.t()) => String.t()},
          extra_args: [String.t()],
          execution_surface: keyword() | map() | nil,
          metadata: map()
        }

  @spec new(t() | keyword() | map()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = authority), do: validate(authority)

  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    authority = %__MODULE__{
      endpoint_ref: fetch(attrs, :endpoint_ref, nil),
      service_identity_ref: fetch(attrs, :service_identity_ref, nil),
      model_config_ref: fetch(attrs, :model_config_ref, nil),
      model_account_ref: fetch(attrs, :model_account_ref, nil),
      provider_account_ref: fetch(attrs, :provider_account_ref, nil),
      target_ref: fetch(attrs, :target_ref, nil),
      target_posture_ref: fetch(attrs, :target_posture_ref, nil),
      attach_grant_ref: fetch(attrs, :attach_grant_ref, nil),
      operation_policy_ref: fetch(attrs, :operation_policy_ref, nil),
      redaction_ref: fetch(attrs, :redaction_ref, nil),
      credential_ref: fetch(attrs, :credential_ref, nil),
      credential_lease_ref: fetch(attrs, :credential_lease_ref, nil),
      model: fetch(attrs, :model, nil),
      alias: fetch(attrs, :alias, nil),
      model_identity: fetch(attrs, :model_identity, fetch(attrs, :model_config_ref, nil)),
      host: fetch(attrs, :host, "127.0.0.1"),
      port: fetch(attrs, :port, 8080),
      api_prefix: fetch(attrs, :api_prefix, ""),
      api_key: fetch(attrs, :api_key, nil),
      api_key_file: fetch(attrs, :api_key_file, nil),
      ctx_size: fetch(attrs, :ctx_size, nil),
      gpu_layers: fetch(attrs, :gpu_layers, :auto),
      threads: fetch(attrs, :threads, nil),
      threads_batch: fetch(attrs, :threads_batch, nil),
      parallel: fetch(attrs, :parallel, nil),
      flash_attn: fetch(attrs, :flash_attn, :auto),
      embeddings: fetch(attrs, :embeddings, false),
      timeout_seconds: fetch(attrs, :timeout_seconds, nil),
      threads_http: fetch(attrs, :threads_http, nil),
      pooling: fetch(attrs, :pooling, nil),
      binary_path: fetch(attrs, :binary_path, "llama-server"),
      launcher_args: fetch(attrs, :launcher_args, []),
      environment: fetch(attrs, :environment, %{}),
      extra_args: fetch(attrs, :extra_args, []),
      execution_surface: fetch(attrs, :execution_surface, nil),
      metadata: fetch(attrs, :metadata, %{})
    }

    with {:ok, authority} <- normalize_model_defaults(authority) do
      validate(authority)
    end
  end

  def new(_attrs), do: {:error, :invalid_governed_authority}

  @spec new!(t() | keyword() | map()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, authority} ->
        authority

      {:error, reason} ->
        raise ArgumentError, "invalid governed llama.cpp authority: #{inspect(reason)}"
    end
  end

  @spec fetch(keyword() | map()) :: {:ok, t()} | {:error, term()} | :error
  def fetch(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> fetch()

  def fetch(attrs) when is_map(attrs) do
    case fetch(attrs, :governed_authority, nil) do
      nil -> :error
      authority -> new(authority)
    end
  end

  def fetch(_attrs), do: :error

  @spec governed?(keyword() | map()) :: boolean()
  def governed?(attrs), do: match?({:ok, _authority}, fetch(attrs))

  @spec reject_unmanaged_attrs(map()) :: :ok | {:error, {:unmanaged_governed_boot_field, atom()}}
  def reject_unmanaged_attrs(attrs) when is_map(attrs) do
    case Enum.find(@unmanaged_boot_fields, &field_present?(attrs, &1)) do
      nil -> :ok
      field -> {:error, {:unmanaged_governed_boot_field, field}}
    end
  end

  def materialize_attrs(%__MODULE__{} = authority, attrs) when is_map(attrs) do
    attrs
    |> drop_unmanaged_fields()
    |> Map.delete(:governed_authority)
    |> Map.delete("governed_authority")
    |> Map.merge(%{
      binary_path: authority.binary_path,
      launcher_args: authority.launcher_args,
      model: authority.model,
      alias: authority.alias,
      model_identity: authority.model_identity,
      host: authority.host,
      port: authority.port,
      api_prefix: authority.api_prefix,
      api_key: authority.api_key,
      api_key_file: authority.api_key_file,
      ctx_size: authority.ctx_size,
      gpu_layers: authority.gpu_layers,
      threads: authority.threads,
      threads_batch: authority.threads_batch,
      parallel: authority.parallel,
      flash_attn: authority.flash_attn,
      embeddings: authority.embeddings,
      timeout_seconds: authority.timeout_seconds,
      threads_http: authority.threads_http,
      pooling: authority.pooling,
      environment: authority.environment,
      extra_args: authority.extra_args,
      execution_surface: execution_surface(authority),
      metadata: metadata(authority)
    })
  end

  @spec refs(t()) :: map()
  def refs(%__MODULE__{} = authority) do
    %{
      endpoint_ref: authority.endpoint_ref,
      service_identity_ref: authority.service_identity_ref,
      model_config_ref: authority.model_config_ref,
      model_account_ref: authority.model_account_ref,
      provider_account_ref: authority.provider_account_ref,
      target_ref: authority.target_ref,
      target_posture_ref: authority.target_posture_ref,
      attach_grant_ref: authority.attach_grant_ref,
      credential_ref: authority.credential_ref,
      credential_lease_ref: authority.credential_lease_ref,
      operation_policy_ref: authority.operation_policy_ref,
      redaction_ref: authority.redaction_ref
    }
  end

  @spec unmanaged_boot_fields() :: nonempty_list(atom())
  def unmanaged_boot_fields, do: @unmanaged_boot_fields

  defp normalize_model_defaults(%__MODULE__{} = authority) do
    model_identity = authority.model_identity || authority.model_config_ref
    alias_name = authority.alias || derive_model_identity(authority.model)
    {:ok, %{authority | alias: alias_name, model_identity: model_identity}}
  end

  defp validate(%__MODULE__{} = authority) do
    with :ok <- validate_refs(authority, @required_refs, :required),
         :ok <- validate_refs(authority, @optional_refs, :optional),
         :ok <- validate_non_empty(:model, authority.model),
         :ok <- validate_non_empty(:alias, authority.alias),
         :ok <- validate_non_empty(:model_identity, authority.model_identity),
         :ok <- validate_non_empty(:host, authority.host),
         :ok <- validate_port(authority.port),
         :ok <- validate_optional_binary(:api_key, authority.api_key),
         :ok <- validate_optional_binary(:api_key_file, authority.api_key_file),
         :ok <- validate_string_list(:launcher_args, authority.launcher_args),
         :ok <- validate_string_list(:extra_args, authority.extra_args),
         :ok <- validate_environment(authority.environment),
         :ok <- validate_metadata(authority.metadata),
         :ok <- validate_distinct_identity_refs(authority),
         :ok <- validate_execution_surface(authority.execution_surface) do
      {:ok, authority}
    end
  end

  defp validate_refs(authority, refs, mode) do
    Enum.reduce_while(refs, :ok, fn field, :ok ->
      value = Map.fetch!(authority, field)

      case {mode, value} do
        {:optional, nil} -> {:cont, :ok}
        _other -> reduce_validation(validate_non_empty(field, value))
      end
    end)
  end

  defp reduce_validation(:ok), do: {:cont, :ok}
  defp reduce_validation({:error, _reason} = error), do: {:halt, error}

  defp validate_non_empty(field, value) when is_binary(value) do
    if String.trim(value) == "" do
      {:error, {:missing_governed_authority_field, field}}
    else
      :ok
    end
  end

  defp validate_non_empty(field, _value), do: {:error, {:missing_governed_authority_field, field}}

  defp validate_port(port) when is_integer(port) and port in 1..65_535, do: :ok
  defp validate_port(port), do: {:error, {:port, port}}

  defp validate_optional_binary(_field, nil), do: :ok
  defp validate_optional_binary(field, value), do: validate_non_empty(field, value)

  defp validate_string_list(_field, values) when is_list(values) do
    if Enum.all?(values, &is_binary/1), do: :ok, else: {:error, {:string_list, values}}
  end

  defp validate_string_list(field, value), do: {:error, {field, value}}

  defp validate_environment(environment) when is_map(environment), do: :ok
  defp validate_environment(environment), do: {:error, {:environment, environment}}

  defp validate_metadata(metadata) when is_map(metadata), do: :ok
  defp validate_metadata(metadata), do: {:error, {:metadata, metadata}}

  defp validate_distinct_identity_refs(%__MODULE__{} = authority) do
    cond do
      authority.service_identity_ref == authority.provider_account_ref ->
        {:error, {:identity_ref_collision, :service_identity_ref, :provider_account_ref}}

      authority.endpoint_ref == authority.provider_account_ref ->
        {:error, {:identity_ref_collision, :endpoint_ref, :provider_account_ref}}

      authority.model_account_ref == authority.provider_account_ref ->
        {:error, {:identity_ref_collision, :model_account_ref, :provider_account_ref}}

      true ->
        :ok
    end
  end

  defp validate_execution_surface(nil), do: :ok

  defp validate_execution_surface(surface) when is_list(surface) do
    if Keyword.keyword?(surface), do: :ok, else: {:error, {:execution_surface, surface}}
  end

  defp validate_execution_surface(surface) when is_map(surface), do: :ok
  defp validate_execution_surface(surface), do: {:error, {:execution_surface, surface}}

  defp execution_surface(%__MODULE__{execution_surface: nil} = authority) do
    [
      surface_kind: :local_subprocess,
      target_id: authority.target_ref,
      lease_ref: authority.attach_grant_ref,
      surface_ref: authority.endpoint_ref
    ]
  end

  defp execution_surface(%__MODULE__{execution_surface: surface}) when is_list(surface),
    do: surface

  defp execution_surface(%__MODULE__{execution_surface: surface}) when is_map(surface) do
    Enum.reduce(surface, [], fn
      {key, value}, acc when is_binary(key) ->
        case Map.get(@surface_key_by_name, key) do
          nil -> acc
          surface_key -> [{surface_key, value} | acc]
        end

      {key, value}, acc ->
        [{key, value} | acc]
    end)
    |> Enum.reverse()
  end

  defp metadata(%__MODULE__{} = authority) do
    authority.metadata
    |> Map.new()
    |> Map.put(:governed_authority_refs, refs(authority))
  end

  defp drop_unmanaged_fields(attrs) do
    Enum.reduce(@unmanaged_boot_fields, attrs, fn field, acc ->
      acc
      |> Map.delete(field)
      |> Map.delete(Atom.to_string(field))
    end)
  end

  defp field_present?(attrs, field) do
    Map.has_key?(attrs, field) or Map.has_key?(attrs, Atom.to_string(field))
  end

  defp fetch(attrs, key, default) when is_map(attrs) do
    Map.get(attrs, key, Map.get(attrs, Atom.to_string(key), default))
  end

  defp derive_model_identity(nil), do: nil

  defp derive_model_identity(model) do
    model
    |> Path.basename()
    |> strip_last_extension()
  end

  defp strip_last_extension(basename) do
    case basename |> :binary.matches(".") |> List.last() do
      {index, 1} when index > 0 -> binary_part(basename, 0, index)
      _other -> basename
    end
  end
end
