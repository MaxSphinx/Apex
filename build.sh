#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# APEX Build & Packaging Pipeline
# Targets Apple Silicon macOS 14.0+ (Swift 6)
# ==============================================================================

APP_NAME="Apex"
VERSION="1.0.0"
BUNDLE_ID="com.maxsphinx.apex"
BUILD_DIR="$(pwd)/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}-arm64.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
ZIP_NAME="${APP_NAME}-${VERSION}-arm64.zip"
ZIP_PATH="${BUILD_DIR}/${ZIP_NAME}"

echo "=================================================="
echo "⚡️ Building ${APP_NAME} v${VERSION} for Apple Silicon"
echo "=================================================="

# Select macOS SDK (fallback to active CommandLineTools SDK if 26.5 not present)
if [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]; then
    export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
elif [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" ]; then
    export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 1. Compile Release Binary with SwiftPM
echo "==> Compiling optimized arm64 release binary..."
swift build -c release --triple arm64-apple-macosx14.0

BIN_PATH="$(swift build -c release --triple arm64-apple-macosx14.0 --show-bin-path)/${APP_NAME}"
if [ ! -f "${BIN_PATH}" ]; then
    # Fallback to standard release path
    BIN_PATH="$(pwd)/.build/release/${APP_NAME}"
fi

echo "Binary compiled at: ${BIN_PATH}"

# 2. Assemble .app Bundle
echo "==> Assembling ${APP_NAME}.app bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Sources/ApexResources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
echo "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

if [ -f "Sources/ApexResources/AppIcon.icns" ]; then
    cp "Sources/ApexResources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# 3. Codesign Bundle
echo "==> Signing ${APP_NAME}.app with local ad-hoc identity..."
codesign --force --deep --sign - --options runtime "${APP_BUNDLE}"
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"

# 4. Create Distributable ZIP Archive
echo "==> Archiving ${ZIP_NAME}..."
(cd "${BUILD_DIR}" && zip -q -r "${ZIP_NAME}" "${APP_NAME}.app")

# 5. Build Polished DMG with Applications Symlink
echo "==> Packaging ${DMG_NAME}..."
DMG_STAGING="${BUILD_DIR}/dmg_staging"
mkdir -p "${DMG_STAGING}"
cp -R "${APP_BUNDLE}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

rm -rf "${DMG_STAGING}"

# 6. Generate Checksums
echo "==> Generating SHA-256 checksums..."
SHA256_DMG=$(shasum -a 256 "${DMG_PATH}" | awk '{print $1}')
SHA256_ZIP=$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')

echo "${SHA256_DMG}  ${DMG_NAME}" > "${BUILD_DIR}/checksums.txt"
echo "${SHA256_ZIP}  ${ZIP_NAME}" >> "${BUILD_DIR}/checksums.txt"

echo "=================================================="
echo "✅ Build Successful!"
echo "   Bundle:   ${APP_BUNDLE}"
echo "   DMG:      ${DMG_PATH}"
echo "   ZIP:      ${ZIP_PATH}"
echo "   DMG SHA:  ${SHA256_DMG}"
echo "   ZIP SHA:  ${SHA256_ZIP}"
echo "=================================================="
