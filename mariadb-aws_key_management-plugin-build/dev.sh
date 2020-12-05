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
	# shellcheck disable=SC2039
	local command_help
	command_help='docker-format - Format shell scripts and Markdown files.
git - Run git.
update - Check for a newer version of mariadb:latest and update this project if so.'
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
			shellutil/format.sh docker-format mariadb-aws_key_management-plugin-build
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
	docker pull --quiet mariadb:latest >/dev/null 2>&1

	# shellcheck disable=SC2039
	local current_image_version
	current_image_version="$(cat VERSION)"
	# shellcheck disable=SC2039
	local ubuntu_codename
	# https://linuxize.com/post/how-to-check-your-ubuntu-version/
	ubuntu_codename="$(docker run --rm mariadb:latest sh -c \
		"grep UBUNTU_CODENAME= </etc/os-release | sed 's/UBUNTU_CODENAME=//'")"
	# shellcheck disable=SC2039
	local mariadb_version
	mariadb_version="$(docker run --rm mariadb:latest sh -c \
		"mariadb --version | sed -E 's/^.*Distrib ([^-]+).*/\1/'")"
	# shellcheck disable=SC2039
	local latest_image_version
	latest_image_version="$mariadb_version"-"$ubuntu_codename"
	# shellcheck disable=SC2039
	local image
	image=creemama/mariadb-aws_key_management-plugin-build:"$latest_image_version"
	# shellcheck disable=SC2039
	local latest_image
	latest_image=creemama/mariadb-aws_key_management-plugin-build:latest
	# shellcheck disable=SC2039
	local git_tag
	git_tag=mariadb-aws_key_management-plugin-build-$latest_image_version

	if [ "$current_image_version" = "$latest_image_version" ]; then
		printf '%s%s%s is the latest version. There is nothing to do.%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$(treset)"
		exit
	fi
	printf '\n%s%sUpdating since %s != %s...%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$latest_image_version" "$(treset)"

	sed -E -i "" \
		's/^FROM ubuntu:.*$/FROM ubuntu:'"$ubuntu_codename"'/;s/ [a-z]+-security/ '"$ubuntu_codename"'-security/;s/mariadb-[0-9]+\.[0-9]+\.[0-9]+/mariadb-'"$mariadb_version"'/' \
		docker/Dockerfile
	# shellcheck disable=SC2016
	sed -E -i "" \
		's/`[0-9]+\.[0-9]+\.[0-9]+-[^`]+`/`'"$latest_image_version"'`/' \
		README.md
	printf %s "$latest_image_version" >VERSION

	printf '\n%s%sFormatting the project...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	./dev.sh docker-format

	printf '\n%s%sBuilding %s...%s\n\n' "$(tbold)" "$(tgreen)" "$image" "$(treset)"
	docker pull ubuntu:"$ubuntu_codename"
	(
		cd docker
		docker build --no-cache --tag "$image" .
	)
	docker run --name aws_key_management_build --rm "$image"

	printf '\n%s%sCommitting to git...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	GPG_TTY=$(tty)
	export GPG_TTY
	git add -A
	git commit -m "Bump the version of mariadb-aws_key_management-plugin-build to $latest_image_version" -S
	git tag "$git_tag"
	git push origin master
	git push origin "$git_tag"

	printf '\n%s%sUploading images to Docker...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	docker push "$image"
	docker tag "$image" "$latest_image"
	docker push "$latest_image"
	docker rmi "$latest_image"

	printf '\n%s%sRemember to update DockerHub README.%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
}

main "$@"
