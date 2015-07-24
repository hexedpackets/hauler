#!/bin/bash

export MIX_ENV=prod

mix deps.clean exrm
rm -rf rel/hauler/

mix deps.get
mix deps.compile
mix compile
mix release

for i in rel/hauler/hauler-*.tar.gz; do
  mv -v $i .
done
