import SwiftUI

public enum EmojiMaskType: String, CaseIterable, Identifiable {
    case grinning = "grinning"
    case laughing = "laughing"
    case cat = "cat"
    case heartEyes = "heart_eyes"
    case kissing = "kissing"
    case wink = "wink"
    case scream = "scream"
    case sunglasses = "sunglasses"
    case crying = "crying"
    case angry = "angry"
    case zany = "zany"
    case starStruck = "star_struck"
    case party = "party"
    case robot = "robot"
    case alien = "alien"
    case clown = "clown"
    case devil = "devil"
    case mask = "mask"

    public var id: String { rawValue }

    public var emoji: String {
        switch self {
        case .grinning: return "😀"
        case .laughing: return "😂"
        case .cat: return "🐱"
        case .heartEyes: return "😍"
        case .kissing: return "😘"
        case .wink: return "😉"
        case .scream: return "😱"
        case .sunglasses: return "😎"
        case .crying: return "😭"
        case .angry: return "😡"
        case .zany: return "🤪"
        case .starStruck: return "🤩"
        case .party: return "🥳"
        case .robot: return "🤖"
        case .alien: return "👽"
        case .clown: return "🤡"
        case .devil: return "😈"
        case .mask: return "😷"
        }
    }

    public var localizationKey: String {
        switch self {
        case .grinning: return "mask_grinning"
        case .laughing: return "mask_laughing"
        case .cat: return "mask_cat"
        case .heartEyes: return "mask_heart_eyes"
        case .kissing: return "mask_kissing"
        case .wink: return "mask_wink"
        case .scream: return "mask_scream"
        case .sunglasses: return "mask_sunglasses"
        case .crying: return "mask_crying"
        case .angry: return "mask_angry"
        case .zany: return "mask_zany"
        case .starStruck: return "mask_star_struck"
        case .party: return "mask_party"
        case .robot: return "mask_robot"
        case .alien: return "mask_alien"
        case .clown: return "mask_clown"
        case .devil: return "mask_devil"
        case .mask: return "mask_mask"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .angry:
            return Color(red: 1.0, green: 0.23, blue: 0.19)
        case .scream:
            return Color(red: 0.38, green: 0.63, blue: 0.85)
        case .robot:
            return Color(red: 0.56, green: 0.64, blue: 0.68)
        case .alien:
            return Color(red: 0.51, green: 0.78, blue: 0.52)
        case .clown:
            return Color.white
        case .devil:
            return Color(red: 0.61, green: 0.15, blue: 0.69)
        default:
            return Color(red: 1.0, green: 0.82, blue: 0.15) // Golden yellow
        }
    }

    public static func defaultMask() -> EmojiMaskType {
        return .grinning
    }
}
