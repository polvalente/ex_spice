defmodule ExSpice.Components.CurrentControlledVoltageSource do
  defstruct [
    :name,
    :node_out_pos,
    :node_out_neg,
    :node_in_pos,
    :node_in_neg,
    :gain,
    :current_in,
    :current_out
  ]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(
          %{
            node_out_pos: node_out_pos,
            node_out_neg: node_out_neg,
            node_in_pos: node_in_pos,
            node_in_neg: node_in_neg,
            current_in: current_in,
            current_out: current_out,
            gain: gain
          },
          {rows, cols}
        ) do
      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_out_pos, ^current_out} -> 1
            {^node_out_neg, ^current_out} -> -1
            {^node_in_pos, ^current_in} -> 1
            {^node_in_neg, ^current_in} -> -1
            {^current_out, ^node_out_pos} -> -1
            {^current_out, ^node_out_neg} -> 1
            {^current_in, ^node_in_pos} -> -1
            {^current_in, ^node_in_neg} -> 1
            {^current_out, ^current_in} -> gain
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
        " V/A"
      ]
    end
  end
end
