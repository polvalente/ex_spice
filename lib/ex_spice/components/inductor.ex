defmodule ExSpice.Components.Inductor do
  @format "L<name> <node +> <node -> <value>"
  @moduledoc """
  Inductor

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :nodes, :value, :current]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(%{nodes: [node_1, node_2], current: j}, {rows, cols}) do
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
        "H"
      ]
    end
  end
end
