FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    procps \
    vim \
    nginx \
    libnginx-mod-http-lua \
    ca-certificates \
    python3 \
    python3-jinja2 \
  && apt-get clean

RUN set -x \
  && unlink /etc/nginx/sites-enabled/default \
  && mkdir -p /etc/nginx/ssl

COPY kwanko-proxy.vhost.jinja2 /etc/nginx/kwanko-proxy.vhost.jinja2
COPY filter_kwanko_cookies_in_request.lua /etc/nginx/filter_kwanko_cookies_in_request.lua
COPY filter_kwanko_cookies_in_response.lua /etc/nginx/filter_kwanko_cookies_in_response.lua

COPY entrypoint.sh /usr/sbin/entrypoint.sh
RUN set -x \
  && chmod +x /usr/sbin/entrypoint.sh

WORKDIR /root/

EXPOSE 80/tcp
EXPOSE 443/tcp

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]
CMD ["start-service"]
