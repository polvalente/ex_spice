defmodule ExSpice.Components.Diode do
  @format "D<name> <node +> <node -> <value>"
  @moduledoc """
  Diode

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :node_pos, :node_neg, :current, vbe: 0.7]

  defimpl ExSpice.Component, for: __MODULE__ do
    def to_string(
          %{
            name: name,
            node_pos: node_pos,
            node_neg: node_neg,
            vbe: vbe
          },
          netlist
        ) do
      [
        name,
        " ",
        ExSpice.Netlist.translate_node(netlist, node_pos),
        " ",
        ExSpice.Netlist.translate_node(netlist, node_neg),
        " ",
        ExSpice.PrettyPrint.to_string(vbe),
        "V"
      ]
    end
  end
end
