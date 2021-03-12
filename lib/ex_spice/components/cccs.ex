defmodule ExSpice.Components.CurrentControlledCurrentSource do
  defstruct [
    :name,
    :node_out_pos,
    :node_out_neg,
    :node_in_pos,
    :node_in_neg,
    :gain,
    :current_out,
    :current_in
  ]
end
