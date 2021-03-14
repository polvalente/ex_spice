defmodule ExSpice.Components.Diode do
  @format "D<name> <node +> <node -> <value>"
  @moduledoc """
  Diode

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :node_pos, :node_neg, :current, vbe: 0.7]
end
