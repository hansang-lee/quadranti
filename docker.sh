#!/bin/bash
# Run a command in the dev container (default: an interactive shell).
#   ./docker.sh                 # shell in /workspaces/quadranti
#   ./docker.sh flutter test
set -e

BASE_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
DOCKER_IMAGE="quadranti"

docker build -t "${DOCKER_IMAGE}" "${BASE_DIR}"

DOCKER_ARGS=(
    "--rm"
    "--interactive"
    "--tty"
    "--name=quadranti"
    "--network=host"
    "--env=TZ=Asia/Seoul"
    "--mount=source=${BASE_DIR},target=/workspaces/quadranti,type=bind"
    "--workdir=/workspaces/quadranti"
    "${DOCKER_IMAGE}"
)

if [ $# -eq 0 ]; then
    set -- /bin/bash
fi
docker run "${DOCKER_ARGS[@]}" "$@"
