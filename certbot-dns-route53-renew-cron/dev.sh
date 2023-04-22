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

main() {
	# shellcheck disable=SC2039
	local command_help
	command_help='docker-format - Format shell scripts and Markdown files.
git - Run git.
update - Check for a newer version of certbot/dns-route53:latest and update this project if so.
update-dockerfile - Check for newer versions of Alpine and Python packages and update this project'"'"'s Dockerfile.'
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
			shellutil/format.sh docker-format certbot-dns-route53-renew-cron
			shellutil/format.sh docker-shell-format certbot-dns-route53-renew-cron/docker
		)
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		shift
		../shellutil/git.sh git "$@"
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		update
	elif [ "$1" = "$(arg 3 $commands)" ]; then
		update_dockerfile
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

update() {
	docker pull --quiet certbot/dns-route53:latest >/dev/null 2>&1

	# shellcheck disable=SC2039
	local current_image_version
	current_image_version="$(cat VERSION)"

	# shellcheck disable=SC2039
	local latest_image_version
	latest_image_version=v"$(docker run -it --rm certbot/dns-route53:latest --version | sed 's/certbot//' | tail -n1 | tr -d '\r')"

	# shellcheck disable=SC2039
	local image
	image=creemama/certbot-dns-route53-renew-cron:"$latest_image_version"

	# shellcheck disable=SC2039
	local latest_image
	latest_image=creemama/certbot-dns-route53-renew-cron:latest

	# shellcheck disable=SC2039
	local git_tag
	git_tag=certbot-dns-route53-renew-cron-"$latest_image_version"

	if [ "$current_image_version" = "$latest_image_version" ]; then
		printf '%s%s%s is the latest version. There is nothing to do.%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$(treset)"
		exit
	fi
	printf '\n%s%sUpdating since %s != %s...%s\n' "$(tbold)" "$(tgreen)" "$current_image_version" "$latest_image_version" "$(treset)"

	sed -E -i "" \
		's#^FROM certbot/dns-route53:.*$#FROM certbot/dns-route53:'"$latest_image_version"'#' \
		docker/Dockerfile
	(
		cd ..
		docker run \
			--entrypoint sh \
			--rm \
			--volume "$(pwd -P):$(pwd -P)" \
			--workdir "$(pwd -P)"/certbot-dns-route53-renew-cron \
			certbot/dns-route53:latest \
			-c './dev.sh update-dockerfile'
	)

	sed -E -i "" \
		's/v[0-9]+\.[0-9]+\.[0-9]+/'"$latest_image_version"'/' \
		README.md
	printf %s "$latest_image_version" >VERSION

	printf '\n%s%sFormatting the project...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	./dev.sh docker-format

	printf '\n%s%sBuilding %s...%s\n\n' "$(tbold)" "$(tgreen)" "$image" "$(treset)"
	(
		cd docker
		docker pull --platform linux/amd64 certbot/dns-route53:"$latest_image_version"
		docker build --no-cache --platform linux/amd64 --tag "$image-amd64" .
		docker rmi certbot/dns-route53:latest
		docker pull --platform linux/arm64/v8 certbot/dns-route53:"$latest_image_version"
		docker build --no-cache --platform linux/arm64/v8 --tag "$image-arm64" .
		docker rmi certbot/dns-route53:latest
	)

	printf '\n%s%sCommitting to git...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	GPG_TTY=$(tty)
	export GPG_TTY
	git add -A
	git commit -m "Bump the version of certbot-dns-route53-renew-cron to $latest_image_version" -S
	git tag "$git_tag"
	git push origin master
	git push origin "$git_tag"

	printf '\n%s%sUploading images to Docker...%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
	docker push "$image-amd64"
	docker push "$image-arm64"
	docker manifest create "$image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest create "$latest_image" --amend "$image-amd64" --amend "$image-arm64"
	docker manifest push "$image"
	docker manifest push "$latest_image"
	docker rmi "$image-amd64"
	docker rmi "$image-arm64"

	printf '\n%s%sRemember to update DockerHub README and delete architecture-specific images.%s\n\n' "$(tbold)" "$(tgreen)" "$(treset)"
}

update_dockerfile() {
	apk_update_package_version tini docker/Dockerfile
	pip_update_package_version pip docker/Dockerfile
	pip_update_package_version schedule docker/Dockerfile
}

main "$@"
