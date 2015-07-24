defmodule Hauler.Supervisor do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Hauler.Server, [:ok]),
      worker(:aberth, [100, 9999, [Hauler.Server]], function: :start_server),
    ]

    opts = [strategy: :one_for_one, name: Hauler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
