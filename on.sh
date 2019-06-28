#!/bin/bash

# Start byebyeproxy

if test ! -e ${HOME}/.byebyeproxy/config.yml
then
  echo "You shall fill the file ${HOME}/.byebyeproxy/config.yml first"
  echo "Have a look at config.template.yml"
  mkdir -p ${HOME}/.byebyeproxy
  exit 1
fi

if [ -z "$(docker ps --filter="ancestor=ftorto/byebyeproxy" -q)" ]
then
  docker run -it -d --net=host --privileged \
    -v ${HOME}/.byebyeproxy:/app/config \
    "ftorto/byebyeproxy:${1:-latest}" start #> /dev/null 2>&1 && echo "byebyeproxy enabled"
else
  echo "byebyeproxy already enabled"
fi
