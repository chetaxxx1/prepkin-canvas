import SwiftUI

/// The three track icons, drawn in code.
///
/// The old Learn screen used emoji (💸 🧾 🏛️) as track marks. Emoji render in
/// Apple's palette, not ours, and they change under the user. These are objects in
/// the app's own colours: a coin rising off two bars, three balanced stones, a
/// dog-eared note card. Same rule book as `PrepkinIcons` — objects rather than
/// symbols, one hue family each.
///
/// Every coordinate is in the handoff's 40×40 space, scaled to `size`.
struct TrackIcon: View {
    let trackID: String
    var size: CGFloat = 30

    var body: some View {
        Glyph40(size: size) {
            switch trackID {
            case "finance": finance
            case "philosophy": philosophy
            default: study
            }
        }
    }

    /// Money that grows rather than money you hold — and it reuses the coin the rest
    /// of the app already spends.
    private var finance: some View {
        ZStack(alignment: .topLeading) {
            rounded(5, 23, 8, 12, 2.5, Theme.coinSoft)
            rounded(15, 17, 8, 18, 2.5, Theme.coin)
            circle(28, 13, 8, Theme.coin)
            line(2.2) { p in
                p.go(28, 8.5); p.to(28, 17.5)
                p.go(25.5, 11); p.to(30.5, 11)
                p.go(25.5, 14.5); p.to(30.5, 14.5)
            }
        }
    }

    /// Thinking as something you stack carefully, rather than a Greek temple that
    /// belongs to somebody else.
    private var philosophy: some View {
        ZStack(alignment: .topLeading) {
            oval(20, 31, 13, 6, Theme.card)
            oval(20, 21, 9.5, 5.5, Theme.card)
            circle(20, 11, 5.5, Theme.card)
        }
    }

    /// The thing a student actually makes when a method works, and it echoes the
    /// card format of the reader itself.
    private var study: some View {
        ZStack(alignment: .topLeading) {
            fill(Theme.card) { p in
                p.go(12, 5); p.to(23, 5); p.to(31, 13); p.to(31, 35)
                p.corner(29, 37, 31, 37)
                p.to(12, 37)
                p.corner(10, 35, 10, 37)
                p.to(10, 7)
                p.corner(12, 5, 10, 5)
                p.closeSubpath()
            }
            line(2.2) { p in
                p.go(12, 5); p.to(23, 5); p.to(31, 13); p.to(31, 35)
                p.corner(29, 37, 31, 37)
                p.to(12, 37)
                p.corner(10, 35, 10, 37)
                p.to(10, 7)
                p.corner(12, 5, 10, 5)
                p.closeSubpath()
            }
            line(2.2) { p in p.go(23, 5); p.to(23, 13); p.to(31, 13) }
            line(2.2) { p in
                p.go(15, 22); p.to(26, 22)
                p.go(15, 28); p.to(22, 28)
            }
        }
    }
}

// MARK: - 40×40 drawing helpers

/// Lays flat shapes out on a 40×40 grid, then scales the lot to `size`.
private struct Glyph40<Content: View>: View {
    let size: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) { content() }
            .frame(width: 40, height: 40, alignment: .topLeading)
            .scaleEffect(size / 40, anchor: .topLeading)
            .frame(width: size, height: size, alignment: .topLeading)
    }
}

private struct Ink: Shape {
    let build: (inout Path) -> Void
    func path(in rect: CGRect) -> Path { var p = Path(); build(&p); return p }
}

private func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                     _ r: CGFloat, _ f: Color) -> some View {
    RoundedRectangle(cornerRadius: r, style: .continuous)
        .fill(f)
        .overlay(RoundedRectangle(cornerRadius: r, style: .continuous)
            .strokeBorder(Theme.ink, lineWidth: 2.2))
        .frame(width: w, height: h)
        .offset(x: x, y: y)
}

private func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ f: Color) -> some View {
    Circle()
        .fill(f)
        .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2.2))
        .frame(width: r * 2, height: r * 2)
        .offset(x: cx - r, y: cy - r)
}

private func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                  _ f: Color) -> some View {
    Ellipse()
        .fill(f)
        .overlay(Ellipse().strokeBorder(Theme.ink, lineWidth: 2.2))
        .frame(width: rx * 2, height: ry * 2)
        .offset(x: cx - rx, y: cy - ry)
}

private func fill(_ f: Color, _ build: @escaping (inout Path) -> Void) -> some View {
    Ink(build: build).fill(f).frame(width: 40, height: 40)
}

private func line(_ w: CGFloat, _ build: @escaping (inout Path) -> Void) -> some View {
    Ink(build: build)
        .stroke(Theme.ink, style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        .frame(width: 40, height: 40)
}

/// File-private on purpose: `PrepkinIcons` declares the same shorthand for its own
/// 24×24 space. Two private extensions never collide; one internal one would.
private extension Path {
    mutating func go(_ x: CGFloat, _ y: CGFloat) { move(to: CGPoint(x: x, y: y)) }
    mutating func to(_ x: CGFloat, _ y: CGFloat) { addLine(to: CGPoint(x: x, y: y)) }
    /// A small rounded corner, drawn as a quadratic through the corner point. Close
    /// enough to an SVG arc at these radii and much cheaper to read.
    mutating func corner(_ x: CGFloat, _ y: CGFloat, _ cx: CGFloat, _ cy: CGFloat) {
        addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }
}

// MARK: - Track surfaces

/// Per-track surface colours.
///
/// Cover panels and tiles are art surfaces, so they take the same licensed exception
/// to the low-chroma rule that figures do. Without them every card on Learn was a
/// white rectangle with a small mark on it, and the screen read as a settings list.
enum TrackTint {
    /// The panel a cover sits on.
    static func soft(_ id: String) -> Color {
        switch id {
        case "finance": return Theme.coinSoft
        case "study": return Theme.mintSoft
        default: return Theme.hex(0xEDE7FB)
        }
    }

    /// The saturated member of the family, for progress and small marks.
    static func accent(_ id: String) -> Color {
        switch id {
        case "finance": return Theme.coin
        case "study": return Theme.mint
        default: return Theme.hex(0xC3B2F0)
        }
    }

    /// Text that has to read on `soft`.
    static func ink(_ id: String) -> Color {
        switch id {
        case "finance": return Theme.coinDark
        case "study": return Theme.mintDark
        default: return Theme.hex(0x6B5CA5)
        }
    }
}
