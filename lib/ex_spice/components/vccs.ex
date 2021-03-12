defmodule ExSpice.Components.VoltageControlledCurrentSource do
  defstruct [:name, :node_out_pos, :node_out_neg, :node_in_pos, :node_in_neg, :gain]

  defimpl Component.DC, for: __MODULE__ do
    def as_tensor(
          %{
            value: value,
            node_out_pos: node_out_pos,
            node_out_neg: node_out_neg,
            node_in_pos: node_in_pos,
            node_in_neg: node_in_neg
          },
          {rows, cols}
        ) do
      g = value

      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_out_pos, ^node_in_pos} -> g
            {^node_out_neg, ^node_in_neg} -> g
            {^node_out_pos, ^node_in_neg} -> -g
            {^node_out_neg, ^node_in_pos} -> -g
            _ -> 0
          end
        end)
      end)
      |> Nx.tensor()
    end
  end
end
