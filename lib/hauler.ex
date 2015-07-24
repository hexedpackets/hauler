defmodule Hauler do
  defmodule Consul do
    def datacenter, do: Application.get_env(:hauler, :consul)[:datacenter]
  end
end
