defmodule Hauler.Docker do
  require Logger

  def default_registry, do: "index.docker.io"

  defp replace_image_tag(image, tag), do: (String.split(image, ":") |> List.first) <> ":" <> to_string(tag)

  @doc """
  Recreates a Docker container from its config, stopping and removing any
  existing containers with the same name.
  """
  def recreate(name, pull_image), do: recreate(name, pull_image, nil)
  def recreate(name, pull_image, nil) do
    confs = get_container_configs(name)
    pre_pull(confs, pull_image)
    stop(name, true)
    _start(confs, [])
  end
  def recreate(name, pull_image, tag) do
    confs = get_container_configs(name)
    |> Enum.map(&(Map.put(&1, :image, replace_image_tag(&1.image, tag))))
    pre_pull(confs, pull_image)
    stop(name, true)
    _start(confs, [])
  end


  @doc """
  Takes the name of a Docker container, finds the relevant configuration,
  pulls the image if required, and ensures the container is started.
  """
  def start(name, pull) do
    confs = get_container_configs(name)

    # All images should be pulled before starting any containers
    pre_pull(confs, pull)
    _start(confs, [])
  end
  defp _start([], results), do: results
  defp _start([conf | tail], results) do
    Logger.debug "Config for #{conf.name}: #{inspect conf}"
    results = List.insert_at(results, 0, run(conf))
    _start(tail, results)
  end

  defp pre_pull(_, false), do: :false
  defp pre_pull(confs, true) do
    confs
    |> Enum.map_reduce(HashSet.new, fn(conf, acc) -> {conf.image, Set.put(acc, conf.image)} end)
    |> elem(1)
    |> Enum.each(&Hauler.Docker.Control.pull/1)
  end

  defp get_container_configs(name) do
    "services/#{name}"
    |> Consul.KV.key_name
    |> Consul.KV.get_conf(:recurse, Hauler.Consul.datacenter)
    |> Enum.filter(fn({key, _value}) -> key |> String.ends_with? "/docker" end)
    |> Dict.values
  end

  @doc """
  Runs a Docker container using the provided config.
  """
  def run(conf = %Docker.Config{}) do
    Docker.find_ids(conf.name)
    |> List.first
    |> inspect_container
    |> _run(conf)
  end

  defp _run(nil, conf) do
    Logger.info "#{conf.name} is not running"
    ensure_image(conf.image)
    Hauler.Docker.Control.run(conf)
  end
  defp _run(container = %{"Name" => name}, _) do
    Logger.info "#{name} is running"
    Logger.debug inspect container
    container
  end

  defp inspect_container(nil), do: nil
  defp inspect_container(container), do: Docker.Containers.inspect(container)

  @doc """
  Ensures that the given image exists locally, pulling it if it doesn't.
  """
  def ensure_image(image) do
    base_image = String.split(image, ":") |> List.first
    full_image = base_image <> ":" <> Docker.Names.extract_tag(image)

    base_image
    |> Docker.Images.list
    |> Enum.filter(&(full_image in &1["RepoTags"]))
    |> _ensure_image(image)
  end
  defp _ensure_image([], image), do: Hauler.Docker.Control.pull(image)
  defp _ensure_image(_, _), do: :ok

  @doc """
  Stops a running Docker container locally.

  Args:
    name: The name of the Docker container to stop.
    remove: Whether to delete the container after stopping it. While a truthy value will always
        remove the container, a falsey value might still cause the container to be removed if
        it was started with the autoremove option.
  Returns:
    A boolean of whether an action was taken.
  """
  def stop(name, remove \\ false) do
    Docker.find_ids(name, :partial)
    |> Enum.map(&Docker.Containers.inspect/1)
    |> Enum.each(&(Hauler.Docker.Control.stop(&1, remove)))
  end

  @doc """
  Restarts a docker container on the target node.

  Args:
    name: The name of the Docker container to restart.
    target: The server on which the container is running.
    pull: Boolean indicating whether to pull the latest image before starting.
  """
  def restart(name, target, pull \\ true) do
    "services/#{name}/docker"
    |> Consul.KV.key_name
    |> Consul.KV.get_conf(:recurse, Hauler.Consul.datacenter)
    {name, target, pull}
  end

  @doc """
  Runs a command inside an existing Docker container.

  Args:
    command: String or list of the command to run.
    name: Name of the container.
    detach: If true the command will run in the background.
  """
  def execute(name, command, detach \\ false) do
    Logger.info "Running #{command} in #{name}"

    Docker.find_ids(name)
    |> List.first
    |> Docker.Containers.exec(command, detach)
  end

  @doc """
  Saves a container config as specified by Docker.Config in Consul.
  """
  def set_config(conf = %Docker.Config{name: name}, targets) do
    base_key = Path.join("services", Consul.KV.key_name(name))

    docker_key = Path.join(base_key, "docker")
    %Docker.Config{conf | name: Docker.Names.container_safe(conf.name)}
    |> Consul.KV.store_json(docker_key)

    Consul.KV.set("docker", Path.join(base_key, "type"))
    Consul.KV.append(targets, Path.join(base_key, "targets"))
  end
  def set_config(conf, targets) when is_binary(conf) do
    conf |> Poison.decode!(as: Docker.Config) |> set_config(targets)
  end

  @doc """
  Finds and returns a list of all unique repos that are currently downloaded.
  """
  def find_local_repos do
    Docker.Images.list
    |> Enum.filter(&(&1["RepoTags"] != ["<none>:<none>"]))
  end

  def find_local_repos(:notags) do
    find_local_repos
    |> Stream.flat_map(&(&1["RepoTags"])) |> Stream.map(&(&1 |> String.split(":") |> List.first))
    |> Enum.uniq
  end

  defp flatten_repo_tags(image) do
    image["RepoTags"]
        |> Stream.map(&(String.split(&1, ":") |> List.to_tuple))
        |> Stream.map(&([repo: elem(&1, 0), tag: elem(&1, 1), id: image["Id"], created: image["Created"]]))
  end

  def images_by_repo do
    find_local_repos
    |> Stream.flat_map(&flatten_repo_tags/1)
    |> Enum.group_by(&(&1[:repo]))
  end

  defmodule Control do
    @doc """
    Authenticates against the Docker registry.
    """
    def login, do: login(Hauler.Docker.default_registry)
    def login(registry) do
      case Consul.KV.docker_credentials(registry) |> Docker.Auth.login do
        %{"Status" => "Login Succeeded"} -> :ok
        "" -> :ok
      end
    end

    def stop(%{"State" => %{"Running" => false}, "Name" => name, "Id" => id}, remove) do
      Logger.info "#{id} (#{name}) is not currently running"
      _remove(id, remove)
    end
    def stop(%{"State" => %{"Running" => true}, "Name" => name, "Id" => id}, remove) do
      Logger.info "Stopping #{id} (#{name})..."
      Logger.debug Docker.Containers.stop(id)
      _remove(id, remove)
    end

    defp _remove(_, false), do: nil
    defp _remove(id, true) do
      Logger.info "Removing container #{id}"
      Docker.Containers.remove(id)
    end


    def run(conf = %Docker.Config{}) do
      Logger.info "Running #{conf.name}"

      name = Docker.Names.container_safe(conf.name)
      start_config = Docker.Config.start_container(conf)

      Docker.Config.create_container(conf)
      |> Dict.update("HostConfig", start_config, &(Dict.merge(&1, start_config)))
      |> create_container(name)
      |> start_container
    end

    #
    # Create an image from the specified values.
    #
    defp create_container(conf, name) do
      conf
      |> Docker.Containers.create(name)
      |> Dict.get("Id")
    end

    defp start_container(id) do
      Docker.Containers.start(id)
      Docker.Containers.inspect(id)
    end

    @doc """
    Pulls down a Docker image from a remote repo.

    Args:
      image: The name of the image to pull.
    """
    def pull(image) do
      Logger.info "Pulling #{image} from repo"

      tag = Docker.Names.extract_tag(image)
      image_name = String.split(image, ":") |> List.first
      {registry, _repo, _name} = Docker.Names.split_image(image_name)

      auth = Consul.KV.docker_credentials(registry)
      Logger.debug Docker.Images.pull(image_name, tag, auth)
    end

    @doc """
    Given the name of a container, returns the results of Docker inspect command.
    """
    def inspect(name) do
      Docker.find_ids(name)
          |> Enum.map(&Docker.Containers.inspect/1)
    end

    @doc """
    Deletes the oldest images for each repo, keeping only the number specified.
    """
    def delete_old_images(images, keep) do
      images
      |> Enum.sort(&(&1[:created] >= &2[:created]))
      |> Stream.uniq(&(&1[:id]))
      |> Stream.drop(keep)
      |> Enum.each(&(Docker.Images.delete(&1[:id])))
    end

    @doc """
    Cleans up old docker images, keeping only the most recent ones for each repo.
    """
    def cleanup(keep) do
      Hauler.Docker.images_by_repo
      |> Enum.each(fn({_repo, images}) -> Hauler.Docker.Control.delete_old_images(images, keep) end)
    end
  end
end
