#!/bin/bash
# PeakTimeMonitor — Build & Launch script
# Usage: ./build.sh [--release]
set -e

CONFIG="${1:-Debug}"
if [ "$1" = "--release" ]; then CONFIG="Release"; fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔨 Building PeakTimeMonitor ($CONFIG)..."

# Generate Xcode project if needed
if [ ! -d "PeakTimeMonitor.xcodeproj" ]; then
    echo "→ Generating Xcode project..."
    xcodegen generate
fi

# Detect Xcode path
if [ -d "/Applications/Xcode.app" ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

# Clean xattr (avoid code sign issues)
xattr -cr PeakTimeMonitorApp 2>/dev/null || true

# Build
xcodebuild \
    -project PeakTimeMonitor.xcodeproj \
    -scheme PeakTimeMonitor \
    -configuration "$CONFIG" \
    -derivedDataPath .build/xcode \
    build

# Kill existing instance
pkill -f PeakTimeMonitor 2>/dev/null || true

# Launch
APP=".build/xcode/Build/Products/$CONFIG/PeakTimeMonitor.app"
echo "✅ Build done — launching..."
open "$APP"

echo "PeakTimeMonitor is running (check menu bar for 🚦 icon)"
