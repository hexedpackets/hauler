## Hauler

Hauler is an Elixir application for controlling and monitoring Docker deployments in conjunction with Consul. It can be controlled using either Erlang RPC calls or [BERT-RPC](https://github.com/lastcanal/aberth).

Back on Cybertron, Hauler was a Constructicon involved in the building of the Crystal City. When his teammates were reprogrammed as Decepticons, Hauler turned to the Autobots, joining their ranks. This choice would eventually put him on board the Ark for its doomed voyage that ended on Earth. When he awoke with the rest of the crew in 1984, he resumed his primary function: the discovery and procurement of energy sources. This task sends him far and wide across the planet, and his tendency towards capricious self-expression often results in him coming back with different colors and parts.

His crane mode can lift 60 tons, and in robot mode, he can launch his hands from their wrist-sockets. The hands can fly through the air under his remote-control guidance, allowing him to perform tasks normally beyond his reach.

Hauler performs tasks related to Docker management. Clients can:
- list all Docker containers on a node
- start/create a container based on a config stored in Consul
- stop and optionally destroy a container
- recreate a container from a new image


## Releasing
### Requirements
- Docker must be installed and running locally. The release script uses a Linux-based Docker image; system libraries get linked in in, so an OSX/Windows based release will not be deployable on Linux.
- [github-releases](https://github.com/aktau/github-release) needs to be installed
- The environmental variables `GITHUB_TOKEN` must be set
- Bump the version number in the VERSION file. Then from the root of the project, run `scripts/release.sh`.
