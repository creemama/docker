#!/bin/sh

set -o errexit -o nounset
IFS="$(printf '\n\t')"
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC3040
	set -o pipefail
fi

# If using proxy_pass in default.conf, wait for the proxied server to be
# available before NGINX attempts to connect to it.
# Otherwise the following error might occur:
# 2019/08/20 23:39:32 [error] 11#11: *1 upstream timed out (110: Operation timed out) while connecting to upstream, client: 127.0.0.1, server: _, request: "GET / HTTP/1.1", upstream: "https://12.345.678.9:8443/", host: "localhost:8443"
#until wget --no-check-certificate -q --spider https://container-name:8443 > /dev/null 2>&1; do
#  sleep 1
#done

lazy-load-ocsp.sh &

exec openresty -g 'daemon off;'
