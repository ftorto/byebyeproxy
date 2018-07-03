# byebyeproxy

Say "byebye" to corporate proxy by running this docker image

You don't have to waste your time configuring your laptop apps several times when you change the network with different proxy configuration

## Explanation

This image redirects all host traffic to a local *transparent proxy* (`redsocks`) using `iptables` rules.
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

```bash
docker run -it --net=host --privileged=true -d \
  -v noproxy.txt:/app/noproxy
  -e http_proxy=<corporate_proxy_url_with_port> \
  ftorto/byebyeproxy:latest
```
