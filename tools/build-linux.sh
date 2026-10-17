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
case "$(uname -m)" in
  x86_64) flutter_arch=x64; deb_arch=amd64; elf_machine='Advanced Micro Devices X86-64' ;;
  aarch64) flutter_arch=arm64; deb_arch=arm64; elf_machine=AArch64 ;;
  *) echo 'Unsupported Linux build architecture' >&2; exit 1 ;;
esac
flutter build linux --release --no-pub --target-platform="linux-$flutter_arch"
source_dir="$task_root/build/linux/$flutter_arch/release/bundle"
mkdir -p "$task_root/dist"
destination="$(mktemp -d "$task_root/dist/linux-$flutter_arch.XXXXXX")"
mkdir -p -- "$destination"
cp -a -- "$source_dir/." "$destination/"
cp -- "$task_root/README.md" "$destination/README.md"
cp -- "$task_root/assets/fonts/OFL-NotoSansThai.txt" "$destination/OFL-NotoSansThai.txt"
test -x "$destination/SMT-CHECK"
readelf -h "$destination/SMT-CHECK" | grep -F "$elf_machine"
while IFS= read -r -d '' library; do
  readelf -h "$library" | grep -F "$elf_machine"
done < <(find "$destination/lib" -name '*.so' -print0)
version="$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' pubspec.yaml)"
# WSL-mounted Windows folders may report mode 0777 despite chmod. Stage the
# package on Linux's temporary filesystem so dpkg receives real Unix modes.
package_root="$(mktemp -d "${TMPDIR:-/tmp}/smt-check-deb.XXXXXX")"
trap 'rm -rf -- "$package_root"' EXIT
mkdir -p "$package_root/DEBIAN" "$package_root/opt/smt-check" "$package_root/usr/bin" "$package_root/usr/share/applications" "$package_root/usr/share/icons/hicolor/256x256/apps"
cp -a "$destination/." "$package_root/opt/smt-check/"
cp "$task_root/docs/app-icon.png" "$package_root/usr/share/icons/hicolor/256x256/apps/smt-check.png"
ln -s /opt/smt-check/SMT-CHECK "$package_root/usr/bin/smt-check"
cat > "$package_root/DEBIAN/control" <<EOF
Package: smt-check
Version: $version
Section: utils
Priority: optional
Architecture: $deb_arch
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
StartupWMClass=com.smtcheck.smt_check
EOF
chmod 755 "$package_root" "$package_root/DEBIAN" "$package_root/opt/smt-check/SMT-CHECK"
dpkg-deb --root-owner-group --build "$package_root" "$task_root/dist/SMT-CHECK-linux-$deb_arch.deb"
(cd -- "$task_root/dist" && sha256sum "SMT-CHECK-linux-$deb_arch.deb" > "SMT-CHECK-linux-$deb_arch.deb.sha256")
printf 'Desktop installer: %s\n' "$task_root/dist/SMT-CHECK-linux-$deb_arch.deb"
