import SwiftUI

/// The driving loop inside the Focus circle: Kin delivers parcels for the length
/// of a shift. Geometry is transcribed from
/// `design/handoff/focus-shift-van/README.md` — a 250pt circle, everything placed
/// from its top-left (the handoff measures from the bottom, so `y = 250 - bottom
/// - height`). The van, wheels and scenery are placeholder shapes in the handoff
/// too; only Kin's paths are final.
///
/// Every position is a pure function of `time`, so pausing the shift freezes the
/// scene exactly where it was and resuming carries on without a jump. Nothing
/// here accumulates — minute 2 and minute 48 look the same, by design.
struct ShiftSceneView: View {
    /// Seconds of *running* shift time, not wall clock.
    var time: Double
    /// The active mascot's body colour; the face crops into the van window.
    var bodyColor: Color
    /// Rendered diameter. The scene is drawn at the handoff's 250pt and scaled as
    /// a whole, so every part keeps its proportion on a shorter phone.
    var size: CGFloat = 250

    private let base: CGFloat = 250

    var body: some View {
        circle
            .scaleEffect(size / base)
            .frame(width: size, height: size)
    }

    private var circle: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: base, height: base)

            // Ground band, then the road it carries.
            Rectangle().fill(ShiftScene.ground)
                .frame(width: base, height: 42)
                .offset(y: base - 42)

            cloud
            bush
            road
            van
        }
        .frame(width: base, height: base)
        .background(Circle().fill(ShiftScene.sky))
        // Stands in for the handoff's `inset 0 -14px 30px` — a soft floor shade.
        .overlay(
            LinearGradient(colors: [.clear, ShiftScene.shade],
                           startPoint: .center, endPoint: .bottom)
        )
        .clipShape(Circle())
    }

    // MARK: - Scenery

    private var cloud: some View {
        Capsule().fill(.white).opacity(0.9)
            .frame(width: 44, height: 13)
            .offset(x: 30 + drift(period: 9), y: 52)
    }

    private var bush: some View {
        UnevenRoundedRectangle(topLeadingRadius: 8.5, bottomLeadingRadius: 0,
                               bottomTrailingRadius: 0, topTrailingRadius: 8.5)
            .fill(ShiftScene.bush)
            .frame(width: 38, height: 17)
            .offset(x: drift(period: 4.5), y: base - 42 - 17)
    }

    /// Dashes scroll one full dash-plus-gap (44pt) every 0.55s, which is what
    /// reads as speed — the van itself never moves horizontally.
    private var road: some View {
        HStack(spacing: 18) {
            ForEach(0..<8, id: \.self) { _ in
                Capsule().fill(ShiftScene.road).frame(width: 26, height: 5)
            }
        }
        .offset(x: -44 * loop(0.55))
        .frame(width: base, height: 5, alignment: .leading)
        .clipped()
        .offset(y: base - 36 - 5)
    }

    // MARK: - Van

    private var van: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: 172, height: 110)

            parcel

            // Cargo box + its label plate.
            UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 8,
                                   bottomTrailingRadius: 4, topTrailingRadius: 4)
                .fill(ShiftScene.van)
                .frame(width: 104, height: 62)
                .offset(y: 32)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(ShiftScene.cream)
                .frame(width: 52, height: 22)
                .overlay(
                    Text("KIN CO")
                        .font(Theme.font(10, .black))
                        .tracking(0.5)
                        .foregroundStyle(ShiftScene.van)
                )
                .offset(x: 16, y: 48)

            // Cab, with the rounded nose the handoff calls for.
            UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 6,
                                   bottomTrailingRadius: 6, topTrailingRadius: 18)
                .fill(ShiftScene.van)
                .frame(width: 58, height: 46)
                .offset(x: 102, y: 48)

            window
            wheel.offset(x: 26, y: 88)
            wheel.offset(x: 122, y: 88)
        }
        .frame(width: 172, height: 110)
        // Bob: 3pt, eased, once every 1.1s.
        .offset(x: 44, y: base - 44 - 110 - 1.5 * (1 - cos(2 * .pi * loop(1.1))))
    }

    /// Kin's face cropping into the glass. Body + face only — no belly and no
    /// ground shadow, matching the handoff's inlined SVG.
    private var window: some View {
        Color.clear
            .frame(width: 30, height: 23)
            .overlay(alignment: .topLeading) {
                ZStack {
                    TracedShape(subpaths: SlimeArt.body).fill(bodyColor)
                    TracedShape(subpaths: SlimeExpression.idle.art).fill(Slime.ink)
                }
                .frame(width: 54, height: 54 / Slime.aspect)
                .offset(x: -7, y: -9)
            }
            .background(ShiftScene.cream)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 2,
                                              bottomTrailingRadius: 2, topTrailingRadius: 10))
            .offset(x: 110, y: 51)
    }

    private var wheel: some View {
        Circle().fill(Theme.ink)
            .frame(width: 30, height: 30)
            .overlay(
                Circle().fill(ShiftScene.hub)
                    .frame(width: 11, height: 11)
                    .overlay(alignment: .top) {
                        // One spoke, so the spin is visible on a plain hub.
                        Capsule().fill(ShiftScene.hub)
                            .frame(width: 3, height: 7)
                            .offset(x: 1.5, y: -7)
                    }
            )
            .rotationEffect(.degrees(loop(0.8) * 360))
    }

    /// Flavour only, on its own 6s cycle — not tied to the miles count.
    private var parcel: some View {
        let t = toss()
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(ShiftScene.parcel)
            .frame(width: 17, height: 17)
            .overlay(alignment: .leading) {
                Rectangle().fill(ShiftScene.cream)
                    .frame(width: 3)
                    .offset(x: 7)
            }
            .opacity(t.opacity)
            .rotationEffect(.degrees(t.rotation))
            .offset(x: -4 + t.x, y: 29 + t.y)
    }

    // MARK: - Timing

    /// Where `time` sits in a loop of `period` seconds, as 0…1.
    private func loop(_ period: Double) -> Double {
        let p = time.truncatingRemainder(dividingBy: period)
        return (p < 0 ? p + period : p) / period
    }

    /// Scenery slides right-to-left across the full circle and wraps.
    private func drift(period: Double) -> CGFloat { 160 - 390 * loop(period) }

    private struct Toss { var x: CGFloat; var y: CGFloat; var rotation: Double; var opacity: Double }

    /// The handoff's keyframes: hidden until 70% of the cycle, popped up and back
    /// at 74%, landed on the road at 86%, faded out by 92%.
    private func toss() -> Toss {
        let p = loop(6)
        let stops: [(at: Double, x: CGFloat, y: CGFloat, rot: Double, opacity: Double)] = [
            (0.70, 0, 0, 0, 0),
            (0.74, -10, -18, -24, 1),
            (0.86, -44, 26, -100, 1),
            (0.92, -54, 30, -110, 0),
        ]
        guard p >= stops[0].at, p < stops[stops.count - 1].at else {
            return Toss(x: 0, y: 0, rotation: 0, opacity: 0)
        }
        for i in 0..<(stops.count - 1) where p < stops[i + 1].at {
            let a = stops[i], b = stops[i + 1]
            let raw = (p - a.at) / (b.at - a.at)
            let f = raw * raw * (3 - 2 * raw)          // ease-in-out
            return Toss(x: a.x + (b.x - a.x) * f,
                        y: a.y + (b.y - a.y) * f,
                        rotation: a.rot + (b.rot - a.rot) * f,
                        opacity: a.opacity + (b.opacity - a.opacity) * f)
        }
        return Toss(x: 0, y: 0, rotation: 0, opacity: 0)
    }
}

/// Illustration-only colours for the shift scene. They stay here rather than in
/// `Theme` because nothing else on any screen paints with them — the van itself
/// uses the app's own amber so the scene still reads as Prepkin.
enum ShiftScene {
    static let sky = Theme.hex(0xF6EEDC)
    static let ground = Theme.hex(0xF1E6CC)
    static let road = Theme.hex(0xD8C6A2)
    static let cream = Theme.hex(0xFFF9EC)
    static let parcel = Theme.hex(0xC08F42)
    static let hub = Theme.hex(0x8A7A66)
    static let shade = Color(red: 120 / 255, green: 92 / 255, blue: 50 / 255).opacity(0.10)
    static let van = Theme.coinBorder
    static let bush = Theme.mintDark
}
