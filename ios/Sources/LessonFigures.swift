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
        case "workmatch":  WorkMatchFigure(step: step)
        case "salaryask":  SalaryAskFigure(step: step)
        case "raiseask":   RaiseAskFigure(step: step)
        case "trolley":    TrolleyFigure(step: step)
        case "ship":       ShipFigure(step: step)
        case "cave":       CaveFigure(step: step)
        case "cornell":    CornellFigure(step: step)
        case "feynman":    FeynmanFigure(step: step)
        case "sleep":      SleepFigure(step: step)
        case "exam":       ExamFigure(step: step)
        case "anchor":     AnchorFigure(step: step)
        case "blame":      BlameFigure(step: step)
        case "sting":      StingFigure(step: step)
        case "search":     SearchFigure(step: step)
        case "sliver":     SliverFigure(step: step)
        case "roster":     RosterFigure(step: step)
        case "trail":      TrailFigure(step: step)
        case "tone":       ToneFigure(step: step)
        case "minimum":    MinimumFigure(step: step)
        case "movein":     MoveinFigure(step: step)
        case "fence":      FenceFigure(step: step)
        case "steel":      SteelFigure(step: step)
        case "decay":      DecayFigure(step: step)
        case "leitner":    LeitnerFigure(step: step)
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
        "workmatch", "salaryask", "raiseask",
        "cornell", "feynman", "sleep", "exam",
        "anchor", "blame", "sting", "search", "sliver", "roster", "trail", "tone", "minimum", "movein", "fence", "steel", "decay", "leitner",
    ]

    static func exists(_ id: String?) -> Bool { id.map(drawn.contains) ?? false }

    /// The step to show when a figure stands in for its lesson — on the key-idea
    /// keepsake, say. Normally that is the finished drawing, but a figure whose last
    /// reveal washes the picture out (`refresh` switches the feed off) reads as a
    /// half-loaded card, so it stops one step earlier.
    static func coverStep(_ id: String?) -> Int {
        switch id {
        case "refresh": return 3
        default: return 9
        }
    }

    /// A lesson whose cover is a whole scene rather than the figure's first reveal.
    /// The in-lesson figure keeps its reveals untouched; this is only the art on the
    /// cards that offer the lesson, where nothing is revealing.
    static func coverArt(_ id: String?) -> String? {
        switch id {
        case "trolley": return "fig-scene-trolley"
        default: return nil
        }
    }

    /// The field a figure sits on. Also the colour a cover paints behind the drawing,
    /// so a lesson's card is tinted even where the drawing does not reach.
    static func field(_ id: String?) -> Color {
        switch id {
        case "compound", "budget", "scale", "interleave",
             "slots", "sunk", "paycheck", "brackets", "jar", "burrito",
             "workmatch":                                             return Fig.coinField
        case "fork", "razor", "spacing", "recall",
             "filter", "cornell", "feynman", "exam", "raiseask":       return Fig.leafField
        case "gauge", "why", "map", "mechanism",
             "refresh", "loop", "arousal", "trolley", "sleep":         return Fig.skyField
        case "email", "no", "echo", "ladder", "apology",
             "salaryask":                                              return Fig.roseField
        case "anchor", "minimum", "movein":                         return Fig.coinField
        case "blame", "search", "fence":                            return Fig.skyField
        case "sliver", "roster", "trail", "tone":                   return Fig.roseField
        case "leitner":                                             return Fig.leafField
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

    // MARK: The scale
    //
    // Every line in a figure is doing one of five jobs, and each job has exactly one
    // weight. Before these were named, the set had four arrow widths and five leader
    // widths doing the same work, which is the kind of thing that reads as sloppy long
    // before anyone can say why.

    /// A hairline from a label to the part it names. Also the small motion ticks.
    static let leader: CGFloat = 2
    /// An arrow that points at a thing.
    static let pointer: CGFloat = 2.5
    /// An arrow that shows movement: a spill, a growth curve.
    static let flow: CGFloat = 5
    /// Crossing something out. Always solid ink, never tinted.
    static let strike: CGFloat = 3
    /// A divider drawn inside an object: a stub's rules, a page's columns.
    static let rule: CGFloat = 2
    /// One rail of a track, and the ties between them. Heavier than a rule because a
    /// track has to read as a track from across the card.
    static let rail: CGFloat = 3

    /// Every word in every figure, on or off. Only the design-time renderer turns it
    /// off: it draws each figure twice, once whole and once wordless, and the pixels
    /// that differ are exactly the glyphs. Anything drawn under those glyphs that is
    /// not one flat fill is type laid over a shape, which is how "ONE" ended up on a
    /// person's head. Always true in the app.
    nonisolated(unsafe) static var drawText = true

    /// One wash for anything shown as spent, faded or unnoticed. Always painted in the
    /// figure's own field colour, so a dimmed thing recedes toward the background
    /// instead of picking up a new grey.
    static let dim: Double = 0.7
    /// Secondary type on a filled surface.
    static let sub: Double = 0.6
    /// A dashed outline standing in for something that is not there — the rest of a
    /// chain of reasons, a slot with nothing in it.
    static let ghost: Double = 0.45

    /// Two type sizes carry almost every word in a figure: a caption or chip, and a
    /// label naming a part. Anything larger is a display size the figure asks for.
    static let caption: CGFloat = 12
    static let label: CGFloat = 13
    /// A chip that IS the figure's headline — the sum on a repair bill, the thing that
    /// broke. Rare on purpose: one per figure at most.
    static let headline: CGFloat = 17
    /// One chip height.
    static let chipH: CGFloat = 30

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
                // The curve is the picture, so it arrives whole; the later steps only
                // mark points on it.
                fxStroke(Fig.ink, Fig.leader) { $0.go(56, compoundAxisY); $0.to(342, compoundAxisY) }
                fxLine(compoundEarly, Fig.leafDeep, 9)
                fxOval(64, compoundStartY, 6, 6, Fig.ink, stroke: 0)
                fxText("$1,000", Fig.caption, 82, compoundAxisY + 18, weight: .black)
            }
            fxLayer(2, step) {
                fxChip("+$80 year one", Fig.caption, 56, 70, 136, Fig.chipH, Fig.coin)
            }
            fxLayer(3, step) {
                fxChip("+$86 year two", Fig.caption, 56, 106, 136, Fig.chipH, Fig.coin)
            }
            fxLayer(4, step) {
                fxDash(2) { $0.go(56, compoundDoubleY); $0.to(compoundDoubleX, compoundDoubleY) }
                fxDash(2) { $0.go(compoundDoubleX, compoundDoubleY); $0.to(compoundDoubleX, compoundAxisY) }
                fxText("twice the money", Fig.caption, 108, compoundDoubleY - 18)
                fxText("9 years", Fig.caption, compoundDoubleX + 14, compoundAxisY + 18, weight: .black)
                fxChip("72 ÷ 8 = 9", Fig.label, 56, 26, 122, Fig.chipH, Fig.paper)
            }
            fxLayer(5, step) {
                fxLine(compoundLate, Fig.sky, 9)
                fxText("age 18", Fig.caption, 300, 50, weight: .black)
                fxText("age 28", Fig.caption, 280, 170, weight: .black)
            }
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
                fxStroke(Fig.ink, Fig.leader) { $0.go(x0 + w * 0.90, 232); $0.to(x0 + w * 0.90, 248) }
                fxChip("moves on payday", Fig.label, 176, 248, 168, Fig.chipH, Fig.paper)
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

/// A $400 repair going two ways. A thick stack of banknotes — three stepped ledges, a
/// printed inner border and an oval portrait medallion — fills the bottom and bleeds off
/// the left, right and bottom edges. Above it sit the two outcomes: a car wheel (black
/// tyre, wide spoked rim, hub cap) on the left, a credit card (magnetic stripe, chip
/// square, embossed number row) on the right, and the $400 itself between them. With
/// every word switched off you still see money, a wheel and a card. The old version was a
/// flat green band, a bare black ring with a pinhole and a blank coral box, which read as
/// a vinyl record and a pink card lying on grass.
struct ForkFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                // Three note edges, each one wider and lower than the one behind it. The
                // stepped ledges are what make this a stack of cash and not a lawn.
                fxRect(16, 172, 328, 24, 10, Fig.leaf)
                fxRect(-4, 182, 368, 26, 12, Fig.leaf)
                fxRect(-22, 192, 404, 128, 16, Fig.leaf)
                // The printed border and the portrait medallion: a banknote's two marks.
                fxRect(-10, 204, 380, 106, 10, Fig.leaf, stroke: 2)
                fxOval(54, 250, 26, 30, Fig.paper)
                fxPerson(54, 268, Fig.leaf, size: 0.5)
                fxText("CASH", 30, 226, 250, weight: .black)
            }
            fxLayer(2, step) {
                // A wheel, not a record: the rim is 68% of the radius and carries five
                // spokes and a hub. A record is a black disc with a pinhole and no spokes.
                fxOval(76, 96, 44, 44, Fig.ink)
                fxOval(76, 96, 30, 30, Fig.paper, stroke: 0)
                ForEach(0..<5, id: \.self) { i in
                    let a = -Double.pi / 2 + Double(i) * 2 * Double.pi / 5
                    let dx = CGFloat(cos(a)), dy = CGFloat(sin(a))
                    fxStroke(Fig.ink, Fig.rail) {
                        $0.go(76 + dx * 10, 96 + dy * 10)
                        $0.to(76 + dx * 29, 96 + dy * 29)
                    }
                }
                fxOval(76, 96, 9, 9, Fig.ink, stroke: 0)
                fxChip("$400", Fig.headline, 128, 81, 76, Fig.chipH, Fig.paper)
                fxText("ERRAND", Fig.label, 76, 157, weight: .black)
            }
            fxLayer(3, step) {
                // A card, not a bar: stripe, chip, number row. The stripe sits 20pt below
                // the top edge so it clears the continuous corner and reads full width.
                fxRect(214, 52, 126, 86, 12, Fig.coral)
                fxRect(214, 72, 126, 16, 0, Fig.ink, stroke: 0)
                fxRect(230, 96, 24, 18, 4, Fig.coin)
                ForEach(0..<4, id: \.self) { i in
                    fxRect(230 + CGFloat(i) * 28, 120, 20, 7, 3.5, Fig.ink, stroke: 0)
                }
                fxText("24%", Fig.label, 298, 105, weight: .black)
                fxText("CRISIS", Fig.label, 277, 157, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A credit score as a dial, with the two inputs that actually move it.
struct GaugeFigure: View {
    let step: Int
    private let cx: CGFloat = 180, cy: CGFloat = 146, d: CGFloat = 208

    // The dial is half a ring, so the filled part has to be the real fraction of the
    // 300-850 range. It used to stop at 296 degrees, which draws 64% for a score that
    // is 75% of the way up — the picture disagreed with its own number.
    private let low = 300.0, high = 850.0, score = 712.0
    private var scoreEnd: Double { 180 + 180 * (score - low) / (high - low) }

    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                dial(to: 360, Fig.paper)
                fxText("300", Fig.label, 60, 172)
                fxText("850", Fig.label, 300, 172)
            }
            fxLayer(2, step) {
                dial(to: scoreEnd, Fig.skyDeep)
                fxText("712", 44, cx, 106, weight: .black)
                fxText("your score", Fig.label, cx, 140)
            }
            fxLayer(3, step) {
                fxChip("paying on time", Fig.label, 20, 194, 156, Fig.chipH, Fig.leaf)
                // FICO weights: payment history 35%, amounts owed 30%. Drawn to scale
                // against each other so the longer bar is longer by the right amount.
                fxRect(20, 240, 140, 14, 7, Fig.leaf)
                fxText("moves it most", Fig.caption, 98, 274)
            }
            fxLayer(4, step) {
                fxChip("how much you use", Fig.label, 190, 194, 150, Fig.chipH, Fig.coin)
                fxRect(190, 240, 120, 14, 7, Fig.coin)
                fxText("keep it under 30%", Fig.caption, 265, 274)
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
                fxChip("the rent you pay", Fig.label, 106, 18, 148, Fig.chipH, Fig.paper)
                fxStroke(Fig.ink, Fig.strike) {
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
                fxText("worth more later", Fig.caption, 92, 274)
            }
            fxLayer(3, step) {
                fxText("a night out", 16, 268, 178, weight: .black)
                fxStroke(Fig.coral, 9) { $0.go(214, 202); $0.curve(322, 242, 250, 208, 288, 228) }
                fxText("worth nothing later", Fig.caption, 268, 274)
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
                fxText("the one you picked", Fig.label, 180, 214)
            }
            fxLayer(3, step) {
                fxRect(24, 228, 148, 38, 12, Fig.lavDeep)
                fxText("index", 15, 98, 247, color: .white, weight: .black)
                fxRect(188, 228, 92, 38, 12, Fig.faint)
                fxText("picker", 15, 234, 247, weight: .black)
                fxText("after fees, 20 years", Fig.caption, 180, 278)
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
                fxStroke(Fig.ink, Fig.leader) { $0.go(180, 22); $0.to(180, 264) }
                fxChip("yours", Fig.headline, 22, 20, 140, 44, Fig.leaf)
                fxChip("not yours", Fig.headline, 198, 20, 140, 44, Fig.sky)
            }
            fxLayer(2, step) {
                fxChip("your effort", Fig.label, 22, 88, 140, 42, Fig.paper)
                fxChip("your reaction", Fig.label, 22, 142, 140, 42, Fig.paper)
            }
            fxLayer(3, step) {
                fxChip("the curve", Fig.label, 198, 88, 140, 42, Fig.paper)
                fxChip("other people", Fig.label, 198, 142, 140, 42, Fig.paper)
                fxArrow(92, 252, 92, 196, Fig.ink, Fig.pointer)
                fxText("spend it here", Fig.label, 92, 268)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A chain of reasons hanging under a belief. The belief is a board that bleeds off
/// the top edge; a chain of interlocking links hangs from it down to a second board,
/// the reason; a second chain hangs from that one and stops in mid-air over an empty
/// dashed frame. With every word off: a big plaque with a chain hanging out of it to a
/// hanging board, then more chain ending above a frame with nothing in it.
struct WhyFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxRect(24, -46, 312, 116, 24, Fig.lav)
                fxText("BELIEF", 32, 180, 36, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(170, 66, 20, 28, 10, Fig.skyField)
                fxRect(164, 88, 32, 20, 10, Fig.skyField)
                fxRect(170, 102, 20, 28, 10, Fig.skyField)
                fxText("WHY", Fig.label, 218, 98, weight: .black)
                fxRect(60, 128, 240, 46, 14, Fig.paper)
                fxText("REASON", Fig.label, 180, 151, weight: .black)
            }
            fxLayer(3, step) {
                fxRect(170, 170, 20, 28, 10, Fig.skyField)
                fxRect(164, 192, 32, 20, 10, Fig.skyField)
                fxRect(170, 206, 20, 28, 10, Fig.skyField)
                fxText("WHY", Fig.label, 218, 202, weight: .black)
                fxDash(2) {
                    $0.go(60, 240); $0.to(300, 240); $0.to(300, 284); $0.to(60, 284); $0.to(60, 240)
                }
                fxText("NO FLOOR", Fig.label, 180, 262, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One blade, two stacks of assumptions. The short one gets tested first.
struct RazorFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxPoly(Fig.sky) { p in
                    p.go(-20, 168); p.to(264, 168); p.to(310, 212); p.to(264, 256); p.to(-20, 256)
                    p.closeSubpath()
                }
                fxText("RAZOR", 30, 140, 212, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(60, 132, 50, 36, 8, Fig.leaf)
                fxText("ONE", Fig.label, 85, 150, weight: .black)
                fxText("FIRST", Fig.label, 85, 116, weight: .black)
            }
            fxLayer(3, step) {
                fxRect(200, 32, 50, 136, 8, Fig.coral)
                fxText("FOUR", Fig.label, 225, 100, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Rawls' veil of ignorance, drawn as a cloth over a crowd. With every word switched off
/// you see five identical people standing in a row and a big lavender veil hanging down
/// over them: a scalloped hem, their heads and shoulders pressing through the cloth as
/// darker silhouettes, their bodies showing below the hem. Nobody is marked out — same
/// body, same head, same colour — so you cannot tell which one you are. At the last step
/// a coral arrow picks one of them at random and that one is you.
struct VeilFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                ForEach(0..<5, id: \.self) { i in
                    fxPerson(56 + CGFloat(i) * 66, 248, Fig.paper, size: 1.4)
                }
                fxPoly(Fig.lav) { p in
                    p.go(-12, -12)
                    p.to(372, -12)
                    p.to(372, 204)
                    p.curve(320, 204, 356, 222, 336, 222)
                    p.curve(254, 204, 304, 222, 270, 222)
                    p.curve(188, 204, 238, 222, 204, 222)
                    p.curve(122, 204, 172, 222, 138, 222)
                    p.curve(56, 204, 106, 222, 72, 222)
                    p.curve(-12, 204, 40, 222, 4, 222)
                    p.closeSubpath()
                }
                ForEach(0..<5, id: \.self) { i in
                    let cx = 56 + CGFloat(i) * 66
                    fxOval(cx, 175.2, 19.6, 19.6, Fig.lavDeep, stroke: 0)
                    fxRect(cx - 22.4, 184, 44.8, 16, 8, Fig.lavDeep, stroke: 0)
                }
                fxText("VEIL", 32, 188, 90, weight: .black)
            }
            fxLayer(2, step) {
                ForEach(0..<5, id: \.self) { i in
                    fxText("?", Fig.label, 56 + CGFloat(i) * 66, 175,
                           color: Fig.paper, weight: .black)
                }
            }
            fxLayer(3, step) {
                fxArrow(254, 264, 254, 246, Fig.coral, Fig.pointer)
                fxText("YOU", Fig.label, 254, 275, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A paper map lying on the land it stands for. With every word off you see a green
/// landmass running off the left edge, and on it a white sheet that is plainly a map:
/// a coastline with blue sea behind it, one yellow road crossing from edge to edge,
/// one red pin. Three red dots sit on the land outside the sheet — the things the map
/// dropped. The first build made the sheet a 5x4 grid, which read as a spreadsheet;
/// the coastline, the road and the pin are what make it a map instead. Every dot is
/// fully inside the land, and no word comes within 8pt of a drawn edge.
struct MapFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxPoly(Fig.leaf) { p in
                    p.go(-20, 58)
                    p.curve(200, 34, 40, 26, 120, 26)
                    p.curve(338, 132, 268, 40, 336, 66)
                    p.curve(190, 268, 340, 216, 268, 262)
                    p.curve(-20, 236, 110, 274, 30, 232)
                    p.closeSubpath()
                }
                fxText("TERRITORY", 22, 186, 234, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(112, 86, 192, 126, 0, Fig.paper)
                fxPoly(Fig.sky) { p in
                    p.go(304, 86)
                    p.to(230, 86)
                    p.curve(262, 128, 236, 104, 254, 110)
                    p.curve(240, 158, 270, 142, 250, 148)
                    p.curve(276, 212, 232, 178, 268, 190)
                    p.to(304, 212)
                    p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.flow) {
                    $0.go(112, 172); $0.to(148, 190); $0.to(190, 194); $0.to(222, 212)
                }
                fxStroke(Fig.coin, Fig.rail) {
                    $0.go(112, 172); $0.to(148, 190); $0.to(190, 194); $0.to(222, 212)
                }
                fxPoly(Fig.coral) { p in
                    p.go(150, 150)
                    p.curve(138, 120, 146, 142, 138, 130)
                    p.curve(162, 120, 138, 103, 162, 103)
                    p.curve(150, 150, 162, 130, 154, 142)
                    p.closeSubpath()
                }
                fxOval(150, 120, 4.5, 4.5, Fig.paper)
                fxText("the map", Fig.label, 196, 106)
            }
            fxLayer(3, step) {
                fxOval(60, 96, 10, 10, Fig.coral)
                fxOval(54, 186, 10, 10, Fig.coral)
                fxOval(250, 66, 10, 10, Fig.coral)
                fxText("left out", Fig.caption, 56, 142)
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
                fxStroke(Fig.ink, Fig.leader) { $0.go(38, 44); $0.to(38, 214); $0.to(340, 214) }
                fxText("what sticks", Fig.caption, 86, 32)
                fxText("time", Fig.caption, 322, 232)
                fxLine(spacingCram, Fig.coral, 8)
                fxText("one long cram", Fig.caption, 246, 176, weight: .black)
            }
            fxLayer(2, step) {
                fxLine(spacingSpaced2, Fig.leafDeep, 8)
                fxLine(spacingSpaced3, Fig.leafDeep, 8)
                fxLine(spacingSpaced4, Fig.leafDeep, 8)
                // the vertical pick-up at each review, so the curve reads as one story
                ForEach(0..<spacingDots.count, id: \.self) { i in
                    fxStroke(Fig.leafDeep.opacity(Fig.sub), Fig.leader) {
                        $0.go(spacingDots[i].x, spacingDots[i].y)
                        $0.to(spacingDots[i].x, spacingRestartY[i])
                    }
                    fxOval(spacingDots[i].x, spacingDots[i].y, 7, 7, Fig.leafDeep)
                }
            }
            fxLayer(3, step) {
                fxChip("the gap is doing the work", Fig.label, 66, 236, 228, Fig.chipH, Fig.paper)
                fxText("same hour, split over six days", Fig.caption, 180, 276)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Osmosis drawn the way you would draw it on scrap paper. One open beaker — a flared
/// lip, two walls, a rounded bottom — with liquid standing against the glass on both
/// sides and a dotted membrane down the middle. The right side is darker, higher, and
/// holds white salt crystals; an arrow crosses the dots toward them. A yellow pencil
/// rests over the mouth, because you drew this. With every word off it still reads as
/// a glass of liquid split by a barrier, not as a rectangle.
struct MechanismFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                // The cavity, so the empty part of the glass is glass and not field.
                fxPoly(Fig.paper, stroke: 0) { p in
                    p.go(44, 60); p.to(316, 60); p.to(304, 236)
                    p.curve(282, 258, 304, 248.2, 293.8, 258)
                    p.to(78, 258)
                    p.curve(56, 236, 66.2, 258, 56, 248.2)
                    p.closeSubpath()
                }
                // Liquid standing against the walls. The salty side stands higher.
                fxPoly(Fig.sky, stroke: 0) { p in
                    p.go(176, 106); p.to(176, 258); p.to(78, 258)
                    p.curve(56, 236, 66.2, 258, 56, 248.2)
                    p.to(47.1, 106); p.closeSubpath()
                }
                fxPoly(Fig.skyDeep, stroke: 0) { p in
                    p.go(184, 86); p.to(314.2, 86); p.to(304, 236)
                    p.curve(282, 258, 304, 248.2, 293.8, 258)
                    p.to(184, 258); p.closeSubpath()
                }
                // The glass itself: open at the top, flaring into a lip.
                fxStroke(Fig.ink, Fig.rail) { p in
                    p.go(34, 50); p.to(44, 60); p.to(56, 236)
                    p.curve(78, 258, 56, 248.2, 66.2, 258)
                    p.to(282, 258)
                    p.curve(304, 236, 293.8, 258, 304, 248.2)
                    p.to(316, 60); p.to(326, 50)
                }
                // A membrane lets things through, so it is drawn broken.
                fxDash(4) { $0.go(180, 66); $0.to(180, 254) }
                grain(206, 120); grain(248, 140); grain(224, 172); grain(286, 124)
                fxText("OSMOSIS", 22, 115, 150, weight: .black)
                fxText("SALT", Fig.label, 272, 198, weight: .black)
            }
            fxLayer(2, step) {
                fxArrow(94, 216, 256, 216, Fig.ink, Fig.pointer)
                fxText("WATER", Fig.label, 106, 242, weight: .black)
            }
            fxLayer(3, step) {
                fxPoly(Fig.coin) { p in
                    p.go(80.7, 49.2); p.to(193.1, 32.0); p.to(191.3, 20.2); p.to(78.9, 37.4)
                    p.closeSubpath()
                }
                fxPoly(Fig.paper) { p in
                    p.go(62, 46); p.to(80.7, 49.2); p.to(78.9, 37.4); p.closeSubpath()
                }
                fxPoly(Fig.coral) { p in
                    p.go(193.1, 32.0); p.to(206.9, 29.9); p.to(205.1, 18.1); p.to(191.3, 20.2)
                    p.closeSubpath()
                }
                fxText("FROM MEMORY", Fig.label, 275, 34, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    /// One salt crystal. A diamond reads as a grain where a square reads as a tile.
    private func grain(_ cx: CGFloat, _ cy: CGFloat) -> some View {
        fxPoly(Fig.paper, stroke: 2) { p in
            p.go(cx, cy - 7); p.to(cx + 7, cy); p.to(cx, cy + 7); p.to(cx - 7, cy)
            p.closeSubpath()
        }
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
                fxText("from memory", Fig.label, 96, 22, weight: .black)
                fxText("your notes", Fig.label, 264, 22, weight: .black)
            }
            fxLayer(2, step) {
                rule(44, 78, 104); rule(44, 108, 84); rule(44, 138, 96)
            }
            fxLayer(3, step) {
                rule(212, 78, 104); rule(212, 108, 84); rule(212, 138, 96)
                mark(212, 170, 100); mark(212, 200, 76)
                fxChip("this is your study list", Fig.label, 154, 244, 180, Fig.chipH, Fig.leaf)
                fxArrow(258, 240, 276, 218)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    private func rule(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat) -> some View {
        Capsule().fill(Fig.ink.opacity(Fig.dim))
            .frame(width: w, height: 7).position(x: x + w / 2, y: y)
    }

    private func mark(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat) -> some View {
        Capsule().fill(Fig.leaf)
            .overlay(Capsule().strokeBorder(Fig.ink, lineWidth: 1.5))
            .frame(width: w, height: 12).position(x: x + w / 2, y: y)
    }
}

/// A punched worksheet page running off the bottom of the frame. Each small square is one
/// problem and its colour is the type. Row one is four of one colour then four of the other,
/// row two is those eight shuffled, row three is the test with every square blank. With the
/// words off you see a worksheet whose colours go from grouped, to mixed, to nothing.
struct InterleaveFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxRect(28, 22, 304, 320, 4, Fig.paper)
                fxStroke(Fig.coral, Fig.rule) { $0.go(70, 22); $0.to(70, 342) }
                ForEach(0..<3, id: \.self) { i in
                    fxOval(48, 66 + CGFloat(i) * 92, 7, 7, Fig.faint)
                }
                ForEach(0..<8, id: \.self) { i in
                    fxRect(84 + CGFloat(i) * 30, 64, 24, 24, 5, i < 4 ? Fig.coin : Fig.sky)
                }
                fxLeft("blocked", Fig.caption, 84, 52, 90)
            }
            fxLayer(2, step) {
                ForEach(0..<8, id: \.self) { i in
                    fxRect(84 + CGFloat(i) * 30, 146, 24, 24, 5,
                           [0, 3, 5, 6].contains(i) ? Fig.coin : Fig.sky)
                }
                fxText("MIXED", 28, 200, 118, weight: .black)
            }
            fxLayer(3, step) {
                ForEach(0..<8, id: \.self) { i in
                    fxRect(84 + CGFloat(i) * 30, 214, 24, 24, 5, Fig.faint)
                }
                fxLeft("the test", Fig.caption, 84, 200, 90)
                fxLeft("nothing labelled", Fig.caption, 84, 258, 120)
            }
        }
        .animation(Fig.reveal, value: step)
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
                fxText("a chapter", Fig.label, 104, 258)
            }
            fxLayer(2, step) {
                fxChip("how does it work?", Fig.label, 190, 48, 148, Fig.chipH, Fig.coin)
                fxArrow(196, 65, 166, 63)
            }
            fxLayer(3, step) {
                fxRect(206, 118, 134, 122, 14, Fig.paper)
                ForEach(0..<4, id: \.self) { i in
                    Capsule().fill(Fig.lavDeep)
                        .frame(width: i == 3 ? 62 : 98, height: 8)
                        .position(x: 224 + (i == 3 ? 31 : 49), y: 146 + CGFloat(i) * 24)
                }
                fxText("four sentences, book shut", Fig.caption, 262, 258)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The whole essay as one flat yellow slab running off the right edge, named once in
/// big type. The first slice of it turns coral and gets its own two words. Then an
/// arrow runs on down the slab: the part you actually do once the start is behind you.
struct StartFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxRect(70, 90, 320, 140, 22, Fig.coin)
                fxText("ESSAY", 32, 254, 138, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(70, 90, 78, 140, 22, Fig.coral)
                fxText("5 MIN", Fig.label, 109, 160, color: .white, weight: .black)
                fxChip("MAY STOP", Fig.caption, 56, 240, 106, Fig.chipH, Fig.paper)
            }
            fxLayer(3, step) {
                fxArrow(162, 196, 330, 196, Fig.ink, Fig.pointer)
                fxText("YOU", Fig.label, 180, 178, color: Fig.ink, weight: .black)
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
                fxRect(24, 76, 244, 118, 22, Fig.sky)
                fxText("working memory", 15, 146, 96, weight: .black)
                ForEach(0..<4, id: \.self) { i in
                    fxRect(29 + CGFloat(i) * 58, 112, 54, 66, 14, Fig.paper, stroke: 0)
                }
            }
            fxLayer(2, step) {
                ForEach(0..<4, id: \.self) { i in
                    fxRect(32 + CGFloat(i) * 58, 116, 48, 58, 12, Fig.coin)
                    fxText(names[i], Fig.caption, 56 + CGFloat(i) * 58, 145)
                }
            }
            fxLayer(3, step) {
                fxRect(280, 126, 62, 64, 12, Fig.coral)
                fxText("the", Fig.caption, 311, 148, color: .white, weight: .black)
                fxText("formula", Fig.caption, 311, 165, color: .white, weight: .black)
                fxStroke(Fig.ink, Fig.leader) { $0.go(270, 126); $0.to(278, 120) }
                fxStroke(Fig.ink, Fig.leader) { $0.go(272, 146); $0.to(280, 142) }
                fxText("no room", Fig.caption, 311, 208)
            }
            fxLayer(4, step) {
                fxChip("8675309 · 7 things", Fig.caption, 16, 20, 152, Fig.chipH, Fig.paper)
                fxChip("867-5309 · 2 things", Fig.caption, 190, 20, 152, Fig.chipH, Fig.leaf)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A phone feed, pulled. The hand and phone run in from the left; the mass beside it is
/// the feed itself — three posts, each a small avatar circle with two short lines of text,
/// under a header rule. With every word off you see a thumb dragging down a phone screen
/// and a stack of posts, one of them wearing a coral badge, with a coral arrow running
/// from the feed back to the phone. The panel now starts clear of the phone's side
/// buttons instead of chopping them. The last step greys the feed out behind one chip.
struct RefreshFigure: View {
    let step: Int
    private let px: CGFloat = 192          // clear of the phone's side buttons
    private let pw: CGFloat = 152
    private func row(_ i: Int) -> CGFloat { 122 + CGFloat(i) * 40 }

    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxArt("scene-refresh", 0, 60, 360, 240)
                fxText("pull", Fig.caption, 148, 232)
                fxRect(px, 50, pw, 190, 16, Fig.paper)
                fxText("MAYBE", 26, 268, 76, weight: .black)
                fxStroke(Fig.ink.opacity(Fig.sub), Fig.rule) { $0.go(204, 100); $0.to(332, 100) }
                ForEach(0..<3, id: \.self) { i in
                    post(row(i))
                }
            }
            fxLayer(2, step) {
                fxOval(332, row(1), 6, 6, Fig.coral, stroke: 0)
                fxText("ONE PAYS", Fig.label, 268, 226, color: Fig.coral, weight: .black)
            }
            fxLayer(3, step) {
                fxArrow(330, 276, 200, 276, Fig.coral, Fig.pointer)
                fxText("KEEP PULLING", Fig.label, 268, 258, color: Fig.coral, weight: .black)
            }
            fxLayer(4, step) {
                fxRect(px, 50, pw, 190, 16, Fig.skyField.opacity(Fig.dim), stroke: 0)
                fxChip("alerts off", Fig.caption, 214, 130, 108, Fig.chipH, Fig.paper)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    /// One post: the avatar circle and the two short lines beside it. These three marks
    /// are what make the panel read as a feed rather than as ruled paper.
    @ViewBuilder private func post(_ cy: CGFloat) -> some View {
        fxOval(214, cy, 9, 9, Fig.sky)
        fxStroke(Fig.ink.opacity(Fig.sub), Fig.rule) { $0.go(234, cy - 6); $0.to(318, cy - 6) }
        fxStroke(Fig.ink.opacity(Fig.sub), Fig.rule) { $0.go(234, cy + 6); $0.to(288, cy + 6) }
    }
}

/// A movie ticket torn in two at "now". The perforation runs down the middle as a dashed
/// line, a notch is bitten out of the top and the bottom edge on each side of it, and the
/// two halves sit apart with a real gap. The stub on the left runs off the edge and holds
/// the $15 already spent; the half still in your hand holds the 90 minutes ahead. The last
/// step adds one arrow — the past reaching across the tear to vote on a choice that is not
/// its own.
struct SunkFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxPoly(Fig.coin) { p in
                    p.go(-46, 92)
                    p.to(153, 92)
                    p.curve(168, 107, 153, 100.28, 159.72, 107)
                    p.to(164, 124)
                    p.to(170, 141)
                    p.to(164, 159)
                    p.to(170, 176)
                    p.to(168, 193)
                    p.curve(153, 208, 159.72, 193, 153, 199.72)
                    p.to(-46, 208)
                    p.closeSubpath()
                }
                fxPoly(Fig.coin) { p in
                    p.go(196, 107)
                    p.curve(211, 92, 204.28, 107, 211, 100.28)
                    p.to(332, 92)
                    p.curve(342, 102, 337.52, 92, 342, 96.48)
                    p.to(342, 198)
                    p.curve(332, 208, 342, 203.52, 337.52, 208)
                    p.to(211, 208)
                    p.curve(196, 193, 211, 199.72, 204.28, 193)
                    p.to(198, 176)
                    p.to(192, 159)
                    p.to(198, 141)
                    p.to(192, 124)
                    p.closeSubpath()
                }
                fxDash(2) { $0.go(182, 90); $0.to(182, 210) }
                fxText("NOW", Fig.caption, 182, 74, weight: .black)
                fxText("$15", 30, 70, 136, weight: .black)
            }
            fxLayer(2, step) {
                fxText("GONE", Fig.label, 70, 170, weight: .black)
            }
            fxLayer(3, step) {
                fxText("90 MIN", Fig.label, 269, 150, weight: .black)
            }
            fxLayer(4, step) {
                fxArrow(80, 240, 262, 240, Fig.coral, Fig.pointer)
                fxText("PAST VOTES", Fig.caption, 171, 264, color: Fig.coral, weight: .black)
            }
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
                fxText("facts", Fig.label, 72, 46)
                fxOval(40, 82, 9, 9, Fig.leafDeep); fxOval(82, 122, 9, 9, Fig.leafDeep)
                fxOval(58, 172, 9, 9, Fig.leafDeep); fxOval(96, 212, 9, 9, Fig.leafDeep)
                fxOval(80, 72, 9, 9, Fig.faint); fxOval(44, 132, 9, 9, Fig.faint)
                fxOval(102, 158, 9, 9, Fig.faint); fxOval(44, 206, 9, 9, Fig.faint)
                fxArt("funnel", 112, 56, 136, 133)
                fxRect(256, 108, 86, 84, 18, Fig.coin)
                fxText("what", Fig.label, 299, 138, weight: .black)
                fxText("you think", Fig.label, 299, 158, weight: .black)
            }
            fxLayer(2, step) {
                fxOval(180, 92, 8, 8, Fig.leafDeep); fxOval(170, 118, 8, 8, Fig.leafDeep)
                fxOval(182, 132, 8, 8, Fig.leafDeep)
                fxArrow(180, 192, 254, 166, Fig.leafDeep, Fig.flow)
                fxText("fits, sails in", Fig.caption, 300, 214)
            }
            fxLayer(3, step) {
                fxOval(118, 96, 8, 8, Fig.faint)
                fxArrow(124, 104, 106, 128, Fig.ink, Fig.pointer)
                fxText("doesn't fit, skipped", Fig.caption, 76, 240)
            }
            fxLayer(4, step) { fxChip("hunt for what breaks it", Fig.caption, 128, 250, 208, Fig.chipH, Fig.coral, color: .white) }
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
            fxLayer(2, step) { fxText("everyone in their own light", Fig.caption, 180, 272, weight: .black) }
            fxLayer(3, step) {
                fxChip("you guessed 50%", Fig.caption, 16, 22, 140, Fig.chipH, Fig.paper)
                fxChip("really 25%", Fig.caption, 214, 22, 118, Fig.chipH, Fig.leaf)
            }
            fxLayer(4, step) {
                fxRect(58, 152, 42, 100, 0, Fig.lavField.opacity(Fig.dim), stroke: 0)
                fxRect(251, 152, 50, 100, 0, Fig.lavField.opacity(Fig.dim), stroke: 0)
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
                fxText("habit", 22, 180, 112, weight: .black)
            }
            fxLayer(2, step) {
                arc(210, 330, Fig.coin)
                fxStroke(Fig.ink, Fig.leader) { $0.go(180, 62); $0.to(180, 50) }
                fxChip("cue: sit on the bed", Fig.label, 92, 18, 176, Fig.chipH, Fig.paper)
            }
            fxLayer(3, step) {
                arc(-30, 90, Fig.coral)
                fxStroke(Fig.ink, Fig.leader) { $0.go(228, 190); $0.to(250, 246) }
                fxChip("routine: open the feed", Fig.caption, 178, 246, 164, Fig.chipH, Fig.paper)
            }
            fxLayer(4, step) {
                arc(90, 210, Fig.leaf)
                fxStroke(Fig.ink, Fig.leader) { $0.go(132, 190); $0.to(110, 246) }
                fxChip("reward: 20 min off", Fig.caption, 18, 246, 156, Fig.chipH, Fig.paper)
            }
            fxLayer(5, step) { fxChip("swap this", Fig.caption, 132, 127, 96, Fig.chipH, Fig.coral, color: .white) }
            fxLayer(1, step) {
                ForEach([-30.0, 90.0, 210.0], id: \.self) { a in
                    let r = a * .pi / 180
                    let px = 180 + 68 * cos(r), py = 142 + 68 * sin(r)
                    let dx = -sin(r), dy = cos(r)
                    fxArrow(px - 11 * dx, py - 11 * dy, px + 11 * dx, py + 11 * dy, Fig.ink, Fig.pointer)
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
                fxArrow(104, 90, 82, 62, Fig.ink, Fig.pointer)
                fxChip("threat", Fig.label, 18, 22, 116, Fig.chipH, Fig.faint)
            }
            fxLayer(3, step) {
                fxArrow(256, 90, 278, 62, Fig.ink, Fig.pointer)
                fxChip("excited", Fig.label, 226, 22, 116, Fig.chipH, Fig.leaf)
            }
            fxLayer(4, step) { fxChip("same body, different label", Fig.caption, 80, 252, 200, Fig.chipH, Fig.paper) }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - People skills

/// A message being written. A header rule with a coral Send button and its paper plane in
/// the top corner, a To row with the recipient's avatar and name, EARLY on the subject
/// line, and the body's four lines arriving one at a time: the first line, a date pill,
/// the attached draft, and a short sign-off. With every word switched off it still reads
/// as an email compose sheet, never as four coloured bars.
struct EmailFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxRect(26, 20, 308, 300, 22, Fig.paper)
                fxOval(292, 49, 19, 19, Fig.coral)
                fxPoly(Fig.paper, stroke: 0) { p in
                    p.go(302, 49); p.to(282, 41); p.to(290, 49); p.to(282, 57)
                    p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.rule) { $0.go(26, 76); $0.to(334, 76) }
                fxOval(82, 96, 11, 11, Fig.faint)
                fxRect(102, 90, 68, 12, 6, Fig.faint, stroke: 0)
                fxLeft("TO", Fig.caption, 46, 96, 30)
                fxStroke(Fig.ink, Fig.rule) { $0.go(46, 116); $0.to(314, 116) }
                fxText("EARLY", 28, 90, 139, color: Fig.coral, weight: .black)
                fxStroke(Fig.ink, Fig.rule) { $0.go(46, 162); $0.to(314, 162) }
            }
            fxLayer(2, step) {
                fxRect(96, 181, 200, 9, 4.5, Fig.faint, stroke: 0)
                fxLeft("WHAT", Fig.label, 46, 186, 60)
            }
            fxLayer(3, step) {
                fxRect(190, 210, 110, 9, 4.5, Fig.faint, stroke: 0)
                fxChip("MONDAY", Fig.caption, 96, 199, 84, 30, Fig.coin)
                fxLeft("ASK", Fig.label, 46, 214, 50)
            }
            fxLayer(4, step) {
                fxPoly(Fig.leaf) { p in
                    p.go(104, 234); p.to(124, 234); p.to(135, 245); p.to(135, 264)
                    p.to(104, 264); p.closeSubpath()
                }
                fxPoly(Fig.paper) { p in
                    p.go(124, 234); p.to(135, 245); p.to(124, 245); p.closeSubpath()
                }
                fxRect(148, 246, 142, 9, 4.5, Fig.faint, stroke: 0)
                fxLeft("DRAFT", Fig.label, 46, 250, 60)
            }
            fxLayer(5, step) {
                fxRect(112, 273, 46, 9, 4.5, Fig.faint, stroke: 0)
                fxLeft("THANKS", Fig.label, 46, 278, 70)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One big speech bubble that IS the no, bleeding off the right edge. "NO" sits huge in the
/// middle; WARM above it, OFFER below it, MAYBE struck out, and the reason left outside as a door.
struct NoFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxPoly(Fig.coral) { p in
                    p.go(16, 30); p.to(380, 30); p.to(380, 200)
                    p.to(270, 200); p.to(240, 236); p.to(226, 200)
                    p.to(16, 200); p.closeSubpath()
                }
                fxText("NO", 34, 180, 118, weight: .black)
            }
            fxLayer(2, step) {
                fxOval(60, 62, 14, 14, Fig.coin)
                fxText("WARM", Fig.label, 60, 92, weight: .black)
            }
            fxLayer(3, step) {
                fxText("MAYBE", Fig.label, 292, 62, weight: .black)
                fxStroke(Fig.ink, Fig.strike) { $0.go(268, 62); $0.to(316, 62) }
            }
            fxLayer(4, step) {
                fxText("OFFER", Fig.label, 180, 172, weight: .black)
            }
            fxLayer(5, step) {
                fxRect(28, 230, 34, 54, 4, Fig.paper)
                fxOval(54, 258, 2.5, 2.5, Fig.ink, stroke: 0)
                fxText("REASON", Fig.caption, 98, 258, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One big lavender speech bubble is the friend's feeling, bleeding off the left edge with
/// "BOMBED" set large inside it. Your replies land to the right: "FINE" struck out, a
/// leaf bubble that echoes, then a "?" with "ASK" under it.
struct EchoFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxPoly(Fig.lav) { p in
                    p.go(-20, 26); p.to(230, 26); p.to(262, 100); p.to(230, 176)
                    p.to(100, 176); p.to(60, 212); p.to(68, 176); p.to(-20, 176)
                    p.closeSubpath()
                }
                fxText("BOMBED", 30, 110, 100, weight: .black)
            }
            fxLayer(2, step) {
                fxChip("FINE", Fig.label, 268, 40, 76, Fig.chipH, Fig.faint)
                fxStroke(Fig.ink, Fig.strike) { $0.go(282, 55); $0.to(330, 55) }
            }
            fxLayer(3, step) {
                fxPoly(Fig.leaf) { p in
                    p.go(150, 200); p.to(344, 200); p.to(344, 262); p.to(330, 262)
                    p.to(334, 284); p.to(302, 262); p.to(150, 262)
                    p.closeSubpath()
                }
                fxText("ECHO", Fig.label, 247, 231, weight: .black)
            }
            fxLayer(4, step) {
                fxOval(300, 120, 18, 18, Fig.coin)
                fxText("?", 16, 300, 120, weight: .black)
                fxText("ASK", Fig.caption, 300, 152, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Three stair treads as one lavender mass that runs off the right and bottom edges.
/// "NEXT" sits inside it from card one; each later card names one rung with a
/// one-word question. The sentence under the card explains, the figure only names.
struct LadderFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxPoly(Fig.lav) { p in
                    p.go(-10, 210); p.to(100, 210); p.to(100, 140); p.to(210, 140)
                    p.to(210, 70); p.to(370, 70); p.to(370, 310); p.to(-10, 310)
                    p.closeSubpath()
                }
                fxPerson(50, 210, Fig.paper, size: 0.62)
                fxText("NEXT", 30, 236, 226, weight: .black)
            }
            fxLayer(2, step) { fxText("FROM?", Fig.label, 45, 240, weight: .black) }
            fxLayer(3, step) { fxText("LIKE?", Fig.label, 155, 166, weight: .black) }
            fxLayer(4, step) { fxText("HOW?", Fig.label, 290, 96, weight: .black) }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One speech bubble, bleeding off the right edge, with SORRY set large inside it. The three
/// parts land as three small words in a row; BUT · IF arrives last and gets struck through.
struct ApologyFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxPoly(Fig.lav) { p in
                    p.go(30, 36); p.to(330, 36); p.to(330, 220)
                    p.to(110, 220); p.to(56, 262); p.to(70, 220)
                    p.to(30, 220); p.closeSubpath()
                }
                fxText("SORRY", 32, 180, 84, weight: .black)
            }
            fxLayer(2, step) { fxText("1 DID", Fig.label, 108, 142, weight: .black) }
            fxLayer(3, step) { fxText("2 COST", Fig.label, 192, 142, weight: .black) }
            fxLayer(4, step) { fxText("3 CHANGE", Fig.label, 282, 142, weight: .black) }
            fxLayer(5, step) {
                fxText("BUT · IF", Fig.label, 180, 190, weight: .black)
                fxStroke(Fig.coral, Fig.strike) { $0.go(146, 190); $0.to(214, 190) }
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Personal finance, continued

/// A pay stub: a wide slip of paper torn off a pad, bleeding off the left edge. With
/// every word off you see the torn top, the black header rule, a column rule splitting
/// labels from amounts, three ruled lines waiting for the deductions, and the heavy
/// total rule near the foot — a printed ledger slip, not a card. The entries fill in
/// one line at a time and the total is closed with a second rule under it.
struct PaycheckFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxPoly(Fig.paper) { p in
                    p.go(-20, 276)
                    p.to(338, 276)
                    p.to(338, 40)
                    for i in 1...18 {
                        p.to(338 - CGFloat(i) * 19.89, i % 2 == 0 ? 40 : 30)
                    }
                    p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.rule) { $0.go(-20, 92); $0.to(338, 92) }
                fxStroke(Fig.faint, Fig.rule) { $0.go(232, 98); $0.to(232, 210) }
                fxStroke(Fig.faint, Fig.rule) { $0.go(22, 135); $0.to(306, 135) }
                fxStroke(Fig.faint, Fig.rule) { $0.go(22, 169); $0.to(306, 169) }
                fxStroke(Fig.ink, Fig.rail) { $0.go(22, 210); $0.to(306, 210) }
                fxLeft("GROSS", Fig.label, 26, 66, 100)
                fxRight("$1,000", 26, 302, 64, 140, weight: .black)
            }
            fxLayer(2, step) {
                fxLeft("Social Security", Fig.caption, 26, 118, 170)
                fxRight("−$62", Fig.caption, 302, 118, 110, color: Fig.coral)
            }
            fxLayer(3, step) {
                fxLeft("Medicare", Fig.caption, 26, 152, 170)
                fxRight("−$14.50", Fig.caption, 302, 152, 110, color: Fig.coral)
            }
            fxLayer(4, step) {
                fxLeft("tax", Fig.caption, 26, 186, 170)
                fxRight("−$0–100", Fig.caption, 302, 186, 110, color: Fig.coral)
            }
            fxLayer(5, step) {
                fxStroke(Fig.ink, Fig.rule) { $0.go(22, 262); $0.to(306, 262) }
                fxLeft("NET", Fig.label, 26, 238, 100)
                fxRight("$825–925", Fig.label, 302, 238, 120, color: Fig.leafDeep)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Three stacked buckets. Income fills from the bottom; only the spill pays the top rate.
struct BracketsFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxText("2025 · single filer", Fig.caption, 180, 34, color: Fig.ink.opacity(Fig.sub))
                fxRect(98, 200, 168, 70, 12, Fig.paper)
                fxRect(98, 126, 168, 70, 12, Fig.paper)
                fxRect(98, 52, 168, 70, 12, Fig.paper)
            }
            fxLayer(2, step) {
                fxRect(102, 204, 160, 62, 9, Fig.coin, stroke: 0)
                fxText("$11,925", Fig.caption, 232, 212)
            }
            fxLayer(3, step) {
                fxRect(102, 130, 160, 62, 9, Fig.leaf, stroke: 0)
                fxText("$48,475", Fig.caption, 232, 138)
            }
            fxLayer(4, step) {
                // $1,525 of the band's $54,875 is 2.8% of its height. Drawn as the level
                // the money reaches rather than as a fill: at 1.9pt a filled sliver is
                // invisible, and a line at the same height is both visible and true.
                fxRect(106, 121 - bracketsFillH, 152, bracketsFillH, 0, Fig.coral, stroke: 0)
                fxText("$103,350", Fig.caption, 232, 64)
                fxText("$50,000", Fig.caption, 54, 100, weight: .black)
                fxText("lands here", Fig.caption, 54, 116)
                fxArrow(80, 100, 94, 114, Fig.ink, Fig.pointer)
            }
            fxLayer(5, step) {
                fxText("a raise", Fig.caption, 56, 150)
                fxText("taxes only", Fig.caption, 56, 167)
                fxText("new dollars", Fig.caption, 56, 184, weight: .black)
            }
            // The rates sit above every fill, so each is drawn once and never doubles.
            fxLayer(1, step) {
                fxText("10%", 22, 182, 235, weight: .black)
                fxText("12%", 22, 182, 161, weight: .black)
                fxText("22%", 22, 182, 87, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One jar. Built to the reference's recipe: the jar is the one big mass and runs off the
/// bottom edge, "ROTH" is set large inside it, and the coin, the green growth, the arrow
/// out and the yearly cap are the only other marks. Five shapes, one arrow, seven words.
/// The sentence under the card carries the rest.
struct JarFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxRect(84, 84, 192, 190, 26, Fig.sky)
                fxRect(96, 66, 168, 26, 8, Fig.sky)
                fxText("ROTH", 30, 180, 134, weight: .black)
                fxOval(180, 40, 18, 18, Fig.coin)
                fxText("IN", Fig.caption, 180, 40, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(90, 180, 180, 92, 22, Fig.leaf, stroke: 0)
                fxText("UNTAXED", Fig.label, 180, 226, weight: .black)
            }
            fxLayer(3, step) {
                fxArrow(250, 150, 332, 150, Fig.ink, Fig.pointer)
                fxText("59½", Fig.label, 312, 132, weight: .black)
            }
            fxLayer(4, step) {
                fxChip("$7,000 / YR", Fig.caption, 16, 26, 112, Fig.chipH, Fig.coin)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One burrito with its end cut off. The cut is a hard ink line straight down through
/// the tortilla, and the piece past it — about a fifth — is set aside in a hollow
/// outline, so with the words off a stranger sees a burrito with a slice taken away
/// rather than a shine on the wrapper. The bracket underneath measures only what is
/// left, which is what the old $8 still buys.
struct BurritoFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxArt("burrito", 36, 96, 288, 128)
                fxChip("$8 · 2020", Fig.label, 26, 36, 130, Fig.chipH, Fig.paper)
            }
            fxLayer(2, step) { fxChip("$10 · 2025", Fig.label, 204, 36, 130, Fig.chipH, Fig.coral, color: .white) }
            fxLayer(3, step) {
                // The end is lifted off the drawing, then re-drawn hollow to the right of
                // a clean gap. The wash this replaces read as a highlight, not a loss.
                fxRect(266, 98, 60, 126, 0, Fig.coinField, stroke: 0)
                fxStroke(Fig.ink, Fig.strike) { $0.go(266, 106); $0.to(266, 214) }
                fxPoly(Fig.coinField) { p in
                    p.go(280, 107)
                    p.curve(332, 160, 308.7, 107, 332, 130.7)
                    p.curve(280, 213, 332, 189.3, 308.7, 213)
                    p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.leader) { $0.go(72, 220); $0.to(72, 228); $0.to(266, 228); $0.to(266, 220) }
                fxText("your $8 buys this much", Fig.caption, 168, 244)
            }
            fxLayer(4, step) { fxChip("cash loses ~3% a year", Fig.label, 80, 256, 200, Fig.chipH, Fig.faint) }
        }
        .animation(Fig.reveal, value: step)
    }
}

// MARK: - Philosophy, continued

/// One track that forks. Built the way the reference builds a figure: the track is the
/// one big mass and bleeds off both edges, the two counts are set large on it, and
/// everything that was decoration — sleepers, a pantograph, a footbridge — is gone.
/// Six shapes, four words. The sentence under the card carries the rest.
/// Asking for a raise, for `work-3`. A calendar, the year it turns on, and the folder
/// you bring. The middle card is a chart from `design/figure-art/lesson_charts.py`.
struct RaiseAskFigure: View {
    let step: Int

    private var art: String {
        switch step {
        case 1:  return "scene-work-calendar"   // the review you were waiting for
        case 2:  return "scene-raise-timing"    // when the money is actually split
        default: return "scene-work-evidence"   // the list you kept all year
        }
    }

    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxArt(art, 0, 0, 360, 300)
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The salary question, for `work-2`. Four pictures, no code-drawn geometry.
///
/// The two charts used to be drawn here from point arrays computed in Python. Nothing
/// in that path could measure a string, so a label was drawn wider than the box it sat
/// in and type landed on lines three separate times. They are now rendered whole by
/// `design/figure-art/lesson_charts.py`, which holds the app's own SFNSRounded and so
/// measures every label before drawing it. The trade is that chart type no longer
/// scales with Dynamic Type — worth it for charts, not for prose.
struct SalaryAskFigure: View {
    let step: Int

    private var art: String {
        switch step {
        case 1:  return "scene-work-question"   // the call: two people, an empty bubble
        case 2:  return "scene-work-band"       // their range, and where the answer fell
        case 3:  return "scene-work-careers"    // ten years of the same raises
        default: return "scene-work-handback"   // the question, passed back
        }
    }

    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxArt(art, 0, 0, 360, 300)
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The 401(k) match.
///
/// Cards 1, 2 and 5 are style-locked variation art — different pictures sharing only a
/// drawing style, so the card swaps the whole image rather than adding a layer, which is
/// why this reads as a `switch` and not as `fxLayer`s. See `design/figure-art/STYLE-BLOCK.md`.
///
/// Cards 3 and 4 are drawn in code, because they carry numbers. Every figure on them
/// comes from `charts.py workmatch`, which prints its own checks: 4% of $52,000 is
/// $2,080, that is $80 across 26 paychecks, and the market at 8% needs 9.01 years to
/// double. An earlier draft asserted "your money doubled" in the copy and drew a picture
/// of coins, which showed the student nothing.
struct WorkMatchFigure: View {
    let step: Int

    var body: some View {
        Group {
            switch step {
            case 3:  math
            case 4:  race
            default: FigureCanvas(field: Fig.coinField) { fxArt(art, 0, 20, 360, 269) }
            }
        }
        .animation(Fig.reveal, value: step)
    }

    private var art: String {
        switch step {
        case 1:  return "scene-work-offer"    // the letter: letterhead, ragged paragraphs, a signature
        case 2:  return "scene-work-second"   // the page beneath, one line highlighted
        default: return "scene-work-refused"  // a coin offered, a palm turned out
        }
    }

    /// Where 4% of a salary actually is, then what the match does to it.
    ///
    /// The slice is drawn at its true width — 12.2pt of a 304pt bar — and the smallness
    /// is the argument: this is the whole ask. The pair below is that same slice blown
    /// up, which is what the two dashed leaders are saying.
    private var math: some View {
        FigureCanvas(field: Fig.coinField) {
            fxRect(workBarX0, 58, workBarW, 40, 8, Fig.paper)
            fxText("$52,000", 20, 90, 78, weight: .black)
            fxRect(workBarX0 + workBarW - workSliceW, 58,
                   workSliceW, 40, 4, Fig.coin, stroke: 0)
            fxText("4%", Fig.caption, 288, 122, weight: .black)
            fxArrow(302, 116, 322, 102, Fig.ink, Fig.pointer)

            // The zoom: the slice's two edges fan down to the pair below.
            fxDash(2) { $0.go(workBarX0 + workBarW - workSliceW, 98); $0.to(48, 150) }
            fxDash(2) { $0.go(workBarX0 + workBarW, 98); $0.to(174, 150) }

            fxRect(48, 150, 126, 66, 10, Fig.coin)
            fxText("$2,080", 22, 111, 172, weight: .black)
            fxText("you put in", Fig.caption, 111, 196)

            fxRect(186, 150, 126, 66, 10, Fig.leaf)
            fxText("$2,080", 22, 249, 172, weight: .black)
            fxText("they add", Fig.caption, 249, 196)

            fxText("$80 a paycheck", Fig.caption, 180, 238, color: Fig.ink.opacity(Fig.sub))
            fxText("$4,160", 24, 180, 266, weight: .black)
        }
    }

    /// Why the match beats anything you could buy.
    ///
    /// Everything here comes from `charts.py workmatch`, including the tick positions
    /// and the shaded gap, so this view only renders. The gold line is the match: it
    /// reaches $4,160 at year zero and waits there. The blue curve is the same $2,080
    /// growing at the 8% `compound` already uses, and it needs 9.01 years to arrive.
    /// The shaded area between them is the whole argument.
    private var race: some View {
        FigureCanvas(field: Fig.coinField) {
            fxPoly(Fig.coin.opacity(Fig.sub), stroke: 0) { p in
                guard let first = workGap.first else { return }
                p.move(to: first)
                for q in workGap.dropFirst() { p.addLine(to: q) }
                p.closeSubpath()
            }
            fxStroke(Fig.ink, Fig.leader) { $0.go(workLeftX, workBaseY); $0.to(342, workBaseY) }
            ForEach(workTickX, id: \.self) { x in
                fxStroke(Fig.ink, Fig.leader) { $0.go(x, workBaseY); $0.to(x, workBaseY + 6) }
            }

            fxLine(workMatchStep, Fig.coin, 9)
            fxLine(workMarket, Fig.skyDeep, 9)
            fxOval(workCrossX, workTopY, 11, 11, Fig.ink, stroke: 0)

            fxText("$4,160", Fig.caption, 104, 80, weight: .black)
            fxText("the match", Fig.caption, 252, 80, weight: .black)
            fxText("on your own", Fig.caption, 244, 190, color: Fig.skyDeep)
            fxText("$2,080", Fig.caption, 84, 248, color: Fig.ink.opacity(Fig.sub))
            fxText("9 years", Fig.caption, workCrossX, 248, weight: .black)
        }
    }
}

/// The trolley problem. A real track — rails and ties — running in from the left and
/// forking down to the side line. Five stand on the main line, one on the side line,
/// and you are at the lever. Every word sits in empty field: nothing is written over a
/// person, which is the mistake the first version of this figure made.
struct TrolleyFigure: View {
    let step: Int

    var body: some View {
        // Steps 1-4 build the scene a layer at a time. Step 5 is a different picture
        // entirely — what people actually answer — so it replaces the drawing rather
        // than adding to it. See design/figure-art/lesson_charts.py.
        Group {
            if step >= 5 {
                FigureCanvas(field: Fig.skyField) { fxArt("scene-trolley-split", 0, 0, 360, 300) }
            } else {
                scene
            }
        }
        .animation(Fig.reveal, value: step)
    }

    private var scene: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxTrack(-20, 118, 380, 118)
                fxTrack(146, 133, 252, 190, tie: 26)
                fxTrack(244, 190, 380, 190)
                // The tram is the hero object, not a rounded rectangle. The box keeps
                // the art's own 1.135 aspect so it fills the box exactly, and its bottom
                // is the rail top (118 - 7), which puts the wheels on the rail.
                fxArt("trolley", 14, 29.9, 92, 81.1)
            }
            fxLayer(2, step) {
                ForEach(0..<5, id: \.self) { i in
                    fxPerson(200 + CGFloat(i) * 26, 111, Fig.paper, size: 0.62)
                }
                fxText("FIVE", 20, 252, 44, weight: .black)
            }
            fxLayer(3, step) {
                fxPerson(318, 183, Fig.paper, size: 0.62)
                fxText("ONE", 20, 318, 220, weight: .black)
            }
            fxLayer(4, step) {
                fxStroke(Fig.ink, Fig.strike) { $0.go(146, 131); $0.to(104, 196) }
                fxOval(104, 196, 8, 8, Fig.coral)
                fxPerson(62, 252, Fig.coral, size: 0.62)
                fxText("YOU", 20, 62, 271, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The ship of Theseus, drawn as a ship: a tapering clinker hull of six planks with two
/// upturned prow posts, a mast and one sail. Replacement happens inside the hull's own
/// rhythm — a new plank is the band between two of the hull's own seams, filled edge to
/// edge, so a board of the ship turns green rather than a sticker landing on it. With
/// every word off you see a sailboat losing its old boards to new ones, and then a second,
/// smaller boat of the same shape built from what came off.
struct ShipFigure: View {
    let step: Int

    // The hull: a trapezoid from (34,192)-(326,192) down to (118,300)-(242,300),
    // bleeding off the bottom edge. Both sides run at the same 0.7778 taper, so a
    // plank band computed from these two functions fits the hull exactly.
    private func hullL(_ y: CGFloat) -> CGFloat { 34 + 0.7778 * (y - 192) }
    private func hullR(_ y: CGFloat) -> CGFloat { 326 - 0.7778 * (y - 192) }
    private func band(_ i: Int) -> CGFloat { 192 + CGFloat(i) * 18 }

    /// One seam between two planks, run wall to wall across the hull.
    private func seam(_ i: Int) -> some View {
        let y = band(i), l = hullL(y), r = hullR(y)
        return fxStroke(Fig.ink, Fig.rule) { $0.go(l, y); $0.to(r, y) }
    }

    /// Plank `i` of the hull, replaced with new wood. Same four corners the hull's own
    /// outline passes through, so it reads as a board of the ship and not a patch on it.
    private func newPlank(_ i: Int) -> some View {
        let t = band(i), b = band(i + 1)
        let lt = hullL(t), rt = hullR(t), lb = hullL(b), rb = hullR(b)
        return fxPoly(Fig.leaf) { p in
            p.go(lt, t); p.to(rt, t); p.to(rb, b); p.to(lb, b); p.closeSubpath()
        }
    }

    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxRect(178, 50, 7, 150, 3, Fig.coin)
                fxPoly(Fig.paper) { p in
                    p.go(190, 56); p.to(190, 200); p.to(318, 200); p.closeSubpath()
                }
                fxPoly(Fig.faint) { p in
                    p.go(34, 192); p.to(326, 192); p.to(242, 300); p.to(118, 300); p.closeSubpath()
                }
                ForEach(1..<6, id: \.self) { i in seam(i) }
                fxStroke(Fig.ink, Fig.rail) { $0.go(34, 192); $0.curve(20, 158, 29, 180, 20, 172) }
                fxStroke(Fig.ink, Fig.rail) { $0.go(326, 192); $0.curve(340, 158, 331, 180, 340, 172) }
                fxText("SAME?", 22, 250, 178, weight: .black)
            }
            fxLayer(2, step) {
                newPlank(1)
                newPlank(3)
                fxText("new wood", Fig.caption, 312, 262)
            }
            fxLayer(3, step) {
                newPlank(0)
                newPlank(2)
                newPlank(4)
                newPlank(5)
                fxText("all new", Fig.caption, 52, 262)
            }
            fxLayer(4, step) {
                fxRect(70, 62, 5, 46, 2, Fig.coin)
                fxPoly(Fig.paper) { p in
                    p.go(79, 68); p.to(79, 110); p.to(120, 110); p.closeSubpath()
                }
                fxPoly(Fig.faint) { p in
                    p.go(22, 104); p.to(126, 104); p.to(100, 152); p.to(48, 152); p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.rule) { $0.go(30.7, 120); $0.to(117.3, 120) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(39.3, 136); $0.to(108.7, 136) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(22, 104); $0.to(18, 86) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(126, 104); $0.to(130, 86) }
                fxText("old planks", Fig.caption, 74, 168)
                fxChip("which is his?", Fig.label, 105, 14, 150, Fig.chipH, Fig.coral, color: .white)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Plato's cave as a hollow in stone: rock overhead with stalactites, rock underfoot, a
/// lit back wall on the left with three prisoners at its foot, a fire on the right, and a
/// rabbit cut-out on a stick standing between them. With every word off you see the fire
/// throw the cut-out's shadow — the same rabbit, two and a half times the size and with
/// no outline — onto the wall the prisoners face, two rays fanning from the flame past
/// the cut-out's ear and belly to the top and bottom of that shadow, and a lit way out.
struct CaveFigure: View {
    let step: Int

    // What makes the dark shape on the wall that rabbit's shadow rather than a blob: a
    // point light inside the flame, the cut-out on the line from it to the wall, and the
    // wall's copy of the same outline `mag` times the size. Because shadow = light +
    // (cut-out − light) × mag, a ray drawn from the light to any point of the shadow
    // runs exactly through the matching point of the cut-out.
    private let lx: CGFloat = 252, ly: CGFloat = 218      // the flame's core
    private let ox: CGFloat = 180, oy: CGFloat = 181.6    // the cut-out
    private let sx: CGFloat = 74, sy: CGFloat = 128       // its shadow on the wall
    private let mag: CGFloat = 2.472
    private let cut: CGFloat = 1.05                       // the cut-out's own size

    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxRect(-12, -12, 384, 324, 0, Fig.lav, stroke: 0)
                // The back wall: the same rock, lit. Where it meets the side of the cave
                // is the line down x = 152, which is what makes it read as a plane.
                fxRect(-12, 20, 164, 250, 0, Fig.paper)
                // Rock overhead, with three stalactites. A jagged line on its own reads
                // as a hill; stone above it with spikes hanging off it reads as a roof.
                fxPoly(Fig.lavDeep) { p in
                    p.go(-12, -12); p.to(372, -12); p.to(372, 44)
                    p.to(330, 32); p.to(300, 46); p.to(268, 34)
                    p.to(248, 100)
                    p.to(228, 44); p.to(198, 30)
                    p.to(176, 104)
                    p.to(152, 36); p.to(120, 42); p.to(86, 36); p.to(34, 30)
                    p.to(22, 62)
                    p.to(12, 34); p.to(-12, 46); p.closeSubpath()
                }
                // Rock underfoot; its top edge is the floor everything stands on.
                fxPoly(Fig.lavDeep) { p in
                    p.go(-12, 270); p.to(372, 270); p.to(372, 312); p.to(-12, 312)
                    p.closeSubpath()
                }
                // The mouth: daylight through a broken edge in the rock, off the right.
                fxPoly(Fig.coin) { p in
                    p.go(296, 270); p.to(308, 226); p.to(300, 190)
                    p.to(316, 150); p.to(344, 132); p.to(372, 126)
                    p.to(372, 270); p.closeSubpath()
                }
                fxPerson(42, 270, Fig.lavDeep, size: 0.68)
                fxPerson(72, 270, Fig.lavDeep, size: 0.68)
                fxPerson(102, 270, Fig.lavDeep, size: 0.68)
            }
            fxLayer(2, step) {
                puppet(sx, sy, cut * mag, Fig.ink, 0)
                fxText("SHADOWS", 22, 78, 203, weight: .black)
            }
            fxLayer(3, step) {
                fxPoly(Fig.coral) { p in
                    p.go(226, 270)
                    p.curve(231, 214, 220, 248, 222, 226)
                    p.curve(250, 176, 240, 200, 242, 186)
                    p.curve(270, 218, 260, 190, 270, 200)
                    p.curve(274, 270, 274, 236, 276, 252)
                    p.closeSubpath()
                }
                fxPoly(Fig.coin) { p in
                    p.go(240, 270)
                    p.curve(243, 226, 236, 252, 238, 236)
                    p.curve(256, 200, 250, 214, 250, 208)
                    p.curve(262, 230, 262, 210, 263, 218)
                    p.curve(261, 270, 263, 246, 261, 256)
                    p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.rule) { $0.go(185, 196); $0.to(185, 270) }
                puppet(ox, oy, cut, Fig.leaf, 2)
                fxDash(2) { $0.go(lx, ly); $0.to(sx - 4 * cut * mag, sy - 29 * cut * mag) }
                fxDash(2) { $0.go(lx, ly); $0.to(sx + 0.59 * cut * mag, sy + 14.89 * cut * mag) }
                fxText("FIRE", Fig.label, 250, 158, weight: .black)
            }
            fxLayer(4, step) {
                fxArrow(286, 214, 310, 196, Fig.ink, Fig.pointer)
                fxPerson(330, 266, Fig.coral, size: 0.68)
                fxText("OUT", Fig.label, 328, 176, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }

    /// The cut-out and the shadow are one outline drawn at two sizes, so the dark shape
    /// on the wall is that rabbit rather than a blob. The shadow takes no outline: an
    /// outlined shape reads as a thing, an unoutlined one reads as the shadow of a thing.
    private func puppet(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                        _ fill: Color, _ stroke: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            fxPoly(fill, stroke: stroke) { p in
                p.go(cx - 15 * s, cy - 6 * s)
                p.to(cx - 15.5 * s, cy - 24 * s)
                p.to(cx - 13.5 * s, cy - 30 * s)
                p.to(cx - 11 * s, cy - 25 * s)
                p.to(cx - 9.5 * s, cy - 6 * s)
                p.closeSubpath()
            }
            fxPoly(fill, stroke: stroke) { p in
                p.go(cx - 8.5 * s, cy - 6 * s)
                p.to(cx - 6.5 * s, cy - 25 * s)
                p.to(cx - 4 * s, cy - 29 * s)
                p.to(cx - 2 * s, cy - 23 * s)
                p.to(cx - 3.5 * s, cy - 6 * s)
                p.closeSubpath()
            }
            fxOval(cx + 5 * s, cy + 5 * s, 13 * s, 10.5 * s, fill, stroke: stroke)
            fxOval(cx - 11 * s, cy - 3 * s, 8 * s, 8.5 * s, fill, stroke: stroke)
        }
    }
}

// MARK: - Study skills, continued

/// A Cornell note page: one portrait sheet with a turned-down corner, pale printed
/// writing lines down the wide side, an ink rule making the narrow question column,
/// and an ink rule across the foot making the summary strip. With every word off it
/// still reads as a sheet of ruled notebook paper split into three zones — which the
/// first version, three flat colour blocks running off the bottom, did not.
struct CornellFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxPoly(Fig.paper, stroke: 2) { p in
                    p.go(64, 16); p.to(272, 16); p.to(296, 40)
                    p.to(296, 284); p.to(64, 284); p.closeSubpath()
                }
                fxPoly(Fig.faint, stroke: 2) { p in
                    p.go(272, 16); p.to(296, 40); p.to(272, 40); p.closeSubpath()
                }
                fxStroke(Fig.sky, Fig.leader) {
                    $0.go(150, 86);  $0.to(286, 86)
                    $0.go(150, 108); $0.to(286, 108)
                    $0.go(150, 130); $0.to(286, 130)
                    $0.go(150, 152); $0.to(286, 152)
                    $0.go(150, 174); $0.to(286, 174)
                    $0.go(150, 196); $0.to(286, 196)
                    $0.go(76, 264);  $0.to(284, 264)
                }
                fxStroke(Fig.ink, Fig.rail) {
                    $0.go(140, 18); $0.to(140, 220)
                    $0.go(66, 220); $0.to(294, 220)
                }
            }
            fxLayer(2, step) {
                fxText("NOTES", 30, 210, 51, weight: .black)
            }
            fxLayer(3, step) {
                fxText("ASK", Fig.label, 102, 51, weight: .black)
            }
            fxLayer(4, step) {
                fxText("SUM UP", Fig.label, 180, 241, weight: .black)
            }
            fxLayer(5, step) {
                fxRect(146, 78, 144, 136, 8, Fig.coral)
                fxText("COVER", Fig.label, 218, 146, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A notebook page you have written an explanation on: three punched holes and a coral
/// margin down the left edge, the topic ruled off at the top, and rows of plain
/// handwriting under it. Where the words go vague the page is torn clean through to the
/// field behind it, and a sticky note goes over the tear with the sentence written
/// again. With every word switched off it is a written page with a hole ripped out of
/// the middle of the writing and a note patched over the hole.
struct FeynmanFigure: View {
    let step: Int

    /// The ruled lines of the page.
    private let ruleY: [CGFloat] = [114, 142, 170, 198, 226, 254, 282]

    /// The handwriting, as words: the line it sits on, then the x it starts and ends at.
    /// The three rows that run into the tear stop short of it, which is what makes the
    /// tear read as a hole in the explanation and not a shape parked on the paper.
    private let words: [[CGFloat]] = [
        [114, 80, 126], [114, 134, 186], [114, 194, 238], [114, 246, 304],
        [142, 80, 118], [142, 126, 176], [142, 184, 222], [142, 230, 278],
        [170, 80, 132], [170, 140, 184], [170, 192, 246], [170, 254, 308],
        [198, 80, 108], [198, 116, 134],
        [226, 80, 122],
        [254, 80, 112], [254, 120, 138],
        [282, 80, 124], [282, 132, 178], [282, 186, 234], [282, 242, 296],
    ]

    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxRect(30, 20, 300, 300, 6, Fig.paper)
                fxOval(50, 96, 7, 7, Fig.leafField)
                fxOval(50, 170, 7, 7, Fig.leafField)
                fxOval(50, 244, 7, 7, Fig.leafField)
                fxStroke(Fig.coral, Fig.rule) { $0.go(72, 28); $0.to(72, 320) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(72, 86); $0.to(314, 86) }
                ForEach(0..<ruleY.count, id: \.self) { i in
                    let y = ruleY[i]
                    fxStroke(Fig.faint, Fig.rule) { $0.go(72, y); $0.to(314, y) }
                }
                fxText("PHOTOSYNTHESIS", 24, 202, 56, weight: .black)
            }
            fxLayer(2, step) {
                ForEach(0..<words.count, id: \.self) { i in
                    let w = words[i]
                    fxStroke(Fig.ink, Fig.strike) { $0.go(w[1], w[0]); $0.to(w[2], w[0]) }
                }
            }
            fxLayer(3, step) {
                fxPoly(Fig.leafField) { p in
                    p.go(290, 224)
                    p.to(279, 234); p.to(283, 246); p.to(262, 251); p.to(256, 262)
                    p.to(235, 262); p.to(219, 269); p.to(202, 264); p.to(181, 268)
                    p.to(169, 258); p.to(152, 254); p.to(149, 243); p.to(134, 235)
                    p.to(138, 224); p.to(131, 213); p.to(150, 206); p.to(148, 192)
                    p.to(169, 189); p.to(181, 180); p.to(201, 183); p.to(219, 179)
                    p.to(234, 187); p.to(256, 186); p.to(261, 198); p.to(280, 203)
                    p.to(277, 214)
                    p.closeSubpath()
                }
                fxText("GAP", Fig.label, 166, 226, weight: .black)
            }
            fxLayer(4, step) {
                fxRect(206, 188, 94, 70, 6, Fig.coin)
                fxText("PLAIN", Fig.label, 253, 211, weight: .black)
                fxStroke(Fig.ink, Fig.strike) { $0.go(218, 234); $0.to(288, 234) }
                fxStroke(Fig.ink, Fig.strike) { $0.go(218, 248); $0.to(254, 248) }
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
                fxText("11pm", Fig.caption, 46, 104); fxText("7am", Fig.caption, 314, 104)
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
                fxStroke(Fig.ink, Fig.leader) { $0.go(96, 182); $0.to(96, 200) }
                fxChip("deep: facts filed", Fig.caption, 26, 200, 140, Fig.chipH, Fig.paper)
            }
            fxLayer(4, step) {
                fxStroke(Fig.ink, Fig.leader) { $0.go(264, 182); $0.to(264, 200) }
                fxChip("dreams: connected", Fig.caption, 194, 200, 140, Fig.chipH, Fig.paper)
            }
            fxLayer(5, step) {
                fxRect(180, 120, 154, 60, 0, Fig.skyField.opacity(Fig.dim), stroke: 0)
                fxStroke(Fig.coral, 3) { $0.go(180, 110); $0.to(180, 190) }
                fxStroke(Fig.ink, Fig.leader) { $0.go(180, 234); $0.to(180, 246) }
                fxChip("cut here: lose the connecting", Fig.caption, 56, 246, 248, Fig.chipH, Fig.coral, color: .white)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A test paper. Read all, bank the easy ones, flag the hard ones, come back.
struct ExamFigure: View {
    let step: Int
    private let rows: [CGFloat] = [52, 86, 120, 154, 188]
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxRect(60, 20, 240, 262, 14, Fig.paper)
                ForEach(0..<5, id: \.self) { i in
                    fxText("\(i + 1).", Fig.label, 82, rows[i], weight: .black)
                    fxStroke(Fig.faint, 6) { $0.go(98, rows[i]); $0.to(i == 2 || i == 4 ? 230 : 200, rows[i]) }
                }
            }
            fxLayer(2, step) { fxChip("read it all first · 60s", Fig.caption, 80, 206, 200, Fig.chipH, Fig.sky) }
            fxLayer(3, step) {
                ForEach([0, 1, 3], id: \.self) { i in
                    fxOval(270, rows[i], 11, 11, Fig.mint)
                    fxStroke(Fig.ink, Fig.leader) { $0.go(264, rows[i]); $0.to(268, rows[i] + 4); $0.to(276, rows[i] - 4) }
                }
            }
            fxLayer(4, step) {
                ForEach([2, 4], id: \.self) { i in fxChip("later", Fig.caption, 240, rows[i] - 11, 54, 22, Fig.coral, color: .white) }
            }
            fxLayer(5, step) { fxChip("come back with time left", Fig.caption, 80, 242, 200, Fig.chipH, Fig.leaf) }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Every arrow the set can draw, for looking at the head shape on its own.
///
/// Arrowheads were wrong three times before they were right, each time only visible
/// once buried inside a finished figure. This draws eight directions and a short one at
/// whatever weight is asked for, so the shape can be checked before it goes anywhere.
/// Rendered by `design/figure-art` tooling; nothing in the app presents it.
struct FigureArrowProbe: View {
    var width: CGFloat = Fig.pointer

    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) / 8 * 2 * .pi
                fxArrow(180, 150, 180 + 96 * cos(a), 150 + 96 * sin(a), Fig.ink, width)
            }
            fxArrow(40, 40, 74, 52, Fig.coral, width)
            fxArrow(320, 260, 300, 232, Fig.leafDeep, width)
        }
    }
}

// MARK: - Generated curves
//
// Computed by design/figure-art/charts.py from the formula each figure is about,
// then mapped into the 360x300 figure space. Re-run that script to change one.

/// $1,000 at 8% a year, from the start.
/// Generated by design/figure-art/charts.py — do not hand-edit.
/// $2,080 at 8% a year for ten years.
/// Generated by design/figure-art/charts.py — do not hand-edit.
/// Label anchors, placed and clearance-checked by charts.py.
private let bandL0: CGPoint = CGPoint(x: 187.3, y: 216.0)   // $70k
private let bandL1: CGPoint = CGPoint(x: 262.4, y: 216.0)   // $80k
private let bandL2: CGPoint = CGPoint(x: 206.1, y: 173.0)   // what they budgeted
private let bandL3: CGPoint = CGPoint(x: 149.7, y: 122.0)   // $65,000
private let bandL4: CGPoint = CGPoint(x: 262.4, y: 128.0)   // $80,000
private let bandL5: CGPoint = CGPoint(x: 112.1, y: 232.0)   // you said
private let bandL6: CGPoint = CGPoint(x: 112.1, y: 256.0)   // $60,000
private let bandX0: CGFloat = 149.7
private let bandX1: CGFloat = 262.4
private let bandSaidX: CGFloat = 112.1
private let bandTop: CGFloat = 150.0
private let bandBottom: CGFloat = 196.0
private let bandTickX: [CGFloat] = [187.3, 262.4]
/// $65,000 with 3% raises.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let anchorTheirs: [CGPoint] = [
    CGPoint(x: 74.0, y: 174.0),
    CGPoint(x: 80.4, y: 172.2),
    CGPoint(x: 86.7, y: 170.5),
    CGPoint(x: 93.1, y: 168.7),
    CGPoint(x: 99.4, y: 166.9),
    CGPoint(x: 105.8, y: 165.1),
    CGPoint(x: 112.2, y: 163.2),
    CGPoint(x: 118.5, y: 161.4),
    CGPoint(x: 124.9, y: 159.6),
    CGPoint(x: 131.2, y: 157.7),
    CGPoint(x: 137.6, y: 155.8),
    CGPoint(x: 143.9, y: 153.9),
    CGPoint(x: 150.3, y: 152.0),
    CGPoint(x: 156.7, y: 150.1),
    CGPoint(x: 163.0, y: 148.1),
    CGPoint(x: 169.4, y: 146.2),
    CGPoint(x: 175.7, y: 144.2),
    CGPoint(x: 182.1, y: 142.2),
    CGPoint(x: 188.5, y: 140.2),
    CGPoint(x: 194.8, y: 138.2),
    CGPoint(x: 201.2, y: 136.2),
    CGPoint(x: 207.5, y: 134.1),
    CGPoint(x: 213.9, y: 132.1),
    CGPoint(x: 220.3, y: 130.0),
    CGPoint(x: 226.6, y: 127.9),
    CGPoint(x: 233.0, y: 125.8),
    CGPoint(x: 239.3, y: 123.7),
    CGPoint(x: 245.7, y: 121.5),
    CGPoint(x: 252.1, y: 119.4),
    CGPoint(x: 258.4, y: 117.2),
    CGPoint(x: 264.8, y: 115.0),
    CGPoint(x: 271.1, y: 112.8),
    CGPoint(x: 277.5, y: 110.6),
    CGPoint(x: 283.8, y: 108.3),
    CGPoint(x: 290.2, y: 106.1),
    CGPoint(x: 296.6, y: 103.8),
    CGPoint(x: 302.9, y: 101.5),
    CGPoint(x: 309.3, y: 99.2),
    CGPoint(x: 315.6, y: 96.9),
    CGPoint(x: 322.0, y: 94.5),
]
/// $60,000 with the same raises.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let anchorYours: [CGPoint] = [
    CGPoint(x: 74.0, y: 191.8),
    CGPoint(x: 80.4, y: 190.2),
    CGPoint(x: 86.7, y: 188.5),
    CGPoint(x: 93.1, y: 186.9),
    CGPoint(x: 99.4, y: 185.2),
    CGPoint(x: 105.8, y: 183.5),
    CGPoint(x: 112.2, y: 181.9),
    CGPoint(x: 118.5, y: 180.2),
    CGPoint(x: 124.9, y: 178.4),
    CGPoint(x: 131.2, y: 176.7),
    CGPoint(x: 137.6, y: 175.0),
    CGPoint(x: 143.9, y: 173.2),
    CGPoint(x: 150.3, y: 171.5),
    CGPoint(x: 156.7, y: 169.7),
    CGPoint(x: 163.0, y: 167.9),
    CGPoint(x: 169.4, y: 166.1),
    CGPoint(x: 175.7, y: 164.3),
    CGPoint(x: 182.1, y: 162.4),
    CGPoint(x: 188.5, y: 160.6),
    CGPoint(x: 194.8, y: 158.7),
    CGPoint(x: 201.2, y: 156.9),
    CGPoint(x: 207.5, y: 155.0),
    CGPoint(x: 213.9, y: 153.1),
    CGPoint(x: 220.3, y: 151.2),
    CGPoint(x: 226.6, y: 149.2),
    CGPoint(x: 233.0, y: 147.3),
    CGPoint(x: 239.3, y: 145.3),
    CGPoint(x: 245.7, y: 143.3),
    CGPoint(x: 252.1, y: 141.3),
    CGPoint(x: 258.4, y: 139.3),
    CGPoint(x: 264.8, y: 137.3),
    CGPoint(x: 271.1, y: 135.3),
    CGPoint(x: 277.5, y: 133.2),
    CGPoint(x: 283.8, y: 131.2),
    CGPoint(x: 290.2, y: 129.1),
    CGPoint(x: 296.6, y: 127.0),
    CGPoint(x: 302.9, y: 124.9),
    CGPoint(x: 309.3, y: 122.7),
    CGPoint(x: 315.6, y: 120.6),
    CGPoint(x: 322.0, y: 118.4),
]
/// The years between the two.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let anchorGap: [CGPoint] = [
    CGPoint(x: 74.0, y: 174.0),
    CGPoint(x: 80.4, y: 172.2),
    CGPoint(x: 86.7, y: 170.5),
    CGPoint(x: 93.1, y: 168.7),
    CGPoint(x: 99.4, y: 166.9),
    CGPoint(x: 105.8, y: 165.1),
    CGPoint(x: 112.2, y: 163.2),
    CGPoint(x: 118.5, y: 161.4),
    CGPoint(x: 124.9, y: 159.6),
    CGPoint(x: 131.2, y: 157.7),
    CGPoint(x: 137.6, y: 155.8),
    CGPoint(x: 143.9, y: 153.9),
    CGPoint(x: 150.3, y: 152.0),
    CGPoint(x: 156.7, y: 150.1),
    CGPoint(x: 163.0, y: 148.1),
    CGPoint(x: 169.4, y: 146.2),
    CGPoint(x: 175.7, y: 144.2),
    CGPoint(x: 182.1, y: 142.2),
    CGPoint(x: 188.5, y: 140.2),
    CGPoint(x: 194.8, y: 138.2),
    CGPoint(x: 201.2, y: 136.2),
    CGPoint(x: 207.5, y: 134.1),
    CGPoint(x: 213.9, y: 132.1),
    CGPoint(x: 220.3, y: 130.0),
    CGPoint(x: 226.6, y: 127.9),
    CGPoint(x: 233.0, y: 125.8),
    CGPoint(x: 239.3, y: 123.7),
    CGPoint(x: 245.7, y: 121.5),
    CGPoint(x: 252.1, y: 119.4),
    CGPoint(x: 258.4, y: 117.2),
    CGPoint(x: 264.8, y: 115.0),
    CGPoint(x: 271.1, y: 112.8),
    CGPoint(x: 277.5, y: 110.6),
    CGPoint(x: 283.8, y: 108.3),
    CGPoint(x: 290.2, y: 106.1),
    CGPoint(x: 296.6, y: 103.8),
    CGPoint(x: 302.9, y: 101.5),
    CGPoint(x: 309.3, y: 99.2),
    CGPoint(x: 315.6, y: 96.9),
    CGPoint(x: 322.0, y: 94.5),
    CGPoint(x: 322.0, y: 118.4),
    CGPoint(x: 315.6, y: 120.6),
    CGPoint(x: 309.3, y: 122.7),
    CGPoint(x: 302.9, y: 124.9),
    CGPoint(x: 296.6, y: 127.0),
    CGPoint(x: 290.2, y: 129.1),
    CGPoint(x: 283.8, y: 131.2),
    CGPoint(x: 277.5, y: 133.2),
    CGPoint(x: 271.1, y: 135.3),
    CGPoint(x: 264.8, y: 137.3),
    CGPoint(x: 258.4, y: 139.3),
    CGPoint(x: 252.1, y: 141.3),
    CGPoint(x: 245.7, y: 143.3),
    CGPoint(x: 239.3, y: 145.3),
    CGPoint(x: 233.0, y: 147.3),
    CGPoint(x: 226.6, y: 149.2),
    CGPoint(x: 220.3, y: 151.2),
    CGPoint(x: 213.9, y: 153.1),
    CGPoint(x: 207.5, y: 155.0),
    CGPoint(x: 201.2, y: 156.9),
    CGPoint(x: 194.8, y: 158.7),
    CGPoint(x: 188.5, y: 160.6),
    CGPoint(x: 182.1, y: 162.4),
    CGPoint(x: 175.7, y: 164.3),
    CGPoint(x: 169.4, y: 166.1),
    CGPoint(x: 163.0, y: 167.9),
    CGPoint(x: 156.7, y: 169.7),
    CGPoint(x: 150.3, y: 171.5),
    CGPoint(x: 143.9, y: 173.2),
    CGPoint(x: 137.6, y: 175.0),
    CGPoint(x: 131.2, y: 176.7),
    CGPoint(x: 124.9, y: 178.4),
    CGPoint(x: 118.5, y: 180.2),
    CGPoint(x: 112.2, y: 181.9),
    CGPoint(x: 105.8, y: 183.5),
    CGPoint(x: 99.4, y: 185.2),
    CGPoint(x: 93.1, y: 186.9),
    CGPoint(x: 86.7, y: 188.5),
    CGPoint(x: 80.4, y: 190.2),
    CGPoint(x: 74.0, y: 191.8),
]
/// Label anchors, placed and clearance-checked by charts.py.
private let careersL0: CGPoint = CGPoint(x: 74.0, y: 226.0)   // now
private let careersL1: CGPoint = CGPoint(x: 198.0, y: 226.0)   // 5 yr
private let careersL2: CGPoint = CGPoint(x: 322.0, y: 226.0)   // 10 yr
private let careersL3: CGPoint = CGPoint(x: 96.3, y: 132.6)   // $65,000
private let careersL4: CGPoint = CGPoint(x: 120.3, y: 233.2)   // $60,000
private let careersL5: CGPoint = CGPoint(x: 202.0, y: 92.0)   // $57,319
private let careersL6: CGPoint = CGPoint(x: 202.0, y: 66.0)   // never earned
private let careersRuleY: [CGFloat] = []
private let careersTickX: [CGFloat] = [74.0, 198.0, 322.0]
private let careersAxisY: CGFloat = 206.0
private let careersLeftX: CGFloat = 74.0
private let careersRightX: CGFloat = 322.0

private let workMarket: [CGPoint] = [
    CGPoint(x: 62.0, y: 228.0),
    CGPoint(x: 72.7, y: 223.8),
    CGPoint(x: 83.4, y: 219.5),
    CGPoint(x: 94.2, y: 215.1),
    CGPoint(x: 104.9, y: 210.5),
    CGPoint(x: 115.6, y: 205.7),
    CGPoint(x: 126.3, y: 200.9),
    CGPoint(x: 137.0, y: 195.8),
    CGPoint(x: 147.8, y: 190.7),
    CGPoint(x: 158.5, y: 185.3),
    CGPoint(x: 169.2, y: 179.8),
    CGPoint(x: 179.9, y: 174.1),
    CGPoint(x: 190.6, y: 168.2),
    CGPoint(x: 201.4, y: 162.2),
    CGPoint(x: 212.1, y: 156.0),
    CGPoint(x: 222.8, y: 149.5),
    CGPoint(x: 233.5, y: 142.9),
    CGPoint(x: 244.2, y: 136.1),
    CGPoint(x: 255.0, y: 129.0),
    CGPoint(x: 265.7, y: 121.7),
    CGPoint(x: 276.4, y: 114.2),
    CGPoint(x: 287.1, y: 106.5),
    CGPoint(x: 297.8, y: 98.5),
    CGPoint(x: 308.6, y: 90.3),
    CGPoint(x: 319.3, y: 81.8),
    CGPoint(x: 330.0, y: 73.0),
]
/// The match: straight to twice the money at year zero.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let workMatchStep: [CGPoint] = [
    CGPoint(x: 62.0, y: 228.0),
    CGPoint(x: 62.0, y: 94.3),
    CGPoint(x: 330.0, y: 94.3),
]
/// What the match hands you, until your own money catches up.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let workGap: [CGPoint] = [
    CGPoint(x: 62.0, y: 94.3),
    CGPoint(x: 303.4, y: 94.3),
    CGPoint(x: 303.4, y: 94.3),
    CGPoint(x: 293.3, y: 101.9),
    CGPoint(x: 283.3, y: 109.3),
    CGPoint(x: 273.2, y: 116.5),
    CGPoint(x: 263.1, y: 123.5),
    CGPoint(x: 253.1, y: 130.2),
    CGPoint(x: 243.0, y: 136.8),
    CGPoint(x: 233.0, y: 143.2),
    CGPoint(x: 222.9, y: 149.5),
    CGPoint(x: 212.9, y: 155.5),
    CGPoint(x: 202.8, y: 161.4),
    CGPoint(x: 192.7, y: 167.1),
    CGPoint(x: 182.7, y: 172.6),
    CGPoint(x: 172.6, y: 178.0),
    CGPoint(x: 162.6, y: 183.2),
    CGPoint(x: 152.5, y: 188.3),
    CGPoint(x: 142.5, y: 193.2),
    CGPoint(x: 132.4, y: 198.0),
    CGPoint(x: 122.3, y: 202.7),
    CGPoint(x: 112.3, y: 207.2),
    CGPoint(x: 102.2, y: 211.6),
    CGPoint(x: 92.2, y: 215.9),
    CGPoint(x: 82.1, y: 220.0),
    CGPoint(x: 72.1, y: 224.1),
    CGPoint(x: 62.0, y: 228.0),
]
/// Year ticks along the foot of the chart.
private let workTickX: [CGFloat] = [62.0, 142.4, 222.8, 303.2]
/// The 4% slice at true width, and the chart's own edges.
private let workSliceW: CGFloat = 12.2
private let workBarX0: CGFloat = 28.0
private let workBarW: CGFloat = 304.0
private let workBaseY: CGFloat = 228.0
private let workTopY: CGFloat = 94.3
private let workLeftX: CGFloat = 62.0
private let workRightX: CGFloat = 330.0
private let workCrossX: CGFloat = 303.4

private let compoundEarly: [CGPoint] = [
    CGPoint(x: 64.0, y: 237.5),
    CGPoint(x: 74.9, y: 235.4),
    CGPoint(x: 85.8, y: 233.1),
    CGPoint(x: 96.6, y: 230.6),
    CGPoint(x: 107.5, y: 227.9),
    CGPoint(x: 118.4, y: 224.9),
    CGPoint(x: 129.3, y: 221.7),
    CGPoint(x: 140.2, y: 218.1),
    CGPoint(x: 151.0, y: 214.1),
    CGPoint(x: 161.9, y: 209.8),
    CGPoint(x: 172.8, y: 205.1),
    CGPoint(x: 183.7, y: 199.9),
    CGPoint(x: 194.6, y: 194.1),
    CGPoint(x: 205.4, y: 187.9),
    CGPoint(x: 216.3, y: 181.0),
    CGPoint(x: 227.2, y: 173.5),
    CGPoint(x: 238.1, y: 165.3),
    CGPoint(x: 249.0, y: 156.2),
    CGPoint(x: 259.8, y: 146.3),
    CGPoint(x: 270.7, y: 135.4),
    CGPoint(x: 281.6, y: 123.4),
    CGPoint(x: 292.5, y: 110.3),
    CGPoint(x: 303.4, y: 96.0),
    CGPoint(x: 314.2, y: 80.2),
    CGPoint(x: 325.1, y: 62.9),
    CGPoint(x: 336.0, y: 44.0),
]
/// The same $1,000 at 8%, begun ten years later.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let compoundLate: [CGPoint] = [
    CGPoint(x: 154.7, y: 237.5),
    CGPoint(x: 161.9, y: 236.1),
    CGPoint(x: 169.2, y: 234.7),
    CGPoint(x: 176.4, y: 233.1),
    CGPoint(x: 183.7, y: 231.5),
    CGPoint(x: 190.9, y: 229.8),
    CGPoint(x: 198.2, y: 227.9),
    CGPoint(x: 205.4, y: 226.0),
    CGPoint(x: 212.7, y: 223.9),
    CGPoint(x: 219.9, y: 221.7),
    CGPoint(x: 227.2, y: 219.3),
    CGPoint(x: 234.5, y: 216.8),
    CGPoint(x: 241.7, y: 214.1),
    CGPoint(x: 249.0, y: 211.3),
    CGPoint(x: 256.2, y: 208.3),
    CGPoint(x: 263.5, y: 205.1),
    CGPoint(x: 270.7, y: 201.6),
    CGPoint(x: 278.0, y: 198.0),
    CGPoint(x: 285.2, y: 194.1),
    CGPoint(x: 292.5, y: 190.0),
    CGPoint(x: 299.7, y: 185.7),
    CGPoint(x: 307.0, y: 181.0),
    CGPoint(x: 314.2, y: 176.1),
    CGPoint(x: 321.5, y: 170.8),
    CGPoint(x: 328.7, y: 165.3),
    CGPoint(x: 336.0, y: 159.3),
]
/// x of the doubling point, and the y of $2,000 and of $1,000.
private let compoundDoubleX: CGFloat = 145.7
private let compoundDoubleY: CGFloat = 216.1
private let compoundAxisY: CGFloat = 246.0
private let compoundStartY: CGFloat = 237.5


/// One long session: a single decay.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let spacingCram: [CGPoint] = [
    CGPoint(x: 38.0, y: 52.0),
    CGPoint(x: 45.6, y: 73.1),
    CGPoint(x: 53.3, y: 91.1),
    CGPoint(x: 60.9, y: 106.4),
    CGPoint(x: 68.6, y: 119.5),
    CGPoint(x: 76.2, y: 130.6),
    CGPoint(x: 83.8, y: 140.1),
    CGPoint(x: 91.5, y: 148.1),
    CGPoint(x: 99.1, y: 155.0),
    CGPoint(x: 106.8, y: 160.9),
    CGPoint(x: 114.4, y: 165.9),
    CGPoint(x: 122.1, y: 170.1),
    CGPoint(x: 129.7, y: 173.7),
    CGPoint(x: 137.3, y: 176.8),
    CGPoint(x: 145.0, y: 179.4),
    CGPoint(x: 152.6, y: 181.7),
    CGPoint(x: 160.3, y: 183.6),
    CGPoint(x: 167.9, y: 185.2),
    CGPoint(x: 175.5, y: 186.6),
    CGPoint(x: 183.2, y: 187.8),
    CGPoint(x: 190.8, y: 188.8),
    CGPoint(x: 198.5, y: 189.6),
    CGPoint(x: 206.1, y: 190.4),
    CGPoint(x: 213.7, y: 191.0),
    CGPoint(x: 221.4, y: 191.5),
    CGPoint(x: 229.0, y: 192.0),
    CGPoint(x: 236.7, y: 192.3),
    CGPoint(x: 244.3, y: 192.7),
    CGPoint(x: 251.9, y: 193.0),
    CGPoint(x: 259.6, y: 193.2),
    CGPoint(x: 267.2, y: 193.4),
    CGPoint(x: 274.9, y: 193.6),
    CGPoint(x: 282.5, y: 193.7),
    CGPoint(x: 290.2, y: 193.8),
    CGPoint(x: 297.8, y: 193.9),
    CGPoint(x: 305.4, y: 194.0),
    CGPoint(x: 313.1, y: 194.1),
    CGPoint(x: 320.7, y: 194.2),
    CGPoint(x: 328.4, y: 194.2),
    CGPoint(x: 336.0, y: 194.3),
]
/// Session 1; each review decays more slowly than the last.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let spacingSpaced1: [CGPoint] = [
    CGPoint(x: 38.0, y: 52.0),
    CGPoint(x: 43.0, y: 66.3),
    CGPoint(x: 48.1, y: 79.2),
    CGPoint(x: 53.1, y: 90.8),
    CGPoint(x: 58.2, y: 101.2),
    CGPoint(x: 63.2, y: 110.6),
    CGPoint(x: 68.3, y: 119.0),
    CGPoint(x: 73.3, y: 126.6),
    CGPoint(x: 78.3, y: 133.4),
    CGPoint(x: 83.4, y: 139.5),
    CGPoint(x: 88.4, y: 145.1),
    CGPoint(x: 93.5, y: 150.0),
    CGPoint(x: 98.5, y: 154.5),
    CGPoint(x: 103.6, y: 158.5),
]
/// Session 2; each review decays more slowly than the last.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let spacingSpaced2: [CGPoint] = [
    CGPoint(x: 103.6, y: 52.0),
    CGPoint(x: 109.1, y: 60.5),
    CGPoint(x: 114.6, y: 68.5),
    CGPoint(x: 120.1, y: 76.0),
    CGPoint(x: 125.6, y: 83.1),
    CGPoint(x: 131.1, y: 89.8),
    CGPoint(x: 136.6, y: 96.0),
    CGPoint(x: 142.1, y: 101.9),
    CGPoint(x: 147.6, y: 107.4),
    CGPoint(x: 153.1, y: 112.6),
    CGPoint(x: 158.6, y: 117.5),
    CGPoint(x: 164.1, y: 122.1),
    CGPoint(x: 169.6, y: 126.4),
    CGPoint(x: 175.1, y: 130.5),
]
/// Session 3; each review decays more slowly than the last.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let spacingSpaced3: [CGPoint] = [
    CGPoint(x: 175.1, y: 52.0),
    CGPoint(x: 181.0, y: 57.4),
    CGPoint(x: 187.0, y: 62.6),
    CGPoint(x: 193.0, y: 67.5),
    CGPoint(x: 198.9, y: 72.3),
    CGPoint(x: 204.9, y: 76.9),
    CGPoint(x: 210.8, y: 81.4),
    CGPoint(x: 216.8, y: 85.6),
    CGPoint(x: 222.8, y: 89.8),
    CGPoint(x: 228.7, y: 93.7),
    CGPoint(x: 234.7, y: 97.5),
    CGPoint(x: 240.6, y: 101.2),
    CGPoint(x: 246.6, y: 104.7),
    CGPoint(x: 252.6, y: 108.1),
]
/// Session 4; each review decays more slowly than the last.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let spacingSpaced4: [CGPoint] = [
    CGPoint(x: 252.6, y: 52.0),
    CGPoint(x: 259.0, y: 55.2),
    CGPoint(x: 265.4, y: 58.3),
    CGPoint(x: 271.8, y: 61.4),
    CGPoint(x: 278.2, y: 64.4),
    CGPoint(x: 284.7, y: 67.3),
    CGPoint(x: 291.1, y: 70.1),
    CGPoint(x: 297.5, y: 72.9),
    CGPoint(x: 303.9, y: 75.6),
    CGPoint(x: 310.3, y: 78.3),
    CGPoint(x: 316.7, y: 80.9),
    CGPoint(x: 323.2, y: 83.5),
    CGPoint(x: 329.6, y: 86.0),
    CGPoint(x: 336.0, y: 88.4),
]
/// Where each review picks the curve back up.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let spacingDots: [CGPoint] = [
    CGPoint(x: 103.6, y: 158.5),
    CGPoint(x: 175.1, y: 130.5),
    CGPoint(x: 252.6, y: 108.1),
]
/// The y each review climbs back to.
private let spacingRestartY: [CGFloat] = [52.0, 52.0, 52.0]


/// 300 to 712 of the 300-850 range.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let gaugeFilled: [CGPoint] = [
    CGPoint(x: 93.5, y: 136.5),
    CGPoint(x: 95.1, y: 132.5),
    CGPoint(x: 96.9, y: 128.6),
    CGPoint(x: 98.8, y: 124.7),
    CGPoint(x: 100.9, y: 121.0),
    CGPoint(x: 103.2, y: 117.3),
    CGPoint(x: 105.7, y: 113.7),
    CGPoint(x: 108.3, y: 110.3),
    CGPoint(x: 111.1, y: 107.0),
    CGPoint(x: 114.0, y: 103.9),
    CGPoint(x: 117.1, y: 100.8),
    CGPoint(x: 120.3, y: 98.0),
    CGPoint(x: 123.7, y: 95.2),
    CGPoint(x: 127.2, y: 92.7),
    CGPoint(x: 130.8, y: 90.3),
    CGPoint(x: 134.5, y: 88.1),
    CGPoint(x: 138.3, y: 86.0),
    CGPoint(x: 142.2, y: 84.1),
    CGPoint(x: 146.1, y: 82.5),
    CGPoint(x: 150.2, y: 81.0),
    CGPoint(x: 154.3, y: 79.7),
    CGPoint(x: 158.5, y: 78.6),
    CGPoint(x: 162.7, y: 77.6),
    CGPoint(x: 167.0, y: 76.9),
    CGPoint(x: 171.2, y: 76.4),
    CGPoint(x: 175.5, y: 76.1),
    CGPoint(x: 179.9, y: 76.0),
    CGPoint(x: 184.2, y: 76.1),
    CGPoint(x: 188.5, y: 76.4),
    CGPoint(x: 192.8, y: 76.9),
    CGPoint(x: 197.0, y: 77.6),
    CGPoint(x: 201.3, y: 78.5),
    CGPoint(x: 205.4, y: 79.6),
    CGPoint(x: 209.6, y: 80.9),
    CGPoint(x: 213.6, y: 82.4),
    CGPoint(x: 217.6, y: 84.0),
    CGPoint(x: 221.5, y: 85.9),
    CGPoint(x: 225.3, y: 87.9),
    CGPoint(x: 229.0, y: 90.1),
    CGPoint(x: 232.6, y: 92.5),
]
/// 712 to 850: the part not earned yet.
/// Generated by design/figure-art/charts.py — do not hand-edit.
private let gaugeRest: [CGPoint] = [
    CGPoint(x: 232.6, y: 92.5),
    CGPoint(x: 235.0, y: 94.3),
    CGPoint(x: 237.4, y: 96.1),
    CGPoint(x: 239.7, y: 98.0),
    CGPoint(x: 241.9, y: 99.9),
    CGPoint(x: 244.0, y: 102.0),
    CGPoint(x: 246.1, y: 104.1),
    CGPoint(x: 248.2, y: 106.2),
    CGPoint(x: 250.1, y: 108.5),
    CGPoint(x: 252.0, y: 110.7),
    CGPoint(x: 253.8, y: 113.1),
    CGPoint(x: 255.6, y: 115.5),
    CGPoint(x: 257.2, y: 118.0),
    CGPoint(x: 258.8, y: 120.5),
    CGPoint(x: 260.3, y: 123.1),
    CGPoint(x: 261.7, y: 125.7),
    CGPoint(x: 263.0, y: 128.3),
    CGPoint(x: 264.2, y: 131.0),
    CGPoint(x: 265.4, y: 133.8),
    CGPoint(x: 266.5, y: 136.5),
]


/// How much of the top bucket is actually filled, in points.
private let bracketsFillH: CGFloat = 1.9

private let decayBarH: [CGFloat] = [200.0, 81.9, 43.1, 26.1, 24.1]
private let decayReviewedH: [CGFloat] = [200.0, 200.0, 164.9, 114.4, 70.4]


private let minimumMonths: Int = 70
private let minimumTotal: Int = 1766
private let minimumFastMonths: Int = 26
private let minimumFastTotal: Int = 1257
private let minimumBarH: [CGFloat] = [150.0, 265.0, 188.6]

/// psy-8, anchoring. The mass is a jacket on a hanger, hem running off the bottom
/// edge: long tapered sleeves with cuff bands, a collar, a half zip with teeth and its pull,
/// two patch pockets. A price tag on a string hangs from each cuff — one jacket, two
/// shops. Steps 2 and 4 write the first price each shop shows you; steps 3 and 5 drop
/// an arrow out of that tag to the number you land on. With every word off you see a
/// jacket hanging on a hanger with a price tag swinging from each sleeve.
struct AnchorFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                // The hanger goes down first so the shoulders swallow the bar's ends.
                fxStroke(Fig.ink, Fig.rail) { $0.go(180, 34); $0.to(180, 24); $0.curve(168, 25, 191, 13, 168, 13) }
                fxStroke(Fig.ink, Fig.rail) { $0.go(126, 58); $0.to(180, 32); $0.to(234, 58) }
                fxPoly(Fig.sky) { p in
                    p.go(106, 52); p.to(154, 52); p.to(180, 82); p.to(206, 52); p.to(254, 52)
                    p.to(314, 152); p.to(284, 174); p.to(250, 108); p.to(250, 300)
                    p.to(110, 300); p.to(110, 108); p.to(76, 174); p.to(46, 152)
                    p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.rule) { $0.go(140, 52); $0.to(180, 96); $0.to(220, 52) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(175, 96); $0.to(175, 150) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(185, 96); $0.to(185, 150) }
                ForEach([104, 112, 120, 128, 136, 144], id: \.self) { y in
                    fxStroke(Fig.ink, Fig.leader) { $0.go(175, CGFloat(y)); $0.to(185, CGFloat(y)) }
                }
                fxRect(172, 150, 16, 18, 5, Fig.paper)
                fxStroke(Fig.ink, Fig.rule) { $0.go(77, 159); $0.to(58, 145) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(283, 159); $0.to(302, 145) }
                fxRect(126, 230, 44, 46, 8, Fig.sky)
                fxRect(190, 230, 44, 46, 8, Fig.sky)
                fxText("JACKET", 30, 180, 190, weight: .black)
                fxStroke(Fig.ink, Fig.leader) { $0.go(61, 163); $0.to(61, 180) }
                fxPoly(Fig.coin) { p in
                    p.go(61, 178); p.to(97, 202); p.to(97, 234); p.to(25, 234); p.to(25, 202); p.closeSubpath()
                }
                fxOval(61, 190, 4.5, 4.5, Fig.coinField)
                fxStroke(Fig.ink, Fig.leader) { $0.go(299, 163); $0.to(299, 180) }
                fxPoly(Fig.coin) { p in
                    p.go(299, 178); p.to(335, 202); p.to(335, 234); p.to(263, 234); p.to(263, 202); p.closeSubpath()
                }
                fxOval(299, 190, 4.5, 4.5, Fig.coinField)
            }
            fxLayer(2, step) {
                fxText("$1,200", Fig.label, 61, 218, weight: .black)
            }
            fxLayer(3, step) {
                fxArrow(61, 238, 61, 258, Fig.ink, Fig.pointer)
                fxText("$900", Fig.label, 61, 272, weight: .black)
            }
            fxLayer(4, step) {
                fxText("$300", Fig.label, 299, 218, weight: .black)
            }
            fxLayer(5, step) {
                fxArrow(299, 238, 299, 258, Fig.coral, Fig.pointer)
                fxText("$450", Fig.label, 299, 272, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// psy-9, the fundamental attribution error. One big tray (the mass) split down the
/// middle into the two boxes a cause can land in: PERSON on the left, SITUATION on the
/// right, "WHY" across the top. Step 2 drops THEM into the person box. Step 3 drops YOU
/// into the situation box, one row lower (the next day). Step 4 ghosts in the situation
/// you never saw, in the person box's row. Step 5 is the fix: one arrow from THEM to the
/// box you skipped. Nothing moves; the sentence under the card does the explaining.
struct BlameFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxRect(16, 60, 328, 260, 24, Fig.sky)
                fxStroke(Fig.ink, Fig.pointer) { $0.go(180, 130); $0.to(180, 300) }
                fxText("WHY", 34, 180, 96, weight: .black)
                fxText("PERSON", Fig.label, 98, 150, weight: .black)
                fxText("SITUATION", Fig.label, 262, 150, weight: .black)
            }
            fxLayer(2, step) {
                fxOval(98, 196, 28, 28, Fig.coral)
                fxText("THEM", Fig.caption, 98, 196, weight: .black)
            }
            fxLayer(3, step) {
                fxOval(262, 258, 28, 28, Fig.lav)
                fxText("YOU", Fig.caption, 262, 258, weight: .black)
            }
            fxLayer(4, step) {
                fxDash(2) { $0.addEllipse(in: CGRect(x: 234, y: 168, width: 56, height: 56)) }
            }
            fxLayer(5, step) {
                fxArrow(132, 196, 226, 196, Fig.coral, Fig.pointer)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// psy-10 "Losing $20 hurts twice as much". One mass: a tall lavender meter tube that runs
/// off the bottom edge, big word FEEL inside it, an EVEN line across the middle. Step 2 adds
/// the found-$20 block (one unit up), step 3 the lost-$20 block (two units down), step 4 the
/// $40 mark on the win side, level with the depth of the loss.
struct StingFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxRect(96, 24, 130, 320, 40, Fig.lav)
                fxStroke(Fig.ink, Fig.strike) { $0.go(96, 160); $0.to(250, 160) }
                fxText("EVEN", Fig.caption, 276, 160, weight: .black)
                fxText("FEEL", 30, 161, 68, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(108, 112, 106, 48, 10, Fig.coin)
                fxText("FOUND", Fig.label, 161, 136, weight: .black)
            }
            fxLayer(3, step) {
                fxRect(108, 160, 106, 96, 10, Fig.coral)
                fxText("LOST", Fig.label, 161, 208, color: .white, weight: .black)
            }
            fxLayer(4, step) {
                fxStroke(Fig.coral, Fig.strike) { $0.go(226, 64); $0.to(250, 64) }
                fxText("$40", Fig.label, 276, 64, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A results page. A search field with a magnifier at the top of the screen, then the
/// list: a loud coral result at the top with its thumbnail and two text lines, an empty
/// slot still loading in the middle, and the ordinary result far down the list. With
/// every word off you still see a search box and a ranked list of result rows, the loud
/// one sitting above the plain one.
struct SearchFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxRect(18, 16, 324, 304, 24, Fig.sky)
                fxRect(34, 26, 292, 40, 20, Fig.paper)
                fxOval(58, 46, 10, 10, Fig.paper)
                fxStroke(Fig.ink, Fig.rail) { $0.go(65, 53); $0.to(72, 60) }
                fxDash(2) {
                    $0.go(34, 130); $0.to(326, 130); $0.to(326, 176); $0.to(34, 176); $0.closeSubpath()
                    $0.go(44, 138); $0.to(74, 138); $0.to(74, 168); $0.to(44, 168); $0.closeSubpath()
                }
                fxLeft("SEARCH", 26, 86, 46, 200, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(34, 76, 292, 46, 12, Fig.coral)
                fxRect(44, 84, 30, 30, 7, Fig.paper)
                fxStroke(Fig.ink, Fig.rule) { $0.go(86, 105); $0.to(206, 105) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(86, 114); $0.to(166, 114) }
                fxLeft("SHARK", Fig.label, 86, 91, 90, weight: .black)
            }
            fxLayer(3, step) {
                fxRect(34, 184, 292, 46, 12, Fig.paper)
                fxRect(44, 192, 30, 30, 7, Fig.sky)
                fxStroke(Fig.ink, Fig.rule) { $0.go(86, 213); $0.to(206, 213) }
                fxStroke(Fig.ink, Fig.rule) { $0.go(86, 222); $0.to(166, 222) }
                fxLeft("DROWNING", Fig.label, 86, 199, 110, weight: .black)
            }
            fxLayer(4, step) {
                fxRight("1/YEAR", Fig.label, 310, 91, 70, weight: .black)
                fxRight("4,000/YEAR", Fig.label, 310, 199, 90, weight: .black)
            }
            fxLayer(5, step) {
                fxChip("OUT OF HOW MANY?", Fig.caption, 105, 240, 150, Fig.chipH, Fig.coral)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A thin sliver of what they said. One big speech bubble — rounded body plus a
/// pointed tail — bleeding off the left edge. A narrow strip is cut clean off its
/// right end: the strip shares the bubble's top, bottom and right rounded corners,
/// so its only new edge is the straight vertical cut. With every word off you see a
/// speech bubble with a thin slice taken off one end, and an arrow pointing at the
/// slice. Nothing floats inside the bubble.
struct SliverFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxRect(-34, 56, 366, 168, 30, Fig.lav)
                fxPoly(Fig.lav, stroke: 0) { p in
                    p.go(56, 218); p.to(102, 218); p.to(62, 262); p.closeSubpath()
                }
                fxStroke(Fig.ink, Fig.rule) { $0.go(56, 220); $0.to(62, 262); $0.to(102, 220) }
                fxText("TOO HOT", 30, 118, 126, weight: .black)
            }
            fxLayer(2, step) {
                fxText("AGREE", Fig.label, 118, 172, weight: .black)
            }
            fxLayer(3, step) {
                fxPoly(Fig.coral) { p in
                    p.go(278, 56)
                    p.to(302, 56)
                    p.curve(332, 86, 318.6, 56, 332, 69.4)
                    p.to(332, 194)
                    p.curve(302, 224, 332, 210.6, 318.6, 224)
                    p.to(278, 224)
                    p.closeSubpath()
                }
                fxText("MORNINGS", Fig.caption, 305, 40, weight: .black)
            }
            fxLayer(4, step) {
                fxText("SAY IT BACK", Fig.label, 178, 250, weight: .black)
            }
            fxLayer(5, step) {
                fxArrow(305, 262, 305, 232, Fig.coral, Fig.pointer)
                fxText("EDIT", Fig.label, 305, 278, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// One paper page bleeding off the bottom, ruled into three columns: WHAT, WHO, WHEN.
/// A coin file lands in the first, one person in the second, a day in the third, and
/// the page's title arrives last: ONE LINK.
struct RosterFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxRect(40, 46, 280, 180, 14, Fig.paper)
                fxStroke(Fig.ink, Fig.leader) {
                    $0.go(40, 102); $0.to(320, 102)
                    $0.go(133, 102); $0.to(133, 226)
                    $0.go(227, 102); $0.to(227, 226)
                }
                fxText("WHAT", Fig.label, 86, 122, weight: .black)
                fxText("WHO", Fig.label, 180, 122, weight: .black)
                fxText("WHEN", Fig.label, 273, 122, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(58, 150, 58, 44, 8, Fig.coin)
            }
            fxLayer(3, step) {
                fxPerson(180, 196, Fig.sky, size: 0.62)
            }
            fxLayer(4, step) {
                fxText("TUE", Fig.label, 273, 172, color: Fig.coral, weight: .black)
            }
            fxLayer(5, step) {
                fxText("ONE LINK", 26, 180, 74, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A trail that is the ask: a wide lavender path running off both edges, with the three
/// stops a good ask names. ASK sits at the trailhead; TRIED, STUCK (coral, one exact
/// spot) and NEED land on the path one per step. Four shapes, four words.
struct TrailFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxPoly(Fig.lav) { p in
                    p.go(-20, 196); p.to(150, 196); p.to(290, 72); p.to(380, 72)
                    p.to(380, 136); p.to(290, 136); p.to(150, 260); p.to(-20, 260)
                    p.closeSubpath()
                }
                fxText("ASK", 30, 60, 228, weight: .black)
            }
            fxLayer(2, step) {
                fxOval(124, 228, 9, 9, Fig.paper)
                fxText("TRIED", Fig.label, 124, 250, weight: .black)
            }
            fxLayer(3, step) {
                fxOval(222, 164, 9, 9, Fig.coral)
                fxText("STUCK", Fig.label, 196, 187, weight: .black)
            }
            fxLayer(4, step) {
                fxOval(316, 104, 9, 9, Fig.paper)
                fxText("NEED", Fig.label, 316, 126, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Tone (ppl-9). One text bubble is the whole subject: it bleeds off the left edge with
/// "FINE." inside. Then the two readings land under it, an arrow names the gap, and a warm
/// chip shows the fix. Five shapes, five labels, eight words.
struct ToneFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.roseField) {
            fxLayer(1, step) {
                fxPoly(Fig.sky) { p in
                    p.go(-40, 60); p.to(240, 60); p.to(240, 190)
                    p.to(184, 190); p.to(176, 214); p.to(150, 190)
                    p.to(-40, 190); p.closeSubpath()
                }
                fxText("FINE.", 34, 110, 125, weight: .black)
            }
            fxLayer(2, step) {
                fxText("YOU 80%", Fig.label, 66, 246, weight: .black)
            }
            fxLayer(3, step) {
                fxText("THEM 50%", Fig.label, 300, 246, color: Fig.coral, weight: .black)
            }
            fxLayer(4, step) {
                fxArrow(112, 246, 250, 246, Fig.ink, Fig.pointer)
                fxText("GAP", Fig.caption, 184, 228, weight: .black)
            }
            fxLayer(5, step) {
                fxChip("ALL GOOD!", Fig.caption, 132, 256, 96, Fig.chipH, Fig.coin)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// The $1,000 price as a wide band that bleeds off the bottom; the interest piles on
/// top of it as a coral tower. Two columns: the $28 minimum and the $50 payment. Every
/// height is minimumBarH (150pt per $1,000), so the towers are the interest above the
/// price and the totals sit at their tops.
struct MinimumFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxRect(-10, 300 - minimumBarH[0], 380, minimumBarH[0] + 20, 0, Fig.coin)
                fxText("$1,000", 30, 180, 240, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(58, 300 - minimumBarH[1], 84, minimumBarH[1] - minimumBarH[0], 0, Fig.coral)
                fxText("$28 MO", Fig.caption, 100, 172, weight: .black)
            }
            fxLayer(3, step) {
                fxText("70 MO", Fig.caption, 100, 196, weight: .black)
            }
            fxLayer(4, step) {
                fxText("+$766", Fig.label, 100, 300 - minimumBarH[1] + 19, weight: .black)
            }
            fxLayer(5, step) {
                fxRect(218, 300 - minimumBarH[2], 84, minimumBarH[2] - minimumBarH[0], 0, Fig.coral)
                fxText("$50 MO", Fig.caption, 260, 172, weight: .black)
                fxText("+$257", Fig.label, 260, 300 - minimumBarH[2] + 19, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// An apartment listing card: a photo box holding a walk-up with two rows of lit
/// windows and a coral street door, the asking rent set big underneath it, then the
/// listing's ruled detail lines, one hidden cost added to each. With every word off it
/// still reads as a listing for an apartment, not a blank card. The card is the mass
/// and runs off the bottom edge.
struct MoveinFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.coinField) {
            fxLayer(1, step) {
                fxRect(56, 14, 248, 302, 16, Fig.paper)
                fxRect(72, 26, 216, 92, 8, Fig.sky)
                fxRect(124, 40, 112, 78, 3, Fig.paper)
                ForEach(0..<3, id: \.self) { c in
                    fxRect(134 + CGFloat(c) * 34, 50, 22, 17, 2, Fig.sky)
                    fxRect(134 + CGFloat(c) * 34, 76, 22, 17, 2, Fig.sky)
                }
                fxRect(169, 98, 22, 20, 4, Fig.coral)
                fxText("$1,200", 28, 180, 140, weight: .black)
            }
            fxLayer(2, step) {
                fxStroke(Fig.ink, Fig.rule) { $0.go(78, 164); $0.to(282, 164) }
                fxText("$2,400 KEY", Fig.label, 180, 180, weight: .black)
            }
            fxLayer(3, step) {
                fxStroke(Fig.ink, Fig.rule) { $0.go(78, 196); $0.to(282, 196) }
                fxText("$255 MO", Fig.label, 180, 212, weight: .black)
            }
            fxLayer(4, step) {
                fxStroke(Fig.ink, Fig.rule) { $0.go(78, 228); $0.to(282, 228) }
                fxText("$800 STUFF", Fig.label, 180, 244, weight: .black)
            }
            fxLayer(5, step) {
                fxStroke(Fig.coral, Fig.strike) { $0.go(78, 260); $0.to(282, 260) }
                fxText("$3,200 IN", Fig.label, 180, 276, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Chesterton's fence, drawn as a fence: six uprights planted in a green field with two
/// rails run across them and one panel missing, and beyond the gap an open well with a
/// roof. With every word off you see a post-and-rail fence with a hole in it, a well
/// behind it, a red arrow lifting one post out, and a black arrow asking about the
/// fence. Every word sits on open sky or open grass, never on a rail.
struct FenceFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.skyField) {
            fxLayer(1, step) {
                fxRect(-20, 80, 400, 250, 0, Fig.leaf)
                ForEach(0..<6, id: \.self) { i in
                    fxRect(16 + CGFloat(i) * 62, 150, 16, 102, 4, Fig.lav)
                }
                fxRect(-20, 172, 176, 14, 3, Fig.lav)
                fxRect(-20, 210, 176, 14, 3, Fig.lav)
                fxRect(202, 172, 178, 14, 3, Fig.lav)
                fxRect(202, 210, 178, 14, 3, Fig.lav)
                fxText("FENCE", 30, 80, 44, weight: .black)
            }
            fxLayer(2, step) {
                fxArrow(86, 168, 54, 112, Fig.coral, Fig.pointer)
                fxText("NOT YET", Fig.label, 74, 270, color: Fig.coral, weight: .black)
            }
            fxLayer(3, step) {
                fxRect(153, 62, 7, 48, 2, Fig.paper)
                fxRect(198, 62, 7, 48, 2, Fig.paper)
                fxPoly(Fig.paper) { p in
                    p.go(179, 40); p.to(218, 68); p.to(140, 68); p.closeSubpath()
                }
                fxRect(150, 106, 58, 26, 4, Fig.paper)
                fxOval(179, 106, 32, 12, Fig.paper)
                fxOval(179, 105, 23, 8, Fig.ink)
                fxText("WELL", Fig.label, 268, 118, weight: .black)
            }
            fxLayer(4, step) {
                fxArrow(241, 272, 241, 230, Fig.ink, Fig.pointer)
                fxText("WHY?", Fig.label, 284, 270, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Steelmanning: their side at its strongest is one solid slab that runs off the right
/// edge; the flimsy version is a thin straw stick beside it. A strawman knocks the
/// stick over. Steelmanning names the slab, then aims at it.
struct SteelFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxRect(136, 40, 200, 246, 24, Fig.lavDeep)
                fxText("REAL", Fig.label, 236, 68, weight: .black)
                fxPoly(Fig.coin) { p in
                    p.go(40, 286); p.to(66, 286); p.to(80, 150); p.to(54, 150)
                    p.closeSubpath()
                }
                fxText("FLIMSY", Fig.label, 70, 132, weight: .black)
            }
            fxLayer(2, step) {
                fxStroke(Fig.coral, Fig.strike) { $0.go(36, 176); $0.to(104, 212) }
                fxText("STRAWMAN", Fig.caption, 76, 108, color: Fig.coral, weight: .black)
            }
            fxLayer(3, step) {
                fxText("STEEL", 32, 236, 160, weight: .black)
            }
            fxLayer(4, step) {
                fxArrow(112, 250, 196, 192, Fig.coral, Fig.pointer)
                fxText("AIM", Fig.label, 100, 264, color: Fig.coral, weight: .black)
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// Five bars on one baseline: all of it today, then what is left on days 1, 2, 4
/// and 7. Empty boxes show what fell out; a day-one review refills the column and
/// holds the later days high. Heights come from decayBarH and decayReviewedH.
struct DecayFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.lavField) {
            fxLayer(1, step) {
                fxPoly(Fig.lav) { p in
                    for i in 0..<5 {
                        let x = 20 + CGFloat(i) * 64
                        let h = decayBarH[i]
                        p.go(x, 262 - h); p.to(x + 64, 262 - h); p.to(x + 64, 262); p.to(x, 262)
                        p.closeSubpath()
                    }
                }
                fxText("ALL", 26, 52, 160, weight: .black)
                fxText("TODAY", Fig.label, 52, 278, weight: .black)
                fxText("DAY 1", Fig.label, 116, 278, weight: .black)
                fxText("DAY 7", Fig.label, 308, 278, weight: .black)
            }
            fxLayer(2, step) {
                fxPoly(Fig.paper) { p in
                    for i in 1..<5 {
                        let x = 20 + CGFloat(i) * 64
                        let top = 262 - decayBarH[i]
                        p.go(x, 62); p.to(x + 64, 62); p.to(x + 64, top); p.to(x, top)
                        p.closeSubpath()
                    }
                }
            }
            fxLayer(3, step) {
                fxRect(84, 262 - decayReviewedH[1], 64, decayReviewedH[1], 0, Fig.lavDeep)
                fxText("REVIEW", Fig.label, 116, 80, weight: .black)
            }
            fxLayer(4, step) {
                fxPoly(Fig.lavDeep) { p in
                    for i in 2..<5 {
                        let x = 20 + CGFloat(i) * 64
                        let h = decayReviewedH[i]
                        p.go(x, 262 - h); p.to(x + 64, 262 - h); p.to(x + 64, 262); p.to(x, 262)
                        p.closeSubpath()
                    }
                }
            }
        }
        .animation(Fig.reveal, value: step)
    }
}

/// A Leitner box as one lavender staircase, rising to the right and bleeding off three
/// edges. A card sits on box one at step 1; the answer gets a redaction bar; the three
/// tiers get their cadence with DAILY as the big word; a copy of the card climbs to box
/// two; and one coral arrow drops a miss all the way back down to box one.
struct LeitnerFigure: View {
    let step: Int
    var body: some View {
        FigureCanvas(field: Fig.leafField) {
            fxLayer(1, step) {
                fxPoly(Fig.lav) { p in
                    p.go(-20, 200); p.to(130, 200); p.to(130, 130); p.to(250, 130)
                    p.to(250, 60); p.to(380, 60); p.to(380, 320); p.to(-20, 320)
                    p.closeSubpath()
                }
                fxRect(24, 130, 96, 70, 10, Fig.paper)
                fxText("ONE FACT", Fig.label, 72, 150, weight: .black)
            }
            fxLayer(2, step) {
                fxRect(36, 168, 72, 18, 4, Fig.ink, stroke: 0)
            }
            fxLayer(3, step) {
                fxText("DAILY", 26, 68, 250, weight: .black)
                fxText("3 DAYS", Fig.label, 200, 215, weight: .black)
                fxText("WEEK", Fig.label, 297, 92, weight: .black)
            }
            fxLayer(4, step) {
                fxRect(148, 68, 84, 62, 10, Fig.paper)
                fxRect(158, 102, 64, 16, 4, Fig.ink, stroke: 0)
            }
            fxLayer(5, step) {
                fxArrow(300, 112, 122, 228, Fig.coral, Fig.pointer)
                fxText("MISS", Fig.label, 262, 176, color: Fig.coral, weight: .black)
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

/// A polyline through points computed elsewhere.
///
/// The curves in these figures are charts, so their points come out of
/// `design/figure-art/charts.py` from the actual formula rather than from Bezier handles
/// tuned by eye. A chart about compound interest should be a picture of compound
/// interest; before this the doubling marker sat wherever it looked right.
private func fxLine(_ pts: [CGPoint], _ color: Color, _ w: CGFloat) -> some View {
    FxShape { p in
        guard let first = pts.first else { return }
        p.move(to: first)
        for q in pts.dropFirst() { p.addLine(to: q) }
    }
    .stroke(color, style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
    .frame(width: FigureCanvasMetrics.w, height: FigureCanvasMetrics.h, alignment: .topLeading)
}

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

/// An arrow that points at something.
///
/// The head is a filled triangle rather than two strokes. Drawn as strokes at 2.5pt it
/// reads as a soft tick, and the shaft's round cap pushes out through the middle of it;
/// both were why arrows here never looked deliberate. The shaft now stops inside the
/// head, and the head is sized from the stroke width, so a hairline pointer and a fat
/// flow arrow are the same shape at different scales.
private func fxArrow(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                     _ color: Color = Fig.ink, _ w: CGFloat = Fig.pointer) -> some View {
    let a = atan2(y2 - y1, x2 - x1)
    let dx = cos(a), dy = sin(a)
    let len = max(w * 3.4, 8)      // head length down the shaft
    let half = max(w * 1.75, 4)    // half its base
    let bx = x2 - len * dx, by = y2 - len * dy          // centre of the base
    let sx = bx + dx * w * 0.7, sy = by + dy * w * 0.7  // shaft stops just inside it
    return ZStack(alignment: .topLeading) {
        fxStroke(color, w) { $0.go(x1, y1); $0.to(sx, sy) }
        FxShape { p in
            p.go(x2, y2)
            p.to(bx - half * dy, by + half * dx)
            p.to(bx + half * dy, by - half * dx)
            p.closeSubpath()
        }
        .fill(color)
        .frame(width: FigureCanvasMetrics.w, height: FigureCanvasMetrics.h, alignment: .topLeading)
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
        .opacity(Fig.drawText ? 1 : 0)
        .position(x: cx, y: cy)
}

/// Type that starts at `x` and runs right, for lines that read like a list.
private func fxLeft(_ s: String, _ size: CGFloat, _ x: CGFloat, _ cy: CGFloat, _ w: CGFloat,
                    color: Color = Fig.ink, weight: Font.Weight = .heavy) -> some View {
    Text(s)
        .font(Theme.font(size, weight))
        .foregroundStyle(color)
        .lineLimit(1)
        .opacity(Fig.drawText ? 1 : 0)
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
        .opacity(Fig.drawText ? 1 : 0)
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

/// A railway track: two rails and the ties across them. The ties are what make a band
/// read as a track instead of a road, so they are the object itself and not the kind of
/// texture the house style bans.
private func fxTrack(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                     half: CGFloat = 7, tie: CGFloat = 30) -> some View {
    let dx = x2 - x1, dy = y2 - y1
    let len = max(sqrt(dx * dx + dy * dy), 1)
    let px = -dy / len * half, py = dx / len * half
    let n = max(Int(len / tie), 1)
    return ZStack(alignment: .topLeading) {
        fxStroke(Fig.ink, Fig.rail) { $0.go(x1 + px, y1 + py); $0.to(x2 + px, y2 + py) }
        fxStroke(Fig.ink, Fig.rail) { $0.go(x1 - px, y1 - py); $0.to(x2 - px, y2 - py) }
        ForEach(0...n, id: \.self) { i in
            let t = CGFloat(i) / CGFloat(n)
            let cx = x1 + dx * t, cy = y1 + dy * t
            fxStroke(Fig.ink, Fig.rail) {
                $0.go(cx + px * 1.3, cy + py * 1.3); $0.to(cx - px * 1.3, cy - py * 1.3)
            }
        }
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
            .opacity(Fig.drawText ? 1 : 0)
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
