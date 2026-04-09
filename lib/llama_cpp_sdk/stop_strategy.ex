defmodule LlamaCppSdk.StopStrategy do
  @moduledoc false

  alias ExecutionPlane.Process.Transport

  @poll_interval_ms 25

  @spec shutdown(pid() | nil, pos_integer()) :: :ok
  def shutdown(nil, _timeout_ms), do: :ok

  def shutdown(transport_pid, timeout_ms)
      when is_pid(transport_pid) and is_integer(timeout_ms) and timeout_ms > 0 do
    _ = Transport.interrupt(transport_pid)
    deadline_ms = System.monotonic_time(:millisecond) + timeout_ms
    wait_for_disconnect(transport_pid, deadline_ms)
  end

  defp wait_for_disconnect(transport_pid, deadline_ms) do
    cond do
      not Process.alive?(transport_pid) ->
        :ok

      Transport.status(transport_pid) == :disconnected ->
        :ok

      System.monotonic_time(:millisecond) >= deadline_ms ->
        _ = Transport.force_close(transport_pid)
        :ok

      true ->
        Process.sleep(@poll_interval_ms)
        wait_for_disconnect(transport_pid, deadline_ms)
    end
  end
end
