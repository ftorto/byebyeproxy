#!/usr/bin/python3

import sys
import json
import os

from os.path import expanduser
home = expanduser("~")

HTTP_PROXY = os.environ.get('http_proxy', "http://127.0.0.1:3128")
HTTPS_PROXY = os.environ.get('https_proxy', HTTP_PROXY)

PROXY_CONFIG = {
    "default": {
        "httpProxy": HTTP_PROXY,
        "httpsProxy": HTTPS_PROXY,
        "noProxy": "localhost,10.0.0.0/8,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.168.0.0/16,224.0.0.0/4"
    }
}


def activate():
    docker_config = {}
    with open("%s/.docker/config.json" % home) as f:
        docker_config = json.load(f)
        docker_config["proxies"] = PROXY_CONFIG
    with open("%s/.docker/config.json" % home, 'w') as f:
        json.dump(docker_config, f, indent=4, sort_keys=True)


def deactivate():
    docker_config = {}
    with open("%s/.docker/config.json" % home) as f:
        docker_config = json.load(f)
        if "proxies" in docker_config:
            del docker_config["proxies"]
    with open("%s/.docker/config.json" % home, 'w') as f:
        json.dump(docker_config, f, indent=4, sort_keys=True)


def main(argv):

    if argv[0] in ["up", "on", "1", "activate", "enable"]:
        try:
            activate()
            print("Proxy activated for Docker")
            sys.exit(0)
        except:
            sys.exit(1)
    if argv[0] in ["down", "dn", "off", "0", "deactivate", "disable"]:
        try:
            deactivate()
            print("Proxy deactivated for Docker")
            sys.exit(0)
        except:
            sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
