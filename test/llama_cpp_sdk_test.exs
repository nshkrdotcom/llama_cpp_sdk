defmodule LlamaCppSdkTest do
  use ExUnit.Case, async: true

  test "metadata reports the package and backend identity" do
    assert %{app: :llama_cpp_sdk, backend: :llama_cpp_sdk, version: _version} =
             LlamaCppSdk.metadata()
  end
end
