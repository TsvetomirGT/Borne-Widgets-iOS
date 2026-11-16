#!/usr/bin/env bash
# Generate the Xcode project and build for a simulator.
# Usage: ./build.sh [simulator-udid-or-destination]
set -euo pipefail
cd "$(dirname "$0")"
DEST=${1:-"platform=iOS Simulator,name=iPhone 17"}
[[ "$DEST" == *=* ]] || DEST="id=$DEST"
xcodegen --quiet
mkdir -p .build
xcodebuild -project BorneWidgets.xcodeproj -scheme BorneWidgets \
  -destination "$DEST" -derivedDataPath .build/dd build > .build/xb.log 2>&1 \
  && echo "** BUILD SUCCEEDED **" \
  || { grep -E "error:" .build/xb.log | sort -u | head -30; echo "** BUILD FAILED ** (log: .build/xb.log)"; exit 1; }
