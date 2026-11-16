#!/usr/bin/env bash
# Build an IPA for sideloading (AltStore, SideStore, Sideloadly).
#
# The app is ad-hoc signed: no Apple developer account involved. Sideloading
# tools re-sign it with the installer's own Apple ID; they read the embedded
# entitlements to know which App Group to register, so we embed them here.
#
# Uses the public BUNDLE_PREFIX from Base.xcconfig, never the one in
# Local.xcconfig, so personal identifiers don't end up in a published build.
#
# Usage: ./release-ipa.sh            -> .build/Borne.ipa
set -euo pipefail
cd "$(dirname "$0")"

PREFIX=dev.borne
GROUP="group.$PREFIX.bornewidgets"
OUT=.build/release
ARCHIVE="$OUT/Borne.xcarchive"

rm -rf "$OUT" && mkdir -p "$OUT"
xcodegen --quiet

echo "Archiving (log: $OUT/archive.log)…"
xcodebuild -project BorneWidgets.xcodeproj -scheme BorneWidgets \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" -derivedDataPath .build/dd-release archive \
  BUNDLE_PREFIX="$PREFIX" DEVELOPMENT_TEAM= \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
  > "$OUT/archive.log" 2>&1 \
  || { grep -E "error:" "$OUT/archive.log" | sort -u | head -30; echo "** ARCHIVE FAILED **"; exit 1; }

APP="$ARCHIVE/Products/Applications/Borne.app"
[[ -d "$APP" ]] || { echo "Borne.app missing from archive"; exit 1; }

# Entitlements shared by the app and the widget extension.
ENT="$OUT/entitlements.plist"
cat > "$ENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array><string>$GROUP</string></array>
</dict>
</plist>
EOF

# Sign inside-out: embedded frameworks, then extensions, then the app.
shopt -s nullglob
for fw in "$APP"/Frameworks/*; do codesign -f -s - "$fw"; done
for ext in "$APP"/PlugIns/*.appex; do codesign -f -s - --entitlements "$ENT" "$ext"; done
codesign -f -s - --entitlements "$ENT" "$APP"

mkdir -p "$OUT/ipa/Payload"
cp -R "$APP" "$OUT/ipa/Payload/"
(cd "$OUT/ipa" && zip -qry ../../Borne.ipa Payload)
rm -rf "$OUT/ipa"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Info.plist")
echo "** IPA READY ** .build/Borne.ipa (version $VERSION, $(du -h .build/Borne.ipa | cut -f1))"
