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
cp -- "$task_root/assets/fonts/OFL-NotoSansThai.txt" "$destination/OFL-NotoSansThai.txt"
test -x "$destination/SMT-CHECK"
version="$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' pubspec.yaml)"
package_root="$(mktemp -d "$task_root/dist/deb-stage.XXXXXX")"
mkdir -p "$package_root/DEBIAN" "$package_root/opt/smt-check" "$package_root/usr/bin" "$package_root/usr/share/applications" "$package_root/usr/share/icons/hicolor/256x256/apps"
cp -a "$destination/." "$package_root/opt/smt-check/"
cp "$task_root/docs/app-icon.png" "$package_root/usr/share/icons/hicolor/256x256/apps/smt-check.png"
ln -s /opt/smt-check/SMT-CHECK "$package_root/usr/bin/smt-check"
cat > "$package_root/DEBIAN/control" <<EOF
Package: smt-check
Version: $version
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Marginal-Z <289210392+Marginal-Z@users.noreply.github.com>
Depends: libgtk-3-0 (>= 3.22), libstdc++6, libglib2.0-0, libc6 (>= 2.35), libegl1, libgles2
Homepage: https://github.com/Marginal-Z/SMT-CHECK
Description: T100 BOM and SMT placement reconciliation desktop application
 Bidirectional material checking with Chinese, English and Thai interfaces.
EOF
cat > "$package_root/usr/share/applications/smt-check.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=SMT-CHECK
Comment=T100 BOM and SMT material checking
Exec=/opt/smt-check/SMT-CHECK
Icon=smt-check
Terminal=false
Categories=Office;Utility;
EOF
chmod 755 "$package_root" "$package_root/DEBIAN" "$package_root/opt/smt-check/SMT-CHECK"
dpkg-deb --root-owner-group --build "$package_root" "$task_root/dist/SMT-CHECK-linux-amd64.deb"
(cd -- "$task_root/dist" && sha256sum SMT-CHECK-linux-amd64.deb > SMT-CHECK-linux-amd64.deb.sha256)
printf 'Desktop installer: %s\n' "$task_root/dist/SMT-CHECK-linux-amd64.deb"
