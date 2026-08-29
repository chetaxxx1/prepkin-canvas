import SwiftUI

/// Design tokens from the Claude Design handoff (design/from-claude-design/HANDOFF.md).
/// Rule: UI colors stay fixed and low-chroma. Mascots are the only saturated thing
/// on screen, so any species color pops.
enum Theme {
    static let paper = hex(0xFAF5EC)        // cream background
    static let card = Color.white
    static let ink = hex(0x2E2822)
    static let muted = hex(0x988D80)        // warm gray text
    static let dim = hex(0xB4A996)          // muted gray
    static let inactive = hex(0xC9BEAC)     // inactive tab icon
    static let hairline = hex(0xF0E9DC)
    static let checkBorder = hex(0xE5DDD0)

    static let coral = hex(0xFF6F61)        // action
    static let coralSoft = hex(0xFFE9E5)
    static let coralIcon = hex(0xFF8A7E)

    static let mint = hex(0x57C79B)         // success / done
    static let mintSoft = hex(0xE3F6EE)
    static let mintDark = hex(0x2E8C68)

    static let coin = hex(0xFFC24B)
    static let coinBorder = hex(0xE8A62E)
    static let coinSoft = hex(0xFFF3D6)
    static let coinDark = hex(0xB07A1A)

    /// Mascot body — the approved slime green. Never approximate.
    static let slime = hex(0x51CFA0)
    static let slimeBelly = hex(0xB1EDD4)
    static let slimeInk = hex(0x101820)
    static let blush = hex(0xFF9E94)

    // Aliases kept for the other tabs.
    static var sun: Color { coin }
    static var sky: Color { hex(0x9BC8F2) }

    static func species(_ id: String) -> Color {
        switch id {
        case "ember", "mochi": return hex(0xF7A8B8)   // pink
        case "droplet", "puff": return hex(0x9BC8F2)  // sky
        case "wisp": return hex(0xC3B2F0)             // lavender
        case "sprout": return hex(0xA5CE6B)           // leaf
        default: return slime
        }
    }

    static func hex(_ v: UInt32) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255,
              green: Double((v >> 8) & 0xFF) / 255,
              blue: Double(v & 0xFF) / 255)
    }
}

/// A purchasable home-screen backdrop. Art lives in Assets.xcassets.
struct Scene0: Identifiable, Equatable {
    let id: String
    let name: String
    let price: Int
    let asset: String
    /// True when the art is dark, so overlaid pills flip to a light-on-dark treatment.
    let isDark: Bool

    static let all: [Scene0] = [
        Scene0(id: "dorm", name: "Study room", price: 0, asset: "scene-dorm", isDark: false),
        Scene0(id: "meadow", name: "Meadow", price: 200, asset: "scene-meadow", isDark: false),
        Scene0(id: "sunset", name: "Golden hour", price: 220, asset: "scene-sunset", isDark: false),
        Scene0(id: "night", name: "Night in", price: 250, asset: "scene-night", isDark: true),
    ]

    static func find(_ id: String) -> Scene0 { all.first { $0.id == id } ?? all[0] }
}

struct CardStyle: ViewModifier {
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            )
    }
}

extension View {
    func card(radius: CGFloat = 20) -> some View { modifier(CardStyle(radius: radius)) }
}
