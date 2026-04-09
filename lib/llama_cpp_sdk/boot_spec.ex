# credo:disable-for-this-file Credo.Check.Warning.StructFieldAmount

defmodule LlamaCppSdk.BootSpec do
  @moduledoc """
  Canonical `llama-server` boot spec for the first `:spawned` backend release.
  """

  @enforce_keys [:model]
  defstruct binary_path: "llama-server",
            launcher_args: [],
            model: nil,
            alias: nil,
            model_identity: nil,
            host: "127.0.0.1",
            port: 8080,
            api_prefix: "",
            ctx_size: nil,
            gpu_layers: :auto,
            threads: nil,
            threads_batch: nil,
            parallel: nil,
            flash_attn: :auto,
            embeddings: false,
            api_key: nil,
            api_key_file: nil,
            timeout_seconds: nil,
            threads_http: nil,
            pooling: nil,
            ready_timeout_ms: 5_000,
            readiness_interval_ms: 100,
            health_interval_ms: 1_000,
            stop_timeout_ms: 1_000,
            execution_surface: [surface_kind: :local_subprocess],
            environment: %{},
            extra_args: [],
            metadata: %{},
            root_url: nil,
            base_url: nil,
            health_url: nil,
            headers: %{}

  @type flash_attn :: :on | :off | :auto
  @type gpu_layers :: non_neg_integer() | :auto | :all
  @type pooling :: :none | :mean | :cls | :last | :rank | nil

  @type t :: %__MODULE__{
          binary_path: String.t(),
          launcher_args: [String.t()],
          model: String.t(),
          alias: String.t(),
          model_identity: String.t(),
          host: String.t(),
          port: pos_integer(),
          api_prefix: String.t(),
          ctx_size: pos_integer() | nil,
          gpu_layers: gpu_layers(),
          threads: pos_integer() | nil,
          threads_batch: pos_integer() | nil,
          parallel: pos_integer() | nil,
          flash_attn: flash_attn(),
          embeddings: boolean(),
          api_key: String.t() | nil,
          api_key_file: String.t() | nil,
          timeout_seconds: pos_integer() | nil,
          threads_http: pos_integer() | nil,
          pooling: pooling(),
          ready_timeout_ms: pos_integer(),
          readiness_interval_ms: pos_integer(),
          health_interval_ms: pos_integer(),
          stop_timeout_ms: pos_integer(),
          execution_surface: keyword() | map() | ExecutionPlane.Placements.Surface.t(),
          environment: %{optional(String.t()) => String.t()},
          extra_args: [String.t()],
          metadata: map(),
          root_url: String.t(),
          base_url: String.t(),
          health_url: String.t(),
          headers: %{optional(String.t()) => String.t()}
        }

  @spec new(keyword() | map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_list(attrs), do: new(Map.new(attrs))

  def new(attrs) when is_map(attrs) do
    with {:ok, binary_path} <-
           normalize_nonempty_binary(fetch(attrs, :binary_path, "llama-server"), :binary_path),
         {:ok, launcher_args} <-
           normalize_string_list(fetch(attrs, :launcher_args, []), :launcher_args),
         {:ok, model} <- normalize_nonempty_binary(fetch(attrs, :model, nil), :model),
         {:ok, host} <- normalize_host(fetch(attrs, :host, "127.0.0.1")),
         {:ok, port} <- normalize_port(fetch(attrs, :port, 8080)),
         {:ok, api_prefix} <- normalize_api_prefix(fetch(attrs, :api_prefix, "")),
         {:ok, ctx_size} <-
           normalize_optional_pos_integer(fetch(attrs, :ctx_size, nil), :ctx_size),
         {:ok, gpu_layers} <- normalize_gpu_layers(fetch(attrs, :gpu_layers, :auto)),
         {:ok, threads} <- normalize_optional_pos_integer(fetch(attrs, :threads, nil), :threads),
         {:ok, threads_batch} <-
           normalize_optional_pos_integer(fetch(attrs, :threads_batch, nil), :threads_batch),
         {:ok, parallel} <-
           normalize_optional_pos_integer(fetch(attrs, :parallel, nil), :parallel),
         {:ok, flash_attn} <- normalize_flash_attn(fetch(attrs, :flash_attn, :auto)),
         {:ok, embeddings} <- normalize_boolean(fetch(attrs, :embeddings, false), :embeddings),
         {:ok, api_key} <- normalize_optional_binary(fetch(attrs, :api_key, nil), :api_key),
         {:ok, api_key_file} <-
           normalize_optional_binary(fetch(attrs, :api_key_file, nil), :api_key_file),
         {:ok, headers} <- normalize_endpoint_headers(api_key, api_key_file),
         {:ok, timeout_seconds} <-
           normalize_optional_pos_integer(fetch(attrs, :timeout_seconds, nil), :timeout_seconds),
         {:ok, threads_http} <-
           normalize_optional_pos_integer(fetch(attrs, :threads_http, nil), :threads_http),
         {:ok, pooling} <- normalize_pooling(fetch(attrs, :pooling, nil)),
         {:ok, ready_timeout_ms} <-
           normalize_optional_pos_integer(
             fetch(attrs, :ready_timeout_ms, 5_000),
             :ready_timeout_ms
           ),
         {:ok, readiness_interval_ms} <-
           normalize_optional_pos_integer(
             fetch(attrs, :readiness_interval_ms, 100),
             :readiness_interval_ms
           ),
         {:ok, health_interval_ms} <-
           normalize_optional_pos_integer(
             fetch(attrs, :health_interval_ms, 1_000),
             :health_interval_ms
           ),
         {:ok, stop_timeout_ms} <-
           normalize_optional_pos_integer(fetch(attrs, :stop_timeout_ms, 1_000), :stop_timeout_ms),
         {:ok, execution_surface} <-
           normalize_execution_surface(fetch(attrs, :execution_surface, nil)),
         {:ok, environment} <- normalize_env(fetch(attrs, :environment, %{})),
         {:ok, extra_args} <- normalize_string_list(fetch(attrs, :extra_args, []), :extra_args),
         {:ok, metadata} <- normalize_metadata(fetch(attrs, :metadata, %{})),
         {:ok, alias_name} <- normalize_alias(fetch(attrs, :alias, nil), model),
         {:ok, model_identity} <-
           normalize_model_identity(fetch(attrs, :model_identity, alias_name), alias_name) do
      root_url = build_root_url(host, port)

      {:ok,
       %__MODULE__{
         binary_path: binary_path,
         launcher_args: launcher_args,
         model: model,
         alias: alias_name,
         model_identity: model_identity,
         host: host,
         port: port,
         api_prefix: api_prefix,
         ctx_size: ctx_size,
         gpu_layers: gpu_layers,
         threads: threads,
         threads_batch: threads_batch,
         parallel: parallel,
         flash_attn: flash_attn,
         embeddings: embeddings,
         api_key: api_key,
         api_key_file: api_key_file,
         timeout_seconds: timeout_seconds,
         threads_http: threads_http,
         pooling: pooling,
         ready_timeout_ms: ready_timeout_ms,
         readiness_interval_ms: readiness_interval_ms,
         health_interval_ms: health_interval_ms,
         stop_timeout_ms: stop_timeout_ms,
         execution_surface: execution_surface,
         environment: environment,
         extra_args: extra_args,
         metadata: metadata,
         root_url: root_url,
         base_url: root_url <> api_prefix <> "/v1",
         health_url: root_url <> "/health",
         headers: headers
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_boot_spec}

  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, %__MODULE__{} = boot_spec} ->
        boot_spec

      {:error, reason} ->
        raise ArgumentError, "invalid llama.cpp boot spec: #{inspect(reason)}"
    end
  end

  @spec instance_key(t()) :: String.t()
  def instance_key(%__MODULE__{} = spec) do
    identity = %{
      binary_path: spec.binary_path,
      launcher_args: spec.launcher_args,
      model: spec.model,
      alias: spec.alias,
      model_identity: spec.model_identity,
      host: spec.host,
      port: spec.port,
      api_prefix: spec.api_prefix,
      ctx_size: spec.ctx_size,
      gpu_layers: spec.gpu_layers,
      threads: spec.threads,
      threads_batch: spec.threads_batch,
      parallel: spec.parallel,
      flash_attn: spec.flash_attn,
      embeddings: spec.embeddings,
      api_key: spec.api_key,
      api_key_file: spec.api_key_file,
      timeout_seconds: spec.timeout_seconds,
      threads_http: spec.threads_http,
      pooling: spec.pooling,
      execution_surface: execution_surface_identity(spec.execution_surface),
      environment: Enum.sort(spec.environment),
      extra_args: spec.extra_args
    }

    digest =
      identity
      |> :erlang.term_to_binary()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.url_encode64(padding: false)

    "llama_cpp_sdk:#{spec.model_identity}:#{digest}"
  end

  defp fetch(attrs, key, default) when is_map(attrs) do
    Map.get(attrs, key, Map.get(attrs, Atom.to_string(key), default))
  end

  defp normalize_nonempty_binary(value, _field) when is_binary(value) and value != "",
    do: {:ok, value}

  defp normalize_nonempty_binary(value, field), do: {:error, {field, value}}

  defp normalize_optional_binary(nil, _field), do: {:ok, nil}
  defp normalize_optional_binary(value, field), do: normalize_nonempty_binary(value, field)

  defp normalize_alias(nil, model), do: {:ok, derive_model_identity(model)}
  defp normalize_alias(value, _model), do: normalize_nonempty_binary(value, :alias)

  defp normalize_model_identity(value, _alias_name),
    do: normalize_nonempty_binary(value, :model_identity)

  defp normalize_host(value) when is_binary(value) and value != "" do
    if String.ends_with?(value, ".sock") do
      {:error, {:unsupported_host, value}}
    else
      {:ok, value}
    end
  end

  defp normalize_host(value), do: {:error, {:host, value}}

  defp normalize_port(value) when is_integer(value) and value in 1..65_535, do: {:ok, value}
  defp normalize_port(value), do: {:error, {:port, value}}

  defp normalize_api_prefix(nil), do: {:ok, ""}
  defp normalize_api_prefix(""), do: {:ok, ""}

  defp normalize_api_prefix(value) when is_binary(value) do
    value =
      value
      |> ensure_prefix_slash()
      |> String.trim_trailing("/")

    {:ok, value}
  end

  defp normalize_api_prefix(value), do: {:error, {:api_prefix, value}}

  defp normalize_optional_pos_integer(nil, _field), do: {:ok, nil}

  defp normalize_optional_pos_integer(value, _field) when is_integer(value) and value > 0 do
    {:ok, value}
  end

  defp normalize_optional_pos_integer(value, field), do: {:error, {field, value}}

  defp normalize_gpu_layers(value) when is_integer(value) and value >= 0, do: {:ok, value}
  defp normalize_gpu_layers(:auto), do: {:ok, :auto}
  defp normalize_gpu_layers(:all), do: {:ok, :all}
  defp normalize_gpu_layers("auto"), do: {:ok, :auto}
  defp normalize_gpu_layers("all"), do: {:ok, :all}
  defp normalize_gpu_layers(value), do: {:error, {:gpu_layers, value}}

  defp normalize_flash_attn(true), do: {:ok, :on}
  defp normalize_flash_attn(false), do: {:ok, :off}
  defp normalize_flash_attn(:on), do: {:ok, :on}
  defp normalize_flash_attn(:off), do: {:ok, :off}
  defp normalize_flash_attn(:auto), do: {:ok, :auto}
  defp normalize_flash_attn("on"), do: {:ok, :on}
  defp normalize_flash_attn("off"), do: {:ok, :off}
  defp normalize_flash_attn("auto"), do: {:ok, :auto}
  defp normalize_flash_attn(value), do: {:error, {:flash_attn, value}}

  defp normalize_pooling(nil), do: {:ok, nil}
  defp normalize_pooling(value) when value in [:none, :mean, :cls, :last, :rank], do: {:ok, value}

  defp normalize_pooling(value) when value in ["none", "mean", "cls", "last", "rank"],
    do: {:ok, String.to_existing_atom(value)}

  defp normalize_pooling(value), do: {:error, {:pooling, value}}

  defp normalize_boolean(value, _field) when is_boolean(value), do: {:ok, value}
  defp normalize_boolean(value, field), do: {:error, {field, value}}

  defp normalize_string_list(value, _field) when value == [], do: {:ok, []}

  defp normalize_string_list(value, _field) when is_list(value) do
    if Enum.all?(value, &is_binary/1) do
      {:ok, value}
    else
      {:error, {:string_list, value}}
    end
  end

  defp normalize_string_list(value, field), do: {:error, {field, value}}

  defp normalize_execution_surface(nil), do: {:ok, [surface_kind: :local_subprocess]}

  defp normalize_execution_surface(%ExecutionPlane.Placements.Surface{} = surface) do
    normalize_execution_surface(%{
      surface_kind: normalize_surface_kind(surface.surface_kind),
      transport_options: surface.transport_options,
      target_id: surface.target_id,
      lease_ref: surface.lease_ref,
      surface_ref: surface.surface_ref,
      boundary_class: surface.boundary_class,
      observability: surface.observability
    })
  end

  defp normalize_execution_surface(surface) when is_list(surface) do
    if Keyword.keyword?(surface) do
      case normalize_surface_kind(Keyword.get(surface, :surface_kind, :local_subprocess)) do
        :local_subprocess -> {:ok, surface}
        surface_kind -> {:error, {:unsupported_execution_surface, surface_kind}}
      end
    else
      {:error, {:execution_surface, surface}}
    end
  end

  defp normalize_execution_surface(surface) when is_map(surface) do
    case normalize_surface_kind(Map.get(surface, :surface_kind, Map.get(surface, "surface_kind"))) do
      :local_subprocess ->
        {:ok,
         surface
         |> Enum.flat_map(fn
           {:__struct__, _value} -> []
           {"surface_kind", value} -> [surface_kind: normalize_surface_kind(value)]
           {:surface_kind, value} -> [surface_kind: normalize_surface_kind(value)]
           {key, value} when is_binary(key) -> [{String.to_existing_atom(key), value}]
           pair -> [pair]
         end)
         |> Keyword.new()}

      nil ->
        {:error, {:execution_surface, surface}}

      surface_kind ->
        {:error, {:unsupported_execution_surface, surface_kind}}
    end
  end

  defp normalize_execution_surface(surface), do: {:error, {:execution_surface, surface}}

  defp normalize_env(env) when is_map(env) do
    {:ok,
     Map.new(env, fn {key, value} ->
       {to_string(key), normalize_env_value(value)}
     end)}
  end

  defp normalize_env(env), do: {:error, {:environment, env}}

  defp normalize_env_value(value) when is_binary(value), do: value
  defp normalize_env_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_env_value(value) when is_boolean(value), do: to_string(value)
  defp normalize_env_value(value) when is_integer(value), do: Integer.to_string(value)
  defp normalize_env_value(value) when is_float(value), do: Float.to_string(value)
  defp normalize_env_value(value), do: inspect(value)

  defp normalize_metadata(metadata) when is_map(metadata), do: {:ok, metadata}
  defp normalize_metadata(metadata), do: {:error, {:metadata, metadata}}

  defp normalize_endpoint_headers(api_key, _api_key_file) when is_binary(api_key) do
    {:ok, authorization_headers(api_key)}
  end

  defp normalize_endpoint_headers(nil, nil), do: {:ok, %{}}

  defp normalize_endpoint_headers(nil, api_key_file) when is_binary(api_key_file) do
    case File.read(api_key_file) do
      {:ok, contents} ->
        case contents |> String.trim() do
          "" -> {:error, {:api_key_file, {api_key_file, :empty}}}
          api_key -> {:ok, authorization_headers(api_key)}
        end

      {:error, reason} ->
        {:error, {:api_key_file, {api_key_file, reason}}}
    end
  end

  defp authorization_headers(api_key), do: %{"authorization" => "Bearer " <> api_key}

  defp build_root_url(host, port) do
    formatted_host =
      if String.contains?(host, ":") and not String.starts_with?(host, "[") do
        "[" <> host <> "]"
      else
        host
      end

    "http://#{formatted_host}:#{port}"
  end

  defp execution_surface_identity(surface) when is_list(surface), do: Enum.sort(surface)

  defp execution_surface_identity(%ExecutionPlane.Placements.Surface{} = surface) do
    surface
    |> Map.from_struct()
    |> Map.delete(:__struct__)
    |> Map.update!(:surface_kind, &normalize_surface_kind/1)
    |> Enum.sort()
  end

  defp execution_surface_identity(surface) when is_map(surface) do
    surface
    |> Map.new(fn
      {:__struct__, _value} -> nil
      {"surface_kind", value} -> {:surface_kind, normalize_surface_kind(value)}
      {:surface_kind, value} -> {:surface_kind, normalize_surface_kind(value)}
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      pair -> pair
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  defp execution_surface_identity(surface), do: surface

  defp normalize_surface_kind(nil), do: nil
  defp normalize_surface_kind("local_subprocess"), do: :local_subprocess
  defp normalize_surface_kind("ssh_exec"), do: :ssh_exec
  defp normalize_surface_kind("guest_bridge"), do: :guest_bridge
  defp normalize_surface_kind(surface_kind) when is_atom(surface_kind), do: surface_kind
  defp normalize_surface_kind(_surface_kind), do: nil

  defp derive_model_identity(model) do
    model
    |> Path.basename()
    |> String.replace(~r/\.[^.]+$/, "")
  end

  defp ensure_prefix_slash(value) do
    if String.starts_with?(value, "/") do
      value
    else
      "/" <> value
    end
  end
end
