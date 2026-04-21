defmodule LlamaCppSdk.MixProject do
  use Mix.Project

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
      self_hosted_inference_core_dep(),
      execution_plane_dep(),
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp self_hosted_inference_core_dep do
    resolve_local_or_git_dep(
      :self_hosted_inference_core,
      "SELF_HOSTED_INFERENCE_CORE_PATH",
      "../self_hosted_inference_core",
      [github: "nshkrdotcom/self_hosted_inference_core", branch: "main"],
      override: true
    )
  end

  defp execution_plane_dep do
    resolve_local_or_git_dep(
      :execution_plane,
      "EXECUTION_PLANE_PATH",
      "../execution_plane",
      [github: "nshkrdotcom/execution_plane", branch: "main"],
      override: true
    )
  end

  defp resolve_local_or_git_dep(app, env_var, sibling_relative_path, fallback_opts, opts) do
    path =
      case System.get_env(env_var) do
        nil -> Path.expand(sibling_relative_path, __DIR__)
        "" -> Path.expand(sibling_relative_path, __DIR__)
        configured -> Path.expand(configured)
      end

    if File.dir?(path) do
      {app, Keyword.merge([path: path], opts)}
    else
      {app, Keyword.merge(fallback_opts, opts)}
    end
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
