FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    procps \
    vim \
    haproxy \
    hatop \
    ca-certificates \
    rsyslog \
    python3 \
    python3-jinja2 \
  && apt-get clean

RUN set -x \
  && mkdir -p /etc/rsyslog.d /etc/haproxy/ssl

COPY rsyslog.conf /etc/rsyslog.d/rsyslog.conf

COPY haproxy.cfg.jinja2 /etc/haproxy/haproxy.cfg.jinja2
COPY filter_kwanko_cookies.lua /etc/haproxy/filter_kwanko_cookies.lua

COPY entrypoint.sh /usr/sbin/entrypoint.sh
RUN set -x \
  && chmod +x /usr/sbin/entrypoint.sh

WORKDIR /root/

EXPOSE 80/tcp
EXPOSE 443/tcp

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]
CMD ["start-service"]
