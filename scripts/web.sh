#!/bin/bash
# Serves the app on http://localhost:8000 (Flutter web dev server, hot
# restart with 'R' in the terminal). Uses the local Flutter when installed,
# otherwise the dev container (scripts/docker.sh). Ctrl+C stops it.
#
#   scripts/web.sh
#   PORT=8001 scripts/web.sh
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
[ "${1:-}" = "--help" ] && { usage_of "$0"; exit 0; }

PORT="${PORT:-8000}"
CMD=(flutter run -d web-server --web-port="${PORT}" --web-hostname=0.0.0.0)

if command -v flutter &>/dev/null; then
    cd "$ROOT"
    flutter pub get
    exec "${CMD[@]}"
else
    exec "$ROOT/scripts/docker.sh" bash -c "flutter pub get && ${CMD[*]}"
fi
