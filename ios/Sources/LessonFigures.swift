import SwiftUI

// MARK: - Lesson figures

/// One drawing per lesson that **accretes** across the deck.
///
/// This is the whole mechanic, and there are three rules behind how these are drawn.
/// All three come from watching the reference app frame by frame.
///
/// 1. **The silhouette arrives whole, on card one.** Later steps add labels, bands
///    and sub-parts *inside* it. Nothing repositions, recolours, resizes or leaves.
///    The first build had figures that started as a small mark in a big white box and
///    grew — which read as a screen that had not finished loading.
/// 2. **Type goes inside the shape.** A word set large inside the mass it names is
///    the thing people remember; a caption beside a diagram is not.
/// 3. **Big flat colour, thin ink.** One dominant mass, one secondary, one accent,
///    over a tinted field that bleeds to the edges of the card. The 2pt outline is
///    there to crisp an edge, never to carry the drawing.
///
/// Figures are the one licensed exception to the app's low-chroma palette, the same
/// way room scenes are.
///
/// Adding a figure is three things: a case in `LessonFigure`, a view drawn in the
/// 360×300 design space below, and `"figure": "<id>"` on the lesson in `lessons.json`.
struct LessonFigure: View {
    let id: String?
    let step: Int

    var body: some View {
        switch id {
        case "compound":   CompoundFigure(step: step)
        case "budget":     BudgetFigure(step: step)
        case "fork":       ForkFigure(step: step)
        case "gauge":      GaugeFigure(step: step)
        case "scale":      ScaleFigure(step: step)
        case "index":      IndexFigure(step: step)
        case "control":    ControlFigure(step: step)
        case "why":        WhyFigure(step: step)
        case "razor":      RazorFigure(step: step)
        case "veil":       VeilFigure(step: step)
        case "map":        MapFigure(step: step)
        case "spacing":    SpacingFigure(step: step)
        case "mechanism":  MechanismFigure(step: step)
        case "recall":     RecallFigure(step: step)
        case "interleave": InterleaveFigure(step: step)
        case "reading":    ReadingFigure(step: step)
        case "start":      StartFigure(step: step)
        default: EmptyView()
        }
    }

    static let drawn: Set<String> = [
        "compound", "budget", "fork", "gauge", "scale", "index",
        "control", "why", "razor", "veil", "map",
        "spacing", "mechanism", "recall", "interleave", "reading", "start",
    ]

    static func exists(_ id: String?) -> Bool { id.map(drawn.contains) ?? false }

    /// The field a figure sits on. Also the colour a cover paints behind the drawing,
    /// so a lesson's card is tinted even where the drawing does not reach.
    static func field(_ id: String?) -> Color {
        switch id {
        case "compound", "budget", "scale", "interleave": return Fig.coinField
        case "fork", "razor", "spacing", "recall":        return Fig.leafField
        case "gauge", "why", "map", "mechanism":          return Fig.skyField
        default:                                          return Fig.lavField
        }
    }
}

// MARK: - Palette

/// Figure colours. Three fills at most per drawing: one dominant mass, one
/// secondary, one accent — over the field.
enum Fig {
    static let ink = Theme.hex(0x2E2622)
    static let paper = Theme.card

    // Fields: what the card is tinted with.
    static let coinField = Theme.hex(0xFFF4DC)
    static let leafField = Theme.hex(0xEAF4E0)
    static let skyField = Theme.hex(0xE6F0FB)
    static let lavField = Theme.hex(0xEDE7FB)

    // Masses.
    static let coin = Theme.hex(0xFFC24B)
    static let coral = Theme.hex(0xFF6F61)
    static let sky = Theme.hex(0x9BC8F2)
    static let skyDeep = Theme.hex(0x6FA3DC)
    static let leaf = Theme.hex(0xA5CE6B)
    static let leafDeep = Theme.hex(0x84B345)
    static let lav = Theme.hex(0xC3B2F0)
    static let lavDeep = Theme.hex(0x9B85E0)
    static let mint = Theme.hex(0x51CFA0)

    /// For the half of a comparison that is meant to look thin.
    static let faint = Theme.hex(0xD9CFC0)
}

// MARK: - Personal finance

/// Interest on interest. The stack and the field arrive whole; the curve, the two
/// gains, the doubling line and the late start are added on top of it.
struct CompoundFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxStroke(Fig.ink, 2.5) { $0.go(20, 250); $0.to(340, 250) }
                fxOval(64, 240, 40, 12, Fig.coin)
                fxOval(64, 220, 40, 12, Fig.coin)
                fxOval(64, 200, 40, 12, Fig.coin)
                fxText("$1,000", 21, 64, 172, weight: .black)
            }
            fxLayer(5, step) {
                fxStroke(Fig.sky, 11) { $0.go(150, 246); $0.curve(336, 176, 214, 240, 268, 216) }
                fxText("start at 28", 13, 284, 202)
            }
            fxLayer(4, step) {
                fxDash(2) { $0.go(24, 78); $0.to(344, 78) }
                fxDash(2) { $0.go(286, 78); $0.to(286, 250) }
                fxText("twice the money", 12.5, 258, 62)
                fxText("9 years", 13, 286, 268)
                fxChip("72 ÷ 8 = 9", 15, 22, 26, 116, 34, Fig.coin)
            }
            fxLayer(2, step) {
                fxStroke(Fig.leafDeep, 11) {
                    $0.go(96, 206); $0.curve(278, 140, 176, 204, 236, 184)
                    $0.curve(336, 56, 306, 116, 326, 82)
                }
                fxChip("+$80", 16, 116, 148, 76, 34, Fig.coin)
            }
            fxLayer(3, step) {
                fxStroke(Fig.ink, 2) { $0.go(192, 165); $0.to(202, 165); $0.to(202, 116); $0.to(214, 116) }
                fxChip("+$86", 16, 214, 99, 76, 34, Fig.coin)
            }
            fxLayer(5, step) { fxText("start at 18", 13, 298, 36) }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One month's money as one bar, filled a share at a time. The bar is full size from
/// the start; the shares land inside it.
struct BudgetFigure: View {
    let step: Int
    private let x0: CGFloat = 26, w: CGFloat = 308, y: CGFloat = 112, h: CGFloat = 84

    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxText("one month's money", 17, 180, 76, weight: .black)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Fig.ink, lineWidth: 2.5)
                    .frame(width: w, height: h)
                    .position(x: x0 + w / 2, y: y + h / 2)
            }
            fxLayer(2, step) { share(0, 0.50, Fig.coin, "50%", "needs", leading: true) }
            fxLayer(3, step) { share(0.50, 0.30, Fig.sky, "30%", "wants") }
            fxLayer(4, step) {
                share(0.80, 0.20, Fig.leaf, "20%", "savings", trailing: true)
                fxStroke(Fig.ink, 2) { $0.go(x0 + w * 0.90, 232); $0.to(x0 + w * 0.90, 248) }
                fxChip("moves on payday", 14, 176, 248, 168, 32, Fig.paper)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    private func share(_ at: CGFloat, _ size: CGFloat, _ fill: Color,
                       _ pct: String, _ word: String,
                       leading: Bool = false, trailing: Bool = false) -> some View {
        let sw = w * size, cx = x0 + w * at + sw / 2
        return ZStack {
            UnevenRoundedRectangle(topLeadingRadius: leading ? 14 : 0,
                                   bottomLeadingRadius: leading ? 14 : 0,
                                   bottomTrailingRadius: trailing ? 14 : 0,
                                   topTrailingRadius: trailing ? 14 : 0,
                                   style: .continuous)
                .fill(fill)
                .frame(width: sw - 5, height: h - 5)
                .position(x: cx, y: y + h / 2)
            fxText(pct, 22, cx, y + h / 2, weight: .black)
            fxText(word, 14, cx, y + h + 22)
        }
    }
}

/// One $400 repair, two ways out. The fork is drawn whole; the two ends fill in.
struct ForkFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxChip("$400 repair", 18, 106, 22, 148, 44, Fig.paper)
                fxStroke(Fig.ink, 2.5) {
                    $0.go(180, 66); $0.to(180, 92)
                    $0.go(96, 92); $0.to(264, 92)
                    $0.go(96, 92); $0.to(96, 118)
                    $0.go(264, 92); $0.to(264, 118)
                }
                fxRect(20, 118, 152, 96, 18, Fig.paper)
                fxRect(188, 118, 152, 96, 18, Fig.paper)
            }
            fxLayer(2, step) {
                fxText("cash you kept", 15, 96, 150, weight: .black)
                fxChip("paid", 15, 56, 168, 80, 32, Fig.leaf)
                fxText("gone by Tuesday", 13, 96, 240)
            }
            fxLayer(3, step) {
                fxText("a card at 24%", 15, 264, 150, weight: .black)
                fxChip("+ interest", 15, 210, 168, 108, 32, Fig.coral)
                fxText("still paying in June", 13, 264, 240)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A credit score as a dial, with the two inputs that actually move it.
struct GaugeFigure: View {
    let step: Int
    private let cx: CGFloat = 180, cy: CGFloat = 146, d: CGFloat = 208

    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                dial(to: 360, Fig.paper)
                fxText("300", 13, 60, 172)
                fxText("850", 13, 300, 172)
            }
            fxLayer(2, step) {
                dial(to: 296, Fig.skyDeep)
                fxText("712", 44, cx, 106, weight: .black)
                fxText("your score", 13, cx, 140)
            }
            fxLayer(3, step) {
                fxChip("paying on time", 14, 20, 194, 156, 38, Fig.leaf)
                fxRect(20, 240, 156, 14, 7, Fig.leaf)
                fxText("moves it most", 12.5, 98, 274)
            }
            fxLayer(4, step) {
                fxChip("how much you use", 13.5, 190, 194, 150, 38, Fig.coin)
                fxRect(190, 240, 66, 14, 7, Fig.coin)
                fxText("keep it under 30%", 12.5, 265, 274)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    /// The top half of a ring, filled from 9 o'clock round to `to`.
    private func dial(to end: Double, _ color: Color) -> some View {
        Arc(from: 180, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: 26, lineCap: .round))
            .frame(width: d, height: d)
            .position(x: cx, y: cy)
    }
}

/// Debt on a scale: what you bought on one side, the rent on the other.
struct ScaleFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxChip("the rent you pay", 15, 106, 18, 148, 36, Fig.paper)
                fxStroke(Fig.ink, 3) {
                    $0.go(180, 54); $0.to(180, 118)
                    $0.go(56, 118); $0.to(304, 118)
                    $0.go(56, 118); $0.to(56, 146)
                    $0.go(304, 118); $0.to(304, 146)
                }
                fxRect(18, 146, 148, 116, 20, Fig.paper)
                fxRect(194, 146, 148, 116, 20, Fig.paper)
            }
            fxLayer(2, step) {
                fxText("a degree", 16, 92, 178, weight: .black)
                fxStroke(Fig.leafDeep, 9) { $0.go(40, 240); $0.curve(146, 200, 78, 236, 116, 216) }
                fxText("worth more later", 12.5, 92, 274)
            }
            fxLayer(3, step) {
                fxText("a night out", 16, 268, 178, weight: .black)
                fxStroke(Fig.coral, 9) { $0.go(214, 202); $0.curve(322, 242, 250, 208, 288, 228) }
                fxText("worth nothing later", 12.5, 268, 274)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Everything versus one pick, and the fee that quietly decides it.
struct IndexFigure: View {
    let step: Int
    private let cols = 10, rows = 5

    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                ForEach(0..<(cols * rows), id: \.self) { i in
                    let c = CGFloat(i % cols), r = CGFloat(i / cols)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Fig.lav)
                        .frame(width: 22, height: 22)
                        .position(x: 42 + c * 30, y: 44 + r * 30)
                }
                fxText("every company on the list", 15, 180, 190, weight: .black)
            }
            fxLayer(2, step) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Fig.coral)
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Fig.ink, lineWidth: 2))
                    .frame(width: 28, height: 28)
                    .position(x: 192, y: 74)
                fxText("the one you picked", 13, 180, 214)
            }
            fxLayer(3, step) {
                fxRect(24, 240, 148, 40, 12, Fig.lavDeep)
                fxText("index", 15, 98, 260, color: .white, weight: .black)
                fxRect(188, 240, 92, 40, 12, Fig.faint)
                fxText("picker", 15, 234, 260, weight: .black)
                fxText("after fees, 20 years", 12.5, 180, 290)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Philosophy

/// Two columns and a line. The world gets sorted, then the arrow says where the
/// effort goes.
struct ControlFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxStroke(Fig.ink, 2.5) { $0.go(180, 22); $0.to(180, 264) }
                fxChip("yours", 17, 22, 20, 140, 44, Fig.leaf)
                fxChip("not yours", 17, 198, 20, 140, 44, Fig.sky)
            }
            fxLayer(2, step) {
                fxChip("your effort", 15, 22, 88, 140, 42, Fig.paper)
                fxChip("your reaction", 15, 22, 142, 140, 42, Fig.paper)
            }
            fxLayer(3, step) {
                fxChip("the curve", 15, 198, 88, 140, 42, Fig.paper)
                fxChip("other people", 15, 198, 142, 140, 42, Fig.paper)
                fxArrow(250, 240, 118, 206)
                fxText("spend it here", 14, 268, 268)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Three "why"s down, and the floor runs out.
struct WhyFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxRect(52, 20, 256, 54, 16, Fig.paper)
                fxText("I believe this", 17, 180, 47, weight: .black)
            }
            fxLayer(2, step) {
                fxArrow(180, 76, 180, 100)
                fxChip("why?", 14, 196, 76, 64, 26, Fig.lavDeep, color: .white)
                fxRect(52, 104, 256, 54, 16, Fig.paper)
                fxText("because of a reason", 16, 180, 131)
            }
            fxLayer(3, step) {
                fxArrow(180, 160, 180, 184)
                fxChip("why?", 14, 196, 160, 64, 26, Fig.lavDeep, color: .white)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Fig.ink.opacity(0.45),
                                  style: StrokeStyle(lineWidth: 2.5, dash: [8, 7]))
                    .frame(width: 256, height: 54)
                    .position(x: 180, y: 215)
                fxText("…", 26, 180, 212, weight: .black)
                fxText("most beliefs run out of floor here", 14, 180, 274)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Two explanations for the same fact. The short one gets tested first — which is
/// not the same as being right.
struct RazorFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxChip("it broke", 17, 118, 16, 124, 44, Fig.paper)
                fxStroke(Fig.ink, 2.5) {
                    $0.go(180, 60); $0.to(180, 84)
                    $0.go(96, 84); $0.to(264, 84)
                    $0.go(96, 84); $0.to(96, 106)
                    $0.go(264, 84); $0.to(264, 106)
                }
            }
            fxLayer(2, step) {
                fxRect(22, 106, 148, 48, 14, Fig.leaf)
                fxText("the line you changed", 13.5, 96, 130, weight: .black)
                fxChip("test this first", 13, 22, 168, 148, 32, Fig.paper)
            }
            fxLayer(3, step) {
                fxRect(190, 106, 148, 40, 12, Fig.paper)
                fxText("a compiler bug", 13, 264, 126)
                fxArrow(264, 148, 264, 166)
                fxRect(190, 168, 148, 40, 12, Fig.paper)
                fxText("…and three more ifs", 12.5, 264, 188)
                fxText("cheaper to check ≠ true", 14, 180, 272)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Write the rule, then get handed a life at random.
struct VeilFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxRect(56, 18, 248, 58, 16, Fig.paper)
                fxText("the rule you write", 16, 180, 47, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(0, 104, 360, 48, 0, Fig.lavDeep)
                fxText("the veil", 17, 180, 128, color: .white, weight: .black)
            }
            fxLayer(3, step) {
                fxChip("a job after school", 13, 14, 182, 156, 38, Fig.paper)
                fxChip("no job", 13, 186, 182, 156, 38, Fig.paper)
                fxChip("a quiet house", 13, 14, 228, 156, 38, Fig.paper)
                fxChip("three siblings", 13, 186, 228, 156, 38, Fig.paper)
                fxText("you get one at random", 14, 180, 282)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The map lies on the territory. What it drops is the whole question.
struct MapFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxPoly(Fig.leaf) { p in
                    p.go(28, 108)
                    p.curve(126, 34, 44, 56, 78, 36)
                    p.curve(250, 62, 176, 32, 216, 44)
                    p.curve(330, 156, 296, 82, 336, 112)
                    p.curve(206, 260, 322, 214, 268, 254)
                    p.curve(28, 108, 128, 268, 20, 200)
                }
                fxText("the territory", 15, 180, 276, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(96, 84, 172, 116, 10, Fig.paper)
                ForEach(0..<3, id: \.self) { i in
                    fxStroke(Fig.skyDeep, 2) {
                        $0.go(96, 113 + CGFloat(i) * 29); $0.to(268, 113 + CGFloat(i) * 29)
                    }
                }
                ForEach(0..<4, id: \.self) { i in
                    fxStroke(Fig.skyDeep, 2) {
                        $0.go(130 + CGFloat(i) * 34, 84); $0.to(130 + CGFloat(i) * 34, 200)
                    }
                }
                fxText("the map", 15, 182, 220, weight: .black)
            }
            fxLayer(3, step) {
                fxOval(58, 92, 15, 15, Fig.coral)
                fxOval(300, 196, 15, 15, Fig.coral)
                fxOval(76, 214, 15, 15, Fig.coral)
                fxText("what it left out", 14, 180, 20)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Study skills

/// The forgetting curve, and what a gap does to it.
struct SpacingFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxStroke(Fig.ink, 2.5) { $0.go(30, 42); $0.to(30, 216); $0.to(340, 216) }
                fxText("what sticks", 12.5, 84, 30)
                fxText("time", 12.5, 320, 236)
                fxStroke(Fig.coral, 8) {
                    $0.go(30, 58); $0.curve(200, 200, 76, 168, 128, 194)
                    $0.curve(336, 208, 254, 204, 300, 207)
                }
                fxText("one long cram", 13.5, 240, 182, weight: .black)
            }
            fxLayer(2, step) {
                fxStroke(Fig.leafDeep, 8) {
                    $0.go(30, 58); $0.curve(96, 120, 52, 102, 74, 116)
                    $0.go(96, 76); $0.curve(170, 132, 122, 116, 148, 128)
                    $0.go(170, 84); $0.curve(250, 128, 200, 118, 226, 124)
                    $0.go(250, 76); $0.curve(336, 108, 286, 100, 312, 104)
                }
                ForEach(0..<3, id: \.self) { i in
                    fxOval(96 + CGFloat(i) * 77, [120, 132, 128][i], 8, 8, Fig.leafDeep)
                }
            }
            fxLayer(3, step) {
                fxChip("the gap is doing the work", 14, 66, 236, 228, 34, Fig.paper)
                fxText("same hour, split over six days", 12.5, 180, 288)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A term you can highlight, versus a mechanism you can draw.
struct MechanismFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxRect(48, 18, 264, 52, 14, Fig.paper)
                fxRect(64, 32, 196, 24, 6, Fig.coin)
                fxText("osmosis: movement of water", 14, 180, 44, weight: .black)
                fxText("you can highlight this", 12.5, 180, 84)
            }
            fxLayer(2, step) {
                fxRect(30, 116, 116, 96, 16, Fig.sky)
                fxText("less salt", 14, 88, 164, weight: .black)
                fxRect(214, 116, 116, 96, 16, Fig.skyDeep)
                fxText("more salt", 14, 272, 164, color: .white, weight: .black)
                fxArrow(150, 164, 208, 164)
                fxText("water", 12.5, 180, 142)
            }
            fxLayer(3, step) {
                fxChip("you can draw this", 14, 84, 240, 192, 34, Fig.leaf)
                fxText("that's the one a quiz asks for", 12.5, 180, 284)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The blank page and the notes. The gap between them is the study list.
struct RecallFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxRect(22, 40, 148, 190, 16, Fig.paper)
                fxRect(190, 40, 148, 190, 16, Fig.paper)
                fxText("from memory", 14, 96, 22, weight: .black)
                fxText("your notes", 14, 264, 22, weight: .black)
            }
            fxLayer(2, step) {
                rule(44, 78, 104); rule(44, 108, 84); rule(44, 138, 96)
            }
            fxLayer(3, step) {
                rule(212, 78, 104); rule(212, 108, 84); rule(212, 138, 96)
                mark(212, 170, 100); mark(212, 200, 76)
                fxChip("this is your study list", 14, 168, 244, 180, 34, Fig.leaf)
                fxArrow(258, 240, 276, 218)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    private func rule(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat) -> some View {
        Capsule().fill(Fig.ink.opacity(0.7))
            .frame(width: w, height: 7).position(x: x + w / 2, y: y)
    }

    private func mark(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat) -> some View {
        Capsule().fill(Fig.leaf)
            .overlay(Capsule().strokeBorder(Fig.ink, lineWidth: 1.5))
            .frame(width: w, height: 12).position(x: x + w / 2, y: y)
    }
}

/// Blocked practice against mixed practice, and what the test actually looks like.
struct InterleaveFigure: View {
    let step: Int
    private let order: [Int] = [0, 0, 0, 1, 1, 1]
    private let mixed: [Int] = [0, 1, 1, 0, 1, 0]

    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxText("how the homework comes", 15, 180, 26, weight: .black)
                row(order, y: 50, labelled: true)
                fxText("the heading already told you", 12.5, 180, 100)
            }
            fxLayer(2, step) {
                fxText("how to practise it", 15, 180, 138, weight: .black)
                row(mixed, y: 160, labelled: true)
            }
            fxLayer(3, step) {
                row(mixed, y: 224, labelled: false)
                fxText("how the test comes — nothing is labelled", 12.5, 180, 282)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    private func row(_ kinds: [Int], y: CGFloat, labelled: Bool) -> some View {
        ForEach(Array(kinds.enumerated()), id: \.offset) { i, k in
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(labelled ? (k == 0 ? Fig.coin : Fig.sky) : Fig.paper)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Fig.ink, lineWidth: 2))
                    .frame(width: 46, height: 40)
                if labelled {
                    fxText(k == 0 ? "A" : "B", 17, 23, 20, weight: .black)
                } else {
                    fxText("?", 17, 23, 20, weight: .black)
                }
            }
            .frame(width: 46, height: 40)
            .position(x: 52 + CGFloat(i) * 52, y: y + 20)
        }
    }
}

/// A heading turned into a question, then four sentences with the book shut.
struct ReadingFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxRect(20, 30, 168, 210, 16, Fig.paper)
                fxRect(40, 52, 116, 22, 6, Fig.lavDeep)
                ForEach(0..<5, id: \.self) { i in
                    Capsule().fill(Fig.ink.opacity(0.18))
                        .frame(width: i == 4 ? 76 : 128, height: 7)
                        .position(x: 40 + (i == 4 ? 38 : 64), y: 100 + CGFloat(i) * 26)
                }
                fxText("a chapter", 13.5, 104, 258)
            }
            fxLayer(2, step) {
                fxChip("how does it work?", 14, 200, 48, 148, 34, Fig.coin)
                fxArrow(196, 65, 166, 63)
            }
            fxLayer(3, step) {
                fxRect(206, 118, 134, 122, 14, Fig.paper)
                ForEach(0..<4, id: \.self) { i in
                    Capsule().fill(Fig.lavDeep)
                        .frame(width: i == 3 ? 62 : 98, height: 8)
                        .position(x: 224 + (i == 3 ? 31 : 49), y: 146 + CGFloat(i) * 24)
                }
                fxText("four sentences, book shut", 12.5, 272, 258)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The whole task next to the only part you actually commit to.
struct StartFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxRect(26, 60, 308, 84, 18, Fig.faint)
                fxText("the whole essay", 19, 180, 102, weight: .black)
                fxText("this is the part you're dreading", 12.5, 180, 40)
            }
            fxLayer(2, step) {
                fxRect(26, 168, 62, 68, 14, Fig.coral)
                fxText("5", 26, 57, 194, color: .white, weight: .black)
                fxText("min", 12, 57, 218, color: .white)
                fxChip("then you may stop", 14, 100, 184, 176, 36, Fig.paper)
            }
            fxLayer(3, step) {
                fxArrow(92, 254, 300, 254)
                fxText("most of the time, you don't", 13, 196, 282)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Design space

/// Lays a figure out in its own 360×300 point space, then scales it to fit whatever
/// box it is given. The field colour paints the whole box, so a wider frame — a cover
/// on Learn — is tinted edge to edge with the drawing centred in it.
private struct FigureCanvas<Content: View>: View {
    static var W: CGFloat { 360 }
    static var H: CGFloat { 300 }

    let field: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Self.W, geo.size.height / Self.H)
            ZStack {
                field
                ZStack(alignment: .topLeading) { content() }
                    .frame(width: Self.W, height: Self.H, alignment: .topLeading)
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

/// The aspect every figure is drawn at, so the reader can size its band to match.
enum FigureSpace {
    static let aspect: CGFloat = 360.0 / 300.0
}

extension Fig {
    /// One reveal: fade and rise 8pt. Nothing else in a figure ever moves.
    static let reveal = Animation.easeOut(duration: 0.28)
}

// MARK: - Primitives

/// A group that fades and rises into place at its step, and never leaves.
@ViewBuilder
private func fxLayer<Content: View>(_ at: Int, _ step: Int,
                                    @ViewBuilder _ content: () -> Content) -> some View {
    let on = step >= at
    content()
        .opacity(on ? 1 : 0)
        .offset(y: on ? 0 : 8)
}

private struct FxShape: Shape {
    let build: (inout Path) -> Void
    func path(in rect: CGRect) -> Path { var p = Path(); build(&p); return p }
}

/// A partial ring, measured in degrees clockwise from 3 o'clock.
private struct Arc: Shape {
    let from: Double
    let to: Double
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.midY), radius: r.width / 2,
                 startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
        return p
    }
}

private func fxRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat,
                    _ fill: Color, stroke: CGFloat = 2) -> some View {
    RoundedRectangle(cornerRadius: r, style: .continuous)
        .fill(fill)
        .overlay(RoundedRectangle(cornerRadius: r, style: .continuous)
            .strokeBorder(Fig.ink, lineWidth: stroke))
        .frame(width: w, height: h)
        .position(x: x + w / 2, y: y + h / 2)
}

private func fxOval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                    _ fill: Color, stroke: CGFloat = 2) -> some View {
    Ellipse()
        .fill(fill)
        .overlay(Ellipse().strokeBorder(Fig.ink, lineWidth: stroke))
        .frame(width: rx * 2, height: ry * 2)
        .position(x: cx, y: cy)
}

private func fxPoly(_ fill: Color, stroke: CGFloat = 2.5,
                    _ build: @escaping (inout Path) -> Void) -> some View {
    ZStack(alignment: .topLeading) {
        FxShape(build: build).fill(fill)
        FxShape(build: build)
            .stroke(Fig.ink, style: StrokeStyle(lineWidth: stroke, lineJoin: .round))
    }
    .frame(width: FigureCanvasMetrics.w, height: FigureCanvasMetrics.h, alignment: .topLeading)
}

private func fxStroke(_ color: Color, _ w: CGFloat,
                      _ build: @escaping (inout Path) -> Void) -> some View {
    FxShape(build: build)
        .stroke(color, style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        .frame(width: FigureCanvasMetrics.w, height: FigureCanvasMetrics.h, alignment: .topLeading)
}

private func fxDash(_ w: CGFloat, _ build: @escaping (inout Path) -> Void) -> some View {
    FxShape(build: build)
        .stroke(Fig.ink.opacity(0.45), style: StrokeStyle(lineWidth: w, dash: [8, 6]))
        .frame(width: FigureCanvasMetrics.w, height: FigureCanvasMetrics.h, alignment: .topLeading)
}

private func fxArrow(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                     _ color: Color = Fig.ink, _ w: CGFloat = 2.5) -> some View {
    let a = atan2(y2 - y1, x2 - x1)
    let head: CGFloat = 11
    return fxStroke(color, w) { p in
        p.go(x1, y1); p.to(x2, y2)
        p.go(x2, y2); p.to(x2 - head * cos(a - .pi / 7), y2 - head * sin(a - .pi / 7))
        p.go(x2, y2); p.to(x2 - head * cos(a + .pi / 7), y2 - head * sin(a + .pi / 7))
    }
}

/// Type, centred on a point. Figures set their words inside the shapes they name, so
/// everything here positions by centre rather than by baseline.
private func fxText(_ s: String, _ size: CGFloat, _ cx: CGFloat, _ cy: CGFloat,
                    color: Color = Fig.ink, weight: Font.Weight = .heavy) -> some View {
    Text(s)
        .font(Theme.font(size, weight))
        .foregroundStyle(color)
        .fixedSize()
        .position(x: cx, y: cy)
}

/// A filled, outlined label, given in rect terms with its text centred inside.
private func fxChip(_ s: String, _ size: CGFloat,
                    _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                    _ fill: Color, color: Color = Fig.ink) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: h / 2, style: .continuous)
            .fill(fill)
            .overlay(RoundedRectangle(cornerRadius: h / 2, style: .continuous)
                .strokeBorder(Fig.ink, lineWidth: 2))
        Text(s)
            .font(Theme.font(size, .heavy))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 10)
    }
    .frame(width: w, height: h)
    .position(x: x + w / 2, y: y + h / 2)
}

/// The design space, as plain numbers the path helpers can size themselves to.
private enum FigureCanvasMetrics {
    static let w: CGFloat = 360
    static let h: CGFloat = 300
}

/// Path shorthand in the figure design space. File-private so it never collides with
/// the identically-named helpers in the icon files.
private extension Path {
    mutating func go(_ x: CGFloat, _ y: CGFloat) { move(to: CGPoint(x: x, y: y)) }
    mutating func to(_ x: CGFloat, _ y: CGFloat) { addLine(to: CGPoint(x: x, y: y)) }
    mutating func curve(_ x: CGFloat, _ y: CGFloat,
                        _ c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat) {
        addCurve(to: CGPoint(x: x, y: y),
                 control1: CGPoint(x: c1x, y: c1y), control2: CGPoint(x: c2x, y: c2y))
    }
}
