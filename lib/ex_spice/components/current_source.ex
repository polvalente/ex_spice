defmodule ExSpice.Components.CurrentSource do
  @format "I<name> <node +> <node -> <value>"
  @moduledoc """
  Current Source

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :value, :node_pos, :node_neg]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(%{node_pos: node_pos, node_neg: node_neg, value: value}, {rows, cols}) do
      last_col = cols - 1

      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_pos, ^last_col} -> -value
            {^node_neg, ^last_col} -> value
            _ -> 0
          end
        end)
      end)
      |> Nx.tensor()
    end

    def to_string(
          %{
            name: name,
            node_pos: node_pos,
            node_neg: node_neg,
            value: value
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
        ExSpice.PrettyPrint.to_string(value),
        "A"
      ]
    end
  end
end
