defprotocol ExSpice.Component.DC do
  @spec as_tensor(struct, Nx.Tensor.shape()) :: Nx.Tensor.t()
  def as_tensor(component, shape)
end
