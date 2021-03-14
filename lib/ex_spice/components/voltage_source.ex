defmodule ExSpice.Components.VoltageSource do
  defstruct [:name, :value, :node_pos, :node_neg, :current]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(
          %{node_pos: node_pos, node_neg: node_neg, current: current, value: value},
          {rows, cols}
        ) do
      last_col = cols - 1

      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_pos, ^current} -> 1
            {^node_neg, ^current} -> -1
            {^current, ^node_pos} -> -1
            {^current, ^node_neg} -> 1
            {^current, ^last_col} -> -value
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
        "V"
      ]
    end
  end
end
