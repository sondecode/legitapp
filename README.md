[![License](https://img.shields.io/github/license/sondecode/legitapp)](LICENSE.txt)
[![Latest release](https://img.shields.io/github/v/release/sondecode/legitapp)](https://github.com/sondecode/legitapp/releases/latest)
[![All releases](https://img.shields.io/github/downloads/sondecode/legitapp/total)](https://github.com/sondecode/legitapp/releases)

# LegitApp

LegitApp là ứng dụng macOS giúp cài đặt, cập nhật, gỡ bỏ và quản lý ứng dụng qua [Homebrew](https://brew.sh/) bằng giao diện trực quan, ưu tiên trải nghiệm tiếng Việt.

<img width="1362" height="1053" alt="image" src="https://github.com/user-attachments/assets/df94c6ce-7c30-418c-a860-7c7629faad45" />

<img width="309" height="389" alt="image" src="https://github.com/user-attachments/assets/db5f7c21-9930-4601-8b27-aa0e186e9c5a" />

Ứng dụng được fork và phát triển dựa trên [Applite](https://github.com/milanvarady/Applite), bổ sung danh mục dành cho người Việt, danh mục AI, quản lý services, menu bar và các công cụ đóng gói/phát hành phù hợp cho người dùng macOS tại Việt Nam.

## Mục Lục

- [Tính năng](#tính-năng)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Tải và cài đặt](#tải-và-cài-đặt)
- [Lưu ý về cảnh báo macOS](#lưu-ý-về-cảnh-báo-macos)
- [Cách sử dụng nhanh](#cách-sử-dụng-nhanh)
- [Dành cho lập trình viên](#dành-cho-lập-trình-viên)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Đóng góp](#đóng-góp)
- [Giấy phép](#giấy-phép)

## Tính Năng

- Cài đặt ứng dụng macOS bằng Homebrew Cask chỉ với một nút bấm.
- Cập nhật từng ứng dụng hoặc cập nhật hàng loạt các ứng dụng đã cài.
- Gỡ cài đặt ứng dụng, hỗ trợ `zap` để dọn thêm dữ liệu liên quan khi Homebrew hỗ trợ.
- Mở ứng dụng đã cài trực tiếp từ LegitApp.
- Xem thông tin chi tiết của cask: tên, mô tả, homepage, cảnh báo, trạng thái deprecated/disabled.
- Tìm kiếm nhanh trong catalog ứng dụng Homebrew.
- Sắp xếp kết quả theo lượt tải, độ khớp hoặc A-Z.
- Lọc ứng dụng ít phổ biến và ứng dụng bị disabled.
- Cache catalog để mở app nhanh hơn, sau đó tự refresh dữ liệu nền.
- Danh mục ứng dụng được tuyển chọn: trình duyệt, productivity, office, menu bar, utilities, creative tools, developer tools, virtualization, AI apps và nhóm dành cho người Việt.
- Hỗ trợ mô tả tiếng Việt cho các app trong `categories.json`.
- Hỗ trợ app chỉ dẫn tới website chính thức để người dùng tự tải và cài khi app không phù hợp cài qua Homebrew.
- Danh mục dành cho người Việt gồm các app phổ biến và bộ gõ tiếng Việt như OpenKey, EVKey, GoTiengViet.
- Danh mục AI Apps cho các công cụ AI phổ biến.
- Quản lý Homebrew Services: start, stop, restart từng service.
- Menu bar context hiển thị service đang chạy, app cần cập nhật và task đang hoạt động.
- Nút mở tất cả / tắt tất cả service ngay trong menu bar.
- Theo dõi tiến trình cài đặt, cập nhật, gỡ app theo thời gian thực.
- Hiển thị lỗi shell trong cửa sổ riêng để dễ debug.
- Import/export danh sách ứng dụng để di chuyển sang máy khác.
- Tự cài Homebrew riêng cho LegitApp nếu máy chưa có Homebrew.
- Kiểm tra Xcode Command Line Tools và Homebrew trước khi cho vào màn hình chính.
- Chờ Homebrew bootstrap Portable Ruby xong để tránh lỗi `brew vendor-install ruby already running`.
- Chọn dùng Homebrew có sẵn hoặc Homebrew riêng của LegitApp.
- Quản lý Homebrew: update, reinstall hoặc cài Homebrew riêng.
- Tùy chọn thư mục cài app tùy chỉnh.
- Tùy chọn bỏ quarantine khi cài app bằng Homebrew, dành cho người dùng hiểu rõ rủi ro.
- Hỗ trợ proxy hệ thống HTTP, HTTPS, SOCKS5.
- Hỗ trợ mirror Homebrew cho API, brew git remote, core git remote và bottle domain.
- Tùy chọn giao diện sáng/tối/theo hệ thống.
- Tùy chọn icon menu bar và giữ app chạy khi đóng cửa sổ.
- Kiểm tra cập nhật app qua Sparkle.
- Công cụ tạo DMG tiếng Việt trong `scripts/create-vietnamese-dmg.sh`.
- Script build package, self-sign và release phục vụ phát hành.
- Mã nguồn mở, miễn phí, không quảng cáo.

## Yêu Cầu Hệ Thống

- macOS 14 Sonoma trở lên.
- Kết nối Internet để tải Homebrew, catalog và ứng dụng.
- Xcode Command Line Tools. LegitApp sẽ hướng dẫn cài khi máy chưa có.
- Homebrew. Nếu máy chưa có, LegitApp có thể tự tạo một bản Homebrew riêng tại `~/Library/Application Support/LegitApp/homebrew`.

## Tải Và Cài Đặt

Tải bản mới nhất tại:

[Download LegitApp.dmg](https://github.com/sondecode/legitapp/releases/latest/download/LegitApp.dmg)

Sau khi tải:

1. Mở file `LegitApp.dmg`.
2. Kéo `LegitApp.app` vào thư mục `Applications`.
3. Mở LegitApp.
4. Chờ app cài hoặc kiểm tra các thành phần bắt buộc.
5. Khi setup hoàn tất, app mới chuyển vào màn hình chính.

## Lưu Ý Về Cảnh Báo macOS

Nếu app chưa được ký và notarize bằng Apple Developer ID, macOS có thể cảnh báo khi mở app tải từ Internet. Đây là cơ chế Gatekeeper của macOS.

Không có Apple Developer Program membership thì có thể self-sign hoặc ad-hoc sign để phục vụ test nội bộ, nhưng không thể tạo bản phân phối công khai hoàn toàn không cảnh báo Gatekeeper cho mọi người dùng.

Với bản tải thủ công, nếu bạn tin tưởng source:

1. Chuột phải hoặc Control-click vào `LegitApp.app`.
2. Chọn `Open`.
3. Xác nhận `Open` trong hộp thoại của macOS.

Hoặc vào `System Settings` -> `Privacy & Security` -> chọn `Open Anyway` cho LegitApp.

Chỉ dùng lệnh xoá quarantine khi bạn hiểu rõ rủi ro và chắc chắn file tải về là bản tin cậy:

```bash
xattr -dr com.apple.quarantine /Applications/LegitApp.app
```

Để phát hành không cảnh báo cho người dùng phổ thông, cần ký bằng Developer ID, bật hardened runtime, notarize với Apple và staple ticket vào app/DMG.

## Cách Sử Dụng Nhanh

### Cài App

1. Mở tab `Discover` hoặc chọn một danh mục ở sidebar.
2. Tìm app cần cài.
3. Nhấn `Install`.
4. Chờ tiến trình hoàn tất.

### Cập Nhật App

1. Mở mục `Updates`.
2. Chọn cập nhật từng app hoặc cập nhật tất cả.
3. Theo dõi tiến trình trong `Active Tasks` hoặc menu bar.

### Gỡ App

1. Mở mục `Installed`.
2. Chọn app cần gỡ.
3. Nhấn `Uninstall`.
4. Chọn `zap` nếu muốn dọn thêm dữ liệu liên quan và cask hỗ trợ.

### Quản Lý Services

1. Mở mục `Services`.
2. Start, stop hoặc restart từng service.
3. Gỡ cài đặt service khi không còn dùng; LegitApp sẽ dừng service trước rồi chạy `brew uninstall`.
4. Có thể thao tác nhanh từ menu bar.
5. Trong menu bar có nút mở tất cả và tắt tất cả service.

### Kế Hoạch Quản Lý Version Service

- Cho phép chọn version khi cài service, ví dụ `postgresql@16`, `postgresql@17`, `php@8.3`, `php@8.4`.
- Hiển thị version đang được link mặc định bằng `brew list --versions` và `brew info`.
- Thêm thao tác đặt version mặc định bằng `brew unlink <formula>` và `brew link --force --overwrite <formula@version>` khi phù hợp.
- Tự cập nhật shell profile như `~/.zshrc` bằng block được quản lý bởi LegitApp, ví dụ thêm `PATH`, `LDFLAGS`, `CPPFLAGS`, `PKG_CONFIG_PATH` theo version mặc định.
- Trước khi sửa `~/.zshrc`, tạo backup và chỉ cập nhật nội dung nằm giữa marker của LegitApp để không ghi đè cấu hình thủ công của người dùng.

### Di Chuyển Sang Máy Khác

1. Mở mục `App Migration`.
2. Export danh sách app đã cài.
3. Trên máy mới, import danh sách đó để cài lại.

## Dành Cho Lập Trình Viên

Clone project:

```bash
git clone https://github.com/sondecode/legitapp.git
cd legitapp
```

Mở bằng Xcode:

```bash
open LegitApp.xcodeproj
```

Build bằng command line:

```bash
xcodebuild -project LegitApp.xcodeproj -scheme Applite -destination 'platform=macOS' build
```

Tạo package tự ký và DMG:

```bash
./scripts/build-package.sh
```

Tạo DMG giao diện tiếng Việt từ app đã build:

```bash
./scripts/create-vietnamese-dmg.sh /path/to/LegitApp.app dist/LegitApp.dmg
```

Ký DMG nếu có Developer ID:

```bash
./scripts/create-vietnamese-dmg.sh /path/to/LegitApp.app dist/LegitApp.dmg --sign "Developer ID Application: Ten Cua Ban (TEAMID)"
```

Thiết lập Supabase Analytics:

1. Tạo project Supabase.
2. Chạy file SQL `docs/supabase-analytics.sql` trong Supabase SQL Editor.
3. Điền `LegitAppSupabaseURL` và `LegitAppSupabaseAnonKey` trong `LegitApp-Info.plist`.
4. App tự động gửi log ẩn danh tối thiểu để thống kê và hạn chế spam. Người dùng vẫn có thể tắt tại `Settings` -> `Analytics` -> `Send security and usage logs`.

Các view thống kê có sẵn:

- `legitapp_daily_active_users`: người dùng hoạt động hằng ngày.
- `legitapp_monthly_active_users`: người dùng hoạt động hằng tháng.
- `legitapp_download_clicks`: lượt bấm tải DMG trên website.
- `legitapp_top_installed_casks`: app được cài qua LegitApp nhiều nhất.
- `legitapp_uninstall_counts`: app bị gỡ qua LegitApp nhiều nhất.
- `legitapp_event_counts`: tổng số event theo loại.

Lượt tải DMG công khai vẫn nên lấy từ GitHub Releases hoặc bổ sung tracking click trên website tải app, vì app chưa chạy thì chưa thể gửi event vào Supabase.

Phát hành release và cập nhật appcast/Homebrew tap:

```bash
./scripts/release.sh <version> <path-to-dmg>
```

## Cấu Trúc Chính

- `LegitApp/Views`: giao diện SwiftUI.
- `LegitApp/Model`: model, cask manager, service manager, preferences.
- `LegitApp/Utilities`: shell runner, Homebrew setup, proxy, migration.
- `LegitApp/Resources/categories.json`: danh mục app, mô tả tiếng Việt và website-only apps.
- `Localizable.xcstrings`: string catalog.
- `LegitApp/Resources/*.lproj/Localizable.strings`: bản dịch theo ngôn ngữ.
- `scripts`: công cụ build, ký, tạo DMG và release.
- `docs`: landing page, appcast và tài liệu đóng góp.

## Công Nghệ Sử Dụng

- [Swift](https://developer.apple.com/swift/)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Homebrew](https://brew.sh/)
- [Sparkle](https://sparkle-project.org/) cho cập nhật app.
- [Kingfisher](https://github.com/onevcat/Kingfisher) cho tải và cache icon.
- [ButtonKit](https://github.com/Dean151/ButtonKit)
- [DebouncedOnChange](https://github.com/Tunous/DebouncedOnChange)
- [SwiftUI-Shimmer](https://github.com/markiv/SwiftUI-Shimmer)
- [CircularProgressSwiftUI](https://github.com/ArnavMotwani/CircularProgressSwiftUI)
- [Ifrit](https://github.com/ukushu/Ifrit)

## Đóng Góp

LegitApp hoan nghênh đóng góp từ cộng đồng, đặc biệt là:

- Bổ sung app hữu ích cho người Việt.
- Viết hoặc chỉnh mô tả tiếng Việt cho app.
- Thêm app AI mới.
- Cải thiện localization.
- Báo lỗi Homebrew, service, proxy, DMG hoặc Gatekeeper.
- Tối ưu hiệu năng load catalog và menu bar.

Xem thêm tại [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Liên Hệ Và Hỗ Trợ

- GitHub Issues: [sondecode/legitapp/issues](https://github.com/sondecode/legitapp/issues)
- Email: [sondecode@gmail.com](mailto:sondecode@gmail.com)

## Giấy Phép

LegitApp được phát hành theo giấy phép [MIT](LICENSE.txt).

Dự án này được fork và phát triển dựa trên mã nguồn của [Applite](https://github.com/milanvarady/Applite) bởi Milán Várady.
