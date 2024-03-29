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
update - Check for a newer version of mariadb:latest and update this project if so.'
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		(
			# We go up one directory to give the Docker container access to shellutil.
			cd ..
			shellutil/format.sh docker-shell-format mariadb-aws_key_management-plugin-base
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
	local tag
	tag=latest
	docker pull --quiet "creemama/mariadb-aws_key_management-plugin-build:$tag" >/dev/null 2>&1

	local current_image_version
	current_image_version="$(cat VERSION)"
	local ubuntu_codename
	# https://linuxize.com/post/how-to-check-your-ubuntu-version/
	ubuntu_codename="$(docker run --rm creemama/mariadb-aws_key_management-plugin-build:$tag sh -c \
		"grep UBUNTU_CODENAME= </etc/os-release | sed 's/UBUNTU_CODENAME=//'")"

	local mariadb_version
	mariadb_version="$(docker run --rm creemama/mariadb-aws_key_management-plugin-build:$tag bash -c \
		"cd /usr/local/src/server && source VERSION && printf '%s.%s.%s' \"\$MYSQL_VERSION_MAJOR\" \"\$MYSQL_VERSION_MINOR\" \"\$MYSQL_VERSION_PATCH\"")"
	local latest_image_version
	latest_image_version="$mariadb_version"-"$ubuntu_codename"
	local image
	image=creemama/mariadb-aws_key_management-plugin-base:"$latest_image_version"
	local latest_image
	latest_image=creemama/mariadb-aws_key_management-plugin-base:latest
	local git_tag
	git_tag=mariadb-aws_key_management-plugin-base-$latest_image_version

	if [ "$current_image_version" = "$latest_image_version" ]; then
		printf '%s%s%s is the latest version. There is nothing to do.%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$(treset)"
		exit
	fi
	printf '\n%s%sUpdating since %s != %s...%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$latest_image_version" "$(treset)"

	printf 'Would you like to update? Press enter to continue or Ctrl+C to exit...\n'
	read -r ans

	sed -E -i "" \
		's/build:[0-9]+\.[0-9]+\.[0-9]+/build:'"$mariadb_version"'/' \
		docker/Dockerfile
	printf %s "$latest_image_version" >VERSION

	printf '\n%s%sFormatting the project...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	./dev.sh docker-format

	printf 'Would you like to build? Press enter to continue or Ctrl+C to exit...\n'
	read -r ans

	printf '\n%s%sBuilding %s...%s\n\n' "$(tbold)" "$(tgreen)" "$image" "$(treset)"
	(
		cd docker
		docker pull --platform linux/amd64 creemama/mariadb-aws_key_management-plugin-build:"$latest_image_version"
		docker build --no-cache --platform linux/amd64 --tag "$image-amd64" .
		docker rmi creemama/mariadb-aws_key_management-plugin-build:"$latest_image_version"
		docker pull --platform linux/arm64/v8 creemama/mariadb-aws_key_management-plugin-build:"$latest_image_version"
		docker build --no-cache --platform linux/arm64/v8 --tag "$image-arm64" .
	)

	printf 'Would you like to commit to Git? Press enter to continue or Ctrl+C to exit...\n'
	read -r ans

	printf '\n%s%sCommitting to git...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	GPG_TTY=$(tty)
	export GPG_TTY
	git add -A
	git commit -m "Bump the version of mariadb-aws_key_management-plugin-base to $latest_image_version" -S
	git tag "$git_tag"
	git push origin master
	git push origin "$git_tag"

	printf 'Would you like to upload to Docker Hub? Press enter to continue or Ctrl+C to exit...\n'
	# shellcheck disable=SC2034
	read -r ans

	printf '\n%s%sUploading images to Docker...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
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
