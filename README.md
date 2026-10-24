# Emoji Mask iOS (Swift & SwiftUI) 🎭✨

Ứng dụng **Emoji Mask iOS** được chuyển đổi và tối ưu hoàn chỉnh từ phiên bản **EmojiMask-ADR (Android)** sang nền tảng **iOS bằng ngôn ngữ Swift & SwiftUI thuần túy**, tận dụng sức mạnh xử lý phần cứng của Apple với **AVFoundation**, **Vision Framework (Apple AI)** và **CoreGraphics**.

Dự án sẵn sàng 100% để mở bằng **Xcode**, cắm máy thật iPhone hoặc chạy trên Simulator và build không phát sinh lỗi.

---

## 🌟 Tính Năng Nổi Bật (Full Features từ ADR)

### 1. 18 Mặt Nạ AR Emoji Đầy Đủ & Độc Quyền
Bao gồm toàn bộ 18 hiệu ứng mặt nạ với chuyển động động học thời gian thực:
1. 😀 **Grinning (Mỉm Cười)**: Khuôn mặt vàng Apple 3D chuẩn tỉ lệ vàng.
2. 😂 **Joy (Cười Ra Nước Mắt)**: Vệt nước mắt cười toả ra 2 bên đuôi mắt với đốm sáng bóng.
3. 🐱 **Cat (Mặt Mèo)**: Đôi tai mèo vàng viền hồng 3D, râu mèo 2 bên má và mũi mèo hồng nhỏ xinh.
4. 😍 **Heart Eyes (Mắt Trái Tim)**: Mắt trái tim hồng đập nhịp theo biểu cảm cười (pulsing).
5. 😘 **Blowing Kiss (Hôn Gió)**: Môi chu hôn kết hợp đàn trái tim bay lượn ngộ nghĩnh.
6. 😉 **Wink (Nháy Mắt)**: Nháy mắt trái/phải linh hoạt theo mắt thật của người dùng.
7. 😱 **Scream (Hét Kinh Hoàng)**: Gradient xanh lam, 2 bàn tay ôm má và miệng há dài kinh ngạc.
8. 😎 **Cool (Kính Ngầu)**: Kính mát đen bóng bẩy với đường vệt sáng phản quang.
9. 😭 **Crying (Khóc Ròng)**: Dòng nước mắt xanh biếc chảy xuống hai gò má.
10. 😡 **Angry (Tức Giận)**: Gradient lửa đỏ rực, lông mày xếch cau có và má ửng hồng phẫn nộ.
11. 🤪 **Zany (Hài Hước)**: Hai mắt so le tinh nghịch, nụ cười nhếch mép hóm hỉnh.
12. 🤩 **Star-Struck (Mắt Ngôi Sao)**: Đôi mắt sao vàng xoay 360 độ lấp lánh.
13. 🥳 **Party (Tiệc Tùng)**: Mũ chóp sinh nhật tím gắn quả bông vàng pom-pom.
14. 🤖 **Robot (Người Máy)**: Đầu kim loại vuông bo góc, ăng-ten bóng đèn đỏ và miệng lưới kim loại.
15. 👽 **Alien (Người Ngoài Hành Tinh)**: Đầu xanh lục tam giác ngược và đôi mắt đen to huyền bí.
16. 🤡 **Clown (Chú Hề)**: Mặt trắng phấn, mũi đỏ tròn và 4 búi tóc cam xoăn bồng bềnh.
17. 😈 **Devil (Ác Quỷ)**: Tím bóng đêm ma mị với cặp sừng ác quỷ cong nhọn.
18. 😷 **Mask (Khẩu Trang)**: Khẩu trang y tế màu xanh ngọc với đường nếp gấp 3D chân thực.

---

### 2. Hai Chế Độ Hiển Thị Thông Minh
Chuyển đổi tức thì bằng 1 chạm trên thanh công cụ:
* **🎭 AR Cutout Mode (Mặt Nạ AR Khoét Lỗ)**:
  - Form mặt 3D ôm sát viền cằm, gò má và thái dương của người dùng.
  - Sử dụng công nghệ Blend Mode `.clear` của CoreGraphics để **khoét lỗ hốc mắt và khuôn miệng**.
  - **Lộ trọn vẹn mắt thật nhấp nháy, nụ cười và lè lưỡi thật** của người dùng qua mặt nạ một cách sống động.
* **🎨 2D Cartoon Mode (Hoạt Hình 2D)**:
  - Toàn bộ khuôn mặt hoạt hình Apple Emoji 3D sống động.
  - Mắt nhắm mở, miệng mở há khoang họng, hàm răng trắng và lưỡi hồng chuyển động theo cơ mặt thật.

---

### 3. Apple Vision Facial Expression Tracking & FaceSmoother
* Tự động phân tích biểu cảm khuôn mặt 60 FPS:
  - **Tỉ lệ nháy mắt (EAR)** cho mắt trái và mắt phải riêng biệt.
  - **Tỉ lệ cười (Smile Ratio)** & chu môi hôn (Kissing / Pucker).
  - **Độ mở miệng (Mouth Opening Ratio)** & há to.
  - **Cau mày tức giận (Brow Furrow)** & nhướng mày ngạc nhiên (Brow Raise).
  - **Góc nghiêng 3D (Pitch, Yaw, Roll)** điều chỉnh phối cảnh mặt nạ xoay theo đầu người dùng.
* Bộ lọc thuật toán **FaceSmoother (Double Exponential Smoothing)** giúp loại bỏ hoàn toàn hiện tượng rung lắc/giật lag khung hình, cho chuyển động mượt mà như bơ.

---

### 4. Đầy Đủ Chức Năng Camera & Điều Khiển
* **Đổi Camera (Flip Camera)**: Chuyển đổi linh hoạt giữa Camera trước (Selfie) và Camera sau.
* **Đèn Flash / Đèn Pin**: 3 chế độ (Auto / Bật / Tắt).
* **Nút Chụp Siêu Thực (Haptic Shutter)**: Hiệu ứng chớp sáng màn hình và rung xúc giác `UIImpactFeedbackGenerator`.
* **Hỗ Trợ Simulator**: Tích hợp sẵn bộ mô phỏng cử động mặt chân thực khi chạy trên Xcode Simulator không có webcam thật.

---

### 5. Xem Lại & Xuất Ảnh Chụp (Photo Preview & Export)
* Ghép mặt nạ vector có độ phân giải cao trực tiếp lên ảnh camera gốc (`ImageCompositor`).
* **Lưu vào Thư Viện Ảnh (Photos)**: Tự động lưu vào album riêng mang tên `EmojiMask`.
* **Chia Sẻ (Share)**: Tích hợp `UIActivityViewController` chia sẻ qua AirDrop, Zalo, Messenger, Instagram, Email, v.v.
* **Chụp lại (Retake)**: Đóng bảng xem lại và tiếp tục chụp nhanh chóng.

---

### 6. Đa Ngôn Ngữ Linh Hoạt (Bilingual EN / VI)
* Hỗ trợ 100% tiếng Việt (🇻🇳 VI) và tiếng Anh (🇬🇧 EN).
* Nút chuyển đổi nhanh trực tiếp ngay góc trên bên trái màn hình.

---

## 📁 Cấu Trúc Dự Án (Project Structure)

```
Emoij-IOS/
├── EmojiMask.xcodeproj/              # Project Xcode tương thích iOS 16+
│   └── project.pbxproj
├── EmojiMask/
│   ├── App/
│   │   ├── EmojiMaskApp.swift        # Điểm khởi chạy ứng dụng
│   │   ├── ContentView.swift         # View điều phối chính
│   │   └── Info.plist                # Quyền Camera & Quyền Photos Library
│   ├── Models/
│   │   ├── EmojiMaskType.swift       # Danh mục 18 emoji masks
│   │   └── FaceExpressionState.swift # Trạng thái nhận diện mặt & cảm xúc
│   ├── Services/
│   │   ├── CameraManager.swift       # Quản lý AVCaptureSession & Flash
│   │   ├── FaceExpressionTracker.swift# Apple Vision AI nhận diện khuôn mặt
│   │   ├── FaceSmoother.swift        # Thuật toán khử rung chuyển động
│   │   ├── LocalizationManager.swift # Bộ chuyển đổi đa ngôn ngữ VI / EN
│   │   └── PhotoManager.swift        # Lưu ảnh vào Album Photo
│   ├── Views/
│   │   ├── Camera/
│   │   │   └── CameraPreviewView.swift # Preview camera phần cứng & Simulator
│   │   ├── Overlay/
│   │   │   ├── EmojiMaskOverlayView.swift # View phủ lên Camera 60FPS
│   │   │   └── EmojiMaskRenderer.swift   # Bộ vẽ Vector 18 mặt nạ CoreGraphics
│   │   ├── Controls/
│   │   │   ├── TopBarView.swift          # Thanh công cụ trên
│   │   │   ├── MaskCarouselView.swift    # Thanh cuộn chọn 18 Emoji
│   │   │   └── BottomBarView.swift       # Nút chụp ảnh & đổi camera
│   │   ├── Preview/
│   │   │   └── PhotoPreviewDialog.swift  # Modal xem trước ảnh đã chụp
│   │   └── Permission/
│   │       └── CameraPermissionCard.swift# Thẻ thông báo cấp quyền Camera
│   ├── Utilities/
│   │   ├── Color+Extensions.swift    # Bảng màu Glassmorphism
│   │   └── ImageCompositor.swift     # Xử lý ghép ảnh độ phân giải cao
│   └── Assets.xcassets/              # AppIcon & AccentColor
├── .gitignore
└── README.md
```

---

## 🚀 Hướng Dẫn Mở & Build Trên Xcode / Máy Thật (Physical Device)

### Yêu Cầu
- **Máy Mac** cài đặt **macOS Ventura / Sonoma / Sequoia**
- **Xcode 15 / 16 / 17**
- Thiết bị thật iPhone chạy **iOS 16.0 trở lên** (hoặc bất kỳ iPhone Simulator nào)

### Các Bước Thực Hiện
1. Clone hoặc tải project về máy Mac:
   ```bash
   git clone https://github.com/PhamTungDuong2111/Emoij-IOS.git
   cd Emoij-IOS
   ```
2. Mở file project bằng Xcode:
   ```bash
   open EmojiMask.xcodeproj
   ```
3. Cấu hình Signing (Ký chứng chỉ nhà phát triển Apple):
   - Chọn project **EmojiMask** ở danh sách cây thư mục bên trái.
   - Chọn Target **EmojiMask** -> Tab **Signing & Capabilities**.
   - Tại mục **Team**: Chọn Apple ID / Tài khoản Developer của bạn.
   - Xcode sẽ tự động tạo Provisioning Profile hợp lệ.
4. Cắm máy thật iPhone qua cáp Lightning / Type-C (hoặc kết nối qua Wi-Fi).
5. Trên thanh chọn thiết bị (Run Destination) ở đỉnh Xcode:
   - Chọn thiết bị iPhone thật của bạn (ví dụ: `Duong's iPhone`).
6. Nhấn nút **▶ Run** (hoặc tổ hợp phím `Command + R`) để build và cài đặt lên máy thật.
7. Khi mở app lần đầu trên iPhone, nhấn **Cho phép (Allow)** khi hệ thống hỏi quyền Camera.

---

## 🔒 Bản Quyền & Tính Riêng Tư (Privacy)
- Ứng dụng hoạt động **100% Offline trên thiết bị (On-Device Processing)**.
- Toàn bộ dữ liệu khuôn mặt và camera được xử lý qua Apple Vision Framework nội bộ trong RAM, không truyền ra internet hay lưu trữ dữ liệu riêng tư của người dùng.
