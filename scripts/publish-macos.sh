#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RID="${1:-osx-arm64}"

case "$RID" in
  osx-arm64|osx-x64) ;;
  *)
    echo "Usage: $0 [osx-arm64|osx-x64]" >&2
    exit 2
    ;;
esac

if [[ ! -f "$ROOT_DIR/libbass.dylib" ]]; then
  cat >&2 <<'EOF'
Missing libbass.dylib.
Download the matching macOS BASS library from Un4seen and place it beside
MajdataEdit-Neo.csproj before publishing.
EOF
  exit 3
fi

DOTNET="${DOTNET:-dotnet}"
SELF_CONTAINED="${SELF_CONTAINED:-false}"
USE_EXISTING_BUILD="${USE_EXISTING_BUILD:-false}"
PUBLISH_DIR="$ROOT_DIR/artifacts/publish/$RID"
APP_DIR="$ROOT_DIR/artifacts/MajdataEdit-Neo-$RID.app"

rm -rf "$PUBLISH_DIR" "$APP_DIR"
mkdir -p "$PUBLISH_DIR" "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

if [[ "$USE_EXISTING_BUILD" == "true" ]]; then
  EXISTING_BUILD_DIR="$ROOT_DIR/bin/Release/net9.0"
  if [[ ! -f "$EXISTING_BUILD_DIR/MajdataEdit-Neo" ]]; then
    echo "Missing existing build at $EXISTING_BUILD_DIR. Run dotnet build first." >&2
    exit 4
  fi
  cp -R "$EXISTING_BUILD_DIR"/. "$PUBLISH_DIR"/
else
  PUBLISH_ARGS=(
    publish "$ROOT_DIR/MajdataEdit-Neo.csproj"
    --configuration Release
    --runtime "$RID"
    --self-contained "$SELF_CONTAINED"
    --output "$PUBLISH_DIR"
  )

  if [[ "$SELF_CONTAINED" != "true" ]]; then
    PUBLISH_ARGS+=(--no-restore)
  fi

  "$DOTNET" "${PUBLISH_ARGS[@]}"
fi

cp -R "$PUBLISH_DIR"/. "$APP_DIR/Contents/MacOS/"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>MajdataEdit Neo</string>
  <key>CFBundleExecutable</key>
  <string>MajdataEdit-Neo</string>
  <key>CFBundleIdentifier</key>
  <string>net.majdata.edit.neo</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>MajdataEdit Neo</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>0.1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
</dict>
</plist>
PLIST

echo "Created $APP_DIR"
