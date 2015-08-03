#!/bin/bash

docker run --rm -v `pwd`:/opt/hauler --workdir /opt/hauler hexedpackets/elixir scripts/exrm.sh
