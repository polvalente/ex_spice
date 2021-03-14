defmodule ExSpice.Components.Transformer do
  @format "K<name> <node 1+> <node 1-> <node 2+> <node 2-> <n>"
  @moduledoc """
  Transformer

  Netlist format: `#{@format}`
  """

  @doc false
  def format, do: @format

  defstruct [:name, :node_1_pos, :node_1_neg, :node_2_pos, :node_2_neg, :n, :current]

  defimpl ExSpice.Component, for: __MODULE__ do
    def dc_stamp(
          %{
            node_1_pos: node_1_pos,
            node_1_neg: node_1_neg,
            node_2_pos: node_2_pos,
            node_2_neg: node_2_neg,
            current: current,
            n: n
          },
          {rows, cols}
        ) do
      Enum.map(0..(rows - 1), fn row ->
        Enum.map(0..(cols - 1), fn col ->
          case {row, col} do
            {^node_1_pos, ^current} -> -n
            {^node_1_neg, ^current} -> n
            {^node_2_pos, ^current} -> 1
            {^node_2_neg, ^current} -> -1
            {^current, ^node_1_pos} -> n
            {^current, ^node_1_neg} -> -n
            {^current, ^node_2_pos} -> -1
            {^current, ^node_2_neg} -> 1
            _ -> 0
          end
        end)
      end)
      |> Nx.tensor()
    end
  end
end
