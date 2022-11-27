#!/bin/sh

set -o errexit -o nounset
IFS="$(printf '\n\t')"
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC3040
	set -o pipefail
fi

# Use this script to try certbot-non-root renew --dry-run.

certbot \
	--config-dir \
	/home/certbot/config \
	--work-dir \
	/home/certbot/work \
	--logs-dir \
	/home/certbot/logs \
	"$@"
