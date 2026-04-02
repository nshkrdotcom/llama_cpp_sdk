defmodule LlamaCppExTest do
  use ExUnit.Case, async: true

  test "metadata reports the package and backend identity" do
    assert %{app: :llama_cpp_ex, backend: :llama_cpp, version: _version} = LlamaCppEx.metadata()
  end
end
