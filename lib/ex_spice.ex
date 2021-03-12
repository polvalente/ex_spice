defmodule ExSpice do
  @moduledoc """
  Main module for the ExSpice circuit simulator

  This module has functionality for parsing SPICE
  netlists and for simulating parsed structures.

  Based on MNA1 by Antonio Carlos M. de Queiroz
  """

  alias ExSpice.Netlist

  @doc """
  Parse the contents of a SPICE netlist
  and return the parsed circuit components.

  Accepted components:

  * Resistor    -  R<name> <node 1> <node 2> <value>
  * Capacitor   -  C<name> <node 1> <node 2> <value>
  * Inductor    -  L<name> <node 1> <node 2> <value>
  * Transformer -  K<name> <node 1+> <node 1-> <node 2+> <node 2-> <n>
  * Op.Amp.     -  O<name> <node out+> <node out-> <node in+> <node in->
  * V.C.V.S.    -  E<name> <node out+> <node out-> <node in+> <node in-> <Gain>
  * C.C.C.S.    -  F<name> <node out+> <node out-> <node in+> <node in-> <Gain>
  * V.C.C.S.    -  G<name> <node out+> <node out-> <node in+> <node in-> <Gain>
  * C.C.V.S.    -  H<name> <node out+> <node out-> <node in+> <node in-> <Gain>
  * Diode       -  D<name> <node +> <node ->
  * Switch      -  $<name> <node +> <node -> <control node +> <control node -> <limit voltage>
  """
  def parse(contents) do
    Netlist.parse(contents)
  end

  def parse_file(filename) do
    case File.read(filename) do
      {:ok, contents} -> parse(contents)
      err -> err
    end
  end

  def simulate(%Netlist{} = netlist, opts \\ []) do
    mode = opts[:mode] || :dc

    case mode do
      :dc -> dc_simulation(netlist)
      _ -> raise ArgumentError, "invalid mode. Got #{mode}, expected one of: [:dc]"
    end
  end

  def dc_simulation(netlist) do
    num_vars = Enum.count(netlist.nodes)
    shape = {num_vars + 1, num_vars + 2}
    yn = Nx.broadcast(0, shape)

    Enum.reduce(netlist.components, yn, fn {component, yn} ->
      Component.as_tensor(component, shape)
    end)
  end
end
