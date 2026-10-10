#!/bin/bash
# Screenshots of the real web build: builds it (unless --no-build), serves
# it on :8765, starts a headless Chrome (412x860) and runs the given steps
# through scripts/web_driver.ts. PNGs land in out/<YYMMDD_hhmmss>/screens/.
# Each run starts from an empty browser profile unless --profile DIR is
# given (keeps the accounts and tasks in DIR between runs). Needs Chrome
# and bun. Steps are listed in scripts/web_driver.ts.
#
#   scripts/screens.sh goto:http://localhost:8765/ wait:3000 shot:login
#   scripts/screens.sh --no-build --profile /tmp/q-profile scheme:dark goto:http://localhost:8765/ wait:3000 shot:home
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
[ "${1:-}" = "--help" ] && { usage_of "$0"; exit 0; }

BUILD=1
PROFILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --no-build) BUILD=0; shift ;;
    --profile) PROFILE="$2"; shift 2 ;;
    *) break ;;
  esac
done
[ $# -gt 0 ] || { usage_of "$0"; exit 1; }

RUN="$(new_run_dir screens)"
echo "Run folder: ${RUN#$ROOT/}"
cd "$ROOT"
if [ $BUILD = 1 ]; then
  require_flutter
  flutter build web --release > "$RUN/screens/build.log" 2>&1 || { echo "web build failed; see $RUN/screens/build.log"; exit 1; }
fi
TEMP_PROFILE=""
if [ -z "$PROFILE" ]; then PROFILE="$(mktemp -d)"; TEMP_PROFILE="$PROFILE"; fi

python3 -m http.server 8765 -d build/web > "$RUN/screens/http.log" 2>&1 &
HTTP_PID=$!
google-chrome --headless=new --remote-debugging-port=9333 --user-data-dir="$PROFILE" \
  --window-size=412,860 about:blank > "$RUN/screens/chrome.log" 2>&1 &
CHROME_PID=$!
cleanup() {
  kill "$HTTP_PID" "$CHROME_PID" 2>/dev/null || true
  wait "$CHROME_PID" 2>/dev/null || true
  if [ -n "$TEMP_PROFILE" ]; then rm -rf "$TEMP_PROFILE"; fi
}
trap cleanup EXIT

for _ in $(seq 50); do
  curl -fs -o /dev/null http://localhost:9333/json/version && curl -fs -o /dev/null http://localhost:8765/ && break
  sleep 0.2
done

SHOTS="$RUN/screens" bun scripts/web_driver.ts "$@"
summarize "$RUN" screens PASS
ls "$RUN/screens"/*.png 2>/dev/null | sed "s|$ROOT/||"
