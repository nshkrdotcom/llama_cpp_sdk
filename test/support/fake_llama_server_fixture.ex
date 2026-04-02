defmodule LlamaCppEx.TestSupport.FakeLlamaServerFixture do
  @moduledoc false

  defstruct [:port, :state_dir, :model_path]

  @type t :: %__MODULE__{
          port: pos_integer(),
          state_dir: String.t(),
          model_path: String.t()
        }

  @spec new!(keyword()) :: t()
  def new!(opts \\ []) do
    port = Keyword.get_lazy(opts, :port, &find_free_port/0)
    state_dir = unique_state_dir()
    model_path = Keyword.get(opts, :model_path, "/models/demo.gguf")

    File.mkdir_p!(state_dir)
    File.write!(Path.join(state_dir, "health.txt"), "healthy")

    %__MODULE__{port: port, state_dir: state_dir, model_path: model_path}
  end

  @spec cleanup(t()) :: :ok
  def cleanup(%__MODULE__{} = fixture) do
    File.rm_rf(fixture.state_dir)
    :ok
  end

  @spec boot_attrs(t(), keyword()) :: map()
  def boot_attrs(%__MODULE__{} = fixture, overrides \\ []) do
    overrides_map = Map.new(overrides)

    %{
      binary_path: System.find_executable("python3") || "python3",
      launcher_args: [script_path()],
      model: Map.get(overrides_map, :model, fixture.model_path),
      alias: Map.get(overrides_map, :alias, "demo-model"),
      host: Map.get(overrides_map, :host, "127.0.0.1"),
      port: Map.get(overrides_map, :port, fixture.port),
      ctx_size: Map.get(overrides_map, :ctx_size, 4_096),
      gpu_layers: Map.get(overrides_map, :gpu_layers, :all),
      threads: Map.get(overrides_map, :threads, 4),
      parallel: Map.get(overrides_map, :parallel, 2),
      flash_attn: Map.get(overrides_map, :flash_attn, :on),
      embeddings: Map.get(overrides_map, :embeddings, false),
      api_key: Map.get(overrides_map, :api_key, "fixture-token"),
      api_prefix: Map.get(overrides_map, :api_prefix, ""),
      ready_timeout_ms: Map.get(overrides_map, :ready_timeout_ms, 2_000),
      health_interval_ms: Map.get(overrides_map, :health_interval_ms, 50),
      execution_surface: [surface_kind: :local_subprocess],
      environment: %{
        "LLAMA_CPP_EX_FAKE_MODE" => Map.get(overrides_map, :mode, "ready"),
        "LLAMA_CPP_EX_FAKE_STATE_DIR" => fixture.state_dir
      },
      metadata: Map.get(overrides_map, :metadata, %{})
    }
    |> Map.merge(Map.drop(overrides_map, [:mode]))
  end

  @spec set_health(t(), :healthy | :degraded | :unavailable) :: :ok | {:error, term()}
  def set_health(%__MODULE__{} = fixture, status)
      when status in [:healthy, :degraded, :unavailable] do
    File.write(Path.join(fixture.state_dir, "health.txt"), Atom.to_string(status))
  end

  @spec args_path(t()) :: String.t()
  def args_path(%__MODULE__{} = fixture), do: Path.join(fixture.state_dir, "args.json")

  @spec signal_path(t()) :: String.t()
  def signal_path(%__MODULE__{} = fixture), do: Path.join(fixture.state_dir, "signal.txt")

  @spec script_path() :: String.t()
  def script_path do
    Path.expand("../../examples/support/fake_llama_server.py", __DIR__)
  end

  defp unique_state_dir do
    Path.join(
      System.tmp_dir!(),
      "llama_cpp_ex_fixture_#{System.unique_integer([:positive, :monotonic])}"
    )
  end

  defp find_free_port do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, packet: :raw, active: false, reuseaddr: true])
    {:ok, port} = :inet.port(socket)
    :ok = :gen_tcp.close(socket)
    port
  end
end
