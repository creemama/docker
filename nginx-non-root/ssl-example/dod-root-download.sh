#!/bin/sh

set -o errexit -o nounset
IFS="$(printf '\n\t' '')"
if [ -n "${BASH_VERSION:-}" ]; then
  set -o pipefail
fi

main () {
  # See https://github.com/mpyne-navy/nginx-cac.
  # See https://github.com/mpyne-navy/nginx-cac/blob/master/Makefile.

  local root_certs="Certificates_PKCS7_v5.6_DoD"
  local root_certs_filename=$(printf "%s" ${root_certs} | tr A-Z. a-z- )

  # https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
  local script_dir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

  docker run \
    --rm \
    --volume "${script_dir}:/tmp/docker" \
    --workdir /tmp \
    alpine:3.10 \
    sh -c "\
      set -o xtrace && \
      apk add openssl && \
      wget \"https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/${root_certs_filename}.zip\" && \
      unzip -p \"${root_certs_filename}.zip\" \"${root_certs}/${root_certs}.pem.p7b\" | openssl pkcs7 -out \"docker/dod-roots.crt\" -print_certs"
}

main "$@"
