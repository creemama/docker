#!/bin/sh

# See "Priming the OCSP cache in Nginx": https://unmitigatedrisk.com/?p=241.
# Test with Firefox. If Firefox is the first to connect, the connection fails.

set -o errexit -o nounset
IFS="$(printf '\n\t' '')"
if [ -n "${BASH_VERSION:-}" ]; then
  set -o pipefail
fi

sleep 1s
wget --no-check-certificate -q --spider https://localhost:8443
