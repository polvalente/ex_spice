defprotocol ExSpice.Component do
  @spec dc_stamp(struct, Nx.Tensor.shape()) :: Nx.Tensor.t()
  def dc_stamp(component, shape)

  @spec dc_stamp(struct, struct) :: String.t()
  def to_string(data, netlist)
end
