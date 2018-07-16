#!/bin/bash

# Stop byebyeproxy

echo "disabling byebyeproxy"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/config.env
test -z $PROXY_URL_HTTP && echo "PROXY_URL_HTTP not filled in ${DIR}/config.env" && exit 1
test -z $PROXY_URL_HTTPS && echo "PROXY_URL_HTTPS not filled in ${DIR}/config.env" && exit 1

pushd ${DIR} > /dev/null
docker stop $(docker ps --filter="ancestor=ftorto/byebyeproxy" -q) >/dev/null 2>&1
docker run -it --net=host --privileged -d \
  -e http_proxy=${PROXY_URL_HTTP} \
  -e https_proxy=${PROXY_URL_HTTPS} \
  ftorto/byebyeproxy:${1:-latest} stop > /dev/null 2>&1 && echo "byebyeproxy disabled"
popd > /dev/null

if [ "$(id -u)" == "0" ]; then
   iptables-save | wc -l
fi

