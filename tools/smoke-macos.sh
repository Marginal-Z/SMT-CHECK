#!/usr/bin/env bash
# macOS Terminal / CI: validate the actual DMG on Intel and Apple Silicon.
set -euo pipefail
task_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$task_root"
mount_dir="$(mktemp -d "${RUNNER_TEMP:-/tmp}/smt-check-mount.XXXXXX")"
install_dir="$(mktemp -d "${RUNNER_TEMP:-/tmp}/smt-check-install.XXXXXX")"
app="$install_dir/SMT-CHECK.app"
app_pid=''
cleanup() {
  if [[ -n "$app_pid" ]]; then kill "$app_pid" 2>/dev/null || true; fi
  hdiutil detach "$mount_dir" -quiet || true
}
trap cleanup EXIT
hdiutil attach "$1" -mountpoint "$mount_dir" -nobrowse -readonly -quiet
ditto "$mount_dir/SMT-CHECK.app" "$app"
expected="$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' pubspec.yaml)"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$expected"
for arch in arm64 x86_64; do
  lipo "$app/Contents/MacOS/SMT-CHECK" -verify_arch "$arch"
  lipo "$app/Contents/Frameworks/App.framework/App" -verify_arch "$arch"
  lipo "$app/Contents/Frameworks/FlutterMacOS.framework/FlutterMacOS" -verify_arch "$arch"
done
codesign --verify --deep --strict "$app"
"$app/Contents/MacOS/SMT-CHECK" > "$install_dir/startup.log" 2>&1 &
app_pid=$!
sleep 15
kill -0 "$app_pid"
cat "$install_dir/startup.log"
if grep -E 'Unhandled Exception|ERROR:flutter|Failed to start' "$install_dir/startup.log"; then exit 1; fi
kill "$app_pid"
wait "$app_pid" || true
app_pid=''
hdiutil detach "$mount_dir" -quiet
trap - EXIT
# Delete only the verified application bundle created by mktemp in this script.
[[ "$app" == "$install_dir/SMT-CHECK.app" && "$install_dir" == */smt-check-install.* ]]
rm -rf -- "$app"
test ! -e "$app"
