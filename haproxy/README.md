# HaProxy configuration

## Requirements

* HaProxy minimal version 1.6 with LUA support.

## Deployment

The file [filter\_kwanko\_cookies.lua](./filter_kwanko_cookies.lua) should be added in `/etc/haproxy/` and the following HaProxy config needs to be integrated in your existing HaProxy config or template:

```
global
    lua-load /etc/haproxy/filter_kwanko_cookies.lua
[...]

frontend ft_kwanko_tracking
    bind <bind_address:port> ssl no-sslv3 crt <path_to_certificate_bundle> alpn h2,http/1.1 # if directly exposed or if using HTTPS between LB and proxy
    bind <bind_address:port> # if behind an SSL offloader
    default_backend bk_kwanko_tracking

backend bk_kwanko_tracking
    balance first
    http-request set-header X-Forwarded-Host %[req.hdr(host),field(1,:)]
    http-request set-header Host action.metaffiliation.com
    #http-request set-header X-Forwarded-For %[src] # uncomment if directly exposed or behind a L4 load balancer
    http-request lua.filter_kwanko_cookies
    http-response lua.filter_kwanko_set_cookies
    server kwanko action.metaffiliation.com:443 no-check no-check-ssl ssl sni str(action.metaffiliation.com) verify required verifyhost str(action.metaffiliation.com) ca-file /etc/ssl/certs/ca-certificates.crt # the location of the ca-certificates public CAs depends on the distribution
```

The cookie filtering is done in LUA by two custom actions defined in [filter\_kwanko\_cookies.lua](./filter_kwanko_cookies.lua):

* `lua.filter_kwanko_cookies`: filter cookies in the request.
* `lua.filter_kwanko_set_cookies`: filter cookies in the response.

These two actions send debug logs with cookie contents. Be sure that your HaProxy log directives specify at least `info` as the maximum log level if you do not want to log these infos.

The `ca-file` option should be adjusted to the system since the name and location of the ca-certificates public certificate authority file depend on the distribution:

* Debian/Ubuntu/Gentoo/etc...: `/etc/ssl/certs/ca-certificates.crt`
* Fedora/RHEL 6: `/etc/pki/tls/certs/ca-bundle.crt`
* CentOS/RHEL 7: `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem`
* OpenSUSE: `/etc/ssl/ca-bundle.pem`
* OpenELEC: `/etc/pki/tls/cacert.pem`
* Alpine Linux: `/etc/ssl/cert.pem`

## Docker

A Dockerfile is provided. However, it is not the recommended way to deploy the proxy since docker will impact HaProxy performance.

The docker instance exposes two ports:

* `80` for HTTP connections from an SSL offloader or an L7 load balancer taking care of the SSL part,
* `443` for HTTPS connections from a direct Internet user or from a load balancer using HTTPS even for internal communication.

The following environment variables can be used to adapt the instance:

* `KWANKO_PROXY_LOG` *(default: `127.0.0.1 local0 info`)*: by default, HaProxy logs to a local rsyslog on udp which writes in the `/var/log/haproxy/haproxy.log` file. This env var overwrites the content of the HaProxy global `log` line. This can be used to redirect HaProxy logs to an external logging system.
* `KWANKO_PROXY_SSL` *(default: `True`)*: setting this to `False` disables the HTTPS frontend in HaProxy config.
* `KWANKO_PROXY_OVERWRITE_X_FORWARDED_FOR` *(default: `False`)*: by default, it is expected that the `X-Forwarded-For` header is already set by an upstream load balancer. If the docker is directly exposed or behind an L4 load balancer, setting this var to `True` will tell HaProxy to overwrite the `X-Forwarded-For` header with the source address of the connection.

The following directory should be mounted outside the instance:

* `/var/log/haproxy`: this directory contains the HaProxy log file used in default config.
* `/etc/haproxy/ssl`: this directory can be mounted read-only and must contain the certificate bundle file (`kwanko-proxy.bundle.pem`) for the HTTPS frontend. The certificate bundle file is the concatenation of the key, the certificate and the certificate chain in PEM format.

For example, a typical docker run command could be:

```
docker run -p 0.0.0.0:80:80 \
  -e 'KWANKO_PROXY_SSL=False' \
  --mount 'type=bind,source=/var/log/kwanko-proxy,destination=/var/log/haproxy' \
  --name kwanko-proxy kwanko-proxy:haproxy-0.1
```

or 

```
docker run -p 0.0.0.0:443:443 \
  -e 'KWANKO_PROXY_LOG=10.10.10.10 local0 info' \
  -e 'KWANKO_PROXY_OVERWRITE_X_FORWARDED_FOR=True' \
  --mount 'type=bind,source=/etc/kwanko-proxy/ssl,destination=/etc/haproxy/ssl,ro' \
  --name kwanko-proxy kwanko-proxy:haproxy-0.1
```
