#!/bin/bash

docker run --rm -v `pwd`:/opt/hauler --workdir /opt/hauler hexedpackets/elixir scripts/exrm.sh && \

VERSION=`cat VERSION | xargs`
git tag v${VERSION} && git push --tags && \
github-release release \
    --user hexedpackets \
    --repo hauler \
    --tag v$VERSION \
    --name "v$VERSION" \
    --description "v$VERSION" && \
github-release release \
    --user hexedpackets \
    --repo hauler \
    --tag v$VERSION \
    --name "linux-amd64-hauler-release.tar.gz" \
    --file hauler-${VERSION}.tar.gz
