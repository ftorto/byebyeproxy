#!/usr/bin/python3

import sys
import json
import os

from os.path import expanduser
home = expanduser("~")

HTTP_PROXY = os.environ.get('HTTP_PROXY', "http://127.0.0.1:3128")
HTTPS_PROXY = os.environ.get('HTTPS_PROXY', HTTP_PROXY)

PROXY_CONFIG = {
    "default": {
        "httpProxy": HTTP_PROXY,
        "httpsProxy": HTTPS_PROXY,
    }
}


def activate():
    docker_config = {}
    with open("%s/.docker/config.json" % home) as f:
        docker_config = json.load(f)
        docker_config["proxies"] = PROXY_CONFIG
    with open("%s/.docker/config.json" % home, 'w') as f:
        json.dump(docker_config, f, indent=4, sort_keys=True)
        print("Proxy activated for Docker")


def deactivate():
    docker_config = {}
    with open("%s/.docker/config.json" % home) as f:
        docker_config = json.load(f)
        if "proxies" in docker_config:
            del docker_config["proxies"]
    with open("%s/.docker/config.json" % home, 'w') as f:
        json.dump(docker_config, f, indent=4, sort_keys=True)
        print("Proxy deactivated for Docker")


def main(argv):

    if argv[0] in ["up", "on", "1", "activate", "enable"]:
        activate()
        sys.exit(0)
    if argv[0] in ["down", "dn", "off", "0", "deactivate", "disable"]:
        deactivate()
        sys.exit(0)


if __name__ == "__main__":
    main(sys.argv[1:])
