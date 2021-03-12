defmodule ExSpice.Components.Inductor do
  defstruct [:name, :nodes, :value]

  defimpl Component.DC, for: __MODULE__ do
    def as_tensor(%{nodes: [node_1, node_2]}, {rows, cols}) do
      g = 1.0e12

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
  end
end
