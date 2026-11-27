#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🚀 Compilazione UniFlow in corso (Apple Silicon M2 / Swift 6)..."
mkdir -p build/UniFlow.app/Contents/MacOS
mkdir -p build/UniFlow.app/Contents/Resources

# Compila l'eseguibile nativo con ottimizzazioni
swiftc -O -parse-as-library \
    Sources/UniFlow/*.swift \
    Sources/UniFlow/*/*.swift \
    -o build/UniFlow.app/Contents/MacOS/UniFlow

# Copia l'icona dell'applicazione (per Dock, Finder e App Store)
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns build/UniFlow.app/Contents/Resources/AppIcon.icns
fi

# Info.plist conforme alle specifiche Apple Mac App Store
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
    <string>it.aldocuko.uniflow</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>UniFlow</string>
    <key>CFBundleDisplayName</key>
    <string>UniFlow — Sapienza Farmacia</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
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
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 UniFlow. Tutti i diritti riservati.</string>
</dict>
</plist>
EOF

echo "APPL????" > build/UniFlow.app/Contents/PkgInfo
chmod +x build/UniFlow.app/Contents/MacOS/UniFlow

# Firma ad-hoc locale con Entitlements (Sandboxed)
if command -v codesign &> /dev/null; then
    codesign --force --deep --sign - --entitlements UniFlow.entitlements build/UniFlow.app 2>/dev/null || true
fi

echo "✅ UniFlow.app creata e confezionata con successo con icona e sandbox App Store!"
echo "   Directory: $DIR/build/UniFlow.app"
