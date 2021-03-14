defmodule ExSpice.Components.Switch do
  @format "$<name> <node +> <node -> <value>"
  @moduledoc """
  Switch

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :node_pos, :node_neg, :control_pos, :control_neg, :limit_voltage]
end
