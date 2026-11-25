#!/usr/bin/env bash
# Build APK phát hành (đã ký bằng khoá SmashZone) và chép sang web khách để tải / tự cập nhật.
#
#   bash scripts/release-android.sh
#
# Yêu cầu:
#   - Docker Desktop đang chạy (build trong image ghcr.io/cirruslabs/flutter:3.38.7)
#   - android/key.properties + android/app/smashzone-release.jks (bản sao lưu ở D:\SmashZone\keys)
#   - Đã tăng `version:` trong pubspec.yaml (vd 1.2.0+3 → tên 1.2.0, build 3)
#
# Sau khi chạy:
#   1. Deploy web khách (smashzone-web) để file APK lên mạng.
#   2. Vào dashboard → Phiên bản app → "Điền link trên web khách", nhập dung lượng in ở cuối, Phát hành.
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="${WEB_DIR:-$APP_DIR/../smashzone-web}"

if [ ! -f "$APP_DIR/android/key.properties" ] || [ ! -f "$APP_DIR/android/app/smashzone-release.jks" ]; then
  echo "Thiếu khoá ký: chép key.properties vào android/ và smashzone-release.jks vào android/app/ (từ D:\\SmashZone\\keys)." >&2
  exit 1
fi

VERSION_LINE=$(grep -E '^version:' "$APP_DIR/pubspec.yaml" | awk '{print $2}')
NAME="${VERSION_LINE%%+*}"
BUILD="${VERSION_LINE##*+}"
OUT="$APP_DIR/build/release-$NAME"
mkdir -p "$OUT"
echo "▶ Build SmashZone v$NAME (build $BUILD)…"

to_docker() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }

MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(to_docker "$APP_DIR"):/src:ro" \
  -v sz-gradle:/root/.gradle -v sz-pub:/root/.pub-cache \
  -v "$(to_docker "$OUT"):/out" \
  ghcr.io/cirruslabs/flutter:3.38.7 bash -c '
    set -e
    mkdir -p /work && cd /src
    tar --exclude=./build --exclude=./.dart_tool --exclude=./android/.gradle -cf - . | (cd /work && tar xf -)
    cd /work && flutter pub get >/dev/null
    flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64
    cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk /out/
    cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk /out/'

mkdir -p "$WEB_DIR/public/download"
for ABI in arm64-v8a armeabi-v7a; do
  cp "$OUT/app-$ABI-release.apk" "$WEB_DIR/public/download/smashzone-$NAME-$ABI.apk"
done

echo
echo "✔ Đã chép APK vào $WEB_DIR/public/download/"
for ABI in arm64-v8a armeabi-v7a; do
  F="$WEB_DIR/public/download/smashzone-$NAME-$ABI.apk"
  BYTES=$(wc -c < "$F" | tr -d ' ')
  awk -v n="$(basename "$F")" -v b="$BYTES" 'BEGIN { printf "  %-40s %.1f MB\n", n, b / 1048576 }'
done
echo
echo "Tiếp theo: deploy web khách, rồi phát hành v$NAME (build $BUILD) trong dashboard → Phiên bản app."
