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

  @valid_line_prefixes ~w(R C L K O E F G H D I V $)

  def parse(["*" | _], _nodes), do: {:ok, nil}

  def parse([<<prefix::binary-size(1), _::bitstring>> | _], _variables)
      when prefix not in @valid_line_prefixes,
      do: {:error, {:invalid_component, prefix}}

  def parse([<<"V", _::bitstring>> = name, node_pos, node_neg, value_str], variables) do
    with {:ok, value} <- parse_value(value_str) do
      {variables, node_pos} = add_variable(variables, node_pos)
      {variables, node_neg} = add_variable(variables, node_neg)
      {variables, j} = add_variable(variables, "j#{name}")

      c = %C.VoltageSource{
        name: name,
        node_pos: node_pos,
        node_neg: node_neg,
        value: value,
        current: j
      }

      {:ok, c, variables}
    end
  end

  def parse([<<"I", _::bitstring>> = name, node_pos, node_neg, value_str], variables) do
    with {:ok, value} <- parse_value(value_str) do
      {variables, node_pos} = add_variable(variables, node_pos)
      {variables, node_neg} = add_variable(variables, node_neg)

      c = %C.CurrentSource{name: name, node_pos: node_pos, node_neg: node_neg, value: value}
      {:ok, c, variables}
    end
  end

  def parse([<<"R", _::bitstring>> = name, node_1, node_2, value_str], variables) do
    with {:ok, value} <- parse_value(value_str) do
      {variables, node_1} = add_variable(variables, node_1)
      {variables, node_2} = add_variable(variables, node_2)

      c = %C.Resistor{name: name, nodes: [node_1, node_2], value: value}
      {:ok, c, variables}
    end
  end

  def parse([<<"C", _::bitstring>> = name, node_1, node_2, value_str], variables) do
    with {:ok, value} <- parse_value(value_str) do
      {variables, node_1} = add_variable(variables, node_1)
      {variables, node_2} = add_variable(variables, node_2)
      {variables, j} = add_variable(variables, "j#{name}")

      c = %C.Capacitor{name: name, nodes: [node_1, node_2], value: value, current: j}
      {:ok, c, variables}
    end
  end

  def parse([<<"L", _::bitstring>> = name, node_1, node_2, value_str], variables) do
    with {:ok, value} <- parse_value(value_str) do
      {variables, node_1} = add_variable(variables, node_1)
      {variables, node_2} = add_variable(variables, node_2)
      {variables, j} = add_variable(variables, "j#{name}")

      c = %C.Inductor{name: name, nodes: [node_1, node_2], value: value, current: j}
      {:ok, c, variables}
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
        variables
      ) do
    with {:ok, n} <- parse_value(value_str) do
      {variables, node_1_pos} = add_variable(variables, node_1_pos)
      {variables, node_1_neg} = add_variable(variables, node_1_neg)
      {variables, node_2_pos} = add_variable(variables, node_2_pos)
      {variables, node_2_neg} = add_variable(variables, node_2_neg)
      {variables, j} = add_variable(variables, "j#{name}")

      c = %C.Transformer{
        name: name,
        node_1_pos: node_1_pos,
        node_1_neg: node_1_neg,
        node_2_pos: node_2_pos,
        node_2_neg: node_2_neg,
        n: n,
        current: j
      }

      {:ok, c, variables}
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
        variables
      ) do
    {variables, node_out_pos} = add_variable(variables, node_out_pos)
    {variables, node_out_neg} = add_variable(variables, node_out_neg)
    {variables, node_in_pos} = add_variable(variables, node_in_pos)
    {variables, node_in_neg} = add_variable(variables, node_in_neg)
    {variables, j} = add_variable(variables, "j#{name}")

    c = %C.OpAmp{
      name: name,
      node_out_pos: node_out_pos,
      node_out_neg: node_out_neg,
      node_in_pos: node_in_pos,
      node_in_neg: node_in_neg,
      current: j
    }

    {:ok, c, variables}
  end

  def parse(
        [
          <<"D", _::bitstring>> = name,
          node_pos,
          node_neg
        ],
        variables
      ) do
    {variables, node_pos} = add_variable(variables, node_pos)
    {variables, node_neg} = add_variable(variables, node_neg)

    {variables, j} = add_variable(variables, "j#{name}")

    c = %C.Diode{
      name: name,
      node_pos: node_pos,
      node_neg: node_neg,
      current: j
    }

    {:ok, c, variables}
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
        variables
      ) do
    with {:ok, limit_voltage} <- parse_value(limit_voltage_str) do
      {variables, node_pos} = add_variable(variables, node_pos)
      {variables, node_neg} = add_variable(variables, node_neg)
      {variables, control_pos} = add_variable(variables, control_pos)
      {variables, control_neg} = add_variable(variables, control_neg)

      c = %C.Switch{
        name: name,
        node_pos: node_pos,
        node_neg: node_neg,
        control_pos: control_pos,
        control_neg: control_neg,
        limit_voltage: limit_voltage
      }

      {:ok, c, variables}
    end
  end

  def parse(
        [
          <<"H", _::bitstring>> = name,
          node_out_pos,
          node_out_neg,
          node_in_pos,
          node_in_neg,
          value_str
        ],
        variables
      ) do
    with {:ok, gain} <- parse_value(value_str) do
      {variables, node_out_pos} = add_variable(variables, node_out_pos)
      {variables, node_out_neg} = add_variable(variables, node_out_neg)
      {variables, node_in_pos} = add_variable(variables, node_in_pos)
      {variables, node_in_neg} = add_variable(variables, node_in_neg)
      {variables, jx} = add_variable(variables, "jx#{name}")
      {variables, jy} = add_variable(variables, "jy#{name}")

      c = %C.CurrentControlledVoltageSource{
        name: name,
        node_out_pos: node_out_pos,
        node_out_neg: node_out_neg,
        node_in_pos: node_in_pos,
        node_in_neg: node_in_neg,
        gain: gain,
        current_out: jy,
        current_in: jx
      }

      {:ok, c, variables}
    end
  end

  def parse(
        [
          <<"G", _::bitstring>> = name,
          node_out_pos,
          node_out_neg,
          node_in_pos,
          node_in_neg,
          value_str
        ],
        variables
      ) do
    with {:ok, gain} <- parse_value(value_str) do
      {variables, node_out_pos} = add_variable(variables, node_out_pos)
      {variables, node_out_neg} = add_variable(variables, node_out_neg)
      {variables, node_in_pos} = add_variable(variables, node_in_pos)
      {variables, node_in_neg} = add_variable(variables, node_in_neg)

      c = %C.VoltageControlledCurrentSource{
        name: name,
        node_out_pos: node_out_pos,
        node_out_neg: node_out_neg,
        node_in_pos: node_in_pos,
        node_in_neg: node_in_neg,
        gain: gain
      }

      {:ok, c, variables}
    end
  end

  for {prefix, model} <- [
        {"E", C.VoltageControlledVoltageSource},
        {"F", C.CurrentControlledCurrentSource}
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
          variables
        ) do
      with {:ok, gain} <- parse_value(value_str) do
        {variables, node_out_pos} = add_variable(variables, node_out_pos)
        {variables, node_out_neg} = add_variable(variables, node_out_neg)
        {variables, node_in_pos} = add_variable(variables, node_in_pos)
        {variables, node_in_neg} = add_variable(variables, node_in_neg)
        {variables, j} = add_variable(variables, "j#{name}")

        c = %unquote(model){
          name: name,
          node_out_pos: node_out_pos,
          node_out_neg: node_out_neg,
          node_in_pos: node_in_pos,
          node_in_neg: node_in_neg,
          gain: gain,
          current: j
        }

        {:ok, c, variables}
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

  defp add_variable(vars, var_name) do
    case Map.get(vars, var_name) do
      nil ->
        var_number = Enum.count(vars)
        {Map.put(vars, var_name, var_number), var_number}

      number ->
        {vars, number}
    end
  end
end
