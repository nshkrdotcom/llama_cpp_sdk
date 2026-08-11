# `build_support/` is not shipped in the published package, so its absence is
# how this file knows it is running inside a consumer's deps/ rather than in a
# source checkout. Guard on the file, not on a directory shape: a shape test
# breaks when the repo is vendored at a different depth or used as a git dep.
workspace_helper = Path.expand("build_support/dependency_sources.exs", __DIR__)

if File.regular?(workspace_helper) and not Code.ensure_loaded?(DependencySources) do
  Code.require_file(workspace_helper)
end

defmodule LlamaCppSdk.MixProject do
  use Mix.Project

  @workspace_checkout? File.regular?(Path.expand("build_support/dependency_sources.exs", __DIR__))

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/llama_cpp_sdk"
  @homepage_url "https://hex.pm/packages/llama_cpp_sdk"

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
      workspace_dep(:self_hosted_inference_core, "~> 0.1.0"),
      workspace_dep(:execution_plane, "~> 0.1.0"),
      workspace_dep(:execution_plane_process, "~> 0.1.0"),
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
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


  # In a source checkout the registry decides the source (path first). In a
  # published package there is no registry, and the requirement stated here is
  # the whole answer.
  defp workspace_dep(app, hex_requirement, opts \\ []) do
    if @workspace_checkout? do
      apply(DependencySources, :dep, [app, __DIR__, opts])
    else
      if opts == [], do: {app, hex_requirement}, else: {app, hex_requirement, opts}
    end
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
        "build_support",
        "assets/*.svg",
        ".formatter.exs",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "AGENTS.md"
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
