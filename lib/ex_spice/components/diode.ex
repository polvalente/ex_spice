defmodule ExSpice.Components.Diode do
  defstruct [:name, :node_pos, :node_neg, :current, vbe: 0.7]
end
