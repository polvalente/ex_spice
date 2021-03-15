defmodule ExSpice.Netlist do
  @moduledoc """
  Netlist parser
  """

  alias ExSpice.Netlist.StatementParser

  defstruct components: [], variables: %{"0" => 0}, solution: nil

  def translate_node(netlist, node_number) do
    {name, _} =
      Enum.find(
        netlist.variables,
        {"Node_#{to_string(node_number)}", nil},
        fn {_k, v} -> v == node_number end
      )

    name
  end

  defimpl ExSpice.PrettyPrint, for: ExSpice.Netlist do
    def to_string(
          %ExSpice.Netlist{
            components: components,
            variables: variables,
            solution: solution
          } = netlist,
          _ \\ nil
        ) do
      components_str =
        components
        |> Enum.sort_by(& &1.name)
        |> Enum.map(&ExSpice.Component.to_string(&1, netlist))
        |> Enum.intersperse("\n")

      solution_str =
        variables
        |> Enum.map(fn
          {"0", _} ->
            "GND: 0V"

          {name, index} ->
            fmt_name =
              case name do
                "j" <> _ -> name
                name -> ["V", name]
              end

            [
              fmt_name,
              ": ",
              solution
              |> Nx.to_flat_list()
              |> Enum.fetch!(index)
              |> Kernel.to_string(),
              # |> ExSpice.PrettyPrint.to_string(),
              "\n"
            ]
        end)
        |> Enum.sort()

      ["Components:\n", components_str, "\n\nSolution:\n", solution_str]
      |> IO.iodata_to_binary()
    end
  end

  def parse(contents) when is_binary(contents) do
    contents
    |> String.split(~r/[\r\n]/, trim: true)
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
