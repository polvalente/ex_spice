defmodule ExSpice.Components.VoltageControlledCurrentSource do
  @format "G<name> <node out+> <node out-> <node in+> <node in-> <Gain>"
  @moduledoc """
  Current Controlled Voltage Source

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :node_out_pos, :node_out_neg, :node_in_pos, :node_in_neg, :gain]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(
          %{
            gain: gain,
            node_out_pos: node_out_pos,
            node_out_neg: node_out_neg,
            node_in_pos: node_in_pos,
            node_in_neg: node_in_neg
          },
          {rows, cols}
        ) do
      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_out_pos, ^node_in_pos} -> gain
            {^node_out_neg, ^node_in_neg} -> gain
            {^node_out_pos, ^node_in_neg} -> -gain
            {^node_out_neg, ^node_in_pos} -> -gain
            _ -> 0
          end
        end)
      end)
      |> Nx.tensor()
    end

    def to_string(
          %{
            name: name,
            node_out_pos: node_out_pos,
            node_out_neg: node_out_neg,
            node_in_pos: node_in_pos,
            node_in_neg: node_in_neg,
            gain: gain
          },
          netlist
        ) do
      [
        name,
        " ",
        ExSpice.Netlist.translate_node(netlist, node_out_pos),
        " ",
        ExSpice.Netlist.translate_node(netlist, node_out_neg),
        " ",
        ExSpice.Netlist.translate_node(netlist, node_in_pos),
        " ",
        ExSpice.Netlist.translate_node(netlist, node_in_neg),
        " ",
        ExSpice.PrettyPrint.to_string(gain),
        " A/V"
      ]
    end
  end
end
