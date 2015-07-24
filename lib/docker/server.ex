defmodule Hauler.Server do
  use GenServer

  def server_name, do: Application.get_env(:hauler, :docker)[:server]

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: server_name)
  end

  @base_timeout 60_000
  def start(name, opts), do: GenServer.call(server_name, {:start, name, opts}, @base_timeout * 7)
  def stop(name, opts), do: GenServer.call(server_name, {:stop, name, opts}, @base_timeout)
  def recreate(name, opts), do: GenServer.call(server_name, {:recreate, name, opts}, @base_timeout * 7)
  def list, do:  GenServer.call(server_name, :list)
  def inspect(name, opts), do: GenServer.call(server_name, {:inspect, name, opts})
  def cleanup, do: GenServer.cast(server_name, {:cleanup, 2})
  def cleanup(nil), do: nil
  def cleanup(keep), do: GenServer.cast(server_name, {:cleanup, keep})
  def register(config), do: GenServer.call(server_name, {:register, config, []})
  def register(config, targets), do: GenServer.call(server_name, {:register, config, targets})


  def handle_call({:start, name, opts}, _from, state) do
    pull = Keyword.get(opts, :pull, true)
    res = Hauler.Docker.start(name, pull) |> parse_inspect_result(opts[:verbose])
    {:reply, res, state}
  end

  def handle_call({:stop, name, opts}, _from, state) do
    remove = Keyword.get(opts, :remove, true)
    res = Hauler.Docker.stop(name, remove)
    {:reply, res, state}
  end

  def handle_call({:recreate, name, opts}, _from, state) do
    pull = Keyword.get(opts, :pull, true)
    keep = Keyword.get(opts, :keep, 2)
    tag = Keyword.get(opts, :tag)

    service_ids = Consul.Agent.service_ids(name)
    Enum.each(service_ids, &(Consul.Agent.service_maint_enable(&1, "Deploying")))

    res = Hauler.Docker.recreate(name, pull, tag) |> parse_inspect_result(opts[:verbose])
    Hauler.Server.cleanup(keep)

    Enum.each(service_ids, &Consul.Agent.service_maint_disable/1)

    {:reply, res, state}
  end

  def handle_call(:list, _from, state) do
    res = Docker.Containers.list
    {:reply, res, state}
  end

  def handle_call({:inspect, name, opts}, _from, state) do
    res = Hauler.Docker.Control.inspect(name)
    |> parse_inspect_result(opts[:verbose])
    {:reply, res, state}
  end

  def handle_call({:register, config, targets}, _from, state) do
    res = Hauler.Docker.set_config(config, targets)
    {:reply, res, state}
  end

  def handle_cast({:cleanup, keep}, state) do
    Hauler.Docker.Control.cleanup(keep)
    {:noreply, state}
  end

  defp parse_inspect_result(result, true), do: result
  defp parse_inspect_result(result, nil), do: parse_inspect_result(result, false)
  defp parse_inspect_result([result], false), do: minimal_result(result)
  defp parse_inspect_result(results, false), do: Enum.map(results, &minimal_result/1)

  defp minimal_result(message) when is_binary(message), do: {:error, message}
  defp minimal_result(%{"State" => %{"Running" => true, "Error" => ""}}), do: :ok
  defp minimal_result(%{"State" => %{"Error" => error}}), do: {:error, error}
end
