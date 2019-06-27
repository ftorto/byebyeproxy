#!/bin/bash

echo "Building the image ${1:-unstable}"

docker build --force-rm --no-cache . -t ftorto/byebyeproxy:${1:-unstable}