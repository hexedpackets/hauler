[
  mappings: [
    "logger.console.level": [
      doc: "Level to log at.",
      to: "logger.console.level",
      datatype: :atom,
      default: :debug
    ],
    "docker.host": [
      doc: "How to connect to the docker daemon.",
      to: "docker.host",
      datatype: :binary,
      default: nil
    ],
    "hauler.docker.server": [
      doc: "Name for the hauler server.",
      to: "hauler.docker.server",
      datatype: :atom,
      default: :hauler
    ],
    "consul.local.datacenter": [
      doc: "Consul datacenter to query.",
      to: "hauler.consul.datacenter",
      datatype: :binary,
      default: nil
    ],
    "consul.central.datacenter": [
      doc: "Consul datacenter holding centralized config values.",
      to: "consul.datacenter",
      datatype: :binary,
      default: nil
    ]
  ],
  translations: [
  ]
]
