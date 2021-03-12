defmodule ExSpice.Components.VoltageSource do
  defstruct [:name, :value, :node_pos, :node_neg, :current]

  # defimpl ExSpice.Component.DC, for: __MODULE__ do
  #   def as_tensor(%{node_pos: node_pos, node_neg: node_neg, value: value}, {rows, cols}) do
  #     g = value

  #     last_col = cols - 1

  #     Enum.map(0..(rows - 1), fn row ->
  #       Enum.map(0..(cols - 1), fn col ->
  #         case {row, col} do
  #           {^node_pos, ^last_col} -> -g
  #           {^node_neg, ^last_col} -> g
  #           _ -> 0
  #         end
  #       end)
  #     end)
  #     |> Nx.tensor()
  #   end
  # end
end
