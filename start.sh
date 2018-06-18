#!/bin/bash

DEFAULT_PROXY_IP=http://127.0.0.1:3128

docker run -it --net=host --privileged -d \
  -e http_proxy=${1:-${DEFAULT_PROXY_IP}} \
  ftorto/byebyeproxy:latest
