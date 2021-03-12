#!/bin/bash
set -xo pipefail

readonly PYTHON_JINJA2="import os; import sys; import jinja2; sys.stdout.write(jinja2.Template(sys.stdin.read()).render(env=os.environ)+'\n')"

# if option is a command to execute
if [[ "$1" != "start-service" ]] ; then
  echo "executing command <$*>"
  exec "$@"
fi

function initialize() {
  mkdir -vp /run/haproxy /var/log/haproxy
  ln -svf /var/log/haproxy/haproxy.log /var/log/haproxy.log
  python3 -c "${PYTHON_JINJA2}" > /etc/haproxy/haproxy.cfg < /etc/haproxy/haproxy.cfg.jinja2 || { echo "templating error" ; exit 1 ; }
  haproxy -c -f /etc/haproxy/haproxy.cfg || { echo "invalid configuration" ; exit 1 ; }
}

if [[ "$1" == "start-service" ]] ; then
  if ! [[ -e '/.initialized' ]] ; then
    initialize
  fi
  if [[ -z "${KWANKO_PROXY_LOG}" ]] || [[ "${KWANKO_PROXY_LOG}" == +(127.0.0.1|/dev/log)* ]] ; then
    rm -vf /run/rsyslogd.pid
    rsyslogd || { echo "fail to start rsyslog" ; exit 1 ; }
  fi
  echo ''
  echo '. starting HaProxy with config:'
  cat /etc/haproxy/haproxy.cfg
  echo '-------------------------------'
  /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -q -db
fi
