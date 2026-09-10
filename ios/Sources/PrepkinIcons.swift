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

/// The Play section's mark on Learn, from the same illustrated set as the tabs.
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
        case .learn:    return "tabLearn"
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

/// The clap on the Cheer button. One colour, so the button can tint it coral when
/// idle and white once cheered without carrying two artworks.
///
/// Two mittens and three sparks, per `design/handoff-friends/Friends Tab.dc.html`.
struct ClapGlyph: View {
    var size: CGFloat = 22
    var tint: Color

    var body: some View {
        Ico(size: size) {
            stroke(tint, 1.8) { p in p.go(12, 2.2); p.to(12, 5.4) }
            stroke(tint, 1.8) { p in p.go(7.2, 3.6); p.to(8.7, 6.4) }
            stroke(tint, 1.8) { p in p.go(16.8, 3.6); p.to(15.3, 6.4) }
            // Back hand, dimmed so the two mittens read apart at 22 pt.
            blob(tint, backHand).opacity(0.72)
            blob(tint, frontHand)
            stroke(.white, 1.2) { p in
                p.go(12.3, 17.6); p.arc(10.7, 15.8, 11.3, 16.5, 10.7, 15.8)
            }
            Ellipse().fill(.white).opacity(0.28)
                .frame(width: 1.8, height: 3.2).offset(x: 13.3, y: 7.7)
        }
    }

    private func backHand(_ p: inout Path) {
        p.go(11.6, 9.2)
        p.to(8.4, 7.4)
        p.arc(5.6, 8.2, 7.4, 6.8, 6.2, 7.2)
        p.to(3.4, 12)
        p.arc(5.0, 19.2, 2.2, 14.4, 2.8, 17.4)
        p.to(6.2, 20.2)
        p.arc(10.5, 20.7, 7.4, 21.2, 9.1, 21.4)
        p.to(11.8, 19.5)
        p.closeSubpath()
    }

    private func frontHand(_ p: inout Path) {
        p.go(10.6, 21.4)
        p.arc(15.0, 19.2, 11.0, 21.2, 15.0, 19.2)
        p.arc(18.4, 12.7, 17.3, 17.8, 18.6, 15.3)
        p.to(18.1, 9.7)
        p.arc(15.8, 7.8, 18.0, 8.5, 17.0, 7.7)
        p.arc(14.1, 9.7, 14.8, 7.9, 14.1, 8.7)
        p.to(14.1, 7.9)
        p.arc(12.5, 6.3, 14.1, 7.0, 13.4, 6.3)
        p.arc(10.9, 7.9, 11.6, 6.3, 10.9, 7.0)
        p.to(10.9, 10.5)
        p.to(8.9, 8.3)
        p.arc(6.4, 8.2, 8.2, 7.6, 7.1, 7.5)
        p.arc(6.4, 10.7, 5.7, 8.9, 5.7, 10.0)
        p.to(9.9, 14.5)
        p.closeSubpath()
    }
}

/// The add-friend button's glyph — one apricot head with a coral plus badge.
/// Stands in for SF `person.badge.plus`, which is the only stroked grey symbol
/// that would have been left in this palette.
struct AddFriendGlyph: View {
    var size: CGFloat = 24

    var body: some View {
        Ico(size: size) {
            blob(Theme.hex(0xE08E56)) { p in
                p.go(2.6, 20.4)
                p.arc(9.4, 14.4, 2.6, 16.6, 5.5, 14.4)
                p.arc(16.2, 20.4, 13.3, 14.4, 16.2, 16.6)
                p.closeSubpath()
            }
            dot(9.4, 8.6, 5.2, Theme.hex(0xF5AE79))
            dot(9.4, 7.3, 4.0, Theme.hex(0xF8C199)).opacity(0.55)
            dot(6.2, 10.1, 0.9, Theme.blush).opacity(0.65)
            dot(12.6, 10.1, 0.9, Theme.blush).opacity(0.65)
            dot(7.8, 8.4, 0.95, Theme.ink)
            dot(11.0, 8.4, 0.95, Theme.ink)
            dot(8.05, 8.1, 0.3, .white)
            dot(11.25, 8.1, 0.3, .white)
            stroke(Theme.ink, 0.95) { p in
                p.go(8.4, 10.5); p.bend(10.4, 10.5, 9.4, 11.5)
            }
            dot(17.6, 16.4, 5.2, Theme.coralShade)
            dot(17.6, 15.9, 5.2, Theme.coral)
            dot(16.2, 14.2, 1.3, .white).opacity(0.28)
            box(16.55, 12.6, 2.1, 6.6, 1.05, .white)
            box(14.3, 14.85, 6.6, 2.1, 1.05, .white)
        }
    }
}
