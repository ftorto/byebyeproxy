#!/bin/bash

pushd /home/ftortora/scripts/byebyeproxy > /dev/null

export http_proxy="http://172.27.128.34:3128"

docker stop $(docker ps --filter="ancestor=ftorto/byebyeproxy" -q) >/dev/null 2>&1

python3 ./docker_conf_proxy.py off

docker run -it --net=host --privileged -d \
  -e http_proxy=${http_proxy} \
  ftorto/byebyeproxy:latest stop

popd > /dev/null

