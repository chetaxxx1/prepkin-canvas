import SwiftUI

/// The shift scene: Sprout swims sideways through a reef that rolls past under him.
/// Ported from `design/reef-route/reef-route.html` (the approved mock).
///
/// Two clocks. `time` is running shift seconds: it freezes on pause, and every part of
/// the reef (floor, arch, chest, far mounds, front dune) is a pure function of it, so a
/// pause holds the frame and a resume carries on without a jump. `life` is the wall
/// clock and never stops: bubbles, fish, crabs, clams and the far swimmers keep moving
/// while he sleeps, which is what a reef does.
///
/// Everything is drawn in two `Canvas` passes (back, front) around the still Sprout,
/// so the sixty-odd sprites cost one draw each per frame.
struct SwimSceneView: View {
    var time: Double
    var life: Double
    var speciesID: String
    var level: Int
    /// What he is wearing. Without this the shift drew the coat's default costume no
    /// matter what the student had chosen — he changed clothes the moment a shift began.
    var skin: String = "classic"
    var animation: ChibiAnimation
    var paused: Bool
    var size: CGFloat = 250

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Seconds between length markers. The floor tile (660) divides 90 × 22, so the arch
    /// lands on the same bare stretch of sand every tick.
    static let secondsPerLength: Double = 90

    private static let base: CGFloat = 250
    private static let tile: Double = 660
    private static let sand: Double = 214
    private static let amp: Double = 5
    private static let vFar = 8.0, vMid = 22.0, vNear = 44.0
    private static let archH: Double = 88
    private static let chestH: Double = 46
    /// A chest every three lengths, 20 s after a tick. (20 × 22) mod 660 = 440 is fixed,
    /// so its stretch of floor is kept bare too.
    private static let chestEvery = secondsPerLength * 3
    private static let chestOffset: Double = 20

    private static func sandY(_ x: Double) -> Double { sand + amp * sin(2 * .pi * x / tile) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas(rendersAsynchronously: false) { ctx, _ in drawBack(&ctx) }
                .frame(width: Self.base, height: Self.base)
            sprout
            Canvas(rendersAsynchronously: false) { ctx, _ in drawFront(&ctx) }
                .frame(width: Self.base, height: Self.base)
                .allowsHitTesting(false)
        }
        .frame(width: Self.base, height: Self.base)
        .clipShape(Circle())
        .scaleEffect(size / Self.base)
        .frame(width: size, height: size)
    }

    // MARK: - Sprout

    private let kinSize: CGFloat = 128
    private var swimBottom: Double { 124 }
    private var sleepBottom: Double { Self.sand + 4 }

    private var sprout: some View {
        let artH = kinSize * SproutImage.heightRatio
        let drift = (paused || reduceMotion) ? 0.0 : sin(time * 2 * .pi / 6) * 8
        let lift = (paused || reduceMotion) ? 0.0 : sin(time * 2 * .pi / 3) * 1.5
        let bottom = paused ? sleepBottom : swimBottom
        return SproutImage(speciesID: speciesID, level: level, skin: skin, animation: animation, size: kinSize)
            .offset(x: (Self.base - kinSize) / 2 + drift, y: bottom - artH + lift)
            .animation(.easeInOut(duration: 0.7), value: paused)
    }

    // MARK: - Back: water, rays, far mounds, far swimmers, fish, floor, arch, chest

    private func drawBack(_ c: inout GraphicsContext) {
        let full = CGRect(x: 0, y: 0, width: Self.base, height: Self.base)
        c.fill(Path(full), with: .linearGradient(
            Gradient(colors: [Reef.waterTop, Reef.waterMid, Reef.waterDeep]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: Self.base)))
        for (x0, w, a) in [(70.0, 26.0, 0.32), (150.0, 18.0, 0.19)] {
            var ray = Path()
            ray.move(to: CGPoint(x: x0, y: -20)); ray.addLine(to: CGPoint(x: x0 + w, y: -20))
            ray.addLine(to: CGPoint(x: x0 - 56 + w * 0.5, y: 230)); ray.addLine(to: CGPoint(x: x0 - 56 - w * 0.5, y: 230)); ray.closeSubpath()
            c.fill(ray, with: .linearGradient(Gradient(colors: [.white.opacity(a), .white.opacity(0)]),
                                              startPoint: CGPoint(x: 0, y: -20), endPoint: CGPoint(x: 0, y: 230)))
        }
        // far mounds: mirrored triple so the strip loops
        let farH = 40.0, farW = ReefSprites.width("far", height: farH), farY = 156.0
        let farS = (time * Self.vFar).truncatingRemainder(dividingBy: 2 * farW)
        for i in 0..<3 {
            let x = Double(i) * farW - farS
            guard x < Self.base, x + farW > 0 else { continue }
            var img = c; img.opacity = 0.3
            if i == 1 { img.translateBy(x: x + farW, y: 0); img.scaleBy(x: -1, y: 1); img.draw(Image("reef-far"), in: CGRect(x: 0, y: farY, width: farW, height: farH)) }
            else { img.draw(Image("reef-far"), in: CGRect(x: x, y: farY, width: farW, height: farH)) }
        }
        drawFarSwimmers(&c)
        drawFish(&c)
        // the floor, two tiles
        let s = (time * Self.vMid).truncatingRemainder(dividingBy: Self.tile)
        for i in 0..<2 { var t = c; t.translateBy(x: Double(i) * Self.tile - s, y: 0); drawTile(&t) }
        // arch and chest ride the floor: their screen x is a function of time, and they stand on the sand there
        let archW = ReefSprites.width("arch", height: Self.archH)
        let tick = Self.secondsPerLength
        let nextTick = (floor(time / tick) + 1) * tick
        drawLandmark(&c, "reef-arch", w: archW, h: Self.archH, screenX: 125 - archW / 2 + (nextTick - time) * Self.vMid, sink: 10)
        if floor(time / tick) > 0 {
            drawLandmark(&c, "reef-arch", w: archW, h: Self.archH, screenX: 125 - archW / 2 - (time - floor(time / tick) * tick) * Self.vMid, sink: 10)
        }
        let chestW = ReefSprites.width("chest-1", height: Self.chestH)
        let m = floor((time - Self.chestOffset) / Self.chestEvery)
        let prevT = m * Self.chestEvery + Self.chestOffset, nextT = prevT + Self.chestEvery
        drawLandmark(&c, "reef-chest-1", w: chestW, h: Self.chestH, screenX: 125 - chestW / 2 + (nextT - time) * Self.vMid, sink: 6)
        if m >= 0 { drawLandmark(&c, "reef-chest-1", w: chestW, h: Self.chestH, screenX: 125 - chestW / 2 - (time - prevT) * Self.vMid, sink: 6) }
    }

    private func drawLandmark(_ c: inout GraphicsContext, _ name: String, w: Double, h: Double, screenX: Double, sink: Double) {
        guard screenX > -200, screenX < 600 else { return }
        let s = (time * Self.vMid).truncatingRemainder(dividingBy: Self.tile)
        let y = Self.sandY(screenX + s + w / 2) + sink - h
        c.draw(Image(name), in: CGRect(x: screenX, y: y, width: w, height: h))
    }

    /// One 660-wide floor tile: kelp and corals planted 6 pt into the sand, the sand band
    /// on top of their bases, then the sand life lying on it. Two bare stretches are kept
    /// for the arch (60–190) and the chest (521–609); `design/reef-route/tools/retile.py`
    /// is the source of these numbers.
    private func drawTile(_ c: inout GraphicsContext) {
        let plants: [(String, Double, Double)] = [
            ("plant-4", 30, 100), ("plant-1", 230, 92), ("plant-2", 300, 70), ("plant-4", 370, 96), ("plant-1", 440, 88), ("plant-2", 500, 66), ("plant-4", 635, 96),
            ("coral-2", 250, 44), ("coral-1", 330, 54), ("coral-4", 410, 50), ("coral-3", 475, 48),
            ("plant-3", 30, 34), ("plant-5", 270, 28), ("plant-3", 355, 32), ("plant-5", 425, 26), ("plant-3", 505, 30), ("plant-5", 632, 27)]
        for (name, cx, h) in plants {
            let w = ReefSprites.width(name, height: h)
            c.draw(Image("reef-" + name), in: CGRect(x: cx - w / 2, y: Self.sandY(cx) + 6 - h, width: w, height: h))
        }
        // sand band and its lighter crest
        var top = Path(); var crest = Path()
        let n = 33
        for i in 0...n {
            let x = Double(i) * Self.tile / Double(n)
            let p = CGPoint(x: x, y: Self.sandY(x))
            i == 0 ? top.move(to: p) : top.addLine(to: p)
        }
        var band = top
        band.addLine(to: CGPoint(x: Self.tile, y: Self.base)); band.addLine(to: CGPoint(x: 0, y: Self.base)); band.closeSubpath()
        c.fill(band, with: .color(Reef.sand))
        crest = top
        for i in stride(from: n, through: 0, by: -1) {
            let x = Double(i) * Self.tile / Double(n)
            crest.addLine(to: CGPoint(x: x, y: Self.sandY(x) + 9))
        }
        crest.closeSubpath()
        c.fill(crest, with: .color(Reef.sandLight))
        // sand life: lies inside the sand band, on the lowest sand under its footprint
        let flat: [(String, Double, Double)] = [("star", 215, 15), ("coral-6", 505, 12), ("coral-7", 325, 8), ("coral-7", 642, 7), ("star", 22, 13)]
        for (name, cx, h) in flat {
            let w = ReefSprites.width(name, height: h)
            c.draw(Image("reef-" + name), in: CGRect(x: cx - w / 2, y: lowestSand(cx, w) + 3, width: w, height: h))
        }
        for (cx, h, ph) in [(360.0, 13.0, 0.0), (470.0, 11.0, 3.7)] {
            let open = (life + ph).truncatingRemainder(dividingBy: 7) < 1.6
            let name = open ? "clam-2" : "clam-1"
            let w = ReefSprites.width("clam-1", height: h)
            c.draw(Image("reef-" + name), in: CGRect(x: cx - w / 2, y: lowestSand(cx, w) + 3, width: w, height: h))
        }
        for (cx, h, ph) in [(430.0, 16.0, 0.0), (262.0, 14.0, 2.1)] {
            let walk = sin(life * 0.32 + ph) * 14
            let moving = abs(cos(life * 0.32 + ph)) > 0.35
            let clawsUp = moving && Int(floor(life * 2.2 + ph)) % 2 == 1
            let w = ReefSprites.width("crab-1", height: h)
            let top = lowestSand(cx, w + 28)
            c.draw(Image(clawsUp ? "reef-crab-2" : "reef-crab-1"), in: CGRect(x: cx - w / 2 + walk, y: top - 0.45 * h, width: w, height: h))
        }
    }

    private func lowestSand(_ cx: Double, _ w: Double) -> Double {
        (0...12).map { Self.sandY(cx - w / 2 + Double($0) * w / 12) }.max() ?? Self.sand
    }

    // MARK: - Life on the wall clock

    private func hash(_ k: Int, _ salt: Int) -> Double {
        let v = sin(Double(k) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return v - floor(v)
    }

    /// A fish (or three darters) every 4–7 s, at Sprout's depth or below, swimming left.
    private func drawFish(_ c: inout GraphicsContext) {
        let kinds: [(String, Double, Double)] = [("puffer", 34, 26), ("darter", 40, 60), ("angel", 28, 40)]
        let period = 5.5
        let first = max(0, Int(floor((life - 40) / period)))
        for k in first...Int(floor(life / period)) {
            let start = Double(k) * period + hash(k, 1) * 2
            guard life >= start else { continue }
            let (name, w, v) = kinds[Int(hash(k, 2) * 3) % 3]
            let h = w / (ReefSprites.aspect[name] ?? 1)
            let y = 30 + hash(k, 3) * 60
            let count = name == "darter" ? 3 : 1
            for i in 0..<count {
                let x = 270 + Double(i) * 34 - (life - start) * v
                guard x > -70, x < Self.base else { continue }
                let bob = sin((life + hash(k, 4) * 6) * 2.2) * 1.5
                var f = c
                f.translateBy(x: x + w / 2, y: y + Double(i % 2) * 10 + bob + h / 2)
                f.rotate(by: .degrees(sin((life + hash(k, 4) * 6) * 9) * 2.5))
                f.draw(Image("reef-" + name), in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
            }
        }
    }

    /// A dolphin, orca, whale or submarine, big, slow and faded, every 22–38 s.
    private func drawFarSwimmers(_ c: inout GraphicsContext) {
        let kinds: [(String, Double, Double)] = [("dolphin", 56, 14), ("orca", 66, 11), ("whale", 84, 8), ("sub", 72, 9)]
        let period = 30.0
        let first = max(0, Int(floor((life - 70) / period)))
        for k in first...Int(floor(life / period)) {
            let start = Double(k) * period + 6 + hash(k, 5) * 8
            guard life >= start else { continue }
            let (name, w, v) = kinds[Int(hash(k, 6) * 4) % 4]
            let h = w / (ReefSprites.aspect[name] ?? 1)
            let x = 280 - (life - start) * v
            guard x > -140, x < Self.base else { continue }
            let y = 26 + hash(k, 7) * 60 + sin((life + hash(k, 8) * 6) * 0.9) * 2
            var f = c; f.opacity = 0.55
            f.draw(Image("reef-" + name), in: CGRect(x: x, y: y, width: w, height: h))
        }
    }

    // MARK: - Front: dune and bubbles

    private func drawFront(_ c: inout GraphicsContext) {
        let s = (time * Self.vNear).truncatingRemainder(dividingBy: 300)
        for i in 0..<3 {
            var d = c; d.translateBy(x: Double(i) * 300 - s, y: 0)
            var dune = Path(); dune.move(to: CGPoint(x: 0, y: 250)); dune.addLine(to: CGPoint(x: 0, y: 241))
            dune.addCurve(to: CGPoint(x: 110, y: 239), control1: CGPoint(x: 40, y: 232), control2: CGPoint(x: 70, y: 232))
            dune.addCurve(to: CGPoint(x: 230, y: 239), control1: CGPoint(x: 150, y: 246), control2: CGPoint(x: 190, y: 246))
            dune.addCurve(to: CGPoint(x: 300, y: 241), control1: CGPoint(x: 260, y: 234), control2: CGPoint(x: 285, y: 235))
            dune.addLine(to: CGPoint(x: 300, y: 250)); dune.closeSubpath()
            d.fill(dune, with: .color(Reef.dune))
            var lip = Path(); lip.move(to: CGPoint(x: 0, y: 241))
            lip.addCurve(to: CGPoint(x: 110, y: 239), control1: CGPoint(x: 40, y: 232), control2: CGPoint(x: 70, y: 232))
            lip.addCurve(to: CGPoint(x: 230, y: 239), control1: CGPoint(x: 150, y: 246), control2: CGPoint(x: 190, y: 246))
            lip.addCurve(to: CGPoint(x: 300, y: 241), control1: CGPoint(x: 260, y: 234), control2: CGPoint(x: 285, y: 235))
            lip.addLine(to: CGPoint(x: 300, y: 245))
            lip.addCurve(to: CGPoint(x: 230, y: 243), control1: CGPoint(x: 285, y: 239), control2: CGPoint(x: 260, y: 238))
            lip.addCurve(to: CGPoint(x: 110, y: 243), control1: CGPoint(x: 190, y: 250), control2: CGPoint(x: 150, y: 250))
            lip.addCurve(to: CGPoint(x: 0, y: 245), control1: CGPoint(x: 70, y: 236), control2: CGPoint(x: 40, y: 236))
            lip.closeSubpath()
            d.fill(lip, with: .color(Reef.duneLight))
        }
        guard !reduceMotion else { return }
        let top = paused ? Self.sand - 10 : 90
        for i in 0..<3 {
            let p = (life * 0.45 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
            let r = [3.0, 2.0, 4.0][i]
            let x = 118 + Double(i) * 22 + sin((life + Double(i)) * 2) * 4
            let y = top - p * 110
            let bubble = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
            var b = c; b.opacity = (1 - p) * 0.9
            b.fill(bubble, with: .color(.white.opacity(0.2)))
            b.stroke(bubble, with: .color(.white.opacity(0.8)), lineWidth: 1.2)
        }
        if paused {
            var z = c; z.opacity = 0.85 * abs(sin(life * 1.2))
            let zs = SleepZs().path(in: CGRect(x: 160, y: 116 - (life * 6).truncatingRemainder(dividingBy: 14), width: 22, height: 22))
            z.stroke(zs, with: .color(.white), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

enum Reef {
    static let waterTop = Theme.hex(0xBFE6DD)
    static let waterMid = Theme.hex(0x7CC8BF)
    static let waterDeep = Theme.hex(0x4FA9A5)
    static let sand = Theme.hex(0xF1DFAE)
    static let sandLight = Theme.hex(0xF8EBC4)
    static let dune = Theme.hex(0xEDD9A5)
    static let duneLight = Theme.hex(0xF6E8C0)
    /// The length marker in the best-shift chip.
    static let float = Theme.coin
    static let floatEdge = Theme.coinBorder
}
