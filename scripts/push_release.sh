#!/bin/bash

VERSION=`cat VERSION | xargs`
git tag v${VERSION} && git push --tags && \
github-release release \
    --user hexedpackets \
    --repo hauler \
    --tag v$VERSION \
    --name "v$VERSION" \
    --description "v$VERSION" && \
github-release upload \
    --user hexedpackets \
    --repo hauler \
    --tag v$VERSION \
    --name "linux-amd64-hauler-release.tar.gz" \
    --file hauler-${VERSION}.tar.gz
