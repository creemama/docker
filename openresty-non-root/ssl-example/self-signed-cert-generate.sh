#!/bin/sh

set -o errexit -o nounset
IFS="$(printf '\n\t')"
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC3040
	set -o pipefail
fi

main() {
	if [ -z "${1-}" ] || [ -z "${2-}" ]; then
		print_help
		exit
	fi

	local script_dir
	script_dir="$(
		cd "$(dirname "$0")"
		pwd -P
	)"

	# shellcheck disable=SC1004
	docker run \
		--rm \
		--user root \
		--volume "$script_dir":/tmp \
		--workdir /tmp \
		creemama/nginx-non-root:stable-alpine \
		sh -c '
			set -o xtrace &&
			apk add openssl &&
			openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
				-keyout self-signed.key -out self-signed.crt -subj "/CN='"$1"'" \
				-addext "subjectAltName='"$2"'"'
}

print_help() {
	cat <<EOF

Usage: $(basename "$0") CN subjectAltName

Generate a self-signed certificate with the specified common name and subject
alternative name(s).

Example: $(basename "$0") example.com 'DNS:example.com,DNS:example.net,IP:10.0.0.1'

See https://stackoverflow.com/a/41366949.

EOF
}

main "$@"
