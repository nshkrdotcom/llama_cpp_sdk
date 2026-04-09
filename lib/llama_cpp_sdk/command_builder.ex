defmodule LlamaCppSdk.CommandBuilder do
  @moduledoc """
  Renders a normalized `%LlamaCppSdk.BootSpec{}` into a transport command.
  """

  alias ExecutionPlane.Command
  alias LlamaCppSdk.BootSpec

  @spec command(BootSpec.t()) :: Command.t()
  def command(%BootSpec{} = boot_spec) do
    Command.new(
      boot_spec.binary_path,
      boot_spec.launcher_args ++ args(boot_spec),
      env: boot_spec.environment
    )
  end

  @spec args(BootSpec.t()) :: [String.t()]
  def args(%BootSpec{} = boot_spec) do
    []
    |> append_option("--model", boot_spec.model)
    |> append_option("--alias", boot_spec.alias)
    |> append_option("--host", boot_spec.host)
    |> append_option("--port", boot_spec.port)
    |> append_optional_option("--ctx-size", boot_spec.ctx_size)
    |> append_option("--gpu-layers", gpu_layers_arg(boot_spec.gpu_layers))
    |> append_optional_option("--threads", boot_spec.threads)
    |> append_optional_option("--threads-batch", boot_spec.threads_batch)
    |> append_optional_option("--parallel", boot_spec.parallel)
    |> append_option("--flash-attn", flash_attn_arg(boot_spec.flash_attn))
    |> append_optional_flag("--embedding", boot_spec.embeddings)
    |> append_optional_option("--api-key", boot_spec.api_key)
    |> append_optional_option("--api-key-file", boot_spec.api_key_file)
    |> append_optional_option("--api-prefix", blank_to_nil(boot_spec.api_prefix))
    |> append_optional_option("--timeout", boot_spec.timeout_seconds)
    |> append_optional_option("--threads-http", boot_spec.threads_http)
    |> append_optional_option("--pooling", boot_spec.pooling)
    |> Kernel.++(boot_spec.extra_args)
  end

  defp append_option(args, flag, value), do: args ++ [flag, to_string(value)]

  defp append_optional_option(args, _flag, nil), do: args
  defp append_optional_option(args, flag, value), do: append_option(args, flag, value)

  defp append_optional_flag(args, _flag, false), do: args
  defp append_optional_flag(args, flag, true), do: args ++ [flag]

  defp gpu_layers_arg(value) when is_integer(value), do: Integer.to_string(value)
  defp gpu_layers_arg(:auto), do: "auto"
  defp gpu_layers_arg(:all), do: "all"

  defp flash_attn_arg(:on), do: "on"
  defp flash_attn_arg(:off), do: "off"
  defp flash_attn_arg(:auto), do: "auto"

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
