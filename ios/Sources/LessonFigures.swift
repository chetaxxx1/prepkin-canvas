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
        case "slots":      SlotsFigure(step: step)
        case "refresh":    RefreshFigure(step: step)
        case "sunk":       SunkFigure(step: step)
        case "filter":     FilterFigure(step: step)
        case "spotlight":  SpotlightFigure(step: step)
        case "loop":       LoopFigure(step: step)
        case "arousal":    ArousalFigure(step: step)
        case "email":      EmailFigure(step: step)
        case "no":         NoFigure(step: step)
        case "echo":       EchoFigure(step: step)
        case "ladder":     LadderFigure(step: step)
        case "apology":    ApologyFigure(step: step)
        case "paycheck":   PaycheckFigure(step: step)
        case "brackets":   BracketsFigure(step: step)
        case "jar":        JarFigure(step: step)
        case "burrito":    BurritoFigure(step: step)
        case "trolley":    TrolleyFigure(step: step)
        case "ship":       ShipFigure(step: step)
        case "cave":       CaveFigure(step: step)
        case "cornell":    CornellFigure(step: step)
        case "feynman":    FeynmanFigure(step: step)
        case "sleep":      SleepFigure(step: step)
        case "exam":       ExamFigure(step: step)
        default: EmptyView()
        }
    }

    static let drawn: Set<String> = [
        "compound", "budget", "fork", "gauge", "scale", "index",
        "control", "why", "razor", "veil", "map",
        "spacing", "mechanism", "recall", "interleave", "reading", "start",
        "slots", "refresh", "sunk", "filter", "spotlight", "loop", "arousal",
        "scene-slots", "scene-refresh", "scene-sunk", "scene-cave",
        "scene-filter", "scene-spotlight", "scene-loop",
        "email", "no", "echo", "ladder", "apology",
        "paycheck", "brackets", "jar", "burrito",
        "trolley", "ship", "cave",
        "cornell", "feynman", "sleep", "exam",
    ]

    static func exists(_ id: String?) -> Bool { id.map(drawn.contains) ?? false }

    /// The field a figure sits on. Also the colour a cover paints behind the drawing,
    /// so a lesson's card is tinted even where the drawing does not reach.
    static func field(_ id: String?) -> Color {
        switch id {
        case "compound", "budget", "scale", "interleave",
             "slots", "sunk", "paycheck", "brackets", "jar", "burrito": return Fig.coinField
        case "fork", "razor", "spacing", "recall",
             "filter", "cornell", "feynman", "exam":                   return Fig.leafField
        case "gauge", "why", "map", "mechanism",
             "refresh", "loop", "arousal", "trolley", "sleep":         return Fig.skyField
        case "email", "no", "echo", "ladder", "apology":               return Fig.roseField
        default:                                                       return Fig.lavField
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
    static let roseField = Theme.hex(0xFFEDE7)

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

    /// Where a figure's hero object comes from. The app reads the `fig-*` vector image
    /// sets (Recraft SVGs packed by design/figure-art/pack.py); the figure renderer
    /// that draws contact sheets on a Mac swaps in a file loader.
    static var artLoader: (String) -> Image = { Image($0) }
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

// MARK: - Psychology

/// Four slots in a tray. The tray arrives whole; the items, the fifth thing that has
/// nowhere to go, and the chunking trick land on it.
struct SlotsFigure: View {
    let step: Int
    private let names = ["song", "text", "phone", "chem"]
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxRect(24, 76, 268, 118, 22, Fig.sky)
                fxText("working memory", 15, 158, 96, weight: .black)
                ForEach(0..<4, id: \.self) { i in
                    fxRect(38 + CGFloat(i) * 64, 112, 54, 66, 14, Fig.paper, stroke: 0)
                }
            }
            fxLayer(2, step) {
                ForEach(0..<4, id: \.self) { i in
                    fxRect(42 + CGFloat(i) * 64, 116, 46, 58, 12, Fig.coin)
                    fxText(names[i], 12, 65 + CGFloat(i) * 64, 145)
                }
            }
            fxLayer(3, step) {
                fxRect(298, 128, 48, 60, 12, Fig.coral)
                fxText("the", 11, 322, 148, color: .white, weight: .black)
                fxText("formula", 11, 322, 164, color: .white, weight: .black)
                fxStroke(Fig.ink, 2.5) { $0.go(288, 126); $0.to(302, 118) }
                fxStroke(Fig.ink, 2.5) { $0.go(292, 146); $0.to(306, 140) }
                fxText("no room", 12, 320, 206)
            }
            fxLayer(4, step) {
                fxChip("8675309 · 7 things", 12, 16, 20, 152, 30, Fig.paper)
                fxChip("867-5309 · 2 things", 12, 190, 20, 152, 30, Fig.leaf)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A thumb pulling a feed down. What the pull returns lands to the right of the phone,
/// then the reason it works, then the setting that ends it.
struct RefreshFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxArt("scene-refresh", 0, 30, 360, 240)
                fxText("pull", 12, 152, 196)
            }
            fxLayer(2, step) {
                fxStroke(Fig.ink, 2) { $0.go(176, 113); $0.to(192, 113) }
                fxChip("nothing", 12, 194, 70, 146, 26, Fig.paper)
                fxChip("nothing", 12, 194, 100, 146, 26, Fig.paper)
                fxChip("a like!", 12, 194, 130, 146, 26, Fig.coral, color: .white)
            }
            fxLayer(3, step) {
                fxText("sometimes", 12.5, 267, 166, weight: .black)
                fxText("beats always", 12, 267, 182)
            }
            fxLayer(4, step) {
                fxStroke(Fig.ink.opacity(0.35), 1.5) { $0.go(196, 190); $0.to(338, 190) }
                fxChip("alerts off", 13, 208, 210, 118, 30, Fig.leaf)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A ticket torn at "now". The stub behind the tear is spent and goes grey; the half
/// in front of it is still yours. Each verdict sits under its own half.
struct SunkFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxText("the bad movie", 17, 180, 34, weight: .black)
                fxArt("ticket", 36, 66, 288, 158)
                fxText("ADMIT ONE", 12, 80, 112, color: Fig.ink.opacity(0.75))
                fxText("$15", 21, 80, 144, weight: .black)
                fxOval(131, 58, 4, 4, Fig.ink, stroke: 0)
                fxStroke(Fig.ink, 2) { $0.go(131, 62); $0.to(131, 76) }
                fxText("now", 12, 131, 46)
            }
            fxLayer(2, step) {
                fxRect(44, 78, 84, 134, 10, Fig.faint.opacity(0.62), stroke: 0)
                fxChip("gone either way", 12, 20, 236, 132, 30, Fig.faint)
            }
            fxLayer(3, step) { fxChip("90 min still yours", 12, 148, 130, 152, 32, Fig.leaf) }
            fxLayer(4, step) { fxChip("only the future votes", 12, 176, 236, 164, 30, Fig.coral, color: .white) }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Facts hit a funnel. The ones that fit sail through to what you believe.
struct FilterFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxText("facts", 13, 72, 46)
                fxOval(40, 82, 9, 9, Fig.leafDeep); fxOval(82, 122, 9, 9, Fig.leafDeep)
                fxOval(58, 172, 9, 9, Fig.leafDeep); fxOval(96, 212, 9, 9, Fig.leafDeep)
                fxOval(80, 72, 9, 9, Fig.faint); fxOval(44, 132, 9, 9, Fig.faint)
                fxOval(102, 158, 9, 9, Fig.faint); fxOval(44, 206, 9, 9, Fig.faint)
                fxArt("funnel", 112, 56, 136, 133)
                fxRect(256, 108, 86, 84, 18, Fig.coin)
                fxText("what", 13, 299, 138, weight: .black)
                fxText("you think", 13, 299, 158, weight: .black)
            }
            fxLayer(2, step) {
                fxOval(180, 92, 8, 8, Fig.leafDeep); fxOval(170, 118, 8, 8, Fig.leafDeep)
                fxOval(186, 140, 8, 8, Fig.leafDeep)
                fxArrow(180, 192, 254, 166, Fig.leafDeep, 4)
                fxText("fits, sails in", 12, 300, 214)
            }
            fxLayer(3, step) {
                fxOval(118, 96, 8, 8, Fig.faint)
                fxArrow(124, 104, 106, 128, Fig.ink, 2)
                fxText("doesn't fit, skipped", 12, 76, 240)
            }
            fxLayer(4, step) { fxChip("hunt for what breaks it", 12.5, 128, 250, 208, 30, Fig.coral, color: .white) }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One person lit on a stage, four more each under their own small light.
struct SpotlightFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxArt("scene-spotlight", 0, 30, 360, 240)
                fxText("you", 15, 170, 140, weight: .black)
            }
            fxLayer(2, step) { fxText("everyone in their own light", 12.5, 180, 272, weight: .black) }
            fxLayer(3, step) {
                fxChip("you guessed 50%", 12, 16, 22, 140, 30, Fig.paper)
                fxChip("really 25%", 12, 214, 22, 118, 30, Fig.leaf)
            }
            fxLayer(4, step) {
                fxRect(58, 152, 42, 100, 0, Fig.lavField.opacity(0.72), stroke: 0)
                fxRect(266, 152, 42, 100, 0, Fig.lavField.opacity(0.72), stroke: 0)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A ring in three colours. The cue and reward stay; the routine is the swap.
struct LoopFigure: View {
    let step: Int
    private func arc(_ from: Double, _ to: Double, _ color: Color, _ width: CGFloat = 24) -> some View {
        fxStroke(color, width) { $0.addArc(center: CGPoint(x: 180, y: 142), radius: 68,
                                           startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false) }
    }
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                arc(0, 360, Fig.ink, 28)
                arc(0, 360, Fig.sky)
                fxText("habit", 22, 180, 142, weight: .black)
            }
            fxLayer(2, step) {
                arc(210, 330, Fig.coin)
                fxStroke(Fig.ink, 2) { $0.go(180, 62); $0.to(180, 50) }
                fxChip("cue: sit on the bed", 13, 92, 18, 176, 32, Fig.paper)
            }
            fxLayer(3, step) {
                arc(-30, 90, Fig.coral)
                fxStroke(Fig.ink, 2) { $0.go(228, 190); $0.to(250, 246) }
                fxChip("routine: open the feed", 12.5, 178, 246, 164, 32, Fig.paper)
            }
            fxLayer(4, step) {
                arc(90, 210, Fig.leaf)
                fxStroke(Fig.ink, 2) { $0.go(132, 190); $0.to(110, 246) }
                fxChip("reward: 20 min off", 12.5, 18, 246, 156, 32, Fig.paper)
            }
            fxLayer(5, step) { fxChip("swap this", 12.5, 132, 160, 96, 28, Fig.coral, color: .white) }
            fxLayer(1, step) {
                ForEach([-30.0, 90.0, 210.0], id: \.self) { a in
                    let r = a * .pi / 180
                    let px = 180 + 68 * cos(r), py = 142 + 68 * sin(r)
                    let dx = -sin(r), dy = cos(r)
                    fxArrow(px - 11 * dx, py - 11 * dy, px + 11 * dx, py + 11 * dy, Fig.ink, 3)
                }
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One heart with a pulse line, two labels. The body doesn't change; the word does.
struct ArousalFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxArt("heart", 70, 62, 220, 165)
            }
            fxLayer(2, step) {
                fxArrow(104, 90, 82, 62, Fig.ink, 2)
                fxChip("threat", 15, 18, 22, 116, 38, Fig.faint)
            }
            fxLayer(3, step) {
                fxArrow(256, 90, 278, 62, Fig.ink, 2)
                fxChip("excited", 15, 226, 22, 116, 38, Fig.leaf)
            }
            fxLayer(4, step) { fxChip("same body, different label", 12.5, 80, 252, 200, 28, Fig.paper) }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - People skills

/// An envelope with the letter pulled half out. The four lines land on the letter.
struct EmailFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxRect(24, 20, 312, 262, 20, Fig.paper)
                fxRect(24, 240, 312, 42, 20, Fig.coral, stroke: 0)
                fxPoly(Fig.coral, stroke: 2.5) { p in p.go(24, 240); p.to(180, 282); p.to(336, 240) }
                fxLeft("To: Ms. Rivera", 14, 42, 48, 280, weight: .black)
                fxLeft("Subject: Bio lab report", 12.5, 42, 72, 280, color: Fig.ink.opacity(0.6))
                fxDash(2) { $0.go(40, 92); $0.to(320, 92) }
            }
            fxLayer(2, step) { fxChip("1 · Bio lab report, due Friday", 12.5, 40, 100, 280, 30, Fig.faint) }
            fxLayer(3, step) { fxChip("2 · Could I turn it in Monday 8am?", 12.5, 40, 136, 280, 30, Fig.coin) }
            fxLayer(4, step) { fxChip("3 · Draft attached, two parts done", 12.5, 40, 172, 280, 30, Fig.leaf) }
            fxLayer(5, step) {
                fxChip("4 · Thanks.", 12.5, 40, 208, 130, 30, Fig.paper)
                fxChip("Send", 14, 250, 208, 70, 30, Fig.coral, color: .white)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A wall that says no. The three lines are written on it; every excuse is a door in it.
struct NoFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxRect(24, 24, 312, 228, 22, Fig.coral)
                fxText("no", 44, 180, 68, color: .white, weight: .black)
            }
            fxLayer(2, step) { fxChip("thanks for thinking of me", 13, 48, 96, 264, 32, Fig.paper) }
            fxLayer(3, step) { fxChip("I can't this weekend", 15, 48, 134, 264, 36, Fig.coin) }
            fxLayer(4, step) { fxChip("but I'm free Tuesday", 13, 48, 176, 264, 32, Fig.leaf) }
            fxLayer(5, step) {
                fxRect(120, 208, 120, 42, 8, Fig.faint)
                fxOval(232, 230, 3.5, 3.5, Fig.ink, stroke: 0)
                fxText("I have so much", 11, 176, 222)
                fxText("homework and…", 11, 176, 237)
                fxText("every excuse is a door", 12, 180, 272)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A friend's line, the reply that ends it, and the reply that keeps it going.
struct EchoFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxRect(20, 24, 210, 60, 20, Fig.lav)
                fxPoly(Fig.lav, stroke: 2) { p in p.go(44, 82); p.to(66, 82); p.to(38, 100); p.closeSubpath() }
                fxStroke(Fig.lav, 4) { $0.go(46, 83); $0.to(64, 83) }
                fxText("I completely bombed that test", 12.5, 125, 54, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(112, 106, 228, 48, 18, Fig.faint)
                fxText("you'll be fine", 13, 226, 130)
                fxStroke(Fig.ink, 3) { $0.go(178, 130); $0.to(274, 130) }
                fxText("ends it", 11.5, 80, 130)
            }
            fxLayer(3, step) {
                fxRect(112, 170, 228, 58, 20, Fig.leaf)
                fxText("sounds like it really got to you", 12.5, 226, 199, weight: .black)
            }
            fxLayer(4, step) { fxChip("what part went wrong?", 12.5, 112, 244, 228, 32, Fig.paper) }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A step ladder; each follow-up question hangs off a rung higher.
struct LadderFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxText("small talk", 17, 180, 32, weight: .black)
                fxArt("ladder", 18, 52, 150, 224)
            }
            fxLayer(2, step) { fxChip("where are you from?", 12.5, 140, 178, 196, 32, Fig.paper) }
            fxLayer(3, step) { fxChip("what do you like about it?", 12.5, 140, 130, 196, 32, Fig.paper) }
            fxLayer(4, step) { fxChip("how did you get into that?", 12.5, 140, 82, 196, 32, Fig.leaf) }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Two banks and a gap. The three parts are the planks that bridge it; "but" and "if" saw them.
struct ApologyFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxRect(0, 92, 96, 208, 0, Fig.leaf, stroke: 0)
                fxRect(264, 92, 96, 208, 0, Fig.leaf, stroke: 0)
                fxStroke(Fig.ink, 2.5) { $0.go(0, 92); $0.to(96, 92); $0.go(264, 92); $0.to(360, 92) }
                fxText("you", 14, 48, 236, weight: .black)
                fxText("them", 14, 312, 236, weight: .black)
                fxText("sorry", 22, 180, 46, weight: .black)
            }
            fxLayer(2, step) { fxChip("1 · what I did", 13, 84, 96, 192, 34, Fig.coin) }
            fxLayer(3, step) { fxChip("2 · what it cost you", 13, 84, 134, 192, 34, Fig.coral, color: .white) }
            fxLayer(4, step) { fxChip("3 · what changes", 13, 84, 172, 192, 34, Fig.paper) }
            fxLayer(5, step) {
                fxChip("but", 14, 104, 230, 64, 30, Fig.faint)
                fxChip("if", 14, 192, 230, 64, 30, Fig.faint)
                fxStroke(Fig.ink, 3) { $0.go(112, 245); $0.to(160, 245); $0.go(200, 245); $0.to(248, 245) }
                fxStroke(Fig.ink.opacity(0.7), 3) { $0.go(96, 206); $0.to(264, 96) }
                fxText("cancel all three", 11, 180, 274)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Personal finance, continued

/// A pay stub. Gross in the top band, the deductions land one row at a time, net in the bottom band.
struct PaycheckFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxRect(50, 20, 260, 262, 18, Fig.paper)
                fxRect(50, 20, 260, 96, 18, Fig.coin, stroke: 0)
                fxRect(50, 86, 260, 30, 0, Fig.coin, stroke: 0)
                fxStroke(Fig.ink, 2) { $0.go(50, 116); $0.to(310, 116) }
                fxText("PAY STUB", 12, 180, 40, color: Fig.ink.opacity(0.75))
                fxText("$1,000", 27, 180, 72, weight: .black)
                fxText("gross", 12, 180, 98)
            }
            fxLayer(2, step) { row("Social Security 6.2%", "−$62", 136) }
            fxLayer(3, step) { row("Medicare 1.45%", "−$14.50", 160) }
            fxLayer(4, step) { row("income tax, varies", "−$0 to $100", 184) }
            fxLayer(5, step) {
                fxRect(50, 208, 260, 74, 18, Fig.leaf, stroke: 0)
                fxRect(50, 208, 260, 30, 0, Fig.leaf, stroke: 0)
                fxStroke(Fig.ink, 2) { $0.go(50, 208); $0.to(310, 208) }
                fxText("take-home", 12, 180, 228)
                fxText("$825–925", 24, 180, 256, weight: .black)
            }
            fxLayer(1, step) {
                fxStroke(Fig.ink, 2) { $0.addRoundedRect(in: CGRect(x: 50, y: 20, width: 260, height: 262),
                                                          cornerSize: CGSize(width: 18, height: 18)) }
            }
        }
        .animation(Fig.reveal, value: step)
    }

    private func row(_ label: String, _ amount: String, _ y: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            fxLeft(label, 12.5, 66, y, 160)
            fxRight(amount, 12.5, 294, y, 110, color: Fig.coral)
        }
    }
}

/// Three stacked buckets. Income fills from the bottom; only the spill pays the top rate.
struct BracketsFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxText("2025 · single filer", 11, 180, 34, color: Fig.ink.opacity(0.55))
                fxRect(98, 200, 168, 70, 12, Fig.paper); fxText("10%", 22, 182, 235, weight: .black)
                fxRect(98, 126, 168, 70, 12, Fig.paper); fxText("12%", 22, 182, 161, weight: .black)
                fxRect(98, 52, 168, 70, 12, Fig.paper);  fxText("22%", 22, 182, 87, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(102, 204, 160, 62, 9, Fig.coin, stroke: 0); fxText("10%", 22, 182, 235, weight: .black)
                fxText("$11,925", 11, 232, 212)
            }
            fxLayer(3, step) {
                fxRect(102, 130, 160, 62, 9, Fig.leaf, stroke: 0); fxText("12%", 22, 182, 161, weight: .black)
                fxText("$48,475", 11, 232, 138)
            }
            fxLayer(4, step) {
                fxRect(102, 111, 160, 7, 2.5, Fig.sky, stroke: 1.5)
                fxText("$103,350", 11, 232, 64)
                fxText("$50,000", 12, 54, 100, weight: .black)
                fxText("lands here", 11, 54, 116)
                fxArrow(84, 110, 100, 115, Fig.ink, 2)
            }
            fxLayer(5, step) {
                fxText("a raise taxes", 11, 56, 150)
                fxText("only the", 11, 56, 167)
                fxText("new dollars", 11, 56, 184, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A jar. Taxed money goes in, growth stays untaxed, it comes out clean.
struct JarFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxArt("jar", 118, 24, 124, 216)
                fxText("Roth IRA", 17, 180, 98, weight: .black)
                fxText("taxed money in", 11, 180, 118)
            }
            fxLayer(2, step) {
                fxStroke(Fig.leafDeep, 8) { $0.go(140, 208); $0.curve(226, 132, 176, 208, 212, 192) }
                fxArrow(220, 140, 230, 126, Fig.leafDeep, 6)
                fxText("grows untaxed", 11.5, 62, 168)
            }
            fxLayer(3, step) {
                fxArrow(240, 46, 268, 70, Fig.ink, 2)
                fxText("out tax-free", 12, 300, 82, weight: .black)
                fxText("at 59½", 12, 300, 100)
            }
            fxLayer(4, step) {
                fxText("needs money", 12, 300, 200)
                fxText("you earned", 12, 300, 218)
                fxStroke(Fig.ink, 2) { $0.go(180, 240); $0.to(180, 250) }
                fxChip("up to $7,000 a year", 12, 100, 250, 160, 30, Fig.leaf)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One burrito, two price tags, and the slice your old $8 no longer buys.
struct BurritoFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxArt("burrito", 36, 96, 288, 128)
                fxChip("$8 · 2020", 15, 26, 36, 130, 40, Fig.paper)
            }
            fxLayer(2, step) { fxChip("$10 · 2025", 15, 204, 36, 130, 40, Fig.coral, color: .white) }
            fxLayer(3, step) {
                fxDash(2) { $0.go(266, 104); $0.to(266, 196) }
                fxPoly(Fig.faint.opacity(0.6), stroke: 0) { p in
                    p.go(262, 108)
                    p.addArc(center: CGPoint(x: 262, y: 150), radius: 42, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                    p.closeSubpath()
                }
                fxStroke(Fig.ink, 2) { $0.go(72, 220); $0.to(72, 228); $0.to(264, 228); $0.to(264, 220) }
                fxText("your $8 buys this much", 12, 168, 244)
            }
            fxLayer(4, step) { fxChip("cash loses ~3% a year", 13, 80, 256, 200, 30, Fig.faint) }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Philosophy, continued

/// Track, fork, trolley. The five, the one and the lever arrive in turn.
struct TrolleyFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxStroke(Fig.faint, 6) {
                    for x in stride(from: 34, through: 330, by: 24) { $0.go(CGFloat(x), 216); $0.to(CGFloat(x), 232) }
                    for i in 0..<6 {
                        let t: CGFloat = CGFloat(i) / 5
                        let x: CGFloat = 176 + t * 104
                        let y: CGFloat = 204 - t * 92
                        $0.go(x - 5, y + 7); $0.to(x + 5, y - 7)
                    }
                }
                fxStroke(Fig.ink, 3) {
                    $0.go(18, 224); $0.to(342, 224)
                    $0.go(150, 224); $0.to(176, 204); $0.to(280, 112); $0.to(342, 100)
                }
                fxPoly(Fig.ink, stroke: 0) { p in p.go(150, 224); p.to(176, 204); p.to(176, 224); p.closeSubpath() }
                fxArt("trolley", 26, 140, 100, 88)
            }
            fxLayer(2, step) {
                ForEach([226, 252, 278, 304, 330], id: \.self) { x in fxPerson(CGFloat(x) - 8, 216, Fig.lav, size: 0.55) }
                fxText("five", 13, 298, 254, weight: .black)
            }
            fxLayer(3, step) {
                fxPerson(306, 107, Fig.lav, size: 0.55)
                fxText("one", 13, 306, 132, weight: .black)
                fxStroke(Fig.ink, 3) { $0.go(150, 228); $0.to(136, 262) }
                fxOval(136, 262, 6, 6, Fig.ink, stroke: 0)
                fxChip("pull?", 13, 70, 250, 62, 28, Fig.coin)
            }
            fxLayer(4, step) { fxChip("most pull", 12, 176, 258, 92, 28, Fig.leaf) }
            fxLayer(5, step) {
                fxChip("lever: 5 → 1", 12, 20, 24, 128, 32, Fig.leaf)
                fxChip("push: 5 → 1", 12, 20, 62, 128, 32, Fig.faint)
                fxText("same math", 12, 84, 112)
                fxStroke(Fig.ink, 2) { $0.go(166, 76); $0.to(224, 76); $0.go(166, 76); $0.to(166, 90); $0.go(224, 76); $0.to(224, 90); $0.go(195, 76); $0.to(195, 90) }
                fxRect(160, 90, 70, 8, 3, Fig.faint)
                fxStroke(Fig.ink, 2) { $0.go(168, 98); $0.to(168, 118); $0.go(222, 98); $0.to(222, 118) }
                fxPerson(195, 90, Fig.lav, size: 0.5)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A ship of old grey planks. New ones are laid over them until none of the old show.
struct ShipFigure: View {
    let step: Int
    private func plank(_ c: Int, _ r: Int) -> some View {
        fxRect(112 + CGFloat(c) * 46, 190 + CGFloat(r) * 13, 40, 9, 3, Fig.leaf)
    }
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxText("same ship?", 16, 180, 34, weight: .black)
                fxArt("ship", 92, 52, 176, 180)
            }
            fxLayer(2, step) { plank(0, 0); plank(2, 1); plank(1, 2) }
            fxLayer(3, step) {
                ForEach(0..<3, id: \.self) { r in
                    ForEach(0..<3, id: \.self) { c in plank(c, r) }
                }
            }
            fxLayer(4, step) {
                fxPoly(Fig.faint) { p in p.go(288, 96); p.to(342, 96); p.to(334, 126); p.to(296, 126); p.closeSubpath() }
                fxStroke(Fig.ink, 1.5) { $0.go(291, 106); $0.to(339, 106); $0.go(294, 116); $0.to(336, 116) }
                fxText("old planks", 11, 315, 142)
                fxChip("which is his?", 13, 100, 252, 160, 30, Fig.coral, color: .white)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The cave scene is the whole picture. Shadows, the real things and the way out land on it.
struct CaveFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxArt("scene-cave", 24, 6, 312, 292)
                fxText("the wall", 14, 110, 60, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(70, 84, 30, 30, 7, Fig.ink.opacity(0.5), stroke: 0)
                fxOval(130, 108, 15, 15, Fig.ink.opacity(0.5), stroke: 0)
                fxText("shadows", 12, 104, 140, weight: .black)
            }
            fxLayer(3, step) {
                fxRect(214, 96, 24, 24, 6, Fig.coin); fxOval(258, 108, 11, 11, Fig.leaf)
                fxText("the real things", 11.5, 240, 74)
            }
            fxLayer(4, step) {
                fxArrow(232, 176, 290, 140, Fig.ink, 2.5)
                fxText("out", 12, 304, 158, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Study skills, continued

/// A page ruled into three zones. Notes, questions, summary, then the cover-up.
struct CornellFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxRect(40, 22, 280, 260, 14, Fig.paper)
                fxRect(42, 24, 78, 210, 0, Fig.coinField, stroke: 0)
                fxRect(42, 238, 276, 42, 0, Fig.lavField, stroke: 0)
                fxStroke(Fig.ink, 2) { $0.go(122, 24); $0.to(122, 236); $0.go(42, 236); $0.to(318, 236) }
            }
            fxLayer(2, step) {
                fxText("notes", 15, 220, 52, weight: .black)
                fxStroke(Fig.sky, 6) {
                    for y in [84, 106, 128, 150, 172, 194] { $0.go(140, CGFloat(y)); $0.to(CGFloat(y % 3 == 0 ? 256 : 300), CGFloat(y)) }
                }
            }
            fxLayer(3, step) {
                fxText("questions", 12, 81, 52, weight: .black)
                fxChip("?", 13, 62, 80, 38, 26, Fig.coin)
                fxChip("?", 13, 62, 124, 38, 26, Fig.coin)
                fxChip("?", 13, 62, 168, 38, 26, Fig.coin)
            }
            fxLayer(4, step) { fxText("one line that sums it up", 12.5, 180, 259, weight: .black) }
            fxLayer(5, step) {
                fxRect(124, 24, 194, 210, 12, Fig.sky)
                fxText("cover this", 14, 222, 118, weight: .black)
                fxText("quiz from the left", 12, 222, 140)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A chalkboard. Plain words, then the spot where they go vague.
struct FeynmanFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxArt("chalkboard", 22, 20, 316, 236)
                fxPerson(36, 282, Fig.coin, size: 0.75)
                fxText("photosynthesis", 18, 176, 58, weight: .black)
            }
            fxLayer(2, step) {
                fxLeft("the plant catches sunlight", 13, 46, 96, 280)
                fxLeft("turns air + water into sugar", 13, 46, 120, 280)
            }
            fxLayer(3, step) {
                fxChip("and then… something?", 13, 46, 148, 200, 32, Fig.coral, color: .white)
                fxStroke(Fig.ink, 2) { $0.go(248, 164); $0.to(262, 164) }
                fxText("the gap", 12, 292, 164, weight: .black)
            }
            fxLayer(4, step) {
                fxArrow(146, 184, 146, 196, Fig.ink, 2.5)
                fxChip("fill it, then say it plain", 12.5, 46, 200, 190, 30, Fig.coin)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One night as a band. Five cycles ride across it, deep early and shallow late;
/// the filing is early, the connecting late.
struct SleepFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxArt("moon", 146, 18, 68, 70)
                fxRect(24, 118, 312, 64, 16, Fig.lavDeep)
                fxText("11pm", 12, 46, 104); fxText("7am", 12, 314, 104)
            }
            fxLayer(2, step) {
                fxStroke(Fig.sky, 4) { p in
                    p.go(30, 150)
                    for i in 0..<5 {
                        let x0: CGFloat = 30 + CGFloat(i) * 60
                        let amp: CGFloat = 26 - CGFloat(i) * 4.5
                        p.curve(x0 + 60, 150, x0 + 20, 150 - amp, x0 + 40, 150 + amp)
                    }
                }
            }
            fxLayer(3, step) {
                fxStroke(Fig.ink, 2) { $0.go(96, 182); $0.to(96, 200) }
                fxChip("deep: facts filed", 12, 26, 200, 140, 32, Fig.paper)
            }
            fxLayer(4, step) {
                fxStroke(Fig.ink, 2) { $0.go(264, 182); $0.to(264, 200) }
                fxChip("dreams: connected", 12, 194, 200, 140, 32, Fig.paper)
            }
            fxLayer(5, step) {
                fxRect(180, 120, 154, 60, 0, Fig.faint.opacity(0.55), stroke: 0)
                fxStroke(Fig.coral, 3) { $0.go(180, 110); $0.to(180, 190) }
                fxStroke(Fig.ink, 2) { $0.go(180, 234); $0.to(180, 246) }
                fxChip("cut here: lose the connecting", 12, 56, 246, 248, 32, Fig.coral, color: .white)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A test paper. Read all, bank the easy ones, flag the hard ones, come back.
struct ExamFigure: View {
    let step: Int
    private let rows: [CGFloat] = [60, 94, 128, 162, 196]
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxRect(60, 20, 240, 262, 14, Fig.paper)
                ForEach(0..<5, id: \.self) { i in
                    fxText("\(i + 1).", 13, 82, rows[i], weight: .black)
                    fxStroke(Fig.faint, 6) { $0.go(98, rows[i]); $0.to(i == 2 || i == 4 ? 230 : 200, rows[i]) }
                }
            }
            fxLayer(2, step) { fxChip("read it all first · 60s", 12, 80, 212, 200, 28, Fig.sky) }
            fxLayer(3, step) {
                ForEach([0, 1, 3], id: \.self) { i in
                    fxOval(270, rows[i], 11, 11, Fig.mint)
                    fxStroke(Fig.ink, 2.5) { $0.go(264, rows[i]); $0.to(268, rows[i] + 4); $0.to(276, rows[i] - 4) }
                }
            }
            fxLayer(4, step) {
                ForEach([2, 4], id: \.self) { i in fxChip("later", 11, 240, rows[i] - 11, 54, 22, Fig.coral, color: .white) }
            }
            fxLayer(5, step) { fxChip("come back with time left", 12, 80, 246, 200, 28, Fig.leaf) }
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

/// Type that starts at `x` and runs right, for lines that read like a list.
private func fxLeft(_ s: String, _ size: CGFloat, _ x: CGFloat, _ cy: CGFloat, _ w: CGFloat,
                    color: Color = Fig.ink, weight: Font.Weight = .heavy) -> some View {
    Text(s)
        .font(Theme.font(size, weight))
        .foregroundStyle(color)
        .lineLimit(1)
        .frame(width: w, alignment: .leading)
        .position(x: x + w / 2, y: cy)
}

/// Type that ends at `x`, for the amounts on a stub.
private func fxRight(_ s: String, _ size: CGFloat, _ x: CGFloat, _ cy: CGFloat, _ w: CGFloat,
                     color: Color = Fig.ink, weight: Font.Weight = .heavy) -> some View {
    Text(s)
        .font(Theme.font(size, weight))
        .foregroundStyle(color)
        .lineLimit(1)
        .frame(width: w, alignment: .trailing)
        .position(x: x - w / 2, y: cy)
}

/// A head and a body, standing on `feet`. The same flat mark the icons use for people.
private func fxPerson(_ cx: CGFloat, _ feet: CGFloat, _ fill: Color, size: CGFloat = 1) -> some View {
    ZStack(alignment: .topLeading) {
        fxRect(cx - 16 * size, feet - 38 * size, 32 * size, 38 * size, 12 * size, fill)
        fxOval(cx, feet - 52 * size, 14 * size, 14 * size, fill)
    }
}

/// A hero object from the asset catalogue, fitted inside a box and centred in it.
private func fxArt(_ name: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
    Fig.artLoader("fig-\(name)")
        .resizable()
        .scaledToFit()
        .frame(width: w, height: h)
        .position(x: x + w / 2, y: y + h / 2)
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
