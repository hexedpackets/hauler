use Mix.Config

config :hauler, :docker,
  server: :hauler

config :hauler, :consul, datacenter: "dc1"
config :consul, datacenter: "dc1"
