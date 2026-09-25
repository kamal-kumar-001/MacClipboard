#!/bin/bash

set -e

APP_NAME="MacClipboard"
BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
SHAREABLE_DMG="$PWD/$APP_NAME.dmg"

echo "Building $APP_NAME..."

mkdir -p "$BUILD_DIR"

DEVELOPER_DIR_PATH="$(xcode-select -p 2>/dev/null || true)"

if [[ "$DEVELOPER_DIR_PATH" == */Xcode.app/Contents/Developer ]]; then
    swift build -c release
else
    echo "Full Xcode is not selected; compiling with Command Line Tools..."
    swiftc \
        -module-cache-path .build/module-cache \
        Sources/MacClipboard/*.swift \
        Sources/MacClipboard/Models/*.swift \
        Sources/MacClipboard/Services/*.swift \
        Sources/MacClipboard/Views/*.swift \
        -O \
        -o "$BUILD_DIR/$APP_NAME" \
        -framework AppKit \
        -framework SwiftUI \
        -framework CryptoKit \
        -framework ApplicationServices \
        -framework Carbon
fi

echo "Creating app bundle..."

rm -rf "$APP_DIR"

mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

ICONSET_DIR=".build/MacClipboard.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

swiftc \
    -module-cache-path .build/module-cache \
    Scripts/create-app-icon.swift \
    -o .build/create-app-icon \
    -framework AppKit \
    -framework ImageIO
.build/create-app-icon "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/MacClipboard.icns"

cp "$BUILD_DIR/$APP_NAME" \
   "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC
"-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>

    <key>CFBundleDisplayName</key>
    <string>MacClipboard</string>

    <key>CFBundleExecutable</key>
    <string>MacClipboard</string>

    <key>CFBundleIdentifier</key>
    <string>com.example.MacClipboard</string>

    <key>CFBundleName</key>
    <string>MacClipboard</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleIconFile</key>
    <string>MacClipboard</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>

    <key>CFBundleVersion</key>
    <string>1</string>

    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>

    <key>LSUIElement</key>
    <true/>

</dict>
</plist>
EOF

echo ""
echo "Build complete:"
echo "$APP_DIR"
echo ""

echo "Opening app..."

open "$APP_DIR" 2>/dev/null || true

if command -v hdiutil >/dev/null 2>&1; then
    rm -f "$DMG_PATH"
    DMG_STAGE=".build/dmg-stage"
    rm -rf "$DMG_STAGE"
    mkdir -p "$DMG_STAGE"
    cp -R "$APP_DIR" "$DMG_STAGE/"
    cp "$APP_DIR/Contents/Resources/MacClipboard.icns" "$DMG_STAGE/.VolumeIcon.icns"
    ln -s /Applications "$DMG_STAGE/Applications"
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$DMG_STAGE" \
        -ov \
        -format UDZO \
        "$DMG_PATH" >/dev/null

    cp "$DMG_PATH" "$SHAREABLE_DMG"

    echo "DMG created:"
    echo "$DMG_PATH"
    echo "Shareable download:"
    echo "$SHAREABLE_DMG"
fi
