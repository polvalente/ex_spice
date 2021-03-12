# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :ex_spice,
  ecto_repos: [ExSpice.Repo]

# Configures the endpoint
config :ex_spice, ExSpiceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1ZMDLytlpXyk4EZMJltIZSqsKVhLBNBgyhIya/3LT9BKMGoK/+YP6CISxqo1wtce",
  render_errors: [view: ExSpiceWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ExSpice.PubSub,
  live_view: [signing_salt: "0H3G3Q9f"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
