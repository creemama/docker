#!/bin/sh

script_dir="$(
	cd "$(dirname "$0")"
	pwd -P
)"
cd "$script_dir"
if [ ! -f shellutil/shellutil.sh ]; then
	git submodule update --init
fi
# shellcheck source=shellutil/mainutil.sh
. shellutil/mainutil.sh
# shellcheck source=shellutil/shellutil.sh
. shellutil/shellutil.sh
# set -o xtrace

format() {
	mariadb-aws_key_management-plugin-build/dev.sh docker-format
	nginx-non-root/dev.sh docker-format
	node-no-yarn/dev.sh docker-format
}

main() {
	# shellcheck disable=SC2039
	local command_help
	command_help='docker-format - Format shell scripts and Markdown files.
git - Run git.
update - Run update in each subproject.'
	# shellcheck disable=SC2039
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		format
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		shift
		shellutil/git.sh git "$@"
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		update
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

update() {
	mariadb-aws_key_management-plugin-build/dev.sh update
	nginx-non-root/dev.sh update
	node-no-yarn/dev.sh update
}

main "$@"
