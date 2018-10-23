# byebyeproxy

Say "byebye" to corporate proxy by running this docker image

You don't have to waste your time configuring your laptop apps several times when you change the network with different proxy configuration

## Explanation

This image redirects all host traffic to a local _transparent proxy_ (`redsocks`) using `iptables` rules.
`iptables` rules are setup inside docker image but due to `--privileged` flag, this acts on host computer.

The proxy will redirect intercepted trafic to the specified corporate proxy in environment variable.

## Limitations

You could brake `iptables` rules if container is killed.
You can try this command or reboot your computer:

```bash
docker run -it --net=host --privileged -d \
  -v noproxy.txt:/app/noproxy \
  -e http_proxy=${http_proxy} \
  ftorto/byebyeproxy:latest stop
```

## Build the image

```bash
docker build . -t ftorto/byebyeproxy:latest
```

## Configuring

- Edit the noproxy file to add your exceptions
- Run the image with environment variables filled properly

## Start byebyeproxy

- Edit `/etc/docker/daemon.json` to add specfic DNS and reload the configuration

```bash
sudo vi /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker
```

- Start byebyeproxy

```bash
corporate_proxy_url_with_port=http://proxy.corp:3128
docker run -it --net=host --privileged=true -d \
  -v noproxy.txt:/app/noproxy \
  -e http_proxy=$corporate_proxy_url_with_port \
  -e https_proxy=$corporate_proxy_url_with_port \
  ftorto/byebyeproxy:latest
```

## Semi-automated usage

- `on.sh` and `off.sh` are 2 scripts that allow the activation/deactivation of byebyeproxy based on a configuration file containing proxy settings `~/.byebyeproxy.conf`.
- Use `INSTALL.sh` to create links and install configuration file and scripts
  - Have a look at it before to know what it's doing. I don't have handled all cases.
