#!/bin/sh

IFS=$(printf '\n\t')
set -o errexit -o nounset
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC2039
	set -o pipefail
fi
# set -o xtrace

# https://unix.stackexchange.com/a/598047
is_integer() {
	case "${1#[+-]}" in
	*[!0123456789]*) return 1 ;;
	'') return 1 ;;
	*) return 0 ;;
	esac
}

is_tty() {
	# "No value for $TERM and no -T specified"
	# https://askubuntu.com/questions/591937/no-value-for-term-and-no-t-specified
	tty -s >/dev/null 2>&1
}

local_tput() {
	if ! is_tty; then
		return 0
	fi
	if test_command_exists tput; then
		# $@ is unquoted.
		# shellcheck disable=SC2068
		tput $@
	fi
}

tbold() {
	local_tput bold
}

tcyan() {
	local_tput setaf 6
}

tgray() {
	local_tput setaf 7
}

tgreen() {
	local_tput setaf 2
}

tred() {
	local_tput setaf 1
}

treset() {
	local_tput sgr0
}

tyellow() {
	local_tput setaf 3
}

test_command_exists() {
	command -v "${1}" >/dev/null 2>&1
}
