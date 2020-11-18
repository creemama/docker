#!/bin/sh

IFS=$(printf '\n\t')
set -o errexit -o nounset
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC2039
	set -o pipefail
fi
# set -o xtrace

build_node_no_yarn() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="${1}"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="${2}"
	cd "${alpine_dir}"
	docker build --no-cache --tag "creemama/node-no-yarn:${docker_tag}" .
	docker tag "creemama/node-no-yarn:${docker_tag}" creemama/node-no-yarn:lts-alpine
	cd ../..
	printf '\nTest Docker image: '
	docker run --rm creemama/node-no-yarn:lts-alpine -e "console.log(process.version)"
	printf '\n'
}

commit_to_git() {
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="${1}"
	# shellcheck disable=SC2039
	local latest_node_lts_alpine_version
	latest_node_lts_alpine_version="${2}"
	GPG_TTY=$(tty)
	export GPG_TTY
	git add -A
	git commit -m "Bump the version of node-no-yarn to ${latest_node_lts_alpine_version}"
	git tag "node-no-yarn-${docker_tag}"
	git push origin master
	git push origin "node-no-yarn-${docker_tag}"
}

download_latest_dockerfile() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="${1}"
	# shellcheck disable=SC2039
	local major_version
	major_version="${2}"
	rm -rf target
	mkdir target
	cd target
	curl --location --remote-name --silent https://github.com/nodejs/docker-node/archive/master.zip
	unzip -q master.zip
	cd ..
	mkdir -p "${major_version}"
	cp -r "target/docker-node-master/${alpine_dir}" "${major_version}"
	rm -rf target
}

# https://unix.stackexchange.com/a/598047
is_integer() {
	case "${1#[+-]}" in
	*[!0123456789]*) return 1 ;;
	'') return 1 ;;
	*) return 0 ;;
	esac
}

main() {
	update
}

remove_old_directories() {
	for dir in */; do
		# shellcheck disable=SC2039
		local dir_without_forward_slash
		dir_without_forward_slash="$(printf '%s' "${dir}" | cut -c1-$((${#dir} - 1)))"
		if is_integer "${dir_without_forward_slash}"; then
			rm -rf "${dir_without_forward_slash}"
		fi
	done
}

remove_yarn_from_dockerfile() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="${1}"
	# Remove the extra new line at the end of the file with sed '$ d'. See
	# https://stackoverflow.com/a/4881990.
	cp "${alpine_dir}/Dockerfile" "${alpine_dir}/Dockerfile.bak"
	tr '\n' '\r' <"${alpine_dir}/Dockerfile.bak" |
		sed -E 's/ENV YARN_VERSION.*  && yarn --version..//g' |
		tr '\r' '\n' |
		sed '$ d' >"${alpine_dir}/Dockerfile"
	rm "${alpine_dir}/Dockerfile.bak"
}

update() {
	# shellcheck disable=SC2039
	local script_dir
	script_dir="$(
		cd "$(dirname "$0")"
		pwd -P
	)"
	cd "${script_dir}"

	# Pull the latest node:lts-alpine.
	docker pull --quiet node:lts-alpine >/dev/null 2>&1

	# shellcheck disable=SC2039
	local current_node_lts_alpine_version
	current_node_lts_alpine_version="$(cat VERSION)"
	# shellcheck disable=SC2039
	local latest_node_lts_alpine_version
	latest_node_lts_alpine_version="$(docker run --rm node:lts-alpine node --version)"

	if [ "${current_node_lts_alpine_version}" = "${latest_node_lts_alpine_version}" ]; then
		printf '%s is the latest version. There is nothing to do.\n' "${current_node_lts_alpine_version}"
		exit
	fi

	# shellcheck disable=SC2039
	local major_version
	major_version=$(printf '%s' "${latest_node_lts_alpine_version}" | sed -E "s/v|\.[0-9]+//g")
	# shellcheck disable=SC2039
	local alpine_version
	alpine_version=$(docker run --rm node:lts-alpine sh -c "cat /etc/os-release | grep VERSION_ID | sed -E \"s/VERSION_ID=|(\.[0-9]+$)//g\"")
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="${major_version}/alpine${alpine_version}"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="$(printf '%s' "${latest_node_lts_alpine_version}" | sed -E "s/v//g")-alpine${alpine_version}"

	printf 'Updating since %s != %s...\n' "${current_node_lts_alpine_version}" "${latest_node_lts_alpine_version}"
	remove_old_directories
	download_latest_dockerfile "${alpine_dir}" "${major_version}"
	remove_yarn_from_dockerfile "${alpine_dir}"
	printf '%s' "${latest_node_lts_alpine_version}" >VERSION
	build_node_no_yarn "${alpine_dir}" "${docker_tag}"
	update_readme "${alpine_dir}" "${docker_tag}"
	./format.sh || true
	commit_to_git "${docker_tag}" "${latest_node_lts_alpine_version}"
	upload_docker_images "${docker_tag}"
	printf '\nUpdate DockerHub README.\n\n'
}

update_readme() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="${1}"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="${2}"
	# shellcheck disable=SC2039
	local node_no_yarn_size
	node_no_yarn_size=$(docker images | grep -E "^creemama/node-no-yarn\s+${docker_tag}" | awk '{ print $NF }')
	# shellcheck disable=SC2039
	local node_size
	node_size=$(docker images | grep -E "^node\s+lts-alpine" | awk '{ print $NF }')

	rm -f README.md
	tr '\n' '\r' <README.template.md |
		sed "s/{{tag}}/${docker_tag}/g;s#{{dir}}#${alpine_dir}#g;s/{{node-no-yarn-size}}/${node_no_yarn_size}/g;s/{{node-size}}/${node_size}/g" |
		tr '\r' '\n' |
		sed '$ d' >README.md
}

upload_docker_images() {
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="${1}"
	docker push "creemama/node-no-yarn:${docker_tag}"
	docker push creemama/node-no-yarn:lts-alpine
}

main "$@"
