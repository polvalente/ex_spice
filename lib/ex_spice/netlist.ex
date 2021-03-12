defmodule ExSpice.Netlist do
  @moduledoc """
  Netlist parser
  """

  alias ExSpice.Netlist.StatementParser

  defstruct components: [], variables: %{"0" => 0}, solution: nil

  def parse(contents) when is_binary(contents) do
    contents
    |> String.split(~r/[\r\n]/)
    |> Enum.with_index(1)
    |> Enum.reduce_while(%__MODULE__{}, fn {line, line_number}, netlist ->
      line
      |> String.split(~r/\s/, trim: true)
      |> StatementParser.parse(netlist.variables)
      |> case do
        {:ok, component, variables} ->
          {:cont, update_netlist(netlist, component, variables)}

        {:error, error} ->
          {:halt, {:error, {:invalid_line, error, line_number}}}
      end
    end)
  end

  defp update_netlist(netlist, component, variables) do
    %{
      netlist
      | components: [component | netlist.components],
        variables: variables
    }
  end
end
