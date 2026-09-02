import SwiftUI

/// Design tokens from the Home handoff (`design_handoff_prepkin_home_v2/README.md`).
/// Rule: UI colors stay fixed and low-chroma. Mascots are the only saturated thing
/// on screen, so any species color pops.
enum Theme {
    static let paper = hex(0xFAF5EC)        // cream background, off-Home screens
    static let card = Color.white
    static let ink = hex(0x2E2622)
    static let muted = hex(0x96877F)        // warm gray text
    static let dim = hex(0xB4A996)          // muted gray
    static let inactive = hex(0xC9BEAC)     // inactive tab icon
    static let hairline = hex(0xF0E9DC)

    /// Task-row tile: one constant near-white circle for every category, so six
    /// objects give the variety without six competing backgrounds.
    static let tile = hex(0xFDF9F4)
    static let tileRing = hex(0xEDE1D3)

    static let checkFill = hex(0xF4F0EB)
    static let checkBorder = hex(0xE6DFD7)
    static let check = hex(0x6FC79E)        // checked box

    static let coral = hex(0xFF6F61)        // action
    static let coralSoft = hex(0xFFE9E5)
    static let coralIcon = hex(0xFF8A7E)
    static let coralDeep = hex(0xE4735F)
    static let coralShade = hex(0xC4523F)

    static let mint = hex(0x57C79B)         // success / affordability dot
    static let mintSoft = hex(0xDFF3E9)
    static let mintDark = hex(0x3E9E78)

    static let coin = hex(0xFFC24B)
    static let coinBorder = hex(0xE8A62E)
    static let coinSoft = hex(0xFFF3D6)
    static let coinDark = hex(0xA8761D)

    // Tab bar. Every icon is a full-colour object, so a tab is found by silhouette
    // and colour — which is the only reason six of them fit.
    static let tabBar = hex(0xFFFDF8)
    static let tabInk = hex(0x6E5F53)
    static let tabActiveInk = hex(0xC24A3E)
    static let tabActiveFill = hex(0xFFE0DA)
    static let kinChip = hex(0x3E2C28)

    // On the scene.
    static let onDarkWarm = hex(0xFFF3E4)
    static let chipDivider = hex(0xE9E1D6)
    static let bagInk = hex(0x8A7869)

    /// Mascot body — the approved slime green. Never approximate.
    static let slime = hex(0x51CFA0)
    static let slimeBelly = hex(0xB1EDD4)
    static let slimeInk = hex(0x101820)
    static let blush = hex(0xFF9E94)

    // Aliases kept for the other tabs.
    static var sun: Color { coin }
    static var sky: Color { hex(0x9BC8F2) }

    // MARK: - Kin tier ramp

    static let lavender = hex(0xC3B2F0)
    static let leaf = hex(0xA5CE6B)
    static let pink = hex(0xF7A8B8)

    /// The field an unowned kin card sits on. One step off `paper` — deliberately
    /// NOT a desaturation, because the kin itself is never dimmed, locked or hidden.
    static let unowned = hex(0xFBF7F0)

    /// A kin's tier colour. It appears in exactly three places and never as a large
    /// fill: the name plate, the cost badge, and a 2pt card border. The UI stays
    /// low-chroma so the kin is still the most saturated thing on screen.
    static func tier(_ t: Int) -> Color {
        switch t {
        case 2: return mint
        case 3: return sky
        case 4: return lavender
        case 5: return coin
        default: return dim
        }
    }

    static func tierName(_ t: Int) -> String {
        switch t {
        case 2: return "UNCOMMON"
        case 3: return "RARE"
        case 4: return "EPIC"
        case 5: return "LEGENDARY"
        default: return "COMMON"
        }
    }

    /// The handoff calls for Nunito; SF Pro Rounded is the sanctioned native stand-in.
    static func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func species(_ id: String) -> Color {
        switch id {
        // Sprout's coat bodies (`palettes.ts` in the Sprout repo), so a tint drawn
        // next to the character is the character's own colour.
        case "ember", "mochi": return hex(0xE07A72)   // coral
        case "droplet", "puff": return hex(0x6BAFE0)  // sky
        case "wisp": return hex(0xB08EE0)             // lilac
        case "sprout": return hex(0xE9A07C)           // peach
        case "comet": return hex(0xE4C45C)            // butter
        default: return hex(0x58CC9F)                 // mint
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
    /// The art's own bottom edge, sampled from the last rows of the asset. Home paints
    /// the whole page this colour, so the illustration just stops and the value carries
    /// on — no gradient, no seam. **Re-sample this whenever the art changes.**
    let floor: Color

    static let all: [Scene0] = [
        Scene0(id: "dorm", name: "Study room", price: 0, asset: "scene-dorm",
               isDark: false, floor: Theme.hex(0xEF6C53)),
        Scene0(id: "meadow", name: "Meadow", price: 200, asset: "scene-meadow",
               isDark: false, floor: Theme.hex(0x515B18)),
        Scene0(id: "sunset", name: "Golden hour", price: 220, asset: "scene-sunset",
               isDark: false, floor: Theme.hex(0xB44417)),
        Scene0(id: "night", name: "Night in", price: 250, asset: "scene-night",
               isDark: true, floor: Theme.hex(0x80423F)),
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
