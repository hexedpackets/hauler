defmodule Hauler.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :hauler,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     name: "Hauler",
     docs: [readme: "README.md", main: "README",
            source_ref: "v#{@version}",
            source_url: "https://github.com/hexedpackets/hauler"],

     # Hex
     description: description,
     package: package]
  end

  def application do
    [applications: [:logger, :poison, :consul, :aberth, :docker],
     mod: {Hauler.Supervisor, []}]
  end

  defp deps do
    [
      {:consul, github: "hexedpackets/exconsul"},
      {:poison, "~> 1.2"},
      {:exrm, "~> 0.14.16"},
      {:hackney, "~> 1.3", override: true},
      {:barrel, github: "hexedpackets/barrel_tcp", override: true},
      {:aberth, github: "lastcanal/aberth"},
      {:docker, github: "hexedpackets/docker-elixir"},
    ]
  end

  defp description do
    """
    Control and monitor Docker deployments in conjunction with Consul.
    """
  end

  defp package do
    [contributors: ["William Huba"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/hexedpackets/hauler"},
     files: ~w(mix.exs README.md LICENSE lib VERSION)]
  end
end
