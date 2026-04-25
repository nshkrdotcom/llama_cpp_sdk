defmodule LlamaCppSdk.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/llama_cpp_sdk"
  @homepage_url "https://hex.pm/packages/llama_cpp_sdk"
  @execution_plane_version "~> 0.1.0"
  @execution_plane_process_version "~> 0.1.0"
  @self_hosted_inference_core_version "~> 0.1.0"

  def project do
    [
      app: :llama_cpp_sdk,
      name: "LlamaCppSdk",
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      docs: docs(),
      dialyzer: dialyzer(),
      package: package(),
      source_url: @source_url,
      homepage_url: @homepage_url
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {LlamaCppSdk.Application, []}
    ]
  end

  defp deps do
    [
      self_hosted_inference_core_dep(),
      execution_plane_dep(),
      execution_plane_process_dep(),
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp self_hosted_inference_core_dep do
    case local_dep_path("../self_hosted_inference_core") do
      nil -> {:self_hosted_inference_core, @self_hosted_inference_core_version}
      path -> {:self_hosted_inference_core, path: path}
    end
  end

  defp execution_plane_dep do
    case local_dep_path("../execution_plane/core/execution_plane") do
      nil -> {:execution_plane, @execution_plane_version}
      path -> {:execution_plane, path: path}
    end
  end

  defp execution_plane_process_dep do
    case execution_plane_workspace_dep_path("runtimes/execution_plane_process") do
      nil -> {:execution_plane_process, @execution_plane_process_version}
      path -> {:execution_plane_process, path: path}
    end
  end

  defp execution_plane_workspace_dep_path(relative_child_path) do
    "../execution_plane"
    |> Path.join(relative_child_path)
    |> local_dep_path()
  end

  defp local_dep_path(relative_path) do
    if local_workspace_deps?() do
      path = Path.expand(relative_path, __DIR__)
      if File.dir?(path), do: path
    end
  end

  defp local_workspace_deps? do
    not hex_packaging_task?() and not Enum.member?(Path.split(__DIR__), "deps")
  end

  defp hex_packaging_task? do
    Enum.any?(System.argv(), &(&1 in ["hex.build", "hex.publish"]))
  end

  defp description do
    """
    First concrete self-hosted inference backend for llama.cpp, owning
    llama-server boot specs, readiness probes, stop semantics, and endpoint
    publication through self_hosted_inference_core.
    """
  end

  defp docs do
    [
      main: "overview",
      name: "LlamaCppSdk",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @homepage_url,
      logo: "assets/llama_cpp_sdk.svg",
      assets: %{"assets" => "assets"},
      extras: [
        "README.md": [title: "Overview", filename: "overview"],
        "guides/architecture.md": [title: "Architecture"],
        "guides/boot_spec.md": [title: "Boot Spec"],
        "guides/readiness_and_health.md": [title: "Readiness And Health"],
        "guides/integration_with_self_hosted_inference_core.md": [title: "Kernel Integration"],
        "examples/README.md": [title: "Examples", filename: "examples"],
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ],
      groups_for_extras: [
        "Project Overview": [
          "README.md",
          "guides/architecture.md",
          "guides/boot_spec.md",
          "guides/readiness_and_health.md",
          "guides/integration_with_self_hosted_inference_core.md"
        ],
        Examples: [
          "examples/README.md"
        ],
        "Project Reference": [
          "CHANGELOG.md",
          "LICENSE.md"
        ]
      ],
      groups_for_modules: [
        "Public API": [
          LlamaCppSdk,
          LlamaCppSdk.BootSpec
        ],
        "Backend Runtime": [
          LlamaCppSdk.Backend,
          LlamaCppSdk.CommandBuilder
        ],
        "Runtime Semantics": [
          LlamaCppSdk.Probes,
          LlamaCppSdk.StopStrategy
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Hex" => @homepage_url,
        "HexDocs" => "https://hexdocs.pm/llama_cpp_sdk"
      },
      files: [
        "lib",
        "assets/*.svg",
        ".formatter.exs",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit],
      plt_core_path: "priv/plts/core",
      plt_local_path: "priv/plts",
      flags: [:error_handling, :underspecs]
    ]
  end
end
