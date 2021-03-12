defmodule ExSpice.Repo do
  use Ecto.Repo,
    otp_app: :ex_spice,
    adapter: Ecto.Adapters.Postgres
end
