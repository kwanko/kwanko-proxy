#!/bin/bash
set -xo pipefail

readonly PYTHON_JINJA2="import os; import sys; import jinja2; sys.stdout.write(jinja2.Template(sys.stdin.read()).render(env=os.environ)+'\n')"

# if option is a command to execute
if [[ "$1" != "start-service" ]] ; then
  echo "executing command <$*>"
  exec "$@"
fi

function initialize() {
  python3 -c "${PYTHON_JINJA2}" > /etc/nginx/sites-enabled/kwanko-proxy < /etc/nginx/kwanko-proxy.vhost.jinja2 || { echo "templating error" ; exit 1 ; }
  nginx -t || { echo "invalid configuration" ; exit 1 ; }
}

if [[ "$1" == "start-service" ]] ; then
  if ! [[ -e '/.initialized' ]] ; then
    initialize
  fi
  if [[ "$?" != "0" ]] ; then
    echo "invalid configuration"
    exit 1
  fi
  echo ''
  echo '. starting Nginx with config:'
  cat /etc/nginx/sites-enabled/kwanko-proxy
  echo '-------------------------------'
  nginx -g 'daemon off;'
fi
