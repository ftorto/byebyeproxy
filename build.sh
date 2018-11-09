#!/bin/bash

echo "Builds the image"

docker build . -t ftorto/byebyeproxy:${1:-latest}