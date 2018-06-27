#!/bin/bash

pushd /home/ftortora/scripts/byebyeproxy > /dev/null

export http_proxy="http://172.27.128.34:3128"

python3 ./docker_conf_proxy.py on

docker run -it --net=host --privileged -d \
  -e http_proxy=${http_proxy} \
  ftorto/byebyeproxy:latest

popd > /dev/null

