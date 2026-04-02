defmodule LlamaCppEx.DocumentationContractTest do
  use ExUnit.Case, async: true

  test "hexdocs navigation includes every guide and examples readme" do
    mix_exs = File.read!("mix.exs")

    expected =
      ["examples/README.md" | Path.wildcard("guides/*.md")]
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    missing =
      expected
      |> Enum.reject(&String.contains?(mix_exs, &1))

    assert missing == [], "missing HexDocs extras: #{inspect(missing)}"
  end

  test "readme stays honest about transport and data-plane ownership" do
    readme =
      "README.md"
      |> File.read!()
      |> String.downcase()

    assert readme =~ "self_hosted_inference_core"
    assert readme =~ "does not parse"
    assert readme =~ "openai"
    assert readme =~ "ssh_exec"
    assert readme =~ "future"
  end

  test "examples include a spawned endpoint publication demo" do
    examples =
      Path.wildcard("examples/*.exs")
      |> Enum.map(&Path.basename/1)
      |> MapSet.new()

    assert "spawned_endpoint_demo.exs" in examples

    readme = File.read!("examples/README.md")

    assert readme =~ "`:spawned`"
    assert readme =~ "spawned_endpoint_demo.exs"
    assert readme =~ "endpoint publication"
  end
end
