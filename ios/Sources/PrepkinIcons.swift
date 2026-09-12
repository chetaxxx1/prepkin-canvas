import SwiftUI

/// The two illustrated icon sets from the Home handoff, drawn in code.
///
/// One rule book for both: objects rather than symbols (a pencil, not a document),
/// filled rather than stroked, no fill lighter than the surface it sits on, and one
/// hue family per icon. Mint appears exactly once in the tab bar — on the mascot.
///
/// Every coordinate below is in the reference's 24×24 space, so these match the SVGs
/// in `design_handoff_prepkin_home_v2/home-reference.html` one for one.

// MARK: - 24×24 drawing helpers

/// Lays flat shapes out on a 24×24 grid, then scales the lot to `size`.
private struct Ico<Content: View>: View {
    let size: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) { content() }
            .frame(width: 24, height: 24, alignment: .topLeading)
            .scaleEffect(size / 24)
            .frame(width: size, height: size)
    }
}

private struct Poly: Shape {
    let build: @Sendable (inout Path) -> Void
    func path(in rect: CGRect) -> Path { var p = Path(); build(&p); return p }
}

private func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                 _ r: CGFloat = 0, _ fill: Color) -> some View {
    RoundedRectangle(cornerRadius: r, style: .continuous)
        .fill(fill).frame(width: w, height: h).offset(x: x, y: y)
}

/// A block rounded on its bottom edge only — for bands that sit inside a rounded body.
private func foot(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                  _ r: CGFloat, _ fill: Color) -> some View {
    UnevenRoundedRectangle(bottomLeadingRadius: r, bottomTrailingRadius: r, style: .continuous)
        .fill(fill).frame(width: w, height: h).offset(x: x, y: y)
}

private func dot(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ fill: Color) -> some View {
    Circle().fill(fill).frame(width: r * 2, height: r * 2).offset(x: cx - r, y: cy - r)
}

private func blob(_ fill: Color, _ build: @escaping @Sendable (inout Path) -> Void) -> some View {
    Poly(build: build).fill(fill).frame(width: 24, height: 24)
}

private func stroke(_ color: Color, _ width: CGFloat,
                    _ build: @escaping @Sendable (inout Path) -> Void) -> some View {
    Poly(build: build)
        .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        .frame(width: 24, height: 24)
}

private extension Path {
    mutating func go(_ x: CGFloat, _ y: CGFloat) { move(to: CGPoint(x: x, y: y)) }
    mutating func to(_ x: CGFloat, _ y: CGFloat) { addLine(to: CGPoint(x: x, y: y)) }
    mutating func bend(_ x: CGFloat, _ y: CGFloat, _ cx: CGFloat, _ cy: CGFloat) {
        addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }
    mutating func arc(_ x: CGFloat, _ y: CGFloat,
                      _ c1x: CGFloat, _ c1y: CGFloat,
                      _ c2x: CGFloat, _ c2y: CGFloat) {
        addCurve(to: CGPoint(x: x, y: y),
                 control1: CGPoint(x: c1x, y: c1y),
                 control2: CGPoint(x: c2x, y: c2y))
    }
}

// MARK: - Task category icons

/// The object that rides in a task row's tile.
///
/// Illustrated, not drawn in code. The whole set is cut from a handful of sheets
/// under `design/icons`, so every object shares one light source, one palette and
/// one optical size. Hand-writing nineteen of these in SwiftUI was the earlier
/// attempt, and a list of them read as nineteen different hands.
///
/// This draws the object only. The tile behind it is `IconTile`.
struct CategoryIcon: View {
    let category: TaskCategory
    var size: CGFloat = 32

    var body: some View {
        Image("icon-" + category.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Tab icons

/// The Play tab's own mark, for use inside the page. Same illustrated set as the tabs.
struct PlayIcon: View {
    var size: CGFloat = 22

    var body: some View {
        Image("icon-tabPlay")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The object in a tab.
///
/// Colour is what makes six tabs findable — each is a distinct hue family, so you
/// look for a silhouette rather than parsing a grey glyph. These are the same
/// illustrated family as the rest of the app, but drawn deliberately chunkier:
/// at 25pt a thin line disappears, so a tab icon is three or four large masses
/// and nothing smaller.
struct TabIcon: View {
    let tab: RootView.Tab
    var size: CGFloat = 27

    var body: some View {
        Group {
            if let name = Self.asset(tab) {
                Image("icon-" + name)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// The Kin tab draws the mascot's own face instead, so it has no asset.
    static func asset(_ tab: RootView.Tab) -> String? {
        switch tab {
        case .home:     return "tabHome"
        case .focus:    return "tabFocus"
        case .play:     return "tabPlay"
        case .calendar: return "tabCalendar"
        case .friends:  return "tabFriends"
        case .kin:      return nil
        }
    }
}

struct KinChip: View {
    var speciesID: String = "slime"
    var size: CGFloat = 28
    /// The disc behind the face. Dark by default, which is right on a light page
    /// but far too heavy inside the tab bar's own cream bubble — pass the species
    /// tint there so the bubble reads as a portrait, not a hole in the bar.
    var plate: Color = Theme.kinChip

    var body: some View {
        SproutFace(speciesID: speciesID, size: size, plate: plate)
    }
}

// MARK: - Friends tab glyphs

