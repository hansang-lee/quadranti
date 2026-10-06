#!/bin/bash
# Serve the app on http://localhost:8000 (Flutter web dev server).
# Uses the local Flutter when installed, otherwise the dev container.
set -e

BASE_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
PORT="${PORT:-8000}"
CMD=(flutter run -d web-server --web-port="${PORT}" --web-hostname=0.0.0.0)

if command -v flutter &>/dev/null; then
    cd "${BASE_DIR}"
    flutter pub get
    exec "${CMD[@]}"
else
    exec "${BASE_DIR}/docker.sh" bash -c "flutter pub get && ${CMD[*]}"
fi
