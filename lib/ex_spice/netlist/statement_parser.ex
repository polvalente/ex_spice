defmodule ExSpice.Netlist.StatementParser do
  @moduledoc """
  Netlist statement parser
  """
  alias ExSpice.Components, as: C

  @unit_mapping %{
    "k" => 1.0e3,
    "meg" => 1.0e6,
    "m" => 1.0e-3,
    "u" => 1.0e-6,
    "n" => 1.0e-9,
    "p" => 1.0e-12,
    "f" => 1.0e-15
  }

  @valid_line_prefixes ~w(R C L K O E F G H D I V$)

  def parse(["*" | _], _nodes), do: {:ok, nil}

  def parse([<<prefix::utf8, _::bitstring>> | _], _nodes)
      when prefix not in @valid_line_prefixes,
      do: {:error, {:invalid_component, prefix}}

  def parse([<<"V", _::bitstring>> = name, node_pos, node_neg, value_str], nodes) do
    with {:ok, value} <- parse_value(value_str) do
      {nodes, node_pos} = add_node(nodes, node_pos)
      {nodes, node_neg} = add_node(nodes, node_neg)

      c = %C.VoltageSource{name: name, node_pos: node_pos, node_neg: node_neg, value: value}
      {:ok, c, nodes}
    end
  end

  def parse([<<"I", _::bitstring>> = name, node_pos, node_neg, value_str], nodes) do
    with {:ok, value} <- parse_value(value_str) do
      {nodes, node_pos} = add_node(nodes, node_pos)
      {nodes, node_neg} = add_node(nodes, node_neg)

      c = %C.CurrentSource{name: name, node_pos: node_pos, node_neg: node_neg, value: value}
      {:ok, c, nodes}
    end
  end

  def parse([<<"R", _::bitstring>> = name, node_1, node_2, value_str], nodes) do
    with {:ok, value} <- parse_value(value_str) do
      {nodes, node_1} = add_node(nodes, node_1)
      {nodes, node_2} = add_node(nodes, node_2)

      c = %C.Resistor{name: name, nodes: [node_1, node_2], value: value}
      {:ok, c, nodes}
    end
  end

  def parse([<<"C", _::bitstring>> = name, node_1, node_2, value_str], nodes) do
    with {:ok, value} <- parse_value(value_str) do
      {nodes, node_1} = add_node(nodes, node_1)
      {nodes, node_2} = add_node(nodes, node_2)

      c = %C.Capacitor{name: name, nodes: [node_1, node_2], value: value}
      {:ok, c, nodes}
    end
  end

  def parse([<<"L", _::bitstring>> = name, node_1, node_2, value_str], nodes) do
    with {:ok, value} <- parse_value(value_str) do
      {nodes, node_1} = add_node(nodes, node_1)
      {nodes, node_2} = add_node(nodes, node_2)

      c = %C.Inductor{name: name, nodes: [node_1, node_2], value: value}
      {:ok, c, nodes}
    end
  end

  def parse(
        [
          <<"K", _::bitstring>> = name,
          node_1_pos,
          node_1_neg,
          node_2_pos,
          node_2_neg,
          value_str
        ],
        nodes
      ) do
    with {:ok, n} <- parse_value(value_str) do
      {nodes, node_1_pos} = add_node(nodes, node_1_pos)
      {nodes, node_1_neg} = add_node(nodes, node_1_neg)
      {nodes, node_2_pos} = add_node(nodes, node_2_pos)
      {nodes, node_2_neg} = add_node(nodes, node_2_neg)

      c = %C.Transformer{
        name: name,
        node_1_pos: node_1_pos,
        node_1_neg: node_1_neg,
        node_2_pos: node_2_pos,
        node_2_neg: node_2_neg,
        n: n
      }

      {:ok, c, nodes}
    end
  end

  def parse(
        [
          <<"O", _::bitstring>> = name,
          node_out_pos,
          node_out_neg,
          node_in_pos,
          node_in_neg
        ],
        nodes
      ) do
    {nodes, node_out_pos} = add_node(nodes, node_out_pos)
    {nodes, node_out_neg} = add_node(nodes, node_out_neg)
    {nodes, node_in_pos} = add_node(nodes, node_in_pos)
    {nodes, node_in_neg} = add_node(nodes, node_in_neg)

    c = %C.OpAmp{
      name: name,
      node_out_pos: node_out_pos,
      node_out_neg: node_out_neg,
      node_in_pos: node_in_pos,
      node_in_neg: node_in_neg
    }

    {:ok, c, nodes}
  end

  def parse(
        [
          <<"D", _::bitstring>> = name,
          node_pos,
          node_neg
        ],
        nodes
      ) do
    {nodes, node_pos} = add_node(nodes, node_pos)
    {nodes, node_neg} = add_node(nodes, node_neg)

    c = %C.Diode{
      name: name,
      node_pos: node_pos,
      node_neg: node_neg
    }

    {:ok, c, nodes}
  end

  def parse(
        [
          <<"S", _::bitstring>> = name,
          node_pos,
          node_neg,
          control_pos,
          control_neg,
          limit_voltage_str
        ],
        nodes
      ) do
    with {:ok, limit_voltage} <- parse_value(limit_voltage_str) do
      {nodes, node_pos} = add_node(nodes, node_pos)
      {nodes, node_neg} = add_node(nodes, node_neg)
      {nodes, control_pos} = add_node(nodes, control_pos)
      {nodes, control_neg} = add_node(nodes, control_neg)

      c = %C.Switch{
        name: name,
        node_pos: node_pos,
        node_neg: node_neg,
        control_pos: control_pos,
        control_neg: control_neg,
        limit_voltage: limit_voltage
      }

      {:ok, c, nodes}
    end
  end

  for {prefix, model} <- [
        {"E", C.VoltageControlledVoltageSource},
        {"F", C.CurrentControlledVoltageSource},
        {"G", C.VoltageControlledCurrentSource},
        {"C", C.CurrentControlledCurrentSource}
      ] do
    def parse(
          [
            <<unquote(prefix), _::bitstring>> = name,
            node_out_pos,
            node_out_neg,
            node_in_pos,
            node_in_neg,
            value_str
          ],
          nodes
        ) do
      with {:ok, gain} <- parse_value(value_str) do
        {nodes, node_out_pos} = add_node(nodes, node_out_pos)
        {nodes, node_out_neg} = add_node(nodes, node_out_neg)
        {nodes, node_in_pos} = add_node(nodes, node_in_pos)
        {nodes, node_in_neg} = add_node(nodes, node_in_neg)

        c = %unquote(model){
          name: name,
          node_out_pos: node_out_pos,
          node_out_neg: node_out_neg,
          node_in_pos: node_in_pos,
          node_in_neg: node_in_neg,
          gain: gain
        }

        {:ok, c, nodes}
      end
    end
  end

  defp parse_value(value_str) do
    {value, unit} = Float.parse(value_str)

    case convert_unit(unit) do
      {:ok, scale} -> {:ok, value * scale}
      error -> error
    end
  end

  defp convert_unit(unit_str)

  defp convert_unit(""), do: {:ok, 1}

  Enum.each(@unit_mapping, fn {k, v} ->
    defp convert_unit(unquote(k)), do: {:ok, unquote(v)}
  end)

  defp convert_unit(unit), do: {:error, {:invalid_unit, unit}}

  defp add_node(nodes, node_name) do
    case Map.get(nodes, node_name) do
      number ->
        {nodes, number}

      nil ->
        {Map.put(nodes, node_name, Enum.count(nodes) + 1)}
    end
  end
end
