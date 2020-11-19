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
	printf '\n%s%sBuilding creemama/node-no-yarn:%s...%s\n\n' "$(output_bold)" "$(output_green)" "${docker_tag}" "$(output_reset)"
	docker build --no-cache --tag "creemama/node-no-yarn:${docker_tag}" .
	docker tag "creemama/node-no-yarn:${docker_tag}" creemama/node-no-yarn:lts-alpine
	cd ../..
	printf '\n%s%sTesting creemama/node-no-yarn:%s...%s\n' "$(output_bold)" "$(output_green)" "${docker_tag}" "$(output_reset)"
	docker run --rm creemama/node-no-yarn:lts-alpine -e "console.log(process.version)"
}

commit_to_git() {
	printf '\n%s%sCommitting to git...%s\n\n' "$(output_bold)" "$(output_green)" "$(output_reset)"
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

format() {
	docker run --rm \
		--volume "$(pwd):/tmp" \
		--workdir /tmp \
		node:lts-alpine \
		sh -c " \
		printf '%s' '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
		&& apk add shellcheck shfmt@edgecommunity \
		&& shfmt -w *.sh \
		&& npm install --global prettier@2.1.2 \
		&& prettier --write . \
		&& shellcheck *.sh"
}

# https://unix.stackexchange.com/a/598047
is_integer() {
	case "${1#[+-]}" in
	*[!0123456789]*) return 1 ;;
	'') return 1 ;;
	*) return 0 ;;
	esac
}

local_tput() {
	if ! test_is_tty; then
		return 0
	fi
	if test_command_exists 'tput'; then
		# $@ is unquoted.
		# shellcheck disable=SC2068
		tput $@
	fi
}

main() {
	if [ "${1:-}" = "format" ]; then
		format
		exit
	fi
	if [ "${1:-}" = "update" ]; then
		update
		exit
	fi
	print_help
}

output_bold() {
	local_tput bold
}

output_cyan() {
	local_tput setaf 6
}

output_gray() {
	local_tput setaf 7
}

output_green() {
	local_tput setaf 2
}

output_reset() {
	local_tput sgr0
}

print_help() {
	cat <<EOF

  $(output_bold)./dev.sh$(output_reset) <command>

  $(output_gray)Commands:
    $(output_gray)- Format shell scripts and Markdown files.
    $(output_cyan)$ ./dev.sh format

    $(output_gray)- Check for a newer version of node:lts-alpine and
      updates this project if so.
    $(output_cyan)$ ./dev.sh update
$(output_reset)

EOF
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

test_command_exists() {
	command -v "$1" >/dev/null 2>&1
}

test_is_tty() {
	# "No value for $TERM and no -T specified"
	# https://askubuntu.com/questions/591937/no-value-for-term-and-no-t-specified
	tty -s >/dev/null 2>&1
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
		printf '%s%s%s is the latest version. There is nothing to do.%s\n' "$(output_bold)" "$(output_green)" "${current_node_lts_alpine_version}" "$(output_reset)"
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

	printf '\n%s%sUpdating since %s != %s...%s\n' "$(output_bold)" "$(output_green)" "${current_node_lts_alpine_version}" "${latest_node_lts_alpine_version}" "$(output_reset)"
	remove_old_directories
	download_latest_dockerfile "${alpine_dir}" "${major_version}"
	remove_yarn_from_dockerfile "${alpine_dir}"
	printf '%s' "${latest_node_lts_alpine_version}" >VERSION
	build_node_no_yarn "${alpine_dir}" "${docker_tag}"
	update_readme "${alpine_dir}" "${docker_tag}"
	printf '\n%s%sFormatting the project...%s\n\n' "$(output_bold)" "$(output_green)" "$(output_reset)"
	./dev.sh format
	commit_to_git "${docker_tag}" "${latest_node_lts_alpine_version}"
	upload_docker_images "${docker_tag}"
	printf '\n%s%sRemember to update DockerHub README.%s\n\n' "$(output_bold)" "$(output_green)" "$(output_reset)"
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
	printf '\n%s%sUploading images to Docker...%s\n\n' "$(output_bold)" "$(output_green)" "$(output_reset)"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="${1}"
	docker push "creemama/node-no-yarn:${docker_tag}"
	docker push creemama/node-no-yarn:lts-alpine
}

main "$@"
