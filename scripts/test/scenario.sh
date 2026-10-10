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
#   scripts/test/scenario.sh --matrix        the same run on each Android version in
#                                            MATRIX_AVDS, one emulator at a time, into
#                                            scenarios/<avd>/ (before a release)
#
# --web needs Google Chrome and a matching chromedriver: CHROMEDRIVER, or
# chromedriver on PATH, or one downloaded once into ~/.cache/quadranti-chromedriver/.
# --matrix stops every running emulator (cling's included), boots each matrix
# AVD in turn, runs the scenarios on it and shuts it down; a cling_e2e that
# was running before is booted again at the end. Do not start it while
# another scenario run (this project's or cling's) is using an emulator.
set -uo pipefail
source "$(dirname "$0")/../lib/common.sh"
require_flutter

AVD="${SCENARIO_AVD:-cling_e2e}"
# The Android versions --matrix runs on: the AVDs cling made for its own
# matrix (cling docs/development.md §3b), shared like cling_e2e. small_phone
# (360x640 dp), google_apis x86_64, 2 GB. Android 9 (the oldest worth
# testing), 13 and 16 (the newest; 15+ draws edge to edge). Plain runs use
# cling_e2e (Android 15). SCENARIO_MATRIX overrides the list.
MATRIX_AVDS=(cling_api28 cling_api33 cling_api36)
[ -n "${SCENARIO_MATRIX:-}" ] && read -r -a MATRIX_AVDS <<<"$SCENARIO_MATRIX"

web=false
show=false
matrix=false
names=()
pass=()   # the arguments but --matrix, for each AVD's run in a matrix
for arg in "$@"; do
  case "$arg" in
    --matrix) matrix=true; continue ;;
    --web) web=true ;;
    --show) show=true ;;
    -h|--help) usage_of "$0"; exit 0 ;;
    *) names+=("${arg%_test.dart}") ;;
  esac
  pass+=("$arg")
done
cd "$ROOT"
if [ ${#names[@]} -eq 0 ]; then
  for f in integration_test/*_test.dart; do names+=("$(basename "$f" _test.dart)"); done
fi

RUN="$(new_run_dir scenarios)"
OUT="$RUN/scenarios${SCENARIO_OUT_SUBDIR:+/$SCENARIO_OUT_SUBDIR}"
mkdir -p "$OUT/logs" "$OUT/screenshots"
# The run's summary.txt; one AVD's part of a matrix keeps its own beside its logs.
SUMMARY="$RUN"
[ -n "${SCENARIO_OUT_SUBDIR:-}" ] && SUMMARY="$OUT"
[ -n "${SCENARIO_OUT_SUBDIR:-}" ] || echo "Run folder: ${RUN#$ROOT/}"
bg_pids=()
trap 'for p in "${bg_pids[@]}"; do kill "$p" 2>/dev/null; done' EXIT

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
ADB="$SDK/platform-tools/adb"
EMULATOR="$SDK/emulator/emulator"
find_emulator() { "$ADB" devices | awk '$1 ~ /^emulator-[0-9]+$/ && $2 == "device" {print $1; exit}'; }
all_emulators() { "$ADB" devices | awk '$1 ~ /^emulator-[0-9]+$/ {print $1}'; }
avd_of() { "$ADB" -s "$1" emu avd name 2>/dev/null | head -1 | tr -d '\r'; }

kill_emulators() {
  local s
  for s in $(all_emulators); do
    echo "Stopping $s ($(avd_of "$s")) ..."
    "$ADB" -s "$s" emu kill >/dev/null 2>&1 || true
  done
  for _ in $(seq 60); do
    [ -z "$(all_emulators)" ] && ! pgrep -f 'qemu-system.*-avd' >/dev/null && break
    sleep 1
  done
  sleep 2
}

# boot_avd AVD LOG: boots AVD headless, waits for it and sets serial.
boot_avd() {
  local avd=$1 log=$2
  [ -x "$EMULATOR" ] || { echo "No emulator binary at $EMULATOR" >&2; return 1; }
  "$EMULATOR" -list-avds | grep -qx "$avd" || { echo "No AVD named $avd (see docs/testing.md, \"Devices\")" >&2; return 1; }
  echo "Booting $avd headless (log: ${log#$ROOT/}) ..."
  # -gpu host: with swiftshader the emulator's adb connection tends to
  # drop as a Flutter app starts (seen in cling).
  nohup "$EMULATOR" -avd "$avd" -no-window -no-audio -no-boot-anim -gpu host -no-snapshot-save > "$log" 2>&1 &
  serial=""
  for _ in $(seq 90); do serial="$(find_emulator)"; [ -n "$serial" ] && break; sleep 2; done
  [ -n "$serial" ] || { echo "The emulator did not come up; see $log" >&2; return 1; }
  for _ in $(seq 120); do
    [ "$("$ADB" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && return 0
    sleep 2
  done
  echo "$serial did not finish booting; see $log" >&2
  return 1
}

# --matrix: this script once per AVD, each a plain run into scenarios/<avd>/.
if [ "$matrix" = true ]; then
  [ "$web" = false ] || { echo "--matrix is for emulators; drop --web" >&2; exit 2; }
  [ -z "${SCENARIO_OUT_SUBDIR:-}" ] || { echo "--matrix cannot be nested" >&2; exit 2; }
  [ -x "$ADB" ] || { echo "adb not found at $ADB (set ANDROID_HOME)" >&2; exit 1; }
  # Check every AVD exists before stopping anything: a typo must not take
  # down an emulator someone else (cling's scenarios) may be using.
  missing=()
  for avd in "${MATRIX_AVDS[@]}"; do "$EMULATOR" -list-avds | grep -qx "$avd" || missing+=("$avd"); done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "No AVD named: ${missing[*]} (create them as in docs/testing.md, \"Devices\"); nothing was stopped." >&2
    exit 1
  fi
  export QUADRANTI_RUN_DIR="$RUN"
  had_default=false
  for s in $(all_emulators); do [ "$(avd_of "$s")" = "$AVD" ] && had_default=true; done
  echo "Matrix: ${MATRIX_AVDS[*]}"
  mfailed=0
  for avd in "${MATRIX_AVDS[@]}"; do
    echo; echo "== $avd =="
    mkdir -p "$OUT/$avd"
    kill_emulators
    if ! boot_avd "$avd" "$OUT/$avd/emulator.log"; then
      summarize "$RUN" "$avd" "FAIL (did not boot)"; mfailed=1; continue
    fi
    version="$("$ADB" -s "$serial" shell getprop ro.build.version.release | tr -d '\r')"
    t0=$(date +%s)
    if SCENARIO_OUT_SUBDIR="$avd" "$0" "${pass[@]+"${pass[@]}"}"; then
      summarize "$RUN" "$avd" "PASS (Android $version, $(( $(date +%s) - t0 ))s)"
    else
      summarize "$RUN" "$avd" "FAIL (Android $version, $(( $(date +%s) - t0 ))s)"; mfailed=1
    fi
  done
  kill_emulators
  if [ "$had_default" = true ]; then
    boot_avd "$AVD" "$OUT/emulator-restore.log" && echo "$AVD is running again."
  fi
  echo
  grep -E "^($(IFS='|'; echo "${MATRIX_AVDS[*]}")):" "$RUN/summary.txt" | sed 's/^/  /'
  if [ $mfailed = 0 ]; then summarize "$RUN" result PASS; echo "All scenarios passed on every AVD."; exit 0; fi
  summarize "$RUN" result FAIL; exit 1
fi

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
  [ -x "$ADB" ] || { echo "adb not found at $ADB (set ANDROID_HOME)" >&2; exit 1; }
  serial="$(find_emulator)"
  if [ -z "$serial" ]; then
    boot_avd "$AVD" "$OUT/emulator.log" || exit 1
  fi
  case "$serial" in emulator-*) ;; *) echo "Refusing to run on $serial: not an emulator" >&2; exit 1 ;; esac
  device_args=(-d "$serial")
  echo "Device: $serial ($(avd_of "$serial"), Android $("$ADB" -s "$serial" shell getprop ro.build.version.release | tr -d '\r'))"
fi

failed=0
for name in "${names[@]}"; do
  target="integration_test/${name}_test.dart"
  [ -f "$target" ] || { echo "No scenario $target" >&2; summarize "$SUMMARY" "$name" MISSING; failed=1; continue; }
  printf '%-16s ' "$name"
  start=$(date +%s)
  SCENARIO_SHOTS_DIR="$OUT/screenshots" flutter drive --driver=test_driver/integration_test.dart \
    --target="$target" "${device_args[@]}" > "$OUT/logs/$name.log" 2>&1
  rc=$?
  took=$(( $(date +%s) - start ))
  if [ $rc = 0 ] && grep -q "All tests passed" "$OUT/logs/$name.log"; then
    echo "PASS (${took}s)"; summarize "$SUMMARY" "$name" "PASS (${took}s)"
  else
    echo "FAIL (${took}s, ${OUT#$ROOT/}/logs/$name.log)"; summarize "$SUMMARY" "$name" "FAIL (${took}s)"
    grep -E "TestFailure|Timed out|Expected:|Actual:|Exception|Error:" "$OUT/logs/$name.log" | head -8 | sed 's/^/    /'
    failed=1
  fi
done

shots=$(ls "$OUT/screenshots" 2>/dev/null | wc -l)
echo "Screenshots: $shots in ${OUT#$ROOT/}/screenshots"
if [ $failed = 0 ]; then summarize "$SUMMARY" result PASS; echo "All scenarios passed."; else summarize "$SUMMARY" result FAIL; exit 1; fi
