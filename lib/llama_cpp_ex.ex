defmodule LlamaCppEx do
  @moduledoc """
  Barebones Elixir surface for future `llama.cpp` integration work.

  The module currently acts as the package entry point while the repository
  establishes its baseline documentation, packaging, and release structure.
  """

  @doc """
  Returns the package status marker.

  ## Examples

      iex> LlamaCppEx.hello()
      :world

  """
  @spec hello() :: :world
  def hello, do: :world

  @doc """
  Returns the current library version placeholder.

  ## Examples

      iex> LlamaCppEx.version()
      "0.1.0"

  """
  @spec version() :: String.t()
  def version, do: "0.1.0"
end
