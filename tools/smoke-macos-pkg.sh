#!/usr/bin/env bash
# macOS CI only: install the actual in-app update payload on a disposable host.
set -euo pipefail
task_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$task_root"
[[ "${CI:-}" == true ]] || { echo 'This installation test requires a disposable CI host.' >&2; exit 1; }
app=/Applications/SMT-CHECK.app
[[ ! -e "$app" ]] || { echo 'Refusing to overwrite an existing application.' >&2; exit 1; }
legacy="$HOME/Library/Containers/com.smtcheck.smtCheck/Data/Library/Preferences/com.smtcheck.smtCheck.plist"
mkdir -p "$(dirname "$legacy")"
python3 - "$legacy" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'wb') as stream:
    plistlib.dump({'flutter.language': 'th', 'flutter.accentColor': 'green'}, stream)
PY
defaults delete com.smtcheck.smtCheck >/dev/null 2>&1 || true
sudo /usr/sbin/installer -pkg "$1" -target /
expected="$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' pubspec.yaml)"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$expected"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$app/Contents/Info.plist")" = 'SMT Fusion'
codesign --verify --deep --strict "$app"
log="$(mktemp "${RUNNER_TEMP:-/tmp}/fusion-pkg-startup.XXXXXX")"
"$app/Contents/MacOS/SMT-CHECK" > "$log" 2>&1 &
app_pid=$!
trap 'kill "$app_pid" 2>/dev/null || true' EXIT
sleep 15
kill -0 "$app_pid"
python3 tools/check_startup_log.py "$log" --allow-startup-frame-clamp
test "$(defaults read com.smtcheck.smtCheck flutter.language)" = th
test "$(defaults read com.smtcheck.smtCheck flutter.accentColor)" = green
kill "$app_pid"
wait "$app_pid" || true
trap - EXIT
# This fixed path was absent before this script installed the package.
sudo rm -rf -- /Applications/SMT-CHECK.app
test ! -e "$app"
rm -- "$legacy"
defaults delete com.smtcheck.smtCheck
