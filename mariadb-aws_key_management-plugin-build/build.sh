set -o errexit -o nounset -o xtrace
IFS="$(printf '\n\t' '')"
if [ -n "${BASH_VERSION:-}" ]; then
  set -o pipefail
fi

version_10_2_patch=25
version_10_3_patch=16
version_10_4_patch=6
version_10_2="10.2.${version_10_2_patch}-bionic"
version_10_3="10.3.${version_10_3_patch}-bionic"
version_10_4="10.4.${version_10_4_patch}-bionic"
versions=("${version_10_2}" "${version_10_3}" "${version_10_4}")

build_images () {
  local script_dir="$( cd "$(dirname "$0")" ; pwd -P )"
  cd "${script_dir}"

  cd 10.2
  docker build --tag "creemama/mariadb-aws_key_management-plugin-build:${version_10_2}" .
  cd ../10.3
  docker build --tag "creemama/mariadb-aws_key_management-plugin-build:${version_10_3}" .
  cd ../10.4
  docker build --tag "creemama/mariadb-aws_key_management-plugin-build:${version_10_4}" .
}

test_images () {
  for version in "${versions[@]}"
  do
    docker run \
      --name aws_key_management_build \
      --rm \
      "creemama/mariadb-aws_key_management-plugin-build:${version}"
  done
}

push_images () {
  for version in "${versions[@]}"
  do
    docker push "creemama/mariadb-aws_key_management-plugin-build:${version}"
  done
}

push_other_images () {
  for version in "10.2-bionic" "10.2.${version_10_2_patch}" "10.2"
  do
    local image="creemama/mariadb-aws_key_management-plugin-build:${version}"
    docker tag \
      "creemama/mariadb-aws_key_management-plugin-build:${version_10_2}" \
      "${image}"
    docker push "${image}"
    docker rmi "${image}"
  done
  for version in "10.3-bionic" "10.3.${version_10_3_patch}" "10.3"
  do
    local image="creemama/mariadb-aws_key_management-plugin-build:${version}"
    docker tag \
      "creemama/mariadb-aws_key_management-plugin-build:${version_10_3}" \
      "${image}"
    docker push "${image}"
    docker rmi "${image}"
  done
  for version in "10.4-bionic" "10-bionic" "bionic" "10.4.${version_10_4_patch}" "10.4" "10" "latest"
  do
    local image="creemama/mariadb-aws_key_management-plugin-build:${version}"
    docker tag \
      "creemama/mariadb-aws_key_management-plugin-build:${version_10_4}" \
      "${image}"
    docker push "${image}"
    docker rmi "${image}"
  done
}

main () {
  build_images
  test_images
  push_images
  push_other_images
}

main "$@"
