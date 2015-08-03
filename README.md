# Hauler

Hauler is an Elixir application for controlling and monitoring Docker deployments in conjunction with Consul. It can be controlled using either Erlang RPC calls or [BERT-RPC](https://github.com/lastcanal/aberth).

Back on Cybertron, Hauler was a Constructicon involved in the building of the Crystal City. When his teammates were reprogrammed as Decepticons, Hauler turned to the Autobots, joining their ranks. This choice would eventually put him on board the Ark for its doomed voyage that ended on Earth. When he awoke with the rest of the crew in 1984, he resumed his primary function: the discovery and procurement of energy sources. This task sends him far and wide across the planet, and his tendency towards capricious self-expression often results in him coming back with different colors and parts.

His crane mode can lift 60 tons, and in robot mode, he can launch his hands from their wrist-sockets. The hands can fly through the air under his remote-control guidance, allowing him to perform tasks normally beyond his reach.

Hauler performs tasks related to Docker management. Clients can:
- list all Docker containers on a node
- start/create a container based on a config stored in Consul
- stop and optionally destroy a container
- recreate a container from a new image

## RPCs
RPCs are the primary way of interacting with Hauler, either from a remote Erlang process or with BERT-RPC. All functions are under the `Hauler.Server` module; from an RPC this should be called as `Elixir.Hauler.Server`. The functions available are:

```elixir
start/2 - Creates and starts a Docker container. If the container already exists, nothing will be changed.
stop/2 - Stops and optionally deletes a running Docker container.
recreate/2 - Creates and starts a new Docker container. If the container already exists, the old one will be removed first.
list/0 - Lists all running Docker containers.
inspect/2 - Lookup information about a currently running container.
cleanup/0 - Remove old images (ignoring tags). Only the most recent is kept.
cleanup/1 - Remove old images (ignoring tags) with a specified number to keep.
register/1 - Store a container configuration in Consul.
register/2 - Store a container configuration in Consul, with a static list of nodes for deploying.
```

## Docker configuration
Hauler uses [docker-elixir](https://github.com/hexedpackets/docker-elixir) to work with the Docker API and convert JSON into a format usable with the API.

## Releasing
### Build
- Docker must be installed and running locally. The release script uses a Linux-based Docker image; system libraries get linked in in, so an OSX/Windows based release will not be deployable on Linux.
- Bump the version number in the VERSION file. Then from the root of the project, run `scripts/build_release.sh`

### Publish
- First build the release as instructed above
- [github-releases](https://github.com/aktau/github-release) needs to be installed
- The environmental variables `GITHUB_TOKEN` must be set
- Run `scripts/push_release.sh`
