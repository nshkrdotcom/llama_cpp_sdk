defmodule LlamaCppSdk.Probes do
  @moduledoc false

  alias LlamaCppSdk.BootSpec

  @tcp_timeout_ms 200
  @http_timeout_ms 200

  @type health_status :: :healthy | :degraded | :unavailable

  @spec ready?(BootSpec.t()) :: boolean()
  def ready?(%BootSpec{} = boot_spec) do
    tcp_ready?(boot_spec) and
      (health_endpoint_ready?(boot_spec) or models_endpoint_ready?(boot_spec))
  end

  @spec health_status(BootSpec.t()) :: {:ok, health_status()}
  def health_status(%BootSpec{} = boot_spec) do
    case request(boot_spec.health_url, boot_spec.headers) do
      {:ok, 200, body} ->
        {:ok, classify_health_body(body)}

      {:ok, status, _body} when status in [502, 503, 504] ->
        {:ok, :degraded}

      {:ok, 404, _body} ->
        fallback_models_health(boot_spec)

      {:error, _reason} ->
        fallback_models_health(boot_spec)

      {:ok, _status, _body} ->
        {:ok, :unavailable}
    end
  end

  defp fallback_models_health(%BootSpec{} = boot_spec) do
    if models_endpoint_ready?(boot_spec) do
      {:ok, :healthy}
    else
      {:ok, :unavailable}
    end
  end

  defp health_endpoint_ready?(%BootSpec{} = boot_spec) do
    case request(boot_spec.health_url, boot_spec.headers) do
      {:ok, 200, _body} -> true
      _other -> false
    end
  end

  defp models_endpoint_ready?(%BootSpec{} = boot_spec) do
    case request(boot_spec.base_url <> "/models", boot_spec.headers) do
      {:ok, 200, _body} -> true
      _other -> false
    end
  end

  defp tcp_ready?(%BootSpec{host: host, port: port}) do
    case :gen_tcp.connect(
           String.to_charlist(host),
           port,
           [:binary, active: false],
           @tcp_timeout_ms
         ) do
      {:ok, socket} ->
        :ok = :gen_tcp.close(socket)
        true

      {:error, _reason} ->
        false
    end
  end

  defp request(url, headers) do
    request = {String.to_charlist(url), to_http_headers(headers)}
    http_opts = [timeout: @http_timeout_ms, connect_timeout: @http_timeout_ms]
    options = [body_format: :binary]

    case :httpc.request(:get, request, http_opts, options) do
      {:ok, {{_version, status, _reason_phrase}, _response_headers, body}} ->
        {:ok, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp to_http_headers(headers) do
    Enum.map(headers, fn {key, value} ->
      {String.to_charlist(key), String.to_charlist(value)}
    end)
  end

  defp classify_health_body(body) do
    body =
      body
      |> to_string()
      |> String.downcase()
      |> String.trim()

    cond do
      String.contains?(body, "unavailable") ->
        :unavailable

      String.contains?(body, "degraded") ->
        :degraded

      true ->
        :healthy
    end
  end
end
