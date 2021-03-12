defmodule ExSpice.Netlist do
  @moduledoc """
  Netlist parser
  """

  alias ExSpice.Netlist.StatementParser

  defstruct components: [], nodes: %{"0" => 0}

  def parse(contents) when is_binary(contents) do
    contents
    |> String.split(~r/[\r\n]/)
    |> Enum.with_index(1)
    |> Enum.reduce_while(%__MODULE__{}, fn {line, line_number}, netlist ->
      line
      |> String.split(~r/\s/, trim: true)
      |> StatementParser.parse(netlist.nodes)
      |> IO.inspect()
      |> case do
        {:ok, component, nodes} -> {:cont, update_netlist(netlist, component, nodes)}
        {:error, error} -> {:halt, {:error, {:invalid_line, error, line_number}}}
      end
    end)
  end

  defp update_netlist(netlist, component, nodes) do
    %{netlist | components: [component | netlist.components], nodes: nodes}
  end
end
