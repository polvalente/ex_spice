defmodule ExSpice.Components.VoltageControlledCurrentSource do
  defstruct [:name, :node_out_pos, :node_out_neg, :node_in_pos, :node_in_neg, :gain]
end
