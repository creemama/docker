#!/bin/sh

set -o errexit -o nounset
IFS="$(printf '\n\t' '')"
if [ -n "${BASH_VERSION:-}" ]; then
	set -o pipefail
fi

main() {
	docker run --rm \
		--volume "$(pwd):/tmp" \
		--workdir /tmp \
		node:lts-alpine \
		sh -c "printf '%s' '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories && apk add shellcheck shfmt@edgecommunity && shfmt -w *.sh && npm install --global prettier@2.1.2 && prettier --write . && shellcheck *.sh"
}

main "$@"
