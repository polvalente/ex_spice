defmodule ExSpice.Components.OpAmp do
  defstruct [:name, :node_out_pos, :node_out_neg, :node_in_pos, :node_in_neg, :current]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(
          %{
            node_out_pos: node_out_pos,
            node_out_neg: node_out_neg,
            node_in_pos: node_in_pos,
            node_in_neg: node_in_neg,
            current: j
          },
          {rows, cols}
        ) do
      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_out_pos, ^j} -> 1
            {^node_out_neg, ^j} -> -1
            {^j, ^node_in_pos} -> 1
            {^j, ^node_in_neg} -> -1
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
            node_in_neg: node_in_neg
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
        ExSpice.Netlist.translate_node(netlist, node_in_neg)
      ]
    end
  end
end
