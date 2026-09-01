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
BUNDLE_DOTNET="${BUNDLE_DOTNET:-false}"
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

if [[ "$BUNDLE_DOTNET" == "true" ]]; then
  # A framework-dependent apphost only searches system locations when started
  # by Finder. Bundle the runtime and use a relative launcher so the .app can
  # be opened without a separate .NET installation.
  DOTNET_ROOT_DIR="${DOTNET_ROOT:-}"
  if [[ -z "$DOTNET_ROOT_DIR" || ! -x "$DOTNET_ROOT_DIR/dotnet" ]]; then
    echo "BUNDLE_DOTNET=true requires DOTNET_ROOT to point to a .NET installation." >&2
    exit 5
  fi
  mkdir -p "$APP_DIR/Contents/MacOS/dotnet-root"
  cp -R "$DOTNET_ROOT_DIR/host" "$APP_DIR/Contents/MacOS/dotnet-root/"
  cp -R "$DOTNET_ROOT_DIR/shared" "$APP_DIR/Contents/MacOS/dotnet-root/"
  cp "$DOTNET_ROOT_DIR/dotnet" "$APP_DIR/Contents/MacOS/dotnet-root/dotnet"
  mv "$APP_DIR/Contents/MacOS/MajdataEdit-Neo" "$APP_DIR/Contents/MacOS/MajdataEdit-Neo.bin"
  cat > "$APP_DIR/Contents/MacOS/MajdataEdit-Neo" <<'LAUNCHER'
#!/bin/sh
set -eu
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export DOTNET_ROOT="$HERE/dotnet-root"
exec "$HERE/MajdataEdit-Neo.bin" "$@"
LAUNCHER
  chmod +x "$APP_DIR/Contents/MacOS/MajdataEdit-Neo"
fi

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
