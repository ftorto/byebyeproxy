# byebyeproxy

Say "byebye" to corporate proxy by running this docker image

You don't have to waste your time configuring your laptop apps several times when you change the network with different proxy configuration

## Explanation

This image intercepts and redirects all host traffic to a local _transparent proxy_ (`redsocks`) using `iptables` rules.
`iptables` rules are setup inside docker image but due to `--privileged` flag, this acts on host computer.

The proxy will redirect intercepted trafic to the specified corporate proxy specified in configuration file.

## Limitations

You could brake `iptables` rules if container is killed.
You can try this command or reboot your computer:

```bash
docker run -it --net=host --privileged -d \
  -v ${HOME}/.byebyeproxy:/app/config \
  ftorto/byebyeproxy:latest stop
```

## Build the image

```bash
docker build . -t ftorto/byebyeproxy:latest
```

## Configuring

- fill in the file `${HOME}/.byebyeproxy/config.yml`

## Start byebyeproxy

- Edit `/etc/docker/daemon.json` to add specfic DNS and reload the configuration

```bash
sudo vi /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker
```

- Start byebyeproxy

```bash
docker run -it --net=host --privileged=true -d \
  -v ${HOME}/.byebyeproxy:/app/config \
  ftorto/byebyeproxy:latest
```

## Semi-automated usage

- `on.sh` and `off.sh` are 2 scripts that allow the activation/deactivation of byebyeproxy based on a configuration file containing proxy settings `~/.byebyeproxy.conf`.
- Use `INSTALL.sh` to create links and install configuration file and scripts
  - Have a look at it before to know what it's doing. I don't have handled all cases.
