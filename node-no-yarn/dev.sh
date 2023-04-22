#!/bin/sh

script_dir="$(
	cd "$(dirname "$0")"
	pwd -P
)"
cd "$script_dir"
if [ ! -f ../shellutil/shellutil.sh ]; then
	git submodule update --init
fi
# shellcheck source=../shellutil/mainutil.sh
. ../shellutil/mainutil.sh
# shellcheck source=../shellutil/shellutil.sh
. ../shellutil/shellutil.sh
# set -o xtrace

build_node_no_yarn() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="$1"
	# shellcheck disable=SC2039
	local alpine_version
	alpine_version="$2"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="$3"
	cd "$alpine_dir"
	printf '\n%s%sBuilding creemama/node-no-yarn:%s...%s\n\n' "$(tbold)" "$(tgreen)" "$docker_tag" "$(treset)"
	docker pull --platform linux/amd64 alpine:"$alpine_version"
	docker build --no-cache --platform linux/amd64 --tag "creemama/node-no-yarn:$docker_tag-amd64" .
	docker rmi alpine:"$alpine_version"
	docker pull --platform linux/arm64/v8 alpine:"$alpine_version"
	docker build --no-cache --platform linux/arm64/v8 --tag "creemama/node-no-yarn:$docker_tag-arm64" .
	docker rmi alpine:"$alpine_version"
	cd ../..
	printf '\n%s%sTesting creemama/node-no-yarn:%s...%s\n' "$(tbold)" "$(tgreen)" "$docker_tag" "$(treset)"
	docker run --platform linux/amd64 --rm "creemama/node-no-yarn:$docker_tag-amd64" -e 'console.log(process.version)'
	docker run --platform linux/arm64/v8 --rm "creemama/node-no-yarn:$docker_tag-arm64" -e 'console.log(process.version)'
}

commit_to_git() {
	printf '\n%s%sCommitting to git...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="$1"
	# shellcheck disable=SC2039
	local latest_node_lts_alpine_version
	latest_node_lts_alpine_version="$2"
	GPG_TTY=$(tty)
	export GPG_TTY
	git add -A
	git commit -m "Bump the version of node-no-yarn to $latest_node_lts_alpine_version" -S
	git tag "node-no-yarn-$docker_tag"
	git push origin master
	git push origin "node-no-yarn-$docker_tag"
}

download_latest_dockerfile() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="$1"
	# shellcheck disable=SC2039
	local major_version
	major_version="$2"
	rm -rf target
	mkdir target
	cd target
	curl --location --remote-name --silent https://github.com/nodejs/docker-node/archive/refs/heads/main.zip
	unzip -q main.zip
	cd ..
	mkdir -p "$major_version"
	cp -r "target/docker-node-main/$alpine_dir" "$major_version"
	rm -rf target
}

main() {
	# shellcheck disable=SC2039
	local command_help
	command_help='docker-format - Format shell scripts and Markdown files.
git - Run git.
update - Check for a newer version of node:lts-alpine and update this project if so.'
	# shellcheck disable=SC2039
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		(
			# We go up one directory to give the Docker container access to shellutil.
			cd ..
			shellutil/format.sh docker-format node-no-yarn
		)
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		shift
		../shellutil/git.sh git "$@"
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		update
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

remove_old_directories() {
	for dir in */; do
		# shellcheck disable=SC2039
		local dir_without_forward_slash
		dir_without_forward_slash="$(printf %s "$dir" | cut -c1-$((${#dir} - 1)))"
		if is_integer "$dir_without_forward_slash"; then
			rm -rf "$dir_without_forward_slash"
		fi
	done
}

remove_yarn_from_dockerfile() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="$1"
	# Remove the extra new line at the end of the file with sed '$ d'. See
	# https://stackoverflow.com/a/4881990.
	cp "$alpine_dir/Dockerfile" "$alpine_dir/Dockerfile.bak"
	tr '\n' '\r' <"$alpine_dir/Dockerfile.bak" |
		sed -E 's/ENV YARN_VERSION.*  && yarn --version..//g' |
		tr '\r' '\n' |
		sed '$ d' >"$alpine_dir/Dockerfile"
	rm "$alpine_dir/Dockerfile.bak"
}

update() {
	# Pull the latest node:lts-alpine.
	docker pull --quiet node:lts-alpine >/dev/null 2>&1

	# shellcheck disable=SC2039
	local current_node_lts_alpine_version
	current_node_lts_alpine_version="$(cat VERSION)"
	# shellcheck disable=SC2039
	local latest_node_lts_alpine_version
	latest_node_lts_alpine_version="$(docker run --rm node:lts-alpine node --version)"

	if [ "$current_node_lts_alpine_version" = "$latest_node_lts_alpine_version" ]; then
		printf '%s%s%s is the latest version. There is nothing to do.%s\n' "$(tbold)" "$(tgreen)" "$current_node_lts_alpine_version" "$(treset)"
		exit
	fi

	# shellcheck disable=SC2039
	local major_version
	major_version="$(printf %s "$latest_node_lts_alpine_version" | sed -E 's/v|\.[0-9]+//g')"
	# shellcheck disable=SC2039
	local alpine_version
	alpine_version="$(docker run --rm node:lts-alpine sh -c 'cat /etc/os-release | grep VERSION_ID | sed -E "s/VERSION_ID=|(\.[0-9]+$)//g"')"
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="$major_version/alpine$alpine_version"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="$(printf %s "$latest_node_lts_alpine_version" | sed -E 's/v//g')-alpine$alpine_version"

	printf '\n%s%sUpdating since %s != %s...%s\n' "$(tbold)" "$(tgreen)" "$current_node_lts_alpine_version" "$latest_node_lts_alpine_version" "$(treset)"
	remove_old_directories
	download_latest_dockerfile "$alpine_dir" "$major_version"
	remove_yarn_from_dockerfile "$alpine_dir"
	printf '%s' "$latest_node_lts_alpine_version" >VERSION
	build_node_no_yarn "$alpine_dir" "$alpine_version" "$docker_tag"
	update_readme "$alpine_dir" "$docker_tag"
	printf '\n%s%sFormatting the project...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	./dev.sh docker-format
	commit_to_git "$docker_tag" "$latest_node_lts_alpine_version"
	upload_docker_images "$docker_tag"
	printf '\n%s%sRemember to update DockerHub README and delete architecture-specific images.%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
}

update_readme() {
	# shellcheck disable=SC2039
	local alpine_dir
	alpine_dir="$1"
	# shellcheck disable=SC2039
	local docker_tag
	docker_tag="$2"
	# shellcheck disable=SC2039
	local node_no_yarn_size
	node_no_yarn_size=$(docker images | grep -E "^creemama/node-no-yarn\s+$docker_tag-arm64" | awk '{ print $NF }')
	# shellcheck disable=SC2039
	local node_size
	node_size=$(docker images | grep -E '^node\s+lts-alpine' | awk '{ print $NF }')

	rm -f README.md
	tr '\n' '\r' <README.template.md |
		sed "s/{{tag}}/$docker_tag/g;s#{{dir}}#$alpine_dir#g;s/{{node-no-yarn-size}}/$node_no_yarn_size/g;s/{{node-size}}/$node_size/g" |
		tr '\r' '\n' |
		sed '$ d' >README.md
}

upload_docker_images() {
	printf '\n%s%sUploading images to Docker...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	local docker_tag
	docker_tag="$1"
	local image
	image="creemama/node-no-yarn:$docker_tag"
	local latest_image
	latest_image=creemama/node-no-yarn:lts-alpine
	docker push "$image-amd64"
	docker push "$image-arm64"
	docker manifest create "$image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest create "$latest_image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest push "$image"
	docker manifest push "$latest_image"
	docker rmi "$image-amd64"
	docker rmi "$image-arm64"
}

main "$@"
