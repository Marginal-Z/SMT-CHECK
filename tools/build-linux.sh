#!/usr/bin/env bash
# Execute in WSL Ubuntu / Linux with a Linux Flutter SDK.
set -euo pipefail
task_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$task_root"
if [[ "${1:-}" != "--skip-checks" ]]; then
  flutter pub get --enforce-lockfile
  flutter analyze --no-pub
  flutter test --no-pub
fi
flutter build linux --release --no-pub
source_dir="$task_root/build/linux/x64/release/bundle"
destination="$task_root/dist/SMT-CHECK-linux-x64"
mkdir -p -- "$destination"
cp -a -- "$source_dir/." "$destination/"
cp -- "$task_root/README.md" "$destination/README.md"
test -x "$destination/SMT-CHECK"
tar -czf "$task_root/dist/SMT-CHECK-linux-x64.tar.gz" -C "$task_root/dist" SMT-CHECK-linux-x64
(cd -- "$task_root/dist" && sha256sum SMT-CHECK-linux-x64.tar.gz > SMT-CHECK-linux-x64.tar.gz.sha256)
printf 'Desktop package: %s\n' "$task_root/dist/SMT-CHECK-linux-x64.tar.gz"
