#!/bin/bash

# Stop byebyeproxy

echo "disabling byebyeproxy"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd ${DIR} > /dev/null
export proxy="http://172.27.128.34:3128"
docker stop $(docker ps --filter="ancestor=ftorto/byebyeproxy" -q) >/dev/null 2>&1
docker run -it --net=host --privileged -d \
  -e http_proxy=${proxy} \
  -e https_proxy=${proxy} \
  ftorto/byebyeproxy:${1:-latest} stop > /dev/null 2>&1 && echo "byebyeproxy disabled"
popd > /dev/null

if [ "$(id -u)" == "0" ]; then
   iptables-save | wc -l
fi

