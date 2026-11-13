#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🚀 Compilazione UniFlow in corso (Apple Silicon M2 / Swift 6)..."
mkdir -p build/UniFlow.app/Contents/MacOS
mkdir -p build/UniFlow.app/Contents/Resources

swiftc -O -parse-as-library \
    Sources/UniFlow/*.swift \
    Sources/UniFlow/*/*.swift \
    -o build/UniFlow.app/Contents/MacOS/UniFlow

cat << 'EOF' > build/UniFlow.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>it</string>
    <key>CFBundleExecutable</key>
    <string>UniFlow</string>
    <key>CFBundleIdentifier</key>
    <string>com.uniflow.macos</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>UniFlow</string>
    <key>CFBundleDisplayName</key>
    <string>UniFlow — Ecosistema Universitario</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.education</string>
</dict>
</plist>
EOF

echo "APPL????" > build/UniFlow.app/Contents/PkgInfo
chmod +x build/UniFlow.app/Contents/MacOS/UniFlow

echo "✅ UniFlow.app creata con successo in:"
echo "   $DIR/build/UniFlow.app"
echo ""
echo "Per avviarla subito, digita:"
echo "   open $DIR/build/UniFlow.app"
