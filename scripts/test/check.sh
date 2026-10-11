#!/usr/bin/env bash
# What CI runs before deploying, and what the pre-push hook runs: shellcheck
# (Docker, over scripts/ and .githooks/), flutter analyze and the unit +
# widget tests, with logs in out/<YYMMDD_hhmmss>/app/ and a summary.txt.
# Ends with "All checks passed." or prints the failing log. --build also
# builds the release web bundle.
#
#   scripts/test/check.sh
#   scripts/test/check.sh --build
# No -e: the steps must all run so the summary reports every result.
set -uo pipefail
source "$(dirname "$0")/../lib/common.sh"
case "${1:-}" in -h|--help) usage_of "$0"; exit 0 ;; esac
require_flutter

BUILD=0
[ "${1:-}" = "--build" ] && BUILD=1

RUN="$(new_run_dir app)"
LOG="$RUN/app"
cd "$ROOT" || exit 1
echo "Run folder: ${RUN#$ROOT/}"

failed=""
step() { # name, command...
  local name="$1"; shift
  printf '%-10s ' "$name"
  if "$@" > "$LOG/$name.log" 2>&1; then
    echo "PASS"; summarize "$RUN" "$name" PASS
  else
    echo "FAIL"; summarize "$RUN" "$name" FAIL
    failed="$failed $name"
  fi
}

# Pinned so a new shellcheck release cannot fail a push on its own. Warnings
# fail, style notes do not.
shellcheck_scripts() {
  command -v docker >/dev/null || { echo "docker not found (shellcheck runs in a container)"; return 1; }
  local files=() f
  while IFS= read -r f; do files+=("$f"); done < <(find scripts .githooks -type f \( -name '*.sh' -o -path '.githooks/*' \) | sort)
  docker run --rm -v "$ROOT:/mnt:ro" -w /mnt koalaman/shellcheck:v0.10.0 \
    --severity=warning --external-sources "${files[@]}"
}

flutter pub get > "$LOG/pub-get.log" 2>&1 || { echo "flutter pub get failed:"; cat "$LOG/pub-get.log"; exit 1; }
step shellcheck shellcheck_scripts
step analyze flutter analyze
step test flutter test --reporter expanded
[ $BUILD = 1 ] && step build flutter build web --release

if [ -z "$failed" ]; then
  summarize "$RUN" result PASS
  echo "All checks passed."
else
  summarize "$RUN" result FAIL
  for name in $failed; do
    echo "--- $name failed; end of $LOG/$name.log:"
    tail -n 60 "$LOG/$name.log"
  done
  exit 1
fi
