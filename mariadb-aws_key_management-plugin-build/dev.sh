#!/bin/sh

script_dir="$(
	cd "$(dirname "$0")"
	pwd -P
)"
cd "$script_dir"
# shellcheck source=shellutil/mainutil.sh
. shellutil/mainutil.sh
# shellcheck source=shellutil/shellutil.sh
. shellutil/shellutil.sh
# set -o xtrace

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
		./shellutil/format.sh docker-format
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		shift
		./shellutil/git.sh git "$@"
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		update
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

update() {
	# shellcheck disable=SC2039
	local image
	image=creemama/mariadb-aws_key_management-plugin-build:"10.4.7-bionic"
	# shellcheck disable=SC2039
	local latest_image
	latest_image=creemama/mariadb-aws_key_management-plugin-build:latest
	(
		cd docker
		docker build --tag "$image" .
	)
	docker run --name aws_key_management_build --rm "$image"
	docker push "$image"
	docker tag "$image" "$latest_image"
	docker push "$latest_image"
	docker rmi "$latest_image"
}

main "$@"
