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

main() {
	local command_help
	command_help='docker-format - Format shell scripts and Markdown files.
git - Run git.
update - Create Docker images.'
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		(
			# We go up one directory to give the Docker container access to shellutil.
			cd ..
			shellutil/format.sh docker-shell-format mariadb
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

update() {
	local commit
	commit=97200971ae9d24a700acc65055eaf9edc4df91f1
	local image
	image=creemama/mariadb:10.11.2-focal
	local latest_image
	latest_image=creemama/mariadb:latest
	local ubuntu_codename
	ubuntu_codename=focal
	local version
	version=10.11

	mkdir -p docker
	curl "https://raw.githubusercontent.com/MariaDB/mariadb-docker/$commit/$version/Dockerfile" -o docker/Dockerfile
	curl "https://raw.githubusercontent.com/MariaDB/mariadb-docker/$commit/$version/docker-entrypoint.sh" -o docker/docker-entrypoint.sh
	curl "https://raw.githubusercontent.com/MariaDB/mariadb-docker/$commit/$version/healthcheck.sh" -o docker/healthcheck.sh
	chmod +x docker/docker-entrypoint.sh
	chmod +x docker/healthcheck.sh
	sed -E -i '' 's#jammy#focal#' docker/Dockerfile
	sed -E -i '' 's#ubu2204#ubu2004#' docker/Dockerfile

	cd docker
	docker pull --platform linux/amd64 "ubuntu:$ubuntu_codename"
	docker build --no-cache --platform linux/amd64 --tag "$image-amd64" .
	docker rmi "ubuntu:$ubuntu_codename"
	docker pull --platform linux/arm64/v8 "ubuntu:$ubuntu_codename"
	docker build --no-cache --platform linux/arm64/v8 --tag "$image-arm64" .
	docker push "$image-amd64"
	docker push "$image-arm64"
	docker manifest create "$image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest create "$latest_image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest push "$image"
	docker manifest push "$latest_image"
	docker rmi "$image-amd64"
	docker rmi "$image-arm64"
	cd ..

	rm -rf docker

	printf '\n%s%sRemember to delete architecture-specific images.%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
}

main "$@"
