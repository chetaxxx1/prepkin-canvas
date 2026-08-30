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
    let build: (inout Path) -> Void
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

private func blob(_ fill: Color, _ build: @escaping (inout Path) -> Void) -> some View {
    Poly(build: build).fill(fill).frame(width: 24, height: 24)
}

private func stroke(_ color: Color, _ width: CGFloat,
                    _ build: @escaping (inout Path) -> Void) -> some View {
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
}

// MARK: - Task category icons

/// The object that rides in a task row's tile. Tiles stay a constant near-white
/// circle — the object carries the colour, so six categories don't put six competing
/// backgrounds down the list.
struct CategoryIcon: View {
    let category: TaskCategory
    var size: CGFloat = 32

    var body: some View {
        Ico(size: size) {
            switch category {
            case .reading:    openBook
            case .writing:    pencil
            case .problemSet: ruler
            case .labs:       flask
            case .study:      flashcards
            case .lifeCare:   waterGlass
            }
        }
    }

    /// Reading — an open book. Coral covers, cream pages, deep-coral spine.
    private var openBook: some View {
        ZStack(alignment: .topLeading) {
            blob(Theme.hex(0xE4735F)) { p in
                p.go(11.8, 7.4); p.to(4.0, 5.2); p.bend(2.4, 6.8, 2.4, 5.2)
                p.to(2.4, 17.4); p.bend(3.6, 18.9, 2.4, 18.6); p.to(11.8, 21.3); p.closeSubpath()
            }
            blob(Theme.hex(0xC4523F)) { p in
                p.go(12.2, 7.4); p.to(20.0, 5.2); p.bend(21.6, 6.8, 21.6, 5.2)
                p.to(21.6, 17.4); p.bend(20.4, 18.9, 21.6, 18.6); p.to(12.2, 21.3); p.closeSubpath()
            }
            blob(Theme.hex(0xFFF1E0)) { p in
                p.go(11.6, 9.0); p.to(4.6, 7.1); p.bend(3.8, 7.9, 3.8, 7.2)
                p.to(3.8, 17.2); p.bend(4.6, 17.9, 3.8, 17.7); p.to(11.6, 20.0); p.closeSubpath()
            }
            blob(Theme.hex(0xFFF1E0)) { p in
                p.go(12.4, 9.0); p.to(19.4, 7.1); p.bend(20.2, 7.9, 20.2, 7.2)
                p.to(20.2, 17.2); p.bend(19.4, 17.9, 20.2, 17.7); p.to(12.4, 20.0); p.closeSubpath()
            }
            box(11.35, 7.3, 1.3, 14.1, 0.5, Theme.hex(0xC4523F))
        }
    }

    /// Writing — a pencil. Not a page: a page reads as "document", a pencil as "write".
    private var pencil: some View {
        ZStack(alignment: .topLeading) {
            box(9.4, 3.0, 5.2, 3.0, 1.4, Theme.hex(0xFF9E94))
            box(9.4, 5.8, 5.2, 1.8, 0, Theme.hex(0xA99F8E))
            box(9.4, 7.2, 5.2, 9.4, 0, Theme.hex(0xFFC24B))
            box(12.0, 7.2, 2.6, 9.4, 0, Theme.hex(0xEDAE33))
            blob(Theme.hex(0xE8C58F)) { p in
                p.go(9.4, 16.6); p.to(14.6, 16.6); p.to(12.0, 20.8); p.closeSubpath()
            }
            blob(Theme.hex(0x4A4038)) { p in
                p.go(11.0, 19.1); p.to(13.0, 19.1); p.to(12.0, 20.8); p.closeSubpath()
            }
        }
    }

    /// Problem sets — a ruler. Reads as measured, repetitive work.
    private var ruler: some View {
        ZStack(alignment: .topLeading) {
            box(3.6, 8.4, 16.8, 7.2, 1.8, Theme.hex(0x7FB2D4))
            foot(3.6, 12.4, 16.8, 3.2, 1.8, Theme.hex(0x5E97BF))
            box(6.8, 8.4, 1.7, 3.0, 0.6, .white)
            box(11.2, 8.4, 1.7, 3.9, 0.6, .white)
            box(15.6, 8.4, 1.7, 3.0, 0.6, .white)
        }
    }

    /// Labs & projects — a flask. The one place mint is allowed in this set.
    private var flask: some View {
        ZStack(alignment: .topLeading) {
            box(9.4, 2.2, 5.2, 2.0, 1.0, Theme.hex(0x7FA0A8))
            blob(Theme.hex(0xC2D8DC)) { p in
                p.go(10.6, 4.2); p.to(13.4, 4.2); p.to(13.4, 7.3); p.to(18.7, 17.8)
                p.bend(16.1, 22.0, 19.3, 20.9); p.to(8.9, 22.0)
                p.bend(6.3, 17.8, 5.7, 20.9); p.closeSubpath()
            }
            blob(Theme.hex(0x2E9E78)) { p in
                p.go(7.2, 13.8); p.to(16.8, 13.8); p.to(18.7, 17.8)
                p.bend(16.1, 22.0, 19.3, 20.9); p.to(8.9, 22.0)
                p.bend(6.3, 17.8, 5.7, 20.9); p.closeSubpath()
            }
            dot(10.3, 17.8, 1.25, Theme.hex(0x7FD9B6))
            dot(14.2, 19.6, 0.85, Theme.hex(0x7FD9B6))
        }
    }

    /// Study & review — flashcards, one tilted behind the other.
    private var flashcards: some View {
        ZStack(alignment: .topLeading) {
            box(4.4, 5.8, 15.2, 10.4, 2.4, Theme.hex(0xC98F2E))
                .rotationEffect(.degrees(-9), anchor: UnitPoint(x: 0.5, y: 0.692))
            box(4.4, 8.2, 15.2, 10.6, 2.4, Theme.hex(0xF5CE79))
            box(7.2, 11.2, 9.6, 1.8, 0.9, Theme.hex(0x96631A))
            box(7.2, 14.4, 6.2, 1.8, 0.9, Theme.hex(0xB57E28))
        }
    }

    /// Life care — a glass of water. Blue body, not the near-white glass that
    /// disappeared against the tile on the first pass.
    private var waterGlass: some View {
        ZStack(alignment: .topLeading) {
            blob(Theme.hex(0xBFDCEC)) { p in
                p.go(7.2, 3.4); p.to(16.8, 3.4); p.to(15.7, 19.6)
                p.bend(13.5, 21.7, 15.6, 21.4); p.to(10.5, 21.7)
                p.bend(8.3, 19.6, 8.4, 21.4); p.closeSubpath()
            }
            blob(Theme.hex(0x3F9BD4)) { p in
                p.go(7.75, 8.0); p.to(16.25, 8.0); p.to(15.4, 19.6)
                p.bend(13.2, 21.7, 15.3, 21.4); p.to(10.2, 21.7)
                p.bend(8.0, 19.6, 8.1, 21.4); p.closeSubpath()
            }
            blob(Theme.hex(0x68BEE8)) { p in
                p.go(7.75, 8.0); p.to(16.25, 8.0); p.to(16.13, 9.7)
                p.addCurve(to: CGPoint(x: 11.78, y: 9.48),
                           control1: CGPoint(x: 14.58, y: 10.7),
                           control2: CGPoint(x: 13.23, y: 9.15))
                p.addCurve(to: CGPoint(x: 7.88, y: 9.92),
                           control1: CGPoint(x: 10.43, y: 9.80),
                           control2: CGPoint(x: 9.33, y: 10.58))
                p.closeSubpath()
            }
            box(9.3, 5.1, 1.7, 3.6, 0.85, .white.opacity(0.8))
        }
    }
}

// MARK: - Tab icons

/// The object in a tab. Colour is what makes six tabs findable — each is a distinct
/// hue family, so you look for a silhouette rather than parsing a grey glyph.
struct TabIcon: View {
    let tab: RootView.Tab
    var size: CGFloat = 27

    var body: some View {
        Ico(size: size) {
            switch tab {
            case .home:    house
            case .focus:   hourglass
            case .games:   console
            case .learn:   books
            case .friends: heads
            case .kin:     EmptyView()   // the Kin tab draws the mascot chip instead
            }
        }
    }

    private var house: some View {
        ZStack(alignment: .topLeading) {
            blob(Theme.hex(0xE4735F)) { p in
                p.go(12, 2.6); p.to(22, 10.6); p.to(2, 10.6); p.closeSubpath()
            }
            blob(Theme.hex(0xC4523F)) { p in
                p.go(12, 2.6); p.to(22, 10.6); p.to(12, 10.6); p.closeSubpath()
            }
            box(4.6, 10.6, 14.8, 9.8, 0, Theme.hex(0xFFF1E0))
            box(9.7, 14.0, 4.6, 6.4, 1.7, Theme.hex(0x4FA6D6))
            box(5.9, 12.4, 2.8, 2.8, 0.7, Theme.hex(0xFFC24B))
            box(3.2, 20.0, 17.6, 1.8, 0.9, Theme.hex(0xC2B5A4))
        }
    }

    /// An hourglass, not a clock face. A clock reads as "time" in the abstract; an
    /// hourglass reads as "a session that runs out".
    private var hourglass: some View {
        ZStack(alignment: .topLeading) {
            blob(Theme.hex(0xBCD1DB)) { p in
                p.go(7.2, 4.4); p.to(16.8, 4.4); p.to(12, 12); p.to(16.8, 19.6)
                p.to(7.2, 19.6); p.to(12, 12); p.closeSubpath()
            }
            blob(Theme.hex(0xF0A02A)) { p in
                p.go(8.5, 5.9); p.to(15.5, 5.9); p.to(12, 11); p.closeSubpath()
            }
            blob(Theme.hex(0xD97E12)) { p in
                p.go(12, 13.3); p.to(16, 18.2); p.to(8, 18.2); p.closeSubpath()
            }
            box(11.4, 10.9, 1.2, 3.2, 0.6, Theme.hex(0xF0A02A))
            box(6.4, 4.4, 1.3, 15.2, 0, Theme.hex(0x9A7550))
            box(16.3, 4.4, 1.3, 15.2, 0, Theme.hex(0x9A7550))
            box(5.2, 2.0, 13.6, 2.6, 1.3, Theme.hex(0x7C5A3C))
            box(5.2, 19.4, 13.6, 2.6, 1.3, Theme.hex(0x7C5A3C))
        }
    }

    /// Games is lavender, not mint — mint belongs to the mascot alone.
    private var console: some View {
        ZStack(alignment: .topLeading) {
            box(2.4, 5.8, 19.2, 12.4, 4.4, Theme.hex(0x8172C9))
            foot(2.4, 14.6, 19.2, 3.6, 4.4, Theme.hex(0x6354A6))
            box(8.7, 8.2, 6.6, 5.0, 1.3, Theme.hex(0x2B2440))
            box(5.1, 10.1, 2.6, 1.2, 0.6, Theme.hex(0xFFF1E0))
            box(5.8, 9.4, 1.2, 2.6, 0.6, Theme.hex(0xFFF1E0))
            dot(17.5, 9.9, 1.15, Theme.hex(0xFF6F61))
            dot(19.4, 12.0, 1.15, Theme.hex(0xFFC24B))
        }
    }

    private var books: some View {
        ZStack(alignment: .topLeading) {
            box(3.4, 16.4, 17.2, 4.0, 1.3, Theme.hex(0x2E6E9E))
            box(5.0, 16.4, 1.6, 4.0, 0, Theme.hex(0xFFF1E0))
            box(4.6, 12.1, 14.8, 4.0, 1.3, Theme.hex(0x4FA6D6))
            box(6.2, 12.1, 1.6, 4.0, 0, Theme.hex(0xFFF1E0))
            box(3.4, 7.8, 17.2, 4.0, 1.3, Theme.hex(0x89C6E8))
            box(5.0, 7.8, 1.6, 4.0, 0, Theme.hex(0xFFF1E0))
        }
    }

    /// Two chibi heads. The left one went apricot so mint stays unique to Kin.
    private var heads: some View {
        ZStack(alignment: .topLeading) {
            dot(15.8, 12.6, 4.6, Theme.hex(0xF2A0BE))
            dot(14.4, 12.2, 0.85, Theme.hex(0x2E2622))
            dot(17.4, 12.2, 0.85, Theme.hex(0x2E2622))
            dot(8.6, 10.8, 5.6, Theme.hex(0xF5AE79))
            dot(6.9, 10.4, 1.0, Theme.hex(0x2E2622))
            dot(10.4, 10.4, 1.0, Theme.hex(0x2E2622))
            stroke(Theme.hex(0x2E2622), 1) { p in
                p.go(7.7, 12.9); p.bend(9.5, 12.9, 8.6, 13.8)
            }
        }
    }
}

/// The Kin tab's face chip. The chip has to be dark: on a pale mint or peach the
/// mascot sits at its own lightness and the crop reads as a colour swatch.
struct KinChip: View {
    var color: Color = Slime.body
    var size: CGFloat = 28

    var body: some View {
        let art = size * 1.36
        return Circle()
            .fill(Theme.kinChip)
            .frame(width: size, height: size)
            .overlay(alignment: .bottom) {
                SlimeView(color: color, level: 3, animation: .idle, size: art)
                    // Drop the body out of frame so the circle holds a face crop.
                    .offset(y: size * 0.43 + SlimeView.footInset(size: art, level: 3))
            }
            .clipShape(Circle())
    }
}
