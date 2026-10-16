#!/usr/bin/env bash
# Execute in macOS Terminal with Xcode installed.
set -euo pipefail
task_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$task_root"
if [[ "${1:-}" != "--skip-checks" ]]; then
  flutter pub get --enforce-lockfile
  flutter analyze --no-pub
  flutter test --no-pub
fi
# Flutter 3.47 supports both architectures; explicitly retain the universal build.
flutter config --no-enable-macos-arm64-only
flutter build macos --release --no-pub
app="$task_root/build/macos/Build/Products/Release/SMT-CHECK.app"
test -d "$app"
for arch in arm64 x86_64; do
  lipo "$app/Contents/MacOS/SMT-CHECK" -verify_arch "$arch"
  lipo "$app/Contents/Frameworks/App.framework/App" -verify_arch "$arch"
  lipo "$app/Contents/Frameworks/FlutterMacOS.framework/FlutterMacOS" -verify_arch "$arch"
done
codesign --verify --deep --strict "$app"
mkdir -p "$task_root/dist"
stage="$(mktemp -d "$task_root/dist/dmg-stage.XXXXXX")"
ditto "$app" "$stage/SMT-CHECK.app"
ln -s /Applications "$stage/Applications"
hdiutil create -volname SMT-CHECK -srcfolder "$stage" -ov -format UDZO "$task_root/dist/SMT-CHECK-macos-universal.dmg"
(cd "$task_root/dist" && shasum -a 256 SMT-CHECK-macos-universal.dmg > SMT-CHECK-macos-universal.dmg.sha256)
