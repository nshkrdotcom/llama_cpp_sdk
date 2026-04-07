defmodule LlamaCppSdk.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = []

    with {:ok, pid} <-
           Supervisor.start_link(children, strategy: :one_for_one, name: LlamaCppSdk.Supervisor) do
      _ = SelfHostedInferenceCore.register_backend(LlamaCppSdk.Backend)
      {:ok, pid}
    end
  end
end
