#!/usr/bin/env zsh
set -euo pipefail

# Tao DMG cai dat LegitApp voi giao dien Finder tieng Viet.
#
# Usage:
#   scripts/create-vietnamese-dmg.sh <path-to-LegitApp.app> [output-dmg] [--sign "Developer ID Application: ..."]
#
# Example:
#   scripts/create-vietnamese-dmg.sh \
#     /tmp/LegitAppDerivedData/Build/Products/Release/LegitApp.app \
#     dist/LegitApp.dmg

APP_PATH="${1:-}"
OUTPUT_DMG="${2:-dist/LegitApp.dmg}"
SIGN_IDENTITY=""

if [[ $# -ge 4 && "${3:-}" == "--sign" ]]; then
  SIGN_IDENTITY="$4"
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" || "${APP_PATH:e}" != "app" ]]; then
  print -u2 "Loi: Hay truyen duong dan toi LegitApp.app"
  print -u2 "Vi du: scripts/create-vietnamese-dmg.sh /path/to/LegitApp.app dist/LegitApp.dmg"
  exit 64
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  print -u2 "Loi: Khong tim thay hdiutil."
  exit 69
fi

APP_PATH="${APP_PATH:A}"
OUTPUT_DMG="${OUTPUT_DMG:A}"
APP_NAME="${APP_PATH:t}"
VOLUME_NAME="Cài đặt LegitApp"
WINDOW_WIDTH=720
WINDOW_HEIGHT=440
ICON_SIZE=104

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/legitapp-dmg.XXXXXX")"
STAGING_DIR="$WORKDIR/staging"
RW_DMG="$WORKDIR/legitapp-rw.dmg"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_PNG="$BACKGROUND_DIR/background.png"
MOUNT_DIR=""

cleanup() {
  if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet -force >/dev/null 2>&1 || true
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

print "Dang chuan bi thu muc DMG..."
rm -f "$OUTPUT_DMG"
mkdir -p "$STAGING_DIR" "$BACKGROUND_DIR" "${OUTPUT_DMG:h}"
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME"
ln -s /Applications "$STAGING_DIR/Applications"

generate_background() {
  if ! command -v swift >/dev/null 2>&1; then
    print "Khong tim thay swift, bo qua anh nen DMG."
    return
  fi

  local generator="$WORKDIR/create_background.swift"
  cat > "$generator" <<'SWIFT'
import AppKit
import Foundation

let outputPath = CommandLine.arguments[1]
let width: CGFloat = 720
let height: CGFloat = 440
let rect = NSRect(x: 0, y: 0, width: width, height: height)

let image = NSImage(size: rect.size)
image.lockFocus()

NSColor(calibratedRed: 0.965, green: 0.972, blue: 0.955, alpha: 1).setFill()
rect.fill()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.988, green: 0.914, blue: 0.792, alpha: 1),
    NSColor(calibratedRed: 0.741, green: 0.878, blue: 0.839, alpha: 1)
])!
gradient.draw(in: rect, angle: -32)

let accent = NSColor(calibratedRed: 0.052, green: 0.196, blue: 0.235, alpha: 1)
let panel = NSBezierPath(roundedRect: NSRect(x: 68, y: 72, width: 584, height: 296), xRadius: 34, yRadius: 34)
NSColor.white.withAlphaComponent(0.72).setFill()
panel.fill()
accent.withAlphaComponent(0.08).setStroke()
panel.lineWidth = 1
panel.stroke()

let title = "Cài đặt LegitApp"
let subtitle = "Kéo LegitApp vào thư mục Applications để cài đặt"
let hint = "Quản lý ứng dụng macOS bằng Homebrew, giao diện tiếng Việt."

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

title.draw(
    in: NSRect(x: 80, y: 295, width: 560, height: 44),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 31, weight: .bold),
        .foregroundColor: accent,
        .paragraphStyle: paragraph
    ]
)

subtitle.draw(
    in: NSRect(x: 100, y: 259, width: 520, height: 30),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
        .foregroundColor: accent.withAlphaComponent(0.82),
        .paragraphStyle: paragraph
    ]
)

hint.draw(
    in: NSRect(x: 112, y: 102, width: 496, height: 28),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .regular),
        .foregroundColor: accent.withAlphaComponent(0.72),
        .paragraphStyle: paragraph
    ]
)

let arrowAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 44, weight: .thin),
    .foregroundColor: accent.withAlphaComponent(0.36),
    .paragraphStyle: paragraph
]
"→".draw(in: NSRect(x: 325, y: 186, width: 70, height: 54), withAttributes: arrowAttributes)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Khong tao duoc anh nen DMG\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
SWIFT

  swift "$generator" "$BACKGROUND_PNG"
}

generate_background

print "Dang tao DMG tam..."
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$RW_DMG" >/dev/null

print "Dang sap xep cua so Finder..."
ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")"
DEVICE="$(print "$ATTACH_OUTPUT" | awk '/\/Volumes\// { print $1; exit }')"
MOUNT_DIR="$(print "$ATTACH_OUTPUT" | sed -n 's#^.*\(/Volumes/.*\)$#\1#p' | head -n 1)"

if [[ -z "$DEVICE" || -z "$MOUNT_DIR" ]]; then
  print -u2 "Loi: Khong mount duoc DMG tam."
  exit 1
fi

if command -v SetFile >/dev/null 2>&1; then
  SetFile -a V "$MOUNT_DIR/.background" || true
else
  chflags hidden "$MOUNT_DIR/.background" || true
fi

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 120 + $WINDOW_WIDTH, 120 + $WINDOW_HEIGHT}
    set viewOptions to icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to $ICON_SIZE
    set background picture of viewOptions to file ".background:background.png"
    set position of item "$APP_NAME" of container window to {200, 230}
    set position of item "Applications" of container window to {520, 230}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DEVICE" -quiet
MOUNT_DIR=""

print "Dang nen DMG..."
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_DMG" >/dev/null
hdiutil internet-enable -no "$OUTPUT_DMG" >/dev/null || true

if [[ -n "$SIGN_IDENTITY" ]]; then
  print "Dang ky DMG..."
  codesign --force --sign "$SIGN_IDENTITY" "$OUTPUT_DMG"
fi

print "Hoan tat: $OUTPUT_DMG"
