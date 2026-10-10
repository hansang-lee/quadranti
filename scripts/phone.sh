#!/bin/bash
# Builds the release APK (signed with the debug key until PLAN 5.3) and
# installs it on the phone plugged in over USB, keeping the app's data.
# Never touches an emulator. The app needs no computer or server once
# installed: everything is stored on the phone.
#
#   scripts/phone.sh            build and install
#   scripts/phone.sh --no-build install the last build
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
[ "${1:-}" = "--help" ] && { usage_of "$0"; exit 0; }

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
ADB="$SDK/platform-tools/adb"
[ -x "$ADB" ] || { echo "adb not found at $ADB (set ANDROID_HOME)" >&2; exit 1; }

phones=$("$ADB" devices | awk 'NR > 1 && $2 == "device" && $1 !~ /^emulator-/ {print $1}')
count=$(echo -n "$phones" | grep -c . || true)
[ "$count" = 1 ] || { echo "Expected one phone over USB, found $count (adb devices; emulators are ignored)" >&2; exit 1; }
model=$("$ADB" -s "$phones" shell getprop ro.product.model | tr -d '\r')

cd "$ROOT"
APK=build/app/outputs/flutter-apk/app-release.apk
if [ "${1:-}" != "--no-build" ]; then
  require_flutter
  echo "Building the release APK ..."
  flutter build apk --release > /dev/null
fi
[ -f "$APK" ] || { echo "No $APK; run without --no-build" >&2; exit 1; }
echo "Installing on $model ($phones) ..."
"$ADB" -s "$phones" install -r "$APK" | tail -1
"$ADB" -s "$phones" shell monkey -p com.hansanglee.quadranti -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1 || true
echo "Installed and started Quadranti on $model."
