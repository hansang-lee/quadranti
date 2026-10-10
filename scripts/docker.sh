#!/bin/bash
# Runs a command in the optional dev container (Flutter + Android SDK, see
# the Dockerfile); default: an interactive shell in /workspaces/quadranti.
# Not needed when Flutter is installed locally.
#
#   scripts/docker.sh
#   scripts/docker.sh flutter test
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
[ "${1:-}" = "--help" ] && { usage_of "$0"; exit 0; }

DOCKER_IMAGE="quadranti"
docker build -t "${DOCKER_IMAGE}" "${ROOT}"

DOCKER_ARGS=(
    "--rm"
    "--interactive"
    "--tty"
    "--name=quadranti"
    "--network=host"
    "--env=TZ=Asia/Seoul"
    "--mount=source=${ROOT},target=/workspaces/quadranti,type=bind"
    "--workdir=/workspaces/quadranti"
    "${DOCKER_IMAGE}"
)

if [ $# -eq 0 ]; then
    set -- /bin/bash
fi
docker run "${DOCKER_ARGS[@]}" "$@"
