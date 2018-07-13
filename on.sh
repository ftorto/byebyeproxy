#!/bin/bash

# Start byebyeproxy

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z $(docker ps --filter="ancestor=ftorto/byebyeproxy" -q) ]
then
  pushd ${DIR} > /dev/null
  export proxy="http://172.27.128.34:3128"
  docker run -it --net=host --privileged -d \
    -e http_proxy=${proxy} \
    -e https_proxy=${proxy} \
    ftorto/byebyeproxy:${1:-latest} > /dev/null 2>&1 && echo "byebyeproxy enabled"
  popd > /dev/null
else
  echo "byebyeproxy already enabled"
fi