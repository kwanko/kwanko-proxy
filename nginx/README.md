# Nginx configuration

## Requirements

* Nginx minimal version 1.10 with lua support (it should also work from Nginx 1.7 but it has not been tested)

## Deployment

The files [filter\_kwanko\_cookies\_in\_request.lua](./filter_kwanko_cookies_in_request.lua) and [filter\_kwanko\_cookies\_in\_response.lua](./filter_kwanko_cookies_in_response.lua) should be added in `/etc/nginx/` and the following Nginx vhost needs to be enabled:

```
server {
  listen 80; # if behind an SSL offloader
  listen 443 ssl; # if directly exposed or if using HTTPS between LB and proxy
  server_name <first-party.client-domain.tld>;

  access_log /var/log/nginx/kwanko-proxy.access.log combined;
  error_log /var/log/nginx/kwanko-proxy.error.log;

  ssl_certificate "/etc/nginx/ssl/kwanko-proxy.crt.pem";
  ssl_certificate_key "/etc/nginx/ssl/kwanko-proxy.key.pem";

  root /var/www;

  access_by_lua_file /etc/nginx/filter_kwanko_cookies_in_request.lua;
  header_filter_by_lua_file /etc/nginx/filter_kwanko_cookies_in_response.lua;

  location / {
    proxy_ssl_server_name on;
    proxy_ssl_name action.metaffiliation.com;
    proxy_ssl_verify on;
    proxy_ssl_verify_depth 3;
    proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt; # the location of the ca-certificates public CAs depends on the distribution
    proxy_set_header X-Forwarded-Host $host;
    #proxy_set_header X-Forwarded-For $remote_addr; # uncomment if directly exposed or behind a L4 load balancer
    proxy_set_header Host action.metaffiliation.com;
    proxy_pass https://action.metaffiliation.com/;
  }
}
```

The cookie filtering is done by two LUA scripts:

* [filter\_kwanko\_cookies\_in\_request.lua](./filter_kwanko_cookies_in_request.lua): filter cookies in the request.
* [filter\_kwanko\_cookies\_in\_response.lua](./filter_kwanko_cookies_in_response.lua): filter cookies in the response.

The `proxy_ssl_trusted_certificate` directive should be adjusted to the system since the name and location of the ca-certificates public certificate authority file depend on the distribution:

* Debian/Ubuntu/Gentoo/etc...: `/etc/ssl/certs/ca-certificates.crt`
* Fedora/RHEL 6: `/etc/pki/tls/certs/ca-bundle.crt`
* CentOS/RHEL 7: `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem`
* OpenSUSE: `/etc/ssl/ca-bundle.pem`
* OpenELEC: `/etc/pki/tls/cacert.pem`
* Alpine Linux: `/etc/ssl/cert.pem`

## Docker

A Dockerfile is also provided. However, it is not the recommended way to deploy the proxy since docker can impact Nginx performance.

The docker instance exposes two ports:

* `80` for HTTP connections from an SSL offloader or an L7 load balancer taking care of the SSL part,
* `443` for HTTPS connections from a direct Internet user or from a load balancer using HTTPS even for internal communication.

The following environment variables can be used to adapt the instance:

* `KWANKO_PROXY_SSL` *(default: `True`)*: setting this to `False` disables the HTTPS config in Nginx vhost.
* `KWANKO_PROXY_OVERWRITE_X_FORWARDED_FOR` *(default: `False`)*: by default, it is expected that the `X-Forwarded-For` header is already set by an upstream load balancer. If the docker is directly exposed or behind an L4 load balancer, setting this var to `True` will tell Nginx to overwrite the `X-Forwarded-For` header with the source address of the connection.

The following directory should be mounted outside the instance:

* `/var/log/nginx`: this directory contains the Nginx log files used in default config.
* `/etc/nginx/ssl`: this directory can be mounted read-only and must contain the certificate (`kwanko-proxy.crt.pem`) and key (`kwanko-proxy.key.pem`) for the HTTPS vhost.

For example, a typical docker run command could be:

```
docker run -p 0.0.0.0:80:80 \
  -e 'KWANKO_PROXY_SSL=False' \
  --mount 'type=bind,source=/var/log/kwanko-proxy,destination=/var/log/nginx' \
  --name kwanko-proxy kwanko-proxy:nginx-0.1
```

or 

```
docker run -p 0.0.0.0:443:443 \
  -e 'KWANKO_PROXY_OVERWRITE_X_FORWARDED_FOR=True' \
  --mount 'type=bind,source=/etc/kwanko-proxy/ssl,destination=/etc/nginx/ssl,ro' \
  --name kwanko-proxy kwanko-proxy:nginx-0.1
```
