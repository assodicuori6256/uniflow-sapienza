#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "📱 ==================================================="
echo "   UniFlow — Generatore Pacchetto IPA per iPhone/iPad"
echo "======================================================"

# Verifica se l'SDK di iOS (iPhoneOS.sdk) è presente
IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)

if [ -z "$IPHONEOS_SDK" ]; then
    # Verifica se Xcode.app è installato ma xcode-select punta ai CommandLineTools
    if [ -d "/Applications/Xcode.app" ]; then
        echo "💡 Xcode.app trovato in /Applications, imposto il developer path..."
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
        IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)
    fi
fi

if [ -z "$IPHONEOS_SDK" ]; then
    echo ""
    echo "⚠️  ERRORE: SDK di iOS non trovato sul Mac."
    echo ""
    echo "Per produrre un file .ipa valido per iPhone e iPad, Apple richiede"
    echo "i framework di iOS (UIKit, CoreMotion, ecc.) contenuti nell'SDK 'iPhoneOS.sdk'."
    echo ""
    echo "Attualmente sul tuo Mac sono attivi solo i 'Command Line Tools' (che compilano per macOS)."
    echo ""
    echo "👉 COME RISOLVERE IN 2 PASSAGGI:"
    echo "1. Scarica gratuitamente Xcode dal Mac App Store:"
    echo "   https://apps.apple.com/it/app/xcode/id497799835"
    echo "2. Una volta completato il download, riesegui questo script:"
    echo "   ./build_ipa.sh"
    echo ""
    exit 1
fi

echo "✅ iOS SDK trovato: $IPHONEOS_SDK"

# Cartelle di output
BUILD_DIR="$DIR/build"
IPA_DIR="$BUILD_DIR/ipa_temp"
PAYLOAD_DIR="$IPA_DIR/Payload"
APP_DIR="$PAYLOAD_DIR/UniFlow.app"

rm -rf "$IPA_DIR" "$BUILD_DIR/UniFlow.ipa"
mkdir -p "$APP_DIR"

echo "🔨 Compilazione binario nativo arm64 per iPhone e iPad..."

# Trova tutti i file Swift
SWIFT_FILES=$(find Sources/UniFlow -name "*.swift" -type f)

# Compila con swiftc per architettura iOS arm64
xcrun swiftc \
    -target arm64-apple-ios16.0 \
    -sdk "$IPHONEOS_SDK" \
    -O \
    -whole-module-optimization \
    -parse-as-library \
    -emit-executable \
    -o "$APP_DIR/UniFlow" \
    $SWIFT_FILES

echo "📄 Generazione Info.plist e metadati per iOS/iPadOS..."

cat << 'EOF' > "$APP_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>it</string>
    <key>CFBundleDisplayName</key>
    <string>UniFlow</string>
    <key>CFBundleExecutable</key>
    <string>UniFlow</string>
    <key>CFBundleIdentifier</key>
    <string>it.aldocuko.uniflow</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>UniFlow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>16.0</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
</dict>
</plist>
EOF

echo "🎨 Generazione icone iOS per iPhone e iPad..."
if [ -f "Resources/AppIcon_1024.png" ]; then
    sips -z 120 120 Resources/AppIcon_1024.png --out "$APP_DIR/AppIcon60x60@2x.png" > /dev/null 2>&1 || true
    sips -z 180 180 Resources/AppIcon_1024.png --out "$APP_DIR/AppIcon60x60@3x.png" > /dev/null 2>&1 || true
    sips -z 152 152 Resources/AppIcon_1024.png --out "$APP_DIR/AppIcon76x76@2x~ipad.png" > /dev/null 2>&1 || true
    sips -z 167 167 Resources/AppIcon_1024.png --out "$APP_DIR/AppIcon83.5x83.5@2x~ipad.png" > /dev/null 2>&1 || true
    cp Resources/AppIcon_1024.png "$IPA_DIR/iTunesArtwork" || true
fi

echo "🔏 Firma del bundle dell'applicazione..."
codesign --force --sign - --timestamp=none "$APP_DIR" 2>/dev/null || true

echo "📦 Creazione del pacchetto UniFlow.ipa..."
cd "$IPA_DIR"
zip -qry "$BUILD_DIR/UniFlow.ipa" Payload iTunesArtwork 2>/dev/null || zip -qry "$BUILD_DIR/UniFlow.ipa" Payload

rm -rf "$IPA_DIR"

echo ""
echo "🎉 SUCCESS! File .ipa generato con successo:"
echo "   👉 $BUILD_DIR/UniFlow.ipa"
echo ""
echo "Puoi installarlo sul tuo iPhone/iPad tramite:"
echo "- AltStore / Sideloadly / TrollStore"
echo "- Oppure via Xcode -> Devices and Simulators"
echo "======================================================"
