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
# shellcheck source=../shellutil/updateutil.sh
. ../shellutil/updateutil.sh
# set -o xtrace

build() {
	local version
	version="$(head -n 1 docker/Dockerfile | sed -E "s#.*:(.*)#\1#")"
	docker pull --platform linux/amd64 "creemama/node-no-yarn:$version"
	docker build --no-cache --platform linux/amd64 --tag "creemama/shellutil-dev:$version-amd64" docker
	docker rmi "creemama/node-no-yarn:$version"
	docker pull --platform linux/arm64/v8 "creemama/node-no-yarn:$version"
	docker build --no-cache --platform linux/arm64/v8 --tag "creemama/shellutil-dev:$version-arm64" docker
	docker rmi "creemama/node-no-yarn:$version"
	docker images | grep shellutil-dev
}

main() {
	local command_help
	command_help='build - Build the creemama/shellutil-dev Docker image.
docker-format - Format shell scripts and Markdown files.
docker-update - Run update using a Docker container.
git - Run git.
push - Push creemama/shellutil-dev to Docker Hub.
update - Check for a newer version of nginx:stable-alpine and update this project if so.'
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		build
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		(
			# We go up one directory to give the Docker container access to shellutil.
			cd ..
			shellutil/format.sh docker-shell-format shellutil-dev
		)
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		run_docker_update
	elif [ "$1" = "$(arg 3 $commands)" ]; then
		shift
		../shellutil/git.sh git "$@"
	elif [ "$1" = "$(arg 4 $commands)" ]; then
		push
	elif [ "$1" = "$(arg 5 $commands)" ]; then
		update
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

push() {
	local version
	version="$(head -n 1 docker/Dockerfile | sed -E "s#.*:(.*)#\1#")"
	local image
	image="creemama/shellutil-dev:$version"
	local latest_image
	latest_image=creemama/shellutil-dev:lts-alpine
	docker push "$image-amd64"
	docker push "$image-arm64"
	docker manifest create "$image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest create "$latest_image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest push "$image"
	docker manifest push "$latest_image"
	docker rmi "$image-amd64"
	docker rmi "$image-arm64"
}

run_docker_update() {
	docker pull creemama/node-no-yarn:lts-alpine
	docker run -it --rm \
		--volume "$(pwd)/..":/tmp \
		--workdir /tmp/shellutil-dev \
		creemama/node-no-yarn:lts-alpine \
		sh -c './dev.sh update'
}

update() {
	apk_update_node_image_version docker/Dockerfile
	apk_update_package_version git docker/Dockerfile
	apk_update_package_version git-gitk docker/Dockerfile
	apk_update_package_version gnupg docker/Dockerfile
	apk_update_package_version ncurses docker/Dockerfile
	apk_update_package_version openssh docker/Dockerfile
	apk_update_package_version shellcheck docker/Dockerfile
	apk_update_package_version shfmt docker/Dockerfile
	apk_update_package_version terminus-font docker/Dockerfile
	npm_update_package_version prettier docker/Dockerfile

	# As a submodule, git status might not work in a Docker container mounted to this
	# script_dir.
	printf '%s%s\nRun git status.\n%s' "$(tbold)" "$(tyellow)" "$(treset)"
}

main "$@"
