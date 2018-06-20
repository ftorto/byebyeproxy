#!/usr/bin/python3

import sys
import json

from os.path import expanduser
home = expanduser("~")

PROXY_CONFIG = {
    "default": {
        "httpProxy": "http://127.0.0.1:3128",
        "httpsProxy": "http://127.0.0.1:3128",
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


def toggle():
    docker_config = {}
    with open("%s/.docker/config.json" % home) as f:
        docker_config = json.load(f)
        if "proxies" in docker_config:
            del docker_config["proxies"]
            print("Proxy deactivated for Docker")
        else:
            docker_config["proxies"] = PROXY_CONFIG
            print("Proxy activated for Docker")

    with open("%s/.docker/config.json" % home, 'w') as f:
        json.dump(docker_config, f, indent=4, sort_keys=True)


def main(argv):

    if argv[0] in ["up", "on", "1"]:
        activate()
        sys.exit(0)
    if argv[0] in ["down", "dn", "off", "0"]:
        deactivate()
        sys.exit(0)
    if argv[0] in ["tog", "toggle"]:
        toggle()
        sys.exit(0)


if __name__ == "__main__":
   main(sys.argv[1:])
