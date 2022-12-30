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
update - Check for a newer version of openresty/openresty:alpine and update this project if so.'
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
			shellutil/format.sh docker-format openresty-non-root
			shellutil/format.sh docker-shell-format openresty-non-root/ssl-example
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
	docker pull --quiet openresty/openresty:alpine >/dev/null 2>&1

	# shellcheck disable=SC2039
	local current_image_version
	current_image_version="$(cat VERSION)"

	# shellcheck disable=SC2039
	local openresty_version
	openresty_version="$(docker run --rm openresty/openresty:alpine sh -c "openresty -version 2>&1 | sed -E 's#^.*/([0-9.]+)\$#\1#'")"

	# shellcheck disable=SC2039
	local latest_image_version
	latest_image_version="$openresty_version"-alpine

	# shellcheck disable=SC2039
	local image
	image=creemama/openresty-non-root:"$latest_image_version"

	# shellcheck disable=SC2039
	local alpine_image
	alpine_image=creemama/openresty-non-root:alpine

	# shellcheck disable=SC2039
	local git_tag
	git_tag=openresty-non-root-"$latest_image_version"

	if [ "$current_image_version" = "$latest_image_version" ]; then
		printf '%s%s%s is the latest version. There is nothing to do.%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$(treset)"
		exit
	fi
	printf '\n%s%sUpdating since %s != %s...%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$latest_image_version" "$(treset)"

	sed -E -i "" \
		's/^FROM openresty\/openresty:.*$/FROM openresty\/openresty:'"$latest_image_version"'/' \
		docker/Dockerfile
	sed -E -i "" \
		's/[0-9]+\.[0-9]+\.[0-9]+-alpine/'"$latest_image_version"'/' \
		README.md
	printf %s "$latest_image_version" >VERSION

	printf '\n%s%sFormatting the project...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	./dev.sh docker-format

	printf '\n%s%sComparing /etc/nginx/conf.d/default.conf...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	docker run --rm --volume "$(pwd -P)"/docker:/tmp openresty/openresty:alpine diff /etc/nginx/conf.d/default.conf /tmp/default.conf || true

	printf '\n%s%sComparing /usr/local/openresty/nginx/conf/nginx.conf...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	docker run --rm --volume "$(pwd -P)"/docker:/tmp openresty/openresty:alpine diff /usr/local/openresty/nginx/conf/nginx.conf /tmp/nginx.conf || true

	printf '\n%s%sBuilding %s...%s\n\n' "$(tbold)" "$(tgreen)" "$image" "$(treset)"
	(
		cd docker
		docker build --no-cache --tag "$image" .
	)

	printf '\n%s%sTry http://localhost:8080 in a browser and type Ctrl+C when done...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	docker run --name openresty-non-root-test -p 8080:8080 --rm "$image"

	docker tag "$image" "$alpine_image"
	printf '\n%s%sTry https://localhost:8443 in a browser and type Ctrl+C when done...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	(
		cd ssl-example
		docker-compose up || true
		docker-compose down
	)

	printf '\n%s%sCommitting to git...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	GPG_TTY=$(tty)
	export GPG_TTY
	git add -A
	git commit -m "Bump the version of openresty-non-root to $latest_image_version" -S
	git tag "$git_tag"
	git push origin master
	git push origin "$git_tag"

	printf '\n%s%sUploading images to Docker...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	docker push "$image"
	docker push "$alpine_image"
	docker rmi "$alpine_image"

	printf '\n%s%sRemember to update DockerHub README.%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
}

main "$@"
