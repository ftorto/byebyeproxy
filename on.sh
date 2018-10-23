#!/bin/bash

# Start byebyeproxy

source "${HOME}/.byebyeproxy.conf"
test -z "$PROXY_URL_HTTP" && echo "PROXY_URL_HTTP not filled in ${HOME}/.byebyeproxy.conf" && exit 1
test -z "$PROXY_URL_HTTPS" && echo "PROXY_URL_HTTPS not filled in ${HOME}/.byebyeproxy.conf" && exit 1

if [ -z "$(docker ps --filter="ancestor=ftorto/byebyeproxy" -q)" ]
then
  docker run -it --net=host --privileged -d \
    -e http_proxy="${PROXY_URL_HTTP}" \
    -e https_proxy="${PROXY_URL_HTTPS}" \
    "ftorto/byebyeproxy:${1:-latest}" > /dev/null 2>&1 && echo "byebyeproxy enabled"
else
  echo "byebyeproxy already enabled"
fi