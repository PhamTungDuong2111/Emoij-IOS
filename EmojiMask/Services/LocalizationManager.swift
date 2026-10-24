import SwiftUI
import Combine

public enum AppLanguage: String, CaseIterable {
    case vi = "vi"
    case en = "en"
    
    public var displayName: String {
        switch self {
        case .vi: return "🇻🇳 VI"
        case .en: return "🇬🇧 EN"
        }
    }
}

public class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selected_language")
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "selected_language") ?? "vi"
        self.currentLanguage = AppLanguage(rawValue: saved) ?? .vi
    }
    
    public func toggleLanguage() {
        currentLanguage = (currentLanguage == .vi) ? .en : .vi
    }
    
    public func string(for key: String) -> String {
        let dict = (currentLanguage == .vi) ? vietnameseStrings : englishStrings
        return dict[key] ?? key
    }
    
    private let englishStrings: [String: String] = [
        "app_name": "Emoji Mask",
        "app_tagline": "Real-Time AR Emoji Mask & Expression Tracker",
        "permission_camera_title": "Camera Permission Required",
        "permission_camera_message": "Emoji Mask needs camera access to detect your face and render AR emoji masks in real-time.",
        "grant_permission": "Grant Permission",
        "permission_denied_toast": "Camera permission is required to use the app.",
        "flip_camera": "Switch Camera",
        "flash_auto": "Flash Auto",
        "flash_on": "Flash On",
        "flash_off": "Flash Off",
        "capture_photo": "Capture Photo",
        "language_toggle": "Language",
        "current_lang_badge": "EN",
        "no_face_detected": "Looking for face…",
        "face_detected": "Face Tracked",
        "expr_smiling": "😄 Smiling",
        "expr_laughing": "😂 Laughing",
        "expr_winking_left": "😉 Winking Left",
        "expr_winking_right": "😉 Winking Right",
        "expr_eyes_closed": "😌 Eyes Closed",
        "expr_mouth_open": "😮 Mouth Open",
        "expr_kissing": "😘 Kissing",
        "expr_frowning": "😠 Frowning",
        "expr_surprised": "😲 Surprised",
        "expr_neutral": "🙂 Neutral",
        "mask_grinning": "Grinning",
        "mask_laughing": "Joy",
        "mask_cat": "Cat",
        "mask_heart_eyes": "Heart Eyes",
        "mask_kissing": "Blowing Kiss",
        "mask_wink": "Wink",
        "mask_scream": "Scream",
        "mask_sunglasses": "Cool",
        "mask_crying": "Crying",
        "mask_angry": "Angry",
        "mask_zany": "Zany",
        "mask_star_struck": "Star-Struck",
        "mask_party": "Party",
        "mask_robot": "Robot",
        "mask_alien": "Alien",
        "mask_clown": "Clown",
        "mask_devil": "Devil",
        "mask_mask": "Mask",
        "mode_ar_cutout": "🎭 AR Mask",
        "mode_cartoon": "🎨 2D Emoji",
        "mode_switched_ar": "Switched to AR Cutout Mode (Face & Tongue visible)",
        "mode_switched_cartoon": "Switched to 2D Emoji Mode",
        "preview_title": "Photo Captured!",
        "save_photo": "Save",
        "share_photo": "Share",
        "retake_photo": "Retake",
        "photo_saved_success": "Photo saved to Photos album (EmojiMask)",
        "photo_save_failed": "Failed to save photo",
        "share_subject": "My Emoji Mask Selfie!",
        "share_text": "Check out my selfie with Emoji Mask! 🎭✨",
        "offline_badge": "100% On-Device • Offline"
    ]
    
    private let vietnameseStrings: [String: String] = [
        "app_name": "Emoji Mask",
        "app_tagline": "Mặt Nạ Emoji AR & Theo Dõi Biểu Cảm Khuôn Mặt",
        "permission_camera_title": "Yêu Cầu Quyền Camera",
        "permission_camera_message": "Emoji Mask cần quyền truy cập camera để nhận diện khuôn mặt và áp dụng mặt nạ Emoji thực tế ảo AR theo thời gian thực.",
        "grant_permission": "Cấp Quyền Camera",
        "permission_denied_toast": "Cần cấp quyền camera để sử dụng ứng dụng.",
        "flip_camera": "Đổi Camera",
        "flash_auto": "Flash Tự Động",
        "flash_on": "Bật Flash",
        "flash_off": "Tắt Flash",
        "capture_photo": "Chụp Ảnh",
        "language_toggle": "Ngôn Ngữ",
        "current_lang_badge": "VI",
        "no_face_detected": "Đang tìm khuôn mặt…",
        "face_detected": "Đã khớp khuôn mặt",
        "expr_smiling": "😄 Mỉm Cười",
        "expr_laughing": "😂 Cười To",
        "expr_winking_left": "😉 Nháy Mắt Trái",
        "expr_winking_right": "😉 Nháy Mắt Phải",
        "expr_eyes_closed": "😌 Nhắm Mắt",
        "expr_mouth_open": "😮 Há Miệng",
        "expr_kissing": "😘 Chu Môi Hôn",
        "expr_frowning": "😠 Cau Mày",
        "expr_surprised": "😲 Kinh Ngạc",
        "expr_neutral": "🙂 Bình Thường",
        "mask_grinning": "Mỉm Cười",
        "mask_laughing": "Cười Ra Nước Mắt",
        "mask_cat": "Mặt Mèo",
        "mask_heart_eyes": "Mắt Trái Tim",
        "mask_kissing": "Hôn Gió",
        "mask_wink": "Nháy Mắt",
        "mask_scream": "Hét Kinh Hoàng",
        "mask_sunglasses": "Kính Ngầu",
        "mask_crying": "Khóc Ròng",
        "mask_angry": "Tức Giận",
        "mask_zany": "Hài Hước",
        "mask_star_struck": "Mắt Ngôi Sao",
        "mask_party": "Tiệc Tùng",
        "mask_robot": "Người Máy",
        "mask_alien": "Người Ngoài Hành Tinh",
        "mask_clown": "Chú Hề",
        "mask_devil": "Ác Quỷ",
        "mask_mask": "Khẩu Trang",
        "mode_ar_cutout": "🎭 Mặt Nạ AR",
        "mode_cartoon": "🎨 Hoạt Hình 2D",
        "mode_switched_ar": "Đã bật Chế độ Mặt Nạ AR Khoét Lỗ (Lộ mắt & lưỡi thật)",
        "mode_switched_cartoon": "Đã bật Chế độ Mặt Nạ Hoạt Hình 2D",
        "preview_title": "Ảnh Đã Chụp!",
        "save_photo": "Lưu Vào Máy",
        "share_photo": "Chia Sẻ",
        "retake_photo": "Chụp Lại",
        "photo_saved_success": "Đã lưu ảnh vào Thư viện (Album EmojiMask)",
        "photo_save_failed": "Không thể lưu ảnh",
        "share_subject": "Ảnh Selfie Emoji Mask của tôi!",
        "share_text": "Xem ảnh selfie thú vị của tôi với Emoji Mask AR này! 🎭✨",
        "offline_badge": "100% Offline • Trên Thiết Bị"
    ]
}

extension View {
    public func loc(_ key: String) -> String {
        return LocalizationManager.shared.string(for: key)
    }
}
