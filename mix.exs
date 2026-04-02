defmodule LlamaCppEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/llama_cpp_ex"
  @homepage_url "https://hex.pm/packages/llama_cpp_ex"

  def project do
    [
      app: :llama_cpp_ex,
      name: "LlamaCppEx",
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
      mod: {LlamaCppEx.Application, []}
    ]
  end

  defp deps do
    [
      local_or_hex_dep(
        :self_hosted_inference_core,
        "~> 0.1.0",
        "../self_hosted_inference_core"
      ),
      local_or_hex_dep(
        :earmark_parser,
        "~> 1.4.44",
        "../external_runtime_transport/deps/earmark_parser",
        override: true,
        only: :dev,
        runtime: false
      ),
      local_or_hex_dep(
        :makeup,
        "~> 1.2",
        "../external_runtime_transport/deps/makeup",
        override: true,
        only: :dev,
        runtime: false
      ),
      local_or_hex_dep(
        :makeup_elixir,
        "~> 1.0",
        "../external_runtime_transport/deps/makeup_elixir",
        override: true,
        only: :dev,
        runtime: false
      ),
      local_or_hex_dep(
        :makeup_erlang,
        "~> 1.0",
        "../external_runtime_transport/deps/makeup_erlang",
        override: true,
        only: :dev,
        runtime: false
      ),
      local_or_hex_dep(
        :ex_doc,
        "~> 0.40",
        "../external_runtime_transport/deps/ex_doc",
        override: true,
        only: :dev,
        runtime: false
      ),
      local_or_hex_dep(
        :credo,
        "~> 1.7",
        "../external_runtime_transport/deps/credo",
        override: true,
        only: [:dev, :test],
        runtime: false
      ),
      local_or_hex_dep(
        :dialyxir,
        "~> 1.4",
        "../external_runtime_transport/deps/dialyxir",
        override: true,
        only: :dev,
        runtime: false
      )
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
      name: "LlamaCppEx",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @homepage_url,
      logo: "assets/llama_cpp_ex.svg",
      assets: %{"assets" => "assets"},
      extras: [
        "README.md": [title: "Overview", filename: "overview"],
        "guides/architecture.md": [title: "Architecture"],
        "guides/boot_spec.md": [title: "Boot Spec"],
        "guides/readiness_and_health.md": [title: "Readiness And Health"],
        "guides/integration_with_self_hosted_inference_core.md": [title: "Kernel Integration"],
        "examples/README.md": [title: "Examples", filename: "examples"],
        "CHANGELOG.md": [title: "Changelog"],
        "LICENSE.md": [title: "License"]
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
          LlamaCppEx,
          LlamaCppEx.BootSpec
        ],
        "Backend Runtime": [
          LlamaCppEx.Backend,
          LlamaCppEx.CommandBuilder
        ],
        "Runtime Semantics": [
          LlamaCppEx.Probes,
          LlamaCppEx.StopStrategy
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
        "HexDocs" => "https://hexdocs.pm/llama_cpp_ex"
      },
      files: [
        "lib",
        "assets/*.svg",
        ".formatter.exs",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "guides",
        "examples",
        "LICENSE",
        "LICENSE.md"
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

  defp local_or_hex_dep(app, version, relative_path, opts \\ []) do
    path = Path.expand(relative_path, __DIR__)

    if local_dep_path?(path) do
      {app, Keyword.put(opts, :path, path)}
    else
      {app, version, opts}
    end
  end

  defp local_dep_path?(path) do
    File.exists?(Path.join(path, "mix.exs")) or File.exists?(Path.join(path, "rebar.config"))
  end
end
