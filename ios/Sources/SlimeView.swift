import SwiftUI
import UIKit

/// The Prepkin slime mascot, drawn in code. All shapes are bezier paths traced
/// programmatically from the approved renders in ~/Desktop/mascot/slime-handoff/
/// (mascot-idle.png + approved-expressions.png), normalized to the character
/// bounding box (aspect 1.1145). Palette from spec.json. The face is
/// always code-drawn — never generated art. Do not hand-edit the path data;
/// re-run the trace scripts in design/slime-trace/ (trace.py → emit_swift.py) instead.
struct SlimeView: View {
    var color: Color = Slime.body
    var level: Int
    /// Which kin to draw. "slime" is the traced production art in `SlimeArt`; every
    /// other id resolves to a silhouette in `KinArt`. Faces are shared — the same
    /// nine approved code-drawn faces, fitted to each head.
    var species: String = "slime"
    var animation: ChibiAnimation
    var size: CGFloat = 130
    /// Optional explicit face; nil derives it from `animation`.
    var expression: SlimeExpression? = nil

    @State private var squish = false

    static func scale(for level: Int) -> CGFloat { [1: 0.78, 2: 0.9, 3: 1.0][level] ?? 0.78 }
    private var scale: CGFloat { Self.scale(for: level) }

    /// Empty space between the bottom of this view's frame and the character's feet.
    /// Home uses it to stand the mascot on the scene's floor rather than above it.
    static func footInset(size: CGFloat, level: Int) -> CGFloat {
        (size * 1.15 - size * scale(for: level) / Slime.aspect) / 2
    }

    @State private var choreoStart: Date? = nil

    private var isChoreographed: Bool {
        switch animation {
        case .dance, .peek, .celebrate, .bounce, .wave, .startle, .slump: return true
        default: return false
        }
    }

    private var face: SlimeExpression {
        if let expression { return expression }
        switch animation {
        case .celebrate, .dance: return .delight
        case .sleep: return .sleep
        case .wave: return .wink
        case .startle: return .surprised
        case .slump: return .sad
        default: return .idle
        }
    }

    var body: some View {
        let w = size * scale                    // character bounding-box width
        let h = w / Slime.aspect                // character bounding-box height
        TimelineView(.animation(paused: !isChoreographed)) { ctx in
            let dance = choreoFrame(at: ctx.date)
            let d = dance.deform
            let faceNow: SlimeExpression = animation == .peek && expression == nil
                ? (dance.face ?? .idle) : face
            ZStack {
                Ellipse()
                    .fill(Slime.ink.opacity(0.10))
                    .frame(width: w * 0.92 * (1 - 0.16 * dance.air), height: h * 0.13)
                    .offset(y: h * 0.47)

                ZStack {
                    character(w: w, h: h, d: d, dance: dance, face: faceNow)
                    blush(w: w, h: h, d: d)
                    if animation == .celebrate || dance.face == .delight {
                        Spark().fill(Theme.coin)
                            .frame(width: w * 0.20, height: w * 0.20)
                            .offset(x: w * 0.52, y: -h * 0.38)
                        Spark().fill(Theme.coin)
                            .frame(width: w * 0.14, height: w * 0.14)
                            .offset(x: -w * 0.56, y: -h * 0.12)
                    }
                    if faceNow == .sleep {
                        SleepZs().stroke(Slime.ink.opacity(0.55),
                                         style: StrokeStyle(lineWidth: w * 0.022,
                                                            lineCap: .round, lineJoin: .round))
                            .frame(width: w * 0.20, height: w * 0.22)
                            .offset(x: w * 0.48, y: -h * 0.40)
                    }
                }
                .rotationEffect(.degrees(dance.tilt), anchor: dance.spinAnchor)
                .scaleEffect(x: isChoreographed ? 1 : (squish ? 1.04 : 0.99),
                             y: isChoreographed ? 1 : (squish ? 0.95 : 1.01),
                             anchor: .bottom)
                .offset(y: dance.hopY * h)
            }
        }
        .frame(width: size * 1.35, height: size * 1.15)
        .onAppear { startIdle() }
        .onChange(of: animation) { _, new in
            switch new {
            case .dance, .peek, .celebrate, .bounce, .wave, .startle, .slump:
                choreoStart = Date()
            default: break
            }
        }
    }

    private var kinArt: KinArt.Species? { KinArt.all[species] }

    /// The kin itself: accent, body, belly, face. Every body-coloured subpath is in one
    /// path per fill, so the bulges read as one silhouette and never as parts.
    @ViewBuilder
    private func character(w: CGFloat, h: CGFloat, d: SlimeDeform,
                           dance: SlimeDance.Frame, face: SlimeExpression) -> some View {
        if let kin = kinArt {
            ZStack {
                if let accent = kin.accent, let rgb = kin.accentRGB {
                    TracedShape(subpaths: accent, deform: d)
                        .fill(Color(red: rgb.0, green: rgb.1, blue: rgb.2))
                        .frame(width: w, height: h)
                }
                TracedShape(subpaths: kin.body, deform: d)
                    .fill(color).frame(width: w, height: h)
                TracedShape(subpaths: kin.belly, deform: d)
                    .fill(Slime.belly(for: color)).frame(width: w, height: h)
                TracedShape(subpaths: face.art, deform: d, fit: kin.faceFit)
                    .fill(Slime.ink).frame(width: w, height: h)
            }
        } else {
            ZStack {
                TracedShape(subpaths: SlimeArt.body, deform: d)
                    .fill(color).frame(width: w, height: h)
                if let armAngle = dance.armAngle {
                    SlimeArm(angleDeg: armAngle, stretch: dance.armStretch)
                        .fill(color).frame(width: w, height: h)
                }
                TracedShape(subpaths: SlimeArt.belly, deform: d)
                    .fill(Slime.belly(for: color)).frame(width: w, height: h)
                TracedShape(subpaths: face.art, deform: d)
                    .fill(Slime.ink).frame(width: w, height: h)
            }
        }
    }

    /// Cheeks ride the face: a smaller head gets smaller cheeks, and a head that sits
    /// lower carries them down with it.
    @ViewBuilder
    private func blush(w: CGFloat, h: CGFloat, d: SlimeDeform) -> some View {
        if level >= 2 {
            let fs = kinArt?.faceScale ?? 1
            let drop = (kinArt?.faceCY ?? KinArt.faceOriginY) - KinArt.faceOriginY
            HStack(spacing: w * 0.50 * fs) {
                Ellipse().fill(Slime.blush).frame(width: w * 0.11 * fs, height: h * 0.045 * fs)
                Ellipse().fill(Slime.blush).frame(width: w * 0.11 * fs, height: h * 0.045 * fs)
            }
            // cheeks sit at y ≈ 0.54 of the bbox; ride the squash
            // (the rigid tilt below carries them sideways)
            .offset(y: h * (0.04 + 0.46 * (1 - d.sy) + drop))
        }
    }

    private func startIdle() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            squish = true
        }
    }

    private func choreoFrame(at date: Date) -> SlimeDance.Frame {
        guard let start = choreoStart else { return SlimeDance.Frame() }
        let t = date.timeIntervalSince(start)
        switch animation {
        case .dance: return SlimeDance.frame(at: t)
        case .peek: return SlimePeek.frame(at: t)
        case .celebrate: return SlimeCelebrate.frame(at: t)
        case .bounce: return SlimeJump.frame(at: t)
        case .wave: return SlimeWave.frame(at: t)
        case .startle: return SlimeStartle.frame(at: t)
        case .slump: return SlimeSlump.frame(at: t)
        default: return SlimeDance.Frame()
        }
    }
}

/// The approved expressions: the original 4 traced faces plus the 5
/// parametric faces approved 2026-08-29 (sleepy/surprised/sad/focused/wink).
enum SlimeExpression {
    case idle, deadpan, judging, delight, sleep, surprised, sad, focused, wink

    var art: [[[Double]]] {
        switch self {
        case .idle: return SlimeArt.faceIdle
        case .deadpan: return SlimeArt.faceDeadpan
        case .judging: return SlimeArt.faceJudging
        case .delight: return SlimeArt.faceDelight
        case .sleep: return SlimeArt.faceSleep
        case .surprised: return SlimeArt.faceSurprised
        case .sad: return SlimeArt.faceSad
        case .focused: return SlimeArt.faceFocused
        case .wink: return SlimeArt.faceWink
        }
    }
}

enum Slime {
    static let body = Color(red: 0x51 / 255, green: 0xCF / 255, blue: 0xA0 / 255)   // #51CFA0
    static let bellyMint = Color(red: 0xB1 / 255, green: 0xED / 255, blue: 0xD4 / 255)  // #B1EDD4
    static let ink = Color(red: 0x10 / 255, green: 0x18 / 255, blue: 0x20 / 255)    // #101820
    static let blush = Color(red: 0xFF / 255, green: 0x9E / 255, blue: 0x94 / 255).opacity(0.7)
    static let aspect: CGFloat = 1.1145

    /// Exact #B1EDD4 for the canonical mint; recolors get the same 57% blend
    /// toward white so ember/droplet/sprout keep the belly relationship.
    static func belly(for bodyColor: Color) -> Color {
        if bodyColor == body { return bellyMint }
        let ui = UIColor(bodyColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let t: CGFloat = 0.57
        return Color(red: r + (1 - r) * t, green: g + (1 - g) * t, blue: b + (1 - b) * t)
    }
}

/// Jelly deformation applied to the unit-space path points, anchored at
/// bottom-center. `sx`/`sy` are squash & stretch. `antennaSway` shifts ONLY
/// the antenna region (top ~15% of the bbox) sideways with a smooth quadratic
/// ramp — the head itself never shears. Body lean is a rigid rotation applied
/// at the view level, not here.
struct SlimeDeform {
    var sx = 1.0, sy = 1.0, antennaSway = 0.0
    /// Positive narrows the base linearly toward y = 1 (cartoon teardrop
    /// stretch on launch — 2D jump-cycle idiom). 0 = straight scaling.
    var taper = 0.0
    /// Pulls the antenna tip down (unit-height at the tip, same quadratic
    /// falloff as the sway). Keep it small and pair it with a sway so the
    /// antenna bends over sideways like a wilting stem — a large droop alone
    /// crushes the nob into the dome.
    var antennaDroop = 0.0
    /// 0…1 retracts the baked-in resting right mitten into the flank — used
    /// while the separate SlimeArm is raised so there aren't two right hands.
    var armTuck = 0.0
    static let neutral = SlimeDeform()

    /// Below this unit-y the sway weight is exactly 0 (head untouched).
    static let antennaBase = 0.15

    func apply(x: Double, y: Double) -> (x: Double, y: Double) {
        var x = x
        if armTuck > 0, x > 0.87, y > 0.48, y < 0.88 {
            let wy = min(1, max(0, 1 - abs(y - 0.68) / 0.20) * 3)
            x -= (x - 0.87) * armTuck * wy
        }
        var nx = 0.5 + (x - 0.5) * sx * (1 - taper * y)
        var ny = 1 - (1 - y) * sy
        if y < Self.antennaBase {
            let wgt = (Self.antennaBase - y) / Self.antennaBase
            nx += antennaSway * wgt * wgt
            ny += antennaDroop * wgt * wgt
        }
        return (nx, ny)
    }
}

/// Dance choreography, TFT-emote style: four alternating tilt-hops.
/// Each beat = anticipation crouch → launch stretch → ballistic arc while the
/// whole body rigidly tilts into the hop → hard landing squash → rebound.
/// The antenna is the only follow-through part: it lags the tilt and whips
/// past it, and wobbles out during the final settle.
/// Pure functions of time, so the app and the offline render harness produce
/// identical frames. Timing: 4 hops × 0.62s + 0.5s settle = 2.98s
/// (must match ChibiAnimation.dance.duration).
enum SlimeDance {
    struct Frame {
        var deform = SlimeDeform.neutral
        var tilt = 0.0   // rigid body lean in degrees, about the base center
        var air = 0.0    // 0 on the ground, 1 near hop apex (drives the shadow)
        var hopY = 0.0   // vertical offset in units of body height
        var face: SlimeExpression? = nil   // frame-driven face; nil = animation default
        var spinAnchor: UnitPoint = .bottom   // .center for airborne flips
        /// When set, the separate right arm is drawn at this angle (degrees
        /// from vertical, positive = away from the body; SlimeArm.restDeg is
        /// the resting pose). Whenever this is set, deform.armTuck must be 1
        /// so the baked-in mitten never shows alongside it.
        var armAngle: Double? = nil
        /// Radial stretch of the raised arm about its pivot (1 = mitten size).
        var armStretch = 1.0
    }

    static let duration = 2.98
    private static let cycle = 0.62
    private static let settleStart = 2.48

    // Keyframes over one hop cycle (u in 0...1), smoothstep-interpolated.
    private static let syKeys: [(Double, Double)] = [
        (0.00, 1.00), (0.14, 0.83), (0.24, 1.14), (0.40, 1.06),
        (0.58, 1.03), (0.70, 1.06), (0.76, 0.78), (0.87, 1.07), (1.00, 1.00),
    ]
    private static let tiltKeys: [(Double, Double)] = [
        (0.00, 0), (0.14, -2.5), (0.30, 4.5), (0.50, 8.5),
        (0.68, 6.0), (0.82, 1.5), (1.00, 0),
    ]
    // ballistic flight window inside a cycle
    private static let liftoff = 0.20, touchdown = 0.72, hopHeight = 0.24

    static func frame(at t: Double) -> Frame {
        guard t >= 0, t < duration else { return Frame() }
        var f = Frame()
        if t < settleStart {
            let i = Int(t / cycle)
            let u = t / cycle - Double(i)
            let dir: Double = i % 2 == 0 ? 1 : -1        // alternate hop direction
            f.deform.sy = track(syKeys, u)
            f.tilt = dir * track(tiltKeys, u)
            if u > liftoff && u < touchdown {            // true parabola in the air
                let v = (u - liftoff) / (touchdown - liftoff)
                f.hopY = -hopHeight * 4 * v * (1 - v)
            }
            // follow-through: the antenna lags the tilt and catches up late
            f.deform.antennaSway = min(0.12, max(-0.12, (tilt(at: t - 0.08) - f.tilt) * 0.012))
        } else {
            // damped jelly wobble back to rest after the last landing
            let s = t - settleStart
            f.deform.sy = 1 + 0.07 * exp(-7 * s) * sin(2 * .pi * 4.2 * s)
            f.deform.antennaSway = 0.09 * exp(-5 * s) * sin(2 * .pi * 4.8 * s)
        }
        f.deform.sx = 1 / f.deform.sy.squareRoot()       // preserve volume
        f.air = min(1, -f.hopY / hopHeight)
        return f
    }

    private static func tilt(at t: Double) -> Double {
        guard t >= 0, t < settleStart else { return 0 }
        let i = Int(t / cycle)
        let u = t / cycle - Double(i)
        let dir: Double = i % 2 == 0 ? 1 : -1
        return dir * track(tiltKeys, u)
    }

    fileprivate static func track(_ keys: [(Double, Double)], _ u: Double) -> Double {
        if u <= keys[0].0 { return keys[0].1 }
        for k in 1..<keys.count where u <= keys[k].0 {
            let (t0, v0) = keys[k - 1]
            let (t1, v1) = keys[k]
            let s = (u - t0) / (t1 - t0)
            return v0 + (v1 - v0) * s * s * (3 - 2 * s)
        }
        return keys.last?.1 ?? 0
    }
}

/// Peek-a-boo choreography, adapted from the TFT sprite tacticians'
/// hide-under-the-cap emote (Mush Sprite showcase, 46–56s): anticipation
/// stretch → crouch down with the judging (peeking) face → playful rock with
/// the antenna lagging → pop back up (delight face + sparkles) → jelly settle.
/// The crouch is a shallow squash, not a pancake — the face must stay readable.
/// Pure function of time, like SlimeDance. Timing: 0.30s duck + 1.12s wiggle
/// + 0.18s pop + 0.80s settle = 2.40s (must match ChibiAnimation.peek.duration).
enum SlimePeek {
    static let duration = 2.40
    private static let duckEnd = 0.30, popStart = 1.42, popEnd = 1.60
    private static let hideSy = 0.72     // crouch depth (face still readable)
    private static let overshoot = 1.15

    static func frame(at t: Double) -> SlimeDance.Frame {
        guard t >= 0, t < duration else { return SlimeDance.Frame() }
        var f = SlimeDance.Frame()
        switch t {
        case ..<duckEnd:
            // stretch up first, then drop into the crouch
            f.deform.sy = SlimeDance.track([(0.00, 1.0), (0.12, 1.09), (0.30, hideSy)], t)
        case ..<popStart:
            // crouched, peeking with the judging face; quick playful rock that
            // ramps in after the duck and dies out before the pop
            let s = t - duckEnd
            f.deform.sy = hideSy + 0.015 * sin(2 * .pi * 1.1 * s)
            f.tilt = wiggleTilt(s)
            // follow-through: the antenna lags the rock and whips past it,
            // same velocity-lag rule as the dance
            f.deform.antennaSway = min(0.12, max(-0.12, (wiggleTilt(s - 0.08) - wiggleTilt(s)) * 0.014))
            f.face = .judging
        case ..<popEnd:
            // spring up with a modest overshoot and a tiny hop
            let v = (t - popStart) / (popEnd - popStart)
            f.deform.sy = hideSy + (overshoot - hideSy) * v * v * (3 - 2 * v)
            f.hopY = -0.08 * 4 * v * (1 - v)
            f.face = .delight
        default:
            // damped jelly settle continuing from the overshoot
            let s = t - popEnd
            f.deform.sy = 1 + (overshoot - 1) * exp(-6 * s) * sin(2 * .pi * 3.6 * s + .pi / 2)
            f.deform.antennaSway = 0.08 * exp(-5 * s) * sin(2 * .pi * 4.4 * s)
            f.face = .delight
        }
        // volume-ish preserve, but cap the width gain so the crouch never
        // reads as a pancake
        f.deform.sx = min(1.11, 1 / f.deform.sy.squareRoot())
        f.air = min(1, -f.hopY / 0.08)
        return f
    }

    /// The crouched rock, as its own function of wiggle-time so the antenna
    /// follow-through can sample it at a lag. 0 outside the wiggle window.
    private static func wiggleTilt(_ s: Double) -> Double {
        guard s > 0 else { return 0 }
        let env = min(1, s * 5) * max(0, min(1, (popStart - duckEnd - s) / 0.22))
        return 7.0 * env * sin(2 * .pi * 1.7 * s)
    }
}

/// Celebrate choreography, adapted from the TFT sprite tacticians' joy-roll
/// (Mush Sprite showcase, 3–7s): crouch → launch → one full airborne 360°
/// backflip spinning about the body center (compact, no sideways sweep) →
/// landing squash → jelly settle. Delight face + sparkles come from the
/// .celebrate defaults. Pure function of time, like SlimeDance.
/// Timing: 0.16 crouch + 0.18 launch + 0.78 flip + 0.20 land + 0.58 settle
/// = 1.90s (must match ChibiAnimation.celebrate.duration).
enum SlimeCelebrate {
    static let duration = 1.90
    private static let launchStart = 0.16, rollStart = 0.34
    private static let rollEnd = 1.12, landEnd = 1.32

    static func frame(at t: Double) -> SlimeDance.Frame {
        guard t >= 0, t < duration else { return SlimeDance.Frame() }
        var f = SlimeDance.Frame()
        switch t {
        case ..<rollStart:
            // anticipation crouch, then launch stretch
            f.deform.sy = SlimeDance.track(
                [(0.00, 1.0), (launchStart, 0.80), (rollStart, 1.14)], t)
        case ..<rollEnd:
            // airborne backflip: ballistic arc + one eased 360° about center
            let v = (t - rollStart) / (rollEnd - rollStart)
            f.tilt = 360 * v * v * (3 - 2 * v)
            f.spinAnchor = .center
            f.hopY = -0.55 * 4 * v * (1 - v)
            f.deform.sy = 1.04
        case ..<landEnd:
            // hard landing squash and release
            f.deform.sy = SlimeDance.track(
                [(rollEnd, 1.04), (1.20, 0.78), (landEnd, 1.08)], t)
        default:
            // damped jelly settle with antenna follow-through
            let s = t - landEnd
            f.deform.sy = 1 + 0.08 * exp(-6 * s) * sin(2 * .pi * 4.0 * s + .pi / 2)
            f.deform.antennaSway = 0.09 * exp(-5 * s) * sin(2 * .pi * 4.6 * s)
        }
        f.deform.sx = 1 / f.deform.sy.squareRoot()       // preserve volume
        f.air = min(1, -f.hopY / 0.5)
        return f
    }
}

/// Bounce choreography, keyframed from a 2D cartoon slime jump cycle
/// (pancake anticipation → teardrop launch with the base tapering into a
/// tail → round at the apex → flatten on descent → wide splat landing →
/// jelly rebound). One hop, then back to idle. Pure function of time.
/// Timing: 0.14 crouch + 0.12 launch + 0.36 air + 0.18 land + 0.60 settle
/// = 1.40s (must match ChibiAnimation.bounce.duration).
enum SlimeJump {
    static let duration = 1.40
    private static let launchStart = 0.14, liftoff = 0.26
    private static let touchdown = 0.62, splatEnd = 0.80
    private static let hopHeight = 0.55

    static func frame(at t: Double) -> SlimeDance.Frame {
        guard t >= 0, t < duration else { return SlimeDance.Frame() }
        var f = SlimeDance.Frame()
        switch t {
        case ..<liftoff:
            // pancake anticipation, then gather into the launch stretch
            f.deform.sy = SlimeDance.track(
                [(0.00, 1.0), (launchStart, 0.72), (liftoff, 1.32)], t)
            f.deform.taper = SlimeDance.track(
                [(launchStart, 0.0), (liftoff, 0.28)], t)
        case ..<touchdown:
            // ballistic arc: teardrop relaxes to round by the apex, then
            // flattens slightly before contact
            let v = (t - liftoff) / (touchdown - liftoff)
            f.hopY = -hopHeight * 4 * v * (1 - v)
            f.deform.sy = SlimeDance.track(
                [(0.0, 1.32), (0.45, 0.98), (0.80, 0.95), (1.0, 0.86)], v)
            f.deform.taper = SlimeDance.track([(0.0, 0.28), (0.5, 0.0)], v)
        case ..<splatEnd:
            // wide splat on contact, then release
            f.deform.sy = SlimeDance.track(
                [(touchdown, 0.86), (0.70, 0.60), (splatEnd, 1.10)], t)
        default:
            // damped jelly rebound with antenna follow-through
            let s = t - splatEnd
            f.deform.sy = 1 + 0.10 * exp(-6 * s) * sin(2 * .pi * 4.0 * s + .pi / 2)
            f.deform.antennaSway = 0.09 * exp(-5 * s) * sin(2 * .pi * 4.6 * s)
        }
        f.deform.sx = min(1.28, 1 / f.deform.sy.squareRoot())  // cap the splat width
        f.air = min(1, -f.hopY / hopHeight)
        return f
    }
}

/// The separate right arm: the EXACT traced resting-mitten outline (copied
/// from SlimeArt.body), rotated about its base and drawn in the body color.
/// At angleDeg == restDeg it overlays the baked-in mitten pixel-for-pixel,
/// so tucking the baked-in one and drawing this is seamless at rest —
/// there is never a second hand. Plain mitten — no thumb.
struct SlimeArm: Shape {
    var angleDeg: Double     // degrees from vertical, positive = outward
    var stretch: Double      // radial scale about the pivot; 1 = mitten size
    /// The angle the traced mitten hangs at.
    static let restDeg = 138.0
    private static let pivot = (x: 0.909, y: 0.657)
    /// Resting-mitten outline, lifted verbatim from the SlimeArt.body trace,
    /// closed across the base (which stays hidden inside the body).
    private static let flipper: [[Double]] = [
        [0.9122, 0.5542, 0.9195, 0.5613, 0.9265, 0.5691, 0.9330, 0.5771],
        [0.9330, 0.5771, 0.9679, 0.6198, 0.9989, 0.6771, 0.9989, 0.7365],
        [0.9989, 0.7365, 0.9989, 0.7513, 0.9986, 0.7653, 0.9927, 0.7790],
        [0.9927, 0.7790, 0.9806, 0.8073, 0.9492, 0.8154, 0.9271, 0.7959],
        [0.9271, 0.7959, 0.9170, 0.7871, 0.9107, 0.7728, 0.9058, 0.7600],
        [0.9058, 0.7600, 0.9070, 0.6914, 0.9101, 0.6228, 0.9122, 0.5542],
    ]

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(angleDeg, stretch) }
        set { angleDeg = newValue.first; stretch = newValue.second }
    }

    func path(in r: CGRect) -> Path {
        // rotate in a square space so angles stay true despite the bbox aspect
        let alpha = (Self.restDeg - angleDeg) * .pi / 180    // lift = CCW
        let ca = cos(alpha), sa = sin(alpha)
        let aspect = 1.1145   // Slime.aspect; literal keeps this file-local
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            let ax = (x - Self.pivot.x) * aspect
            let ay = y - Self.pivot.y
            let rx = (ca * ax + sa * ay) * stretch
            let ry = (-sa * ax + ca * ay) * stretch
            let px: Double = r.minX + (Self.pivot.x + rx / aspect) * r.width
            let py: Double = r.minY + (Self.pivot.y + ry) * r.height
            return CGPoint(x: px, y: py)
        }
        var p = Path()
        p.move(to: pt(Self.flipper[0][0], Self.flipper[0][1]))
        for s in Self.flipper {
            p.addCurve(to: pt(s[6], s[7]), control1: pt(s[2], s[3]), control2: pt(s[4], s[5]))
        }
        p.closeSubpath()
        return p
    }
}

/// Wave choreography v3, keyframed from the approved Flow reference clip
/// (Green_slime_character_waving_hello_202608300339.mp4): the arm sweeps up
/// beside the head, waves side to side 2½ times like a wiper about the
/// shoulder, then lowers. The body barely moves — a perk-up and a slight
/// lean, wink face (from the .wave default) the whole way.
/// Timing: 0.30 raise + 0.95 wave + 0.35 lower = 1.60s
/// (must match ChibiAnimation.wave.duration).
enum SlimeWave {
    static let duration = 1.60
    private static let raiseEnd = 0.30, waveEnd = 1.25
    private static let upAngle = 22.0   // degrees from vertical when waving

    /// NOTE: the arm-wave version of this one-shot is moving to the Rive rig
    /// (hybrid plan, 2026-08-30). Until the .riv ships, wave is a simple
    /// perk-and-bob so nothing broken reaches the app. SlimeArm and the
    /// armTuck deform stay for the transition period.
    static func frame(at t: Double) -> SlimeDance.Frame {
        guard t >= 0, t < duration else { return SlimeDance.Frame() }
        var f = SlimeDance.Frame()
        switch t {
        case ..<raiseEnd:
            let v = t / raiseEnd
            let eased = v * v * (3 - 2 * v)
            f.deform.sy = 1 + 0.05 * eased
            f.tilt = 2.0 * eased
        case ..<waveEnd:
            let s = t - raiseEnd
            let env = max(0, min(1, (waveEnd - raiseEnd - s) / 0.12))
            f.deform.sy = 1.05 - 0.03 * env * (1 - cos(2 * .pi * 2.2 * s)) / 2
            f.deform.antennaSway = 0.05 * env * sin(2 * .pi * 2.2 * s)
            f.tilt = 2.0
        default:
            let v = (t - waveEnd) / (duration - waveEnd)
            let eased = v * v * (3 - 2 * v)
            f.deform.sy = 1.05 - 0.05 * eased
            f.tilt = 2.0 * (1 - eased)
        }
        f.deform.sx = 1 / f.deform.sy.squareRoot()
        return f
    }
}

/// Startle choreography — "whoa!". A sharp upward stretch with a tiny hop,
/// a short trembling hold, then a quick settle. Surprised face from the
/// .startle default. Timing: 0.10 pop + 0.45 tremble + 0.45 settle = 1.00s
/// (must match ChibiAnimation.startle.duration).
enum SlimeStartle {
    static let duration = 1.00
    private static let popEnd = 0.10, holdEnd = 0.55

    static func frame(at t: Double) -> SlimeDance.Frame {
        guard t >= 0, t < duration else { return SlimeDance.Frame() }
        var f = SlimeDance.Frame()
        switch t {
        case ..<popEnd:
            let v = t / popEnd
            f.deform.sy = 1 + 0.20 * v
            f.hopY = -0.12 * v
        case ..<holdEnd:
            // stretched, quivering
            let s = t - popEnd
            f.deform.sy = 1.14 + 0.025 * exp(-3 * s) * sin(2 * .pi * 9 * s)
            f.hopY = -0.12 * max(0, 1 - s / 0.18)
        default:
            let s = t - holdEnd
            f.deform.sy = 1 + 0.14 * exp(-7 * s) * cos(2 * .pi * 3.0 * s)
        }
        f.deform.sx = 1 / f.deform.sy.squareRoot()
        f.air = min(1, -f.hopY / 0.12)
        return f
    }
}

/// Slump choreography v4 — the overdue-homework sigh. A double sag into a
/// slight melt, the antenna WILTING OVER SIDEWAYS like a stem (sway-led bend
/// with only a touch of droop — never crushed into the dome), two heavy
/// breaths, then a slow straighten-up with the antenna springing back last.
/// Sad face from the .slump default. Timing: 0.55 sag + 1.15 heavy hold +
/// 0.70 rise = 2.40s (must match ChibiAnimation.slump.duration).
enum SlimeSlump {
    static let duration = 2.40
    private static let sinkEnd = 0.55, sighEnd = 1.70
    private static let slumpSy = 0.82, melt = -0.10, lean = -3.0
    private static let wiltSway = -0.17, wiltDroop = 0.05

    static func frame(at t: Double) -> SlimeDance.Frame {
        guard t >= 0, t < duration else { return SlimeDance.Frame() }
        var f = SlimeDance.Frame()
        switch t {
        case ..<sinkEnd:
            // first give → beat → the real sag; the antenna wilts over
            f.deform.sy = SlimeDance.track(
                [(0.00, 1.0), (0.15, 0.90), (0.28, 0.92), (0.48, 0.79), (sinkEnd, slumpSy)], t)
            let v = min(1, t / sinkEnd)
            f.deform.taper = melt * v * v
            f.tilt = lean * v * v
            f.deform.antennaSway = wiltSway * v * v
            f.deform.antennaDroop = wiltDroop * v * v
        case ..<sighEnd:
            // sagging: two slow heavy breaths, antenna hanging over
            let s = t - sinkEnd
            f.deform.sy = slumpSy + 0.028 * (1 - cos(2 * .pi * s / 0.57)) / 2
            f.deform.taper = melt
            f.tilt = lean
            f.deform.antennaSway = wiltSway + 0.012 * sin(2 * .pi * s / 0.57)
            f.deform.antennaDroop = wiltDroop
        default:
            // straighten up; the antenna springs back last with a tiny
            // overshoot past upright
            let v = (t - sighEnd) / (duration - sighEnd)
            let eased = v * v * (3 - 2 * v)
            f.deform.sy = slumpSy + (1 - slumpSy) * eased
            f.deform.taper = melt * (1 - eased)
            f.tilt = lean * (1 - eased)
            let spring = 1 - eased * eased
            f.deform.antennaSway = wiltSway * spring + 0.05 * eased * sin(2 * .pi * 2.2 * v)
            f.deform.antennaDroop = wiltDroop * spring
        }
        f.deform.sx = 1 / f.deform.sy.squareRoot()
        return f
    }
}

/// Renders pre-traced cubic-bezier subpaths (unit coords over the character
/// bounding box) scaled into the given rect. Each component is a single
/// closed contour (no holes).
/// Where a borrowed face sits on a head that is not the slime's: scale about the
/// face's own centre, then move to that species' face position. Applied before the
/// jelly deform, so a face squashes with the body it is on.
struct KinFaceFit {
    var scale: Double = 1
    var cx: Double = KinArt.faceOriginX
    var cy: Double = KinArt.faceOriginY

    static let identity = KinFaceFit()
    var isIdentity: Bool { scale == 1 && cx == KinArt.faceOriginX && cy == KinArt.faceOriginY }

    func apply(_ x: Double, _ y: Double) -> (x: Double, y: Double) {
        (cx + scale * (x - KinArt.faceOriginX), cy + scale * (y - KinArt.faceOriginY))
    }
}

struct TracedShape: Shape {
    let subpaths: [[[Double]]]
    var deform: SlimeDeform = .neutral
    var fit: KinFaceFit = .identity

    func path(in r: CGRect) -> Path {
        var p = Path()
        for segs in subpaths {
            guard let first = segs.first else { continue }
            func pt(_ x0: Double, _ y0: Double) -> CGPoint {
                let f = fit.isIdentity ? (x: x0, y: y0) : fit.apply(x0, y0)
                let d = deform.apply(x: f.x, y: f.y)
                return CGPoint(x: r.minX + d.x * r.width, y: r.minY + d.y * r.height)
            }
            p.move(to: pt(first[0], first[1]))
            for s in segs {
                p.addCurve(to: pt(s[6], s[7]),
                           control1: pt(s[2], s[3]),
                           control2: pt(s[4], s[5]))
            }
            p.closeSubpath()
        }
        return p
    }
}

/// Traced path data. Generated — do not hand-edit.
enum SlimeArt {
    static let body: [[[Double]]] = [
        [
            [0.5974, 0.0001, 0.6072, 0.0009, 0.6169, 0.0031, 0.6244, 0.0108],
            [0.6244, 0.0108, 0.6383, 0.0253, 0.6352, 0.0511, 0.6202, 0.0628],
            [0.6202, 0.0628, 0.6032, 0.0760, 0.5845, 0.0641, 0.5686, 0.0740],
            [0.5686, 0.0740, 0.5611, 0.0786, 0.5569, 0.0892, 0.5656, 0.0953],
            [0.5656, 0.0953, 0.5732, 0.1006, 0.5854, 0.1007, 0.5939, 0.1032],
            [0.5939, 0.1032, 0.6126, 0.1088, 0.6316, 0.1156, 0.6490, 0.1249],
            [0.6490, 0.1249, 0.7301, 0.1682, 0.7891, 0.2330, 0.8316, 0.3210],
            [0.8316, 0.3210, 0.8530, 0.3653, 0.8676, 0.4149, 0.8776, 0.4638],
            [0.8776, 0.4638, 0.8803, 0.4775, 0.8856, 0.5243, 0.8902, 0.5329],
            [0.8902, 0.5329, 0.8946, 0.5415, 0.9055, 0.5478, 0.9122, 0.5542],
            [0.9122, 0.5542, 0.9195, 0.5613, 0.9265, 0.5691, 0.9330, 0.5771],
            [0.9330, 0.5771, 0.9679, 0.6198, 0.9989, 0.6771, 0.9989, 0.7365],
            [0.9989, 0.7365, 0.9989, 0.7513, 0.9986, 0.7653, 0.9927, 0.7790],
            [0.9927, 0.7790, 0.9806, 0.8073, 0.9492, 0.8154, 0.9271, 0.7959],
            [0.9271, 0.7959, 0.9170, 0.7871, 0.9107, 0.7728, 0.9058, 0.7600],
            [0.9058, 0.7600, 0.9047, 0.7572, 0.9021, 0.7467, 0.8991, 0.7457],
            [0.8991, 0.7457, 0.8977, 0.7452, 0.8962, 0.7466, 0.8953, 0.7478],
            [0.8953, 0.7478, 0.8916, 0.7535, 0.8922, 0.7678, 0.8914, 0.7746],
            [0.8914, 0.7746, 0.8895, 0.7889, 0.8828, 0.8029, 0.8894, 0.8169],
            [0.8894, 0.8169, 0.8932, 0.8249, 0.8997, 0.8310, 0.9049, 0.8378],
            [0.9049, 0.8378, 0.9168, 0.8534, 0.9270, 0.8773, 0.9191, 0.8978],
            [0.9191, 0.8978, 0.9066, 0.9302, 0.8561, 0.9460, 0.8281, 0.9548],
            [0.8281, 0.9548, 0.7384, 0.9832, 0.6370, 0.9965, 0.5440, 0.9987],
            [0.5440, 0.9987, 0.4367, 1.0013, 0.3294, 0.9932, 0.2242, 0.9693],
            [0.2242, 0.9693, 0.1850, 0.9604, 0.1279, 0.9470, 0.0962, 0.9194],
            [0.0962, 0.9194, 0.0911, 0.9149, 0.0864, 0.9097, 0.0828, 0.9037],
            [0.0828, 0.9037, 0.0703, 0.8828, 0.0802, 0.8564, 0.0931, 0.8389],
            [0.0931, 0.8389, 0.1003, 0.8292, 0.1099, 0.8209, 0.1121, 0.8079],
            [0.1121, 0.8079, 0.1143, 0.7948, 0.1076, 0.7737, 0.1058, 0.7598],
            [0.1058, 0.7598, 0.1055, 0.7572, 0.1053, 0.7456, 0.1017, 0.7449],
            [0.1017, 0.7449, 0.0984, 0.7443, 0.0880, 0.7725, 0.0855, 0.7773],
            [0.0855, 0.7773, 0.0670, 0.8123, 0.0267, 0.8194, 0.0072, 0.7810],
            [0.0072, 0.7810, 0.0007, 0.7681, -0.0000, 0.7532, -0.0000, 0.7388],
            [-0.0000, 0.7388, 0.0000, 0.6773, 0.0313, 0.6186, 0.0679, 0.5748],
            [0.0679, 0.5748, 0.0758, 0.5652, 0.1074, 0.5380, 0.1102, 0.5303],
            [0.1102, 0.5303, 0.1146, 0.5183, 0.1155, 0.4958, 0.1180, 0.4822],
            [0.1180, 0.4822, 0.1238, 0.4502, 0.1317, 0.4188, 0.1413, 0.3880],
            [0.1413, 0.3880, 0.1778, 0.2712, 0.2543, 0.1706, 0.3570, 0.1214],
            [0.3570, 0.1214, 0.3868, 0.1072, 0.4188, 0.0981, 0.4509, 0.0935],
            [0.4509, 0.0935, 0.4698, 0.0908, 0.4907, 0.0928, 0.5086, 0.0848],
            [0.5086, 0.0848, 0.5491, 0.0666, 0.5407, 0.0056, 0.5974, 0.0001],
        ],
    ]
    static let belly: [[[Double]]] = [
        [
            [0.4982, 0.6855, 0.5594, 0.6856, 0.6353, 0.7140, 0.6562, 0.7852],
            [0.6562, 0.7852, 0.6614, 0.8029, 0.6620, 0.8228, 0.6558, 0.8404],
            [0.6558, 0.8404, 0.6362, 0.8957, 0.5562, 0.9117, 0.5092, 0.9119],
            [0.5092, 0.9119, 0.4636, 0.9122, 0.3916, 0.9051, 0.3585, 0.8660],
            [0.3585, 0.8660, 0.3285, 0.8307, 0.3359, 0.7769, 0.3646, 0.7434],
            [0.3646, 0.7434, 0.3989, 0.7034, 0.4496, 0.6862, 0.4982, 0.6855],
        ],
    ]
    static let faceIdle: [[[Double]]] = [
        [
            [0.3317, 0.3535, 0.3414, 0.3535, 0.3517, 0.3561, 0.3604, 0.3609],
            [0.3604, 0.3609, 0.4170, 0.3919, 0.4154, 0.4804, 0.3560, 0.5064],
            [0.3560, 0.5064, 0.3482, 0.5098, 0.3384, 0.5123, 0.3299, 0.5119],
            [0.3299, 0.5119, 0.2534, 0.5090, 0.2330, 0.3954, 0.3028, 0.3599],
            [0.3028, 0.3599, 0.3118, 0.3554, 0.3219, 0.3535, 0.3317, 0.3535],
        ],
        [
            [0.4500, 0.4390, 0.4594, 0.4390, 0.4647, 0.4477, 0.4718, 0.4536],
            [0.4718, 0.4536, 0.4811, 0.4614, 0.4920, 0.4660, 0.5037, 0.4654],
            [0.5037, 0.4654, 0.5160, 0.4647, 0.5267, 0.4557, 0.5355, 0.4471],
            [0.5355, 0.4471, 0.5381, 0.4446, 0.5403, 0.4417, 0.5434, 0.4400],
            [0.5434, 0.4400, 0.5562, 0.4330, 0.5599, 0.4501, 0.5586, 0.4604],
            [0.5586, 0.4604, 0.5576, 0.4688, 0.5442, 0.4801, 0.5381, 0.4845],
            [0.5381, 0.4845, 0.5110, 0.5036, 0.4758, 0.4992, 0.4515, 0.4765],
            [0.4515, 0.4765, 0.4472, 0.4726, 0.4423, 0.4664, 0.4407, 0.4604],
            [0.4407, 0.4604, 0.4386, 0.4527, 0.4417, 0.4394, 0.4500, 0.4390],
        ],
        [
            [0.6692, 0.3535, 0.6789, 0.3535, 0.6891, 0.3561, 0.6979, 0.3609],
            [0.6979, 0.3609, 0.7551, 0.3922, 0.7519, 0.4848, 0.6903, 0.5075],
            [0.6903, 0.5075, 0.6831, 0.5102, 0.6746, 0.5124, 0.6670, 0.5119],
            [0.6670, 0.5119, 0.6551, 0.5113, 0.6433, 0.5077, 0.6329, 0.5014],
            [0.6329, 0.5014, 0.6206, 0.4940, 0.6110, 0.4819, 0.6048, 0.4681],
            [0.6048, 0.4681, 0.5808, 0.4147, 0.6161, 0.3535, 0.6692, 0.3535],
        ],
    ]
    static let faceDeadpan: [[[Double]]] = [
        [
            [0.3298, 0.3815, 0.3945, 0.3816, 0.3912, 0.4869, 0.3311, 0.4892],
            [0.3311, 0.4892, 0.2675, 0.4916, 0.2640, 0.3816, 0.3298, 0.3815],
        ],
        [
            [0.4875, 0.4492, 0.5013, 0.4492, 0.5347, 0.4484, 0.5462, 0.4543],
            [0.5462, 0.4543, 0.5544, 0.4586, 0.5591, 0.4715, 0.5497, 0.4783],
            [0.5497, 0.4783, 0.5456, 0.4814, 0.5350, 0.4828, 0.5300, 0.4830],
            [0.5300, 0.4830, 0.5143, 0.4838, 0.4592, 0.4866, 0.4476, 0.4785],
            [0.4476, 0.4785, 0.4445, 0.4763, 0.4426, 0.4710, 0.4423, 0.4671],
            [0.4423, 0.4671, 0.4413, 0.4501, 0.4771, 0.4492, 0.4875, 0.4492],
        ],
        [
            [0.6668, 0.3815, 0.7328, 0.3816, 0.7304, 0.4901, 0.6668, 0.4892],
            [0.6668, 0.4892, 0.6602, 0.4891, 0.6533, 0.4861, 0.6475, 0.4829],
            [0.6475, 0.4829, 0.6019, 0.4580, 0.6153, 0.3816, 0.6668, 0.3815],
        ],
    ]
    static let faceJudging: [[[Double]]] = [
        [
            [0.2760, 0.3815, 0.3050, 0.3815, 0.3340, 0.3815, 0.3629, 0.3815],
            [0.3629, 0.3815, 0.3689, 0.3815, 0.3920, 0.3794, 0.3960, 0.3826],
            [0.3960, 0.3826, 0.4029, 0.3882, 0.3982, 0.4028, 0.3978, 0.4098],
            [0.3978, 0.4098, 0.3959, 0.4486, 0.3625, 0.4720, 0.3312, 0.4756],
            [0.3312, 0.4756, 0.3278, 0.4760, 0.3245, 0.4742, 0.3211, 0.4740],
            [0.3211, 0.4740, 0.2963, 0.4719, 0.2764, 0.4545, 0.2656, 0.4300],
            [0.2656, 0.4300, 0.2624, 0.4228, 0.2554, 0.3890, 0.2609, 0.3829],
            [0.2609, 0.3829, 0.2637, 0.3798, 0.2724, 0.3815, 0.2760, 0.3815],
        ],
        [
            [0.4950, 0.4492, 0.5075, 0.4492, 0.5335, 0.4498, 0.5436, 0.4584],
            [0.5436, 0.4584, 0.5544, 0.4676, 0.5491, 0.4877, 0.5354, 0.4889],
            [0.5354, 0.4889, 0.5251, 0.4898, 0.5075, 0.4823, 0.4974, 0.4834],
            [0.4974, 0.4834, 0.4876, 0.4845, 0.4648, 0.4917, 0.4564, 0.4871],
            [0.4564, 0.4871, 0.4515, 0.4844, 0.4484, 0.4791, 0.4477, 0.4730],
            [0.4477, 0.4730, 0.4456, 0.4519, 0.4820, 0.4492, 0.4950, 0.4492],
        ],
        [
            [0.6158, 0.3815, 0.6448, 0.3815, 0.6737, 0.3815, 0.7027, 0.3815],
            [0.7027, 0.3815, 0.7086, 0.3815, 0.7319, 0.3794, 0.7358, 0.3826],
            [0.7358, 0.3826, 0.7408, 0.3867, 0.7361, 0.4125, 0.7350, 0.4187],
            [0.7350, 0.4187, 0.7289, 0.4518, 0.6966, 0.4771, 0.6667, 0.4756],
            [0.6667, 0.4756, 0.6411, 0.4743, 0.6163, 0.4586, 0.6050, 0.4323],
            [0.6050, 0.4323, 0.6010, 0.4231, 0.5932, 0.3910, 0.6007, 0.3829],
            [0.6007, 0.3829, 0.6036, 0.3798, 0.6122, 0.3815, 0.6158, 0.3815],
        ],
    ]
    static let faceDelight: [[[Double]]] = [
        [
            [0.3290, 0.3538, 0.3570, 0.3539, 0.3797, 0.3704, 0.3921, 0.3980],
            [0.3921, 0.3980, 0.3984, 0.4121, 0.4057, 0.4462, 0.3825, 0.4461],
            [0.3825, 0.4461, 0.3665, 0.4460, 0.3677, 0.4277, 0.3627, 0.4160],
            [0.3627, 0.4160, 0.3562, 0.4006, 0.3416, 0.3901, 0.3264, 0.3908],
            [0.3264, 0.3908, 0.3114, 0.3915, 0.2982, 0.4065, 0.2938, 0.4217],
            [0.2938, 0.4217, 0.2923, 0.4268, 0.2930, 0.4320, 0.2906, 0.4369],
            [0.2906, 0.4369, 0.2865, 0.4456, 0.2762, 0.4482, 0.2685, 0.4440],
            [0.2685, 0.4440, 0.2548, 0.4365, 0.2601, 0.4166, 0.2639, 0.4043],
            [0.2639, 0.4043, 0.2734, 0.3737, 0.3002, 0.3538, 0.3290, 0.3538],
        ],
        [
            [0.5670, 0.4900, 0.6050, 0.4995, 0.6055, 0.5358, 0.5905, 0.5692],
            [0.5905, 0.5692, 0.5755, 0.6027, 0.5419, 0.6247, 0.5087, 0.6276],
            [0.5087, 0.6276, 0.4677, 0.6312, 0.4249, 0.6095, 0.4061, 0.5677],
            [0.4061, 0.5677, 0.3979, 0.5494, 0.3906, 0.5152, 0.4084, 0.5000],
            [0.4084, 0.5000, 0.4310, 0.4807, 0.4599, 0.4984, 0.4849, 0.5014],
            [0.4849, 0.5014, 0.5133, 0.5047, 0.5393, 0.4931, 0.5670, 0.4900],
        ],
        [
            [0.6688, 0.3538, 0.6959, 0.3539, 0.7233, 0.3727, 0.7326, 0.4019],
            [0.7326, 0.4019, 0.7367, 0.4148, 0.7433, 0.4365, 0.7283, 0.4442],
            [0.7283, 0.4442, 0.6972, 0.4602, 0.7115, 0.3923, 0.6703, 0.3908],
            [0.6703, 0.3908, 0.6553, 0.3903, 0.6405, 0.4011, 0.6343, 0.4165],
            [0.6343, 0.4165, 0.6295, 0.4285, 0.6303, 0.4463, 0.6143, 0.4461],
            [0.6143, 0.4461, 0.5911, 0.4458, 0.5992, 0.4113, 0.6054, 0.3975],
            [0.6054, 0.3975, 0.6178, 0.3698, 0.6408, 0.3538, 0.6688, 0.3538],
        ],
    ]

    // MARK: - Expression set 2 (approved 2026-08-29)
    // Parametric, code-drawn in the same vector language as the traced faces.
    // Eye anchors from spec.json: cx 0.3308 / 0.6681, cy 0.4326.

    private static let eyeL = 0.3308, eyeR = 0.6681, eyeY = 0.4326

    /// Sleepy: relaxed closed lids + small o mouth.
    static let faceSleep: [[[Double]]] = [
        arcStroke(eyeL, 0.435, 0.135, 0.028, 0.048),
        arcStroke(eyeR, 0.435, 0.135, 0.028, 0.048),
        ellipseSub(0.5, 0.505, 0.020, 0.016),
    ]

    /// Surprised: round eyes a touch taller + tall O mouth.
    static let faceSurprised: [[[Double]]] = [
        ellipseSub(eyeL, eyeY - 0.008, 0.078, 0.086),
        ellipseSub(eyeR, eyeY - 0.008, 0.078, 0.086),
        ellipseSub(0.5, 0.535, 0.040, 0.050),
    ]

    /// Sad: smaller, lower eyes + frown.
    static let faceSad: [[[Double]]] = [
        ellipseSub(eyeL, eyeY + 0.012, 0.064, 0.070),
        ellipseSub(eyeR, eyeY + 0.012, 0.064, 0.070),
        arcStroke(0.5, 0.520, 0.130, 0.026, -0.048),
    ]

    /// Focused: brows angled in over the judging half-lids + the idle smile.
    static let faceFocused: [[[Double]]] =
        [brow(eyeL, 0.292, 0.054, 0.026, 0.026),
         brow(eyeR, 0.292, 0.054, -0.026, 0.026)]
        + [faceJudging[0], faceJudging[2]]
        + [faceIdle[1]]

    /// Wink: open left eye, delight ^ arc right eye, idle smile.
    static let faceWink: [[[Double]]] = [faceIdle[0], faceDelight[2], faceIdle[1]]

    // MARK: parametric shape builders

    /// A straight edge as a degenerate cubic (controls at the thirds).
    private static func seg(_ a: (Double, Double), _ b: (Double, Double)) -> [Double] {
        [a.0, a.1,
         a.0 + (b.0 - a.0) / 3, a.1 + (b.1 - a.1) / 3,
         a.0 + 2 * (b.0 - a.0) / 3, a.1 + 2 * (b.1 - a.1) / 3,
         b.0, b.1]
    }

    private static func ellipseSub(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> [[Double]] {
        let k = 0.5523
        return [
            [cx + rx, cy, cx + rx, cy + k * ry, cx + k * rx, cy + ry, cx, cy + ry],
            [cx, cy + ry, cx - k * rx, cy + ry, cx - rx, cy + k * ry, cx - rx, cy],
            [cx - rx, cy, cx - rx, cy - k * ry, cx - k * rx, cy - ry, cx, cy - ry],
            [cx, cy - ry, cx + k * rx, cy - ry, cx + rx, cy - k * ry, cx + rx, cy],
        ]
    }

    /// Thin arc band. bow > 0 bulges downward (closed lid), bow < 0 upward (frown).
    private static func arcStroke(_ cx: Double, _ cy: Double, _ w: Double, _ t: Double, _ bow: Double) -> [[Double]] {
        let x0 = cx - w / 2, x1 = cx + w / 2
        return [
            [x0, cy, cx - w / 6, cy + bow, cx + w / 6, cy + bow, x1, cy],
            seg((x1, cy), (x1, cy + t)),
            [x1, cy + t, cx + w / 6, cy + bow + t, cx - w / 6, cy + bow + t, x0, cy + t],
            seg((x0, cy + t), (x0, cy)),
        ]
    }

    /// Slanted brow bar. slant > 0 lowers the right end.
    private static func brow(_ cx: Double, _ cy: Double, _ halfW: Double, _ slant: Double, _ t: Double) -> [[Double]] {
        let yl = cy - slant / 2, yr = cy + slant / 2
        return [
            seg((cx - halfW, yl), (cx + halfW, yr)),
            seg((cx + halfW, yr), (cx + halfW, yr + t)),
            seg((cx + halfW, yr + t), (cx - halfW, yl + t)),
            seg((cx - halfW, yl + t), (cx - halfW, yl)),
        ]
    }
}


/// A four-point sparkle with concave sides. Replaces the ✨ the mascot used to carry —
/// emoji render in the system font, which is the one thing on screen not in the palette.
struct Spark: Shape {
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let R = min(r.width, r.height) / 2
        let w = R * 0.30
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - R))
        p.addQuadCurve(to: CGPoint(x: c.x + R, y: c.y), control: CGPoint(x: c.x + w, y: c.y - w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + R), control: CGPoint(x: c.x + w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x - R, y: c.y), control: CGPoint(x: c.x - w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - R), control: CGPoint(x: c.x - w, y: c.y - w))
        p.closeSubpath()
        return p
    }
}

/// Three rising z's, drawn rather than the 💤 emoji.
struct SleepZs: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let sizes: [(CGFloat, CGFloat, CGFloat)] = [(0.00, 0.62, 0.38), (0.34, 0.30, 0.30), (0.62, 0.04, 0.22)]
        for (x0, y0, s) in sizes {
            let x = r.minX + x0 * r.width
            let y = r.minY + y0 * r.height
            let d = s * min(r.width, r.height)
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x + d, y: y))
            p.addLine(to: CGPoint(x: x, y: y + d))
            p.addLine(to: CGPoint(x: x + d, y: y + d))
        }
        return p
    }
}
