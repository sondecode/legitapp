#!/usr/bin/env zsh
set -euo pipefail

# ==============================================================================
# LegitApp Self-Signing Tool (Ad-Hoc)
# Giúp ký ứng dụng để vượt qua Gatekeeper mà không cần trả phí Apple Developer.
# ==============================================================================

APP_PATH="${1:-}"

if [[ -z "$APP_PATH" ]]; then
    echo "❌ Lỗi: Thiếu đường dẫn tới app."
    echo "Sử dụng: $0 path/to/LegitApp.app"
    exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "❌ Lỗi: Không tìm thấy ứng dụng tại $APP_PATH"
    exit 1
fi

echo "🚀 Đang bắt đầu ký LegitApp (Ad-Hoc)..."

# 1. Loại bỏ các thuộc tính mở rộng (quarantine) - Quan trọng để bypass Gatekeeper
echo "🧹 Loại bỏ thuộc tính 'quarantine'..."
sudo xattr -rd com.apple.quarantine "$APP_PATH" || true

# 2. Xóa chữ ký cũ (nếu có)
echo "🗑️ Xóa chữ ký cũ..."
codesign --remove-signature "$APP_PATH"

# 3. Ký lại toàn bộ các thành phần bên trong (Deep scan)
# Sử dụng dấu gạch ngang '-' để chỉ định ad-hoc signing (không cần Apple ID)
# --force: Ghi đè chữ ký cũ
# --deep: Ký cả các thư viện, framework bên trong
# --options runtime: Bật Hardened Runtime (tùy chọn, ad-hoc có thể bỏ qua nhưng nên có)
echo "✍️ Đang thực hiện ký Ad-Hoc..."
codesign --force --deep --sign - "$APP_PATH"

# 4. Kiểm tra chữ ký
echo "🔍 Kiểm tra lại chữ ký..."
codesign --verify --deep --strict "$APP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Hoàn tất! LegitApp đã được ký và sẵn sàng khởi chạy."
    echo "💡 Lưu ý: Nếu vẫn bị lỗi, người dùng có thể cần chạy lệnh 'spctl --add' cho app này."
else
    echo "❌ Lỗi: Quá trình ký không thành công."
    exit 1
fi
