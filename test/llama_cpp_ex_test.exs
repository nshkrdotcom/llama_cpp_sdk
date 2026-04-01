defmodule LlamaCppExTest do
  use ExUnit.Case
  doctest LlamaCppEx

  test "returns the package status marker" do
    assert LlamaCppEx.hello() == :world
  end

  test "returns the project version placeholder" do
    assert LlamaCppEx.version() == "0.1.0"
  end
end
