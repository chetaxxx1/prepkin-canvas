import SwiftUI

/// Design tokens from the Home handoff (`design_handoff_prepkin_home_v2/README.md`).
/// Rule: UI colors stay fixed and low-chroma. Mascots are the only saturated thing
/// on screen, so any species color pops.
enum Theme {
    /// The page. Measured off the Imprint frames George keeps pointing at: they run a
    /// near-white page (#F8F8F8) with pure-white cards and a hairline border, not a
    /// cream. Cream muddied every warm accent we put on it.
    static let paper = hex(0xF8F8F8)
    /// The hairline that keeps a white card visible on a near-white page.
    static let cardEdge = hex(0xECEAE6)
    static let card = Color.white
    static let ink = hex(0x2E2622)
    static let muted = hex(0x96877F)        // warm gray text
    static let dim = hex(0xB4A996)          // muted gray
    static let inactive = hex(0xC9BEAC)     // inactive tab icon
    static let hairline = hex(0xF0E9DC)
    /// One step under the page: the segmented track, the ‹ Today › pill and the
    /// folded-past strip on Calendar. Sunk, not raised — nothing on it floats.
    static let paperSunk = hex(0xF3ECE0)
    /// One step darker than `muted`, for a caption sitting on a tinted block
    /// (a class in the calendar), where `muted` drops under 4.5:1.
    static let mutedDeep = hex(0x7B6C63)
    /// The glyph and label inside a `paperSunk` pill.
    static let mutedInk = hex(0x5F534A)

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
    /// The amber that reads on white. `coinDark` is 3.2:1 there and fails, so
    /// the calendar's "Still counts" header and captions use this instead.
    static let coinInk = hex(0x8A5F14)
    static let coinHairline = hex(0xE8CFA0)

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
    /// Reading sizes (20pt and under) follow the system text size, capped at 1.3×
    /// so the tank, the tab bar and the fixed-height cards survive. Display sizes
    /// (the 56pt timer, 34pt page titles) stay put. This is "large", not the
    /// accessibility sizes; the release checklist says so. One function, so the
    /// cap moves in one place.
    static func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size <= 20 ? size * readingScale : size, weight: weight, design: .rounded)
    }

    /// For the few labels that must never grow: the tab bar, chips inside the tank.
    static func fixedFont(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static var readingScale: CGFloat {
        let s = UIFontMetrics(forTextStyle: .body).scaledValue(for: 17) / 17
        return min(max(s, 1), 1.3)
    }

    static func species(_ id: String) -> Color {
        switch id {
        // Sprout's coat bodies (`palettes.ts` in the Sprout repo), so a tint drawn
        // next to the character is the character's own colour.
        case "ember", "mochi": return hex(0xE07A72)   // coral
        case "droplet", "puff": return hex(0x6BAFE0)  // sky
        case "wisp": return hex(0xB08EE0)  // lilac
        case "sprout": return hex(0xE9A07C)           // peach
        case "comet": return hex(0xE4C45C)            // butter
        default: return hex(0x58CC9F)                 // mint
        }
    }

    /// The disc behind a kin's portrait. Colour theory, not a lookup: the
    /// complement of the kin's own colour (hue + 180°), held pastel at a fixed
    /// saturation and brightness, so any coat — mint on rose, coral on aqua,
    /// butter on periwinkle — pops instead of sinking into a tint of itself. A new kin gets the right plate without anyone picking one.
    /// Chosen 2026-09-10 from a sheet of four saturations at ship size.
    static func plate(for speciesID: String) -> Color {
        var h: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        UIColor(species(speciesID)).getHue(&h, saturation: &sat, brightness: &bri, alpha: &alpha)
        return Color(hue: (h + 0.5).truncatingRemainder(dividingBy: 1), saturation: 0.32, brightness: 0.97)
    }

    // MARK: - Shape

    /// Five radii. Before this the tree held 23 different values, which is what
    /// made six tabs read as six apps. If a shape is not on this list it is a bug;
    /// `ios/Tests/UniformTests.swift` fails the build over a new one.
    enum Radius {
        /// Small chips, checkboxes, day cells.
        static let chip: CGFloat = 10
        /// Buttons, fields, and the 44pt icon tile.
        static let control: CGFloat = 14
        /// Every card and row on a page.
        static let card: CGFloat = 20
        /// Sheets, the hero card, a full-bleed art band.
        static let sheet: CGFloat = 28
        /// A tile's corner is a constant fraction of its side, so the 44 and 52
        /// sizes land on `control` and one step above it without a second rule.
        static func tile(_ size: CGFloat) -> CGFloat { size * 0.32 }
    }

    /// The page gutter. Every header, section label and card edge lines up on it.
    static let gutter: CGFloat = 18
    /// Between two bands of a page.
    static let band: CGFloat = 14

    /// What anything that scrolls has to leave at its bottom so the last row is not
    /// under the floating tab bar. Four different values were in the tree (104, 120,
    /// 124 and a local 58) and the last row clipped on two screens because of it.
    static let tabClearance: CGFloat = 112

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
    /// The art's own bottom edge, sampled from the last rows of the asset. The page
    /// starts at this value so the illustration hands over without a step.
    /// **Re-sample this whenever the art changes** (`scripts/cut_ios_tanks.py` prints it).
    let floor: Color
    /// Where the page has drifted to by the bottom of the screen. The paintings keep
    /// getting slightly deeper toward the viewer, so freezing the ramp at the handoff
    /// told the eye a new surface started there even though the colour matched. This
    /// continues the ramp, clamped to about 5 points of CIELAB lightness so the hue
    /// cannot slide. Printed alongside `floor` by the same script.
    let floorDeep: Color
    /// The plate without its pieces, for a tank whose slots the student can change.
    /// The five painted tanks have none: their props are part of the painting.
    var emptyAsset: String? = nil
    /// Where a standing piece's feet go, as a fraction of the plate's height. Each
    /// tank's horizon sets it (`compose_tank.py`: horizon + 0.10, clamped 0.72–0.78).
    var feet: CGFloat = 0.765

    /// Sprout is a fish, so a scene is the water he lives in. These are the five
    /// tank plates from the Sprout build, cut for the phone: `scenes/…` in the
    /// asset catalogue for the still, the same art under `SproutWeb/tanks/ios/`
    /// for the live Home tank. The ids match the web build's tank ids.
    /// The five painted tanks, then the fifteen themed ones. Theme.swift is also
    /// compiled into the widget and the Live Activity, so the themed rows live here
    /// rather than in `TankCatalog` (which needs the app's piece types).
    static let all: [Scene0] = painted + themed

    static let painted: [Scene0] = [
        Scene0(id: "lagoon", name: "Lagoon", price: 0, asset: "scene-lagoon",
               isDark: false, floor: Theme.hex(0xE4EFD9), floorDeep: Theme.hex(0xDBE6D0)),
        Scene0(id: "reef", name: "Reef", price: 200, asset: "scene-reef",
               isDark: false, floor: Theme.hex(0xF2B389), floorDeep: Theme.hex(0xE3A57C)),
        Scene0(id: "kelp", name: "Kelp", price: 220, asset: "scene-kelp",
               isDark: false, floor: Theme.hex(0xC8A840), floorDeep: Theme.hex(0xB99B33)),
        Scene0(id: "dusk", name: "Dusk", price: 250, asset: "scene-dusk",
               isDark: false, floor: Theme.hex(0xBC87B4), floorDeep: Theme.hex(0xAE7AA6)),
        Scene0(id: "deep", name: "Deep", price: 280, asset: "scene-deep",
               isDark: true, floor: Theme.hex(0x3B7AB1), floorDeep: Theme.hex(0x2A6EA3)),
    ]

    // GENERATED by design/tanks/ship_tanks.py — do not edit between the markers.
    // themed:begin
    static let themed: [Scene0] = [
        Scene0(id: "treasure", name: "Treasure", price: 300, asset: "scene-treasure",
               isDark: false, floor: Theme.hex(0xC4AF85), floorDeep: Theme.hex(0xB6A278),
               emptyAsset: "scene-treasure-empty", feet: 0.7796),
        Scene0(id: "castle", name: "Castle", price: 300, asset: "scene-castle",
               isDark: false, floor: Theme.hex(0x968877), floorDeep: Theme.hex(0x897B6B),
               emptyAsset: "scene-castle-empty", feet: 0.7796),
        Scene0(id: "zen", name: "Zen", price: 320, asset: "scene-zen",
               isDark: false, floor: Theme.hex(0xB29680), floorDeep: Theme.hex(0xA48973),
               emptyAsset: "scene-zen-empty", feet: 0.7759),
        Scene0(id: "frost", name: "Frost", price: 320, asset: "scene-frost",
               isDark: false, floor: Theme.hex(0xB9CCDA), floorDeep: Theme.hex(0xABBECC),
               emptyAsset: "scene-frost-empty", feet: 0.7796),
        Scene0(id: "vapor", name: "Vapor", price: 340, asset: "scene-vapor",
               isDark: false, floor: Theme.hex(0xAA8FC5), floorDeep: Theme.hex(0x9D82B7),
               emptyAsset: "scene-vapor-empty", feet: 0.7796),
        Scene0(id: "lantern", name: "Lantern", price: 360, asset: "scene-lantern",
               isDark: true, floor: Theme.hex(0x694735), floorDeep: Theme.hex(0x5C3C2A),
               emptyAsset: "scene-lantern-empty", feet: 0.7796),
        Scene0(id: "disco", name: "Disco", price: 380, asset: "scene-disco",
               isDark: true, floor: Theme.hex(0x413359), floorDeep: Theme.hex(0x35284D),
               emptyAsset: "scene-disco-empty", feet: 0.7796),
        Scene0(id: "orbit", name: "Orbit", price: 380, asset: "scene-orbit",
               isDark: true, floor: Theme.hex(0x3C3F53), floorDeep: Theme.hex(0x313447),
               emptyAsset: "scene-orbit-empty", feet: 0.7796),
        Scene0(id: "arcade", name: "Arcade", price: 400, asset: "scene-arcade",
               isDark: true, floor: Theme.hex(0x525379), floorDeep: Theme.hex(0x505177),
               emptyAsset: "scene-arcade-empty", feet: 0.7796),
        Scene0(id: "magma", name: "Magma", price: 400, asset: "scene-magma",
               isDark: true, floor: Theme.hex(0x4B423F), floorDeep: Theme.hex(0x3F3734),
               emptyAsset: "scene-magma-empty", feet: 0.7796),
        Scene0(id: "library", name: "Library", price: 340, asset: "scene-library",
               isDark: true, floor: Theme.hex(0x6E4C38), floorDeep: Theme.hex(0x61402D),
               emptyAsset: "scene-library-empty", feet: 0.7444),
        Scene0(id: "cottage", name: "Cottage", price: 320, asset: "scene-cottage",
               isDark: false, floor: Theme.hex(0x9E9E6B), floorDeep: Theme.hex(0x91915F),
               emptyAsset: "scene-cottage-empty", feet: 0.7796),
        Scene0(id: "lofi", name: "Lofi", price: 360, asset: "scene-lofi",
               isDark: true, floor: Theme.hex(0x50495C), floorDeep: Theme.hex(0x443E50),
               emptyAsset: "scene-lofi-empty", feet: 0.7194),
        Scene0(id: "court", name: "Court", price: 340, asset: "scene-court",
               isDark: false, floor: Theme.hex(0xC49B7D), floorDeep: Theme.hex(0xB68E70),
               emptyAsset: "scene-court-empty", feet: 0.7796),
        Scene0(id: "haunt", name: "Haunt", price: 300, asset: "scene-haunt",
               isDark: true, floor: Theme.hex(0x352A36), floorDeep: Theme.hex(0x2A202B),
               emptyAsset: "scene-haunt-empty", feet: 0.7796),
    ]
    // themed:end

    /// The land scenes this replaced. A save that still names one lands on the
    /// tank closest to it in mood, so nobody loses a scene they paid for.
    static let retired: [String: String] = [
        "dorm": "lagoon", "meadow": "kelp", "sunset": "reef", "night": "deep",
    ]

    static func find(_ id: String) -> Scene0 {
        all.first { $0.id == id } ?? all.first { $0.id == retired[id] } ?? all[0]
    }
}

/// A card: white, one hairline, no shadow.
///
/// The shadow used to be here and it was the wrong call. A page of eight shadowed
/// cards has no hierarchy left to spend — everything is lifted, so nothing is.
/// Shadows now belong only to things that genuinely float above the page: the tab
/// bar and a presented sheet.
struct CardStyle: ViewModifier {
    var radius: CGFloat = Theme.Radius.card
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.cardEdge, lineWidth: 1)
            )
    }
}

extension View {
    func card(radius: CGFloat = Theme.Radius.card, padding: CGFloat = 16) -> some View {
        modifier(CardStyle(radius: radius, padding: padding))
    }
}
