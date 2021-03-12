defmodule ExSpice.Components.Inductor do
  defstruct [:name, :nodes, :value, :current]

  defimpl ExSpice.Component.DC, for: __MODULE__ do
    def as_tensor(%{nodes: [node_1, node_2], current: j}, {rows, cols}) do
      g = 1.0e-12

      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_1, ^j} -> 1
            {^node_2, ^j} -> -1
            {^j, ^node_1} -> -1
            {^j, ^node_2} -> 1
            {^j, ^j} -> g
            _ -> 0
          end
        end)
      end)
      |> Nx.tensor()
      |> IO.inspect(label: "L stamp")
    end
  end
end
