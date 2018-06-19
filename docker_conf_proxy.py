#!/bin/python3

import json

from os.path import expanduser
home = expanduser("~")

PROXY_CONFIG = {
    "default": {
        "httpProxy": "http://127.0.0.1:3128",
        "httpsProxy": "http://127.0.0.1:3128",
    }
}

docker_config = {}
with open("%s/.docker/config.json" % home) as f:
    docker_config = json.load(f)
    if "proxies" in docker_config:
        print ("Disable proxy")
        del docker_config["proxies"]
    else:
        print ("Enable proxy")
        docker_config["proxies"] = PROXY_CONFIG

with open("%s/.docker/config.json" % home, 'w') as f:
    json.dump(docker_config, f, indent=4, sort_keys=True)
    print("Configuration written")
