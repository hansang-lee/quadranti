#!/bin/bash
# What CI runs before deploying: flutter analyze and the unit + widget
# tests, with logs in out/<YYMMDD_hhmmss>/app/ and a summary.txt. Ends with
# "All checks passed." or prints the failing log. --build also builds the
# release web bundle.
#
#   scripts/test/check.sh
#   scripts/test/check.sh --build
set -uo pipefail
source "$(dirname "$0")/../lib/common.sh"
[ "${1:-}" = "--help" ] && { usage_of "$0"; exit 0; }
require_flutter

BUILD=0
[ "${1:-}" = "--build" ] && BUILD=1

RUN="$(new_run_dir app)"
LOG="$RUN/app"
cd "$ROOT"
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

flutter pub get > "$LOG/pub-get.log" 2>&1 || { echo "flutter pub get failed:"; cat "$LOG/pub-get.log"; exit 1; }
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
