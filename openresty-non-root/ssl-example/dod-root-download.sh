#!/bin/sh

set -o errexit -o nounset
IFS="$(printf '\n\t')"
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC3040
	set -o pipefail
fi

main() {
	# See https://github.com/mpyne-navy/nginx-cac.
	# See https://github.com/mpyne-navy/nginx-cac/blob/master/Makefile.

	local root_certs
	root_certs=Certificates_PKCS7_v5.9_DoD

	local root_certs_filename
	root_certs_filename=certificates_pkcs7_DoD.zip

	local script_dir
	script_dir="$(
		cd "$(dirname "$0")" >/dev/null 2>&1
		pwd -P
	)"

	docker run \
		--rm \
		--user root \
		--volume "$script_dir":/tmp/docker \
		--workdir /tmp \
		creemama/openresty-non-root:alpine \
		sh -c '
			set -o xtrace &&
			apk add openssl &&
			wget "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/'"$root_certs_filename"'" &&
			unzip -p "'"$root_certs_filename"'" "'"$root_certs/$root_certs"'.pem.p7b" | openssl pkcs7 -out "docker/dod-roots.crt" -print_certs'
}

main "$@"
