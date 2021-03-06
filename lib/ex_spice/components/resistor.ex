defmodule ExSpice.Components.Resistor do
  @format "R<name> <node +> <node -> <value>"
  @moduledoc """
  Resistor

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :nodes, :value]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(%{value: value, nodes: [node_1, node_2]}, {rows, cols}) do
      g = 1 / value

      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_1, ^node_1} -> g
            {^node_1, ^node_2} -> -g
            {^node_2, ^node_1} -> -g
            {^node_2, ^node_2} -> g
            _ -> 0
          end
        end)
      end)
      |> Nx.tensor()
    end

    def to_string(
          %{
            name: name,
            nodes: [node_1, node_2],
            value: value
          },
          netlist
        ) do
      [
        name,
        " ",
        ExSpice.Netlist.translate_node(netlist, node_1),
        " ",
        ExSpice.Netlist.translate_node(netlist, node_2),
        " ",
        ExSpice.PrettyPrint.to_string(value),
        "Ohm"
      ]
    end
  end
end
