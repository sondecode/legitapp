#!/usr/bin/env zsh
set -euo pipefail

# ==============================================================================
# LegitApp Full Build & Package Script
# Quy trình: Build .app -> Self-Sign -> Create Vietnamese DMG
# ==============================================================================

# Cấu hình đường dẫn
PROJECT_NAME="LegitApp"
SCHEME="Applite" # Vẫn giữ scheme cũ để build, hoặc bạn có thể đổi trong Xcode sau
BUILD_DIR="$PWD/build"
APP_PATH="$BUILD_DIR/Release/$PROJECT_NAME.app"
DIST_DIR="$PWD/dist"
OUTPUT_DMG="$DIST_DIR/LegitApp.dmg"

echo "🏗️  Bắt đầu quy trình đóng gói $PROJECT_NAME..."

# 1. Dọn dẹp thư mục cũ
echo "🧹 Đang dọn dẹp..."
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 2. Build ứng dụng bằng xcodebuild
echo "🔨 Đang build ứng dụng (Release)..."
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
           -scheme "$SCHEME" \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           clean build | xcbeautify || xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" -configuration Release -derivedDataPath "$BUILD_DIR" clean build

# Kiểm tra xem app có tồn tại không
if [[ ! -d "$APP_PATH" ]]; then
    # Thử tìm ở đường dẫn mặc định của xcodebuild nếu đường dẫn trên sai
    APP_PATH=$(find "$BUILD_DIR" -name "$PROJECT_NAME.app" -type d | head -n 1)
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
    echo "❌ Lỗi: Không tìm thấy file .app sau khi build."
    exit 1
fi

echo "✅ Đã build thành công tại: $APP_PATH"

# 3. Ký Ad-Hoc (Bypass Gatekeeper)
echo "✍️  Đang ký Ad-Hoc cho app..."
./scripts/self-sign.sh "$APP_PATH"

# 4. Đóng gói DMG với giao diện tiếng Việt
echo "📦 Đang đóng gói DMG..."
if [[ -f "./scripts/create-vietnamese-dmg.sh" ]]; then
    ./scripts/create-vietnamese-dmg.sh "$APP_PATH" "$OUTPUT_DMG"
else
    echo "⚠️  Không tìm thấy scripts/create-vietnamese-dmg.sh, đang dùng hdiutil cơ bản..."
    hdiutil create -volname "$PROJECT_NAME" -srcfolder "$APP_PATH" -ov -format UDZO "$OUTPUT_DMG"
fi

echo ""
echo "===================================================="
echo "🎉 HOÀN TẤT!"
echo "📂 File cài đặt: $OUTPUT_DMG"
echo "💡 Bạn có thể dùng file này để upload lên GitHub."
echo "===================================================="
