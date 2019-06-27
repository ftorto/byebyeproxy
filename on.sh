#!/bin/bash

# Start byebyeproxy

source ${HOME}/.byebyeproxy.conf
test -z $PROXY_URL_HTTP && echo "PROXY_URL_HTTP not filled in ${HOME}/.byebyeproxy.conf" && exit 1

if [ -z "$(docker ps --filter="ancestor=ftorto/byebyeproxy" -q)" ]
then
  docker run -d -it --net=host --privileged \
    -e http_proxy="${PROXY_URL_HTTP}" \
    -e https_proxy="${PROXY_URL_HTTPS:-${PROXY_URL_HTTP}}" \
    -e no_proxy="${NO_PROXY_URLS}" \
    -e proxy_socks="${PROXY_SOCKS:-${PROXY_URL_HTTPS}}" \
    -e SOCKS_LOGIN="${SOCKS_LOGIN:-""}" \
    -e SOCKS_PASSWORD="${SOCKS_PASSWORD:-""}" \
    "ftorto/byebyeproxy:${1:-latest}" > /dev/null 2>&1 && echo "byebyeproxy enabled"

else
  echo "byebyeproxy already enabled"
fi
