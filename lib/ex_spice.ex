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

    yn =
      Enum.reduce(netlist.components, Nx.broadcast(0, shape), fn component, yn ->
        ExSpice.Component.DC.as_tensor(component, shape)
        |> Nx.add(yn)
      end)

    solve(
      Nx.slice(yn, [1, 1], [num_vars - 1, num_vars - 1]),
      Nx.slice(yn, [1, num_vars + 1], [num_vars - 1, 1])
    )
  end

  @doc """
  Solves a system Ax = b for x, where A is a square matrix

  ## Examples
      iex> ExSpice.solve(Nx.tensor([[1, 0, 1], [1, 0, -1], [0, 1, 0]]), Nx.tensor([4, -2, 2]))
      #Nx.Tensor<
        f32[3]
        [1.0, 2.0, 3.0]
      >
  """
  def solve(a, b) do
    {q, r} = Nx.qr(a)

    # triangularize the system
    b_prime = q |> Nx.transpose() |> Nx.dot(b)

    IO.inspect(a, label: "a")
    IO.inspect(b, label: "b")
    IO.inspect(q, label: "q")
    IO.inspect(r, label: "r")

    triangular_solve(r, b_prime)
  end

  @doc false
  def triangular_solve(%{shape: {rows, rows}} = a, b) do
    zeros = List.duplicate(0, rows)

    row_range = Enum.uniq((rows - 1)..0)

    for row <- row_range, reduce: Nx.broadcast(0, {rows}) do
      solution ->
        i_range = Enum.filter(row_range, &(&1 >= row + 1))

        x =
          for i <- i_range, reduce: Nx.to_scalar(Nx.reshape(b[[row]], {})) do
            x ->
              res = x - Nx.to_scalar(a[[row, i]]) * Nx.to_scalar(solution[[i]])
              res
          end

        x = x / Nx.to_scalar(a[[row, row]])

        Nx.add(solution, Nx.tensor(List.replace_at(zeros, row, x)))
    end
  end
end
