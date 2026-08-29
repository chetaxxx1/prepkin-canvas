#!/usr/bin/env python3
"""Emit SlimeView.swift with traced bezier data."""
import json

SCRATCH = "/private/tmp/claude-501/-Users-georgeshi-Desktop-app-prepkin-canvas/8e386b9b-4386-4450-acc7-6b9b7ff1db2a/scratchpad"
OUT = "/Users/georgeshi/Desktop/app/prepkin-canvas/ios/Sources/SlimeView.swift"

res = json.load(open(f"{SCRATCH}/trace_result.json"))
ASPECT = res["aspect"]  # W/H of full character bbox


def fmt_segs(segs, indent="        "):
    """Each seg -> [x0,y0, c1x,c1y, c2x,c2y, x3,y3]"""
    lines = []
    for s in segs:
        nums = ", ".join(f"{v:.4f}" for p in s for v in p)
        lines.append(f"{indent}[{nums}],")
    return "\n".join(lines)


def subpaths_block(name, subpaths):
    parts = []
    for sp in subpaths:
        parts.append("        [\n" + fmt_segs(sp, "            ") + "\n        ],")
    return f"    static let {name}: [[[Double]]] = [\n" + "\n".join(parts) + "\n    ]\n"


body = res["body"]
belly = res["belly"]
idle_face = [c["segs"] for c in res["idle_face"]]
expr = res["expressions_meta"]
deadpan = [c["segs"] for c in expr["deadpan"]]
judging = [c["segs"] for c in expr["judging"]]
delight = [c["segs"] for c in expr["delight"]]

data = ""
data += subpaths_block("body", [body])
data += subpaths_block("belly", [belly])
data += subpaths_block("faceIdle", idle_face)
data += subpaths_block("faceDeadpan", deadpan)
data += subpaths_block("faceJudging", judging)
data += subpaths_block("faceDelight", delight)

swift = f'''import SwiftUI

/// The Prepkin slime mascot, drawn in code. All shapes are bezier paths traced
/// programmatically from the approved renders in ~/Desktop/mascot/slime-handoff/
/// (mascot-idle.png + approved-expressions.png), normalized to the character
/// bounding box (aspect {ASPECT:.4f}). Palette from spec.json. The face is
/// always code-drawn — never generated art. Do not hand-edit the path data;
/// re-run the trace scripts instead.
struct SlimeView: View {{
    var color: Color = Slime.body
    var level: Int
    var animation: ChibiAnimation
    var size: CGFloat = 130
    /// Optional explicit face; nil derives it from `animation`.
    var expression: SlimeExpression? = nil

    @State private var squish = false
    @State private var hop = false

    private var scale: CGFloat {{ [1: 0.78, 2: 0.9, 3: 1.0][level] ?? 0.78 }}

    private var face: SlimeExpression {{
        if let expression {{ return expression }}
        switch animation {{
        case .celebrate: return .delight
        case .sleep: return .sleep
        default: return .idle
        }}
    }}

    var body: some View {{
        let w = size * scale                    // character bounding-box width
        let h = w / Slime.aspect                // character bounding-box height
        ZStack {{
            Ellipse()
                .fill(Slime.ink.opacity(0.10))
                .frame(width: w * 0.92, height: h * 0.13)
                .offset(y: h * 0.47)

            ZStack {{
                TracedShape(subpaths: SlimeArt.body).fill(color).frame(width: w, height: h)
                TracedShape(subpaths: SlimeArt.belly).fill(Slime.belly(for: color)).frame(width: w, height: h)
                TracedShape(subpaths: face.art).fill(Slime.ink).frame(width: w, height: h)

                if level >= 2 {{
                    HStack(spacing: w * 0.50) {{
                        Ellipse().fill(Slime.blush).frame(width: w * 0.11, height: h * 0.045)
                        Ellipse().fill(Slime.blush).frame(width: w * 0.11, height: h * 0.045)
                    }}
                    .offset(y: h * 0.04)
                }}
                if level >= 3 {{
                    Text("👑")
                        .font(.system(size: w * 0.24))
                        .rotationEffect(.degrees(-12))
                        .offset(x: -w * 0.20, y: -h * 0.46)
                }}
                if animation == .celebrate {{
                    Text("✨").font(.system(size: w * 0.22)).offset(x: w * 0.52, y: -h * 0.38)
                    Text("✨").font(.system(size: w * 0.16)).offset(x: -w * 0.56, y: -h * 0.12)
                }}
                if face == .sleep {{
                    Text("💤").font(.system(size: w * 0.2)).offset(x: w * 0.48, y: -h * 0.40)
                }}
            }}
            .scaleEffect(x: squish ? 1.04 : 0.99, y: squish ? 0.95 : 1.01, anchor: .bottom)
            .offset(y: hop ? -size * 0.22 : 0)
        }}
        .frame(width: size * 1.35, height: size * 1.15)
        .onAppear {{ startIdle() }}
        .onChange(of: animation) {{ _, new in
            guard new == .bounce || new == .celebrate || new == .wave else {{ return }}
            withAnimation(.interpolatingSpring(stiffness: 260, damping: 9)) {{ hop = true }}
            Task {{
                try? await Task.sleep(for: .seconds(0.32))
                withAnimation(.interpolatingSpring(stiffness: 260, damping: 9)) {{ hop = false }}
            }}
        }}
    }}

    private func startIdle() {{
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {{
            squish = true
        }}
    }}
}}

/// The 4 approved expressions + the sleep placeholder (not yet approved —
/// currently reuses the deadpan-style closed lids; see handoff BRIEF).
enum SlimeExpression {{
    case idle, deadpan, judging, delight, sleep

    var art: [[[Double]]] {{
        switch self {{
        case .idle: return SlimeArt.faceIdle
        case .deadpan: return SlimeArt.faceDeadpan
        case .judging: return SlimeArt.faceJudging
        case .delight: return SlimeArt.faceDelight
        case .sleep: return SlimeArt.faceSleep
        }}
    }}
}}

enum Slime {{
    static let body = Color(red: 0x51 / 255, green: 0xCF / 255, blue: 0xA0 / 255)   // #51CFA0
    static let bellyMint = Color(red: 0xB1 / 255, green: 0xED / 255, blue: 0xD4 / 255)  // #B1EDD4
    static let ink = Color(red: 0x10 / 255, green: 0x18 / 255, blue: 0x20 / 255)    // #101820
    static let blush = Color(red: 0.98, green: 0.55, blue: 0.55).opacity(0.4)
    static let aspect: CGFloat = {ASPECT:.4f}

    /// Exact #B1EDD4 for the canonical mint; recolors get the same 57% blend
    /// toward white so ember/droplet/sprout keep the belly relationship.
    static func belly(for bodyColor: Color) -> Color {{
        if bodyColor == body {{ return bellyMint }}
        let ui = UIColor(bodyColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let t: CGFloat = 0.57
        return Color(red: r + (1 - r) * t, green: g + (1 - g) * t, blue: b + (1 - b) * t)
    }}
}}

/// Renders pre-traced cubic-bezier subpaths (unit coords over the character
/// bounding box) scaled into the given rect. Each component is a single
/// closed contour (no holes).
struct TracedShape: Shape {{
    let subpaths: [[[Double]]]

    func path(in r: CGRect) -> Path {{
        var p = Path()
        for segs in subpaths {{
            guard let first = segs.first else {{ continue }}
            func pt(_ x: Double, _ y: Double) -> CGPoint {{
                CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height)
            }}
            p.move(to: pt(first[0], first[1]))
            for s in segs {{
                p.addCurve(to: pt(s[6], s[7]),
                           control1: pt(s[2], s[3]),
                           control2: pt(s[4], s[5]))
            }}
            p.closeSubpath()
        }}
        return p
    }}
}}

/// Traced path data. Generated — do not hand-edit.
enum SlimeArt {{
{data}
    /// Sleep placeholder: gentle closed lids (thin down-arcs at the eye
    /// positions). Pending an approved sleep expression.
    static let faceSleep: [[[Double]]] = closedLid(cx: 0.3308, cy: 0.4326)
        + closedLid(cx: 0.6681, cy: 0.4326)

    private static func closedLid(cx: Double, cy: Double) -> [[[Double]]] {{
        // a shallow stroked-arc outline, built as a filled shape
        let w = 0.115, t = 0.026, bow = 0.038
        let x0 = cx - w / 2, x1 = cx + w / 2
        return [[
            [x0, cy, cx - w / 6, cy + bow, cx + w / 6, cy + bow, x1, cy],
            [x1, cy, x1, cy + t, x1, cy + t, x1, cy + t],
            [x1, cy + t, cx + w / 6, cy + bow + t, cx - w / 6, cy + bow + t, x0, cy + t],
            [x0, cy + t, x0, cy, x0, cy, x0, cy],
        ]]
    }}
}}
'''

with open(OUT, "w") as f:
    f.write(swift)
print(f"wrote {OUT} ({len(swift.splitlines())} lines)")
