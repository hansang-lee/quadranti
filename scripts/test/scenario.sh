#!/bin/bash
# The scenario tests (integration_test/): the real app on real storage,
# one user journey per file, with a screenshot per step. Runs on an Android
# emulator (the cling_e2e AVD, booted headless if none is running; never on
# a phone), or with --web in headless Chrome through chromedriver.
# Screenshots, logs and a summary.txt go to out/<YYMMDD_hhmmss>/scenarios/.
#
#   scripts/test/scenario.sh                 every scenario on the emulator
#   scripts/test/scenario.sh repeat backup   some, by file name (repeat_test.dart, ...)
#   scripts/test/scenario.sh --web           every scenario in headless Chrome
#   scripts/test/scenario.sh --web --show    in a visible Chrome window
#
# --web needs Google Chrome and a matching chromedriver: CHROMEDRIVER, or
# chromedriver on PATH, or one downloaded once into ~/.cache/quadranti-chromedriver/.
set -uo pipefail
source "$(dirname "$0")/../lib/common.sh"
require_flutter

web=false
show=false
names=()
for arg in "$@"; do
  case "$arg" in
    --web) web=true ;;
    --show) show=true ;;
    -h|--help) usage_of "$0"; exit 0 ;;
    *) names+=("${arg%_test.dart}") ;;
  esac
done
cd "$ROOT"
if [ ${#names[@]} -eq 0 ]; then
  for f in integration_test/*_test.dart; do names+=("$(basename "$f" _test.dart)"); done
fi

RUN="$(new_run_dir scenarios)"
OUT="$RUN/scenarios"
mkdir -p "$OUT/logs" "$OUT/screenshots"
echo "Run folder: ${RUN#$ROOT/}"
bg_pids=()
trap 'for p in "${bg_pids[@]}"; do kill "$p" 2>/dev/null; done' EXIT

# A chromedriver of Chrome's own version (Chrome for Testing), downloaded
# once into ~/.cache/quadranti-chromedriver/<version>/. Prints its path.
ensure_chromedriver() {
  if [ -n "${CHROMEDRIVER:-}" ]; then echo "$CHROMEDRIVER"; return; fi
  if command -v chromedriver >/dev/null; then command -v chromedriver; return; fi
  local version dir url tmp
  version="$(google-chrome --version | grep -oE '[0-9]+(\.[0-9]+){3}' | head -1)"
  [ -n "$version" ] || { echo "Google Chrome not found" >&2; return 1; }
  dir="$HOME/.cache/quadranti-chromedriver/$version"
  if [ ! -x "$dir/chromedriver" ]; then
    url="https://storage.googleapis.com/chrome-for-testing-public/$version/linux64/chromedriver-linux64.zip"
    echo "Downloading chromedriver $version into $dir ..." >&2
    tmp="$(mktemp -d)"
    curl -fsSL -m 300 -o "$tmp/cd.zip" "$url" && python3 -I -m zipfile -e "$tmp/cd.zip" "$tmp/x" &&
      mkdir -p "$dir" && mv "$tmp/x/chromedriver-linux64/chromedriver" "$dir/chromedriver" &&
      chmod +x "$dir/chromedriver" || { rm -rf "$tmp"; echo "Could not download $url" >&2; return 1; }
    rm -rf "$tmp"
  fi
  echo "$dir/chromedriver"
}

device_args=()
if [ "$web" = true ]; then
  driver="$(ensure_chromedriver)" || exit 1
  port="${CHROMEDRIVER_PORT:-4444}"
  "$driver" --port="$port" > "$OUT/chromedriver.log" 2>&1 &
  bg_pids+=($!)
  for _ in $(seq 50); do curl -fs -m 1 "http://127.0.0.1:$port/status" >/dev/null && break; sleep 0.2; done
  curl -fs -m 1 "http://127.0.0.1:$port/status" >/dev/null || { echo "chromedriver did not start; see $OUT/chromedriver.log" >&2; exit 1; }
  headless=--headless
  [ "$show" = true ] && headless=--no-headless
  # --profile: the debug web compiler serves only the target's folder.
  device_args=(--profile -d web-server --browser-name=chrome --driver-port="$port" "$headless" --browser-dimension=412x860)
  echo "Device: Chrome (chromedriver on :$port)"
else
  SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
  ADB="$SDK/platform-tools/adb"
  AVD="${SCENARIO_AVD:-cling_e2e}"
  [ -x "$ADB" ] || { echo "adb not found at $ADB (set ANDROID_HOME)" >&2; exit 1; }
  find_emulator() { "$ADB" devices | awk '$1 ~ /^emulator-[0-9]+$/ && $2 == "device" {print $1; exit}'; }
  serial="$(find_emulator)"
  if [ -z "$serial" ]; then
    echo "Booting $AVD headless (log: $OUT/emulator.log) ..."
    # -gpu host: with swiftshader the emulator's adb connection tends to
    # drop as a Flutter app starts (seen in cling).
    nohup "$SDK/emulator/emulator" -avd "$AVD" -no-window -no-audio -no-boot-anim -gpu host -no-snapshot-save \
      > "$OUT/emulator.log" 2>&1 &
    for _ in $(seq 90); do serial="$(find_emulator)"; [ -n "$serial" ] && break; sleep 2; done
    [ -n "$serial" ] || { echo "The emulator did not come up; see $OUT/emulator.log" >&2; exit 1; }
    for _ in $(seq 90); do
      [ "$("$ADB" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break
      sleep 2
    done
  fi
  case "$serial" in emulator-*) ;; *) echo "Refusing to run on $serial: not an emulator" >&2; exit 1 ;; esac
  device_args=(-d "$serial")
  echo "Device: $serial"
fi

failed=0
for name in "${names[@]}"; do
  target="integration_test/${name}_test.dart"
  [ -f "$target" ] || { echo "No scenario $target" >&2; summarize "$RUN" "$name" MISSING; failed=1; continue; }
  printf '%-16s ' "$name"
  start=$(date +%s)
  SCENARIO_SHOTS_DIR="$OUT/screenshots" flutter drive --driver=test_driver/integration_test.dart \
    --target="$target" "${device_args[@]}" > "$OUT/logs/$name.log" 2>&1
  rc=$?
  took=$(( $(date +%s) - start ))
  if [ $rc = 0 ] && grep -q "All tests passed" "$OUT/logs/$name.log"; then
    echo "PASS (${took}s)"; summarize "$RUN" "$name" "PASS (${took}s)"
  else
    echo "FAIL (${took}s, $OUT/logs/$name.log)"; summarize "$RUN" "$name" "FAIL (${took}s)"
    grep -E "TestFailure|Timed out|Expected:|Actual:|Exception|Error:" "$OUT/logs/$name.log" | head -8 | sed 's/^/    /'
    failed=1
  fi
done

shots=$(ls "$OUT/screenshots" 2>/dev/null | wc -l)
echo "Screenshots: $shots in ${OUT#$ROOT/}/screenshots"
if [ $failed = 0 ]; then summarize "$RUN" result PASS; echo "All scenarios passed."; else summarize "$RUN" result FAIL; exit 1; fi
