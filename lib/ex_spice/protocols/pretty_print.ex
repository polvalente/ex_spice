defprotocol ExSpice.PrettyPrint do
  def to_string(netlist_or_data)
end

defimpl ExSpice.PrettyPrint, for: Integer do
  def to_string(n), do: ExSpice.PrettyPrint.to_string(1.0 * n)
end

defimpl ExSpice.PrettyPrint, for: Float do
  def to_string(n) do
    {sign_str, abs_value} = split_sign(n)

    {val, unit} =
      cond do
        abs_value < 1.0e-12 -> {abs_value * 1.0e15, "f"}
        abs_value < 1.0e-9 -> {abs_value * 1.0e12, "p"}
        abs_value < 1.0e-6 -> {abs_value * 1.0e9, "n"}
        abs_value < 1.0e-3 -> {abs_value * 1.0e6, "u"}
        abs_value < 1.0 -> {abs_value * 1.0e3, "m"}
        abs_value < 1.0e3 -> {abs_value, ""}
        abs_value < 1.0e6 -> {abs_value * 1.0e-3, "k"}
        true -> {abs_value * 1.0e-6, "meg"}
      end

    IO.iodata_to_binary([sign_str, val |> Float.round(3) |> Float.to_string(), unit])
  end

  defp split_sign(n) when n >= 0, do: {"", n}
  defp split_sign(n), do: {"-", abs(n)}
end

defimpl ExSpice.PrettyPrint, for: Map do
  def to_string(%{netlist: netlist, component: component}) do
    ExSpice.Component.PrettyPrint.to_string(component, netlist)
  end
end
