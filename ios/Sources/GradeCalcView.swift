import SwiftUI

/// "What do I need on the final?" — the RogerHub question, nothing more.
///
/// Three numbers in (grade now, goal, what the final is worth), one number out,
/// and a "what if" ladder for the student who wants to see the whole picture.
/// Scene, mascot and cards follow `design_handoff_grade_calculator` (2a for the
/// top half, 1c for the ladder). The class-distribution and curve-model cards in
/// that handoff were dropped: nobody types six quartiles off Canvas into a phone.
struct GradeCalcView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var current = 88
    /// The grade this course is aiming at, as a percent. `nil` until one is picked.
    @State private var goal: Double?
    @State private var showingPlus = false
    @State private var target = 90
    @State private var weight = 20      // final's share of the course grade, percent

    /// This handoff carries its own palette — a warmer cream and a lighter coral
    /// than the rest of the app, because the screen is a scene rather than a list.
    private enum G {
        static let ink = Theme.hex(0x2B2320)
        static let ink2 = Theme.hex(0x6E645B)
        static let muted = Theme.hex(0x8C8178)
        static let muted2 = Theme.hex(0xB5ADA3)
        static let page = Theme.hex(0xF8F4EC)
        static let cream = Theme.hex(0xFFFDF7)
        static let well = Theme.hex(0xF3EFE7)
        static let coral = Theme.hex(0xF76C5E)
        static let amber = Theme.hex(0xE9A23B)
        static let red = Theme.hex(0xC94B3D)
        static let green = Theme.hex(0x5BB08A)
        static let hitBg = Theme.hex(0xE4F1E9)
        static let hitInk = Theme.hex(0x3E8F68)
    }

    enum Mood { case happy, flat, sad }

    // MARK: - Math

    private var w: Double { Double(weight) / 100 }

    /// needed = (target − current·(1−w)) / w
    private var needed: Double {
        guard w > 0 else { return 0 }
        return (Double(target) - Double(current) * (1 - w)) / w
    }

    /// Course grade if the final comes in at `score`.
    private func course(ifFinal score: Int) -> Double {
        Double(current) * (1 - w) + Double(score) * w
    }

    private func letter(_ p: Double) -> String {
        switch p {
        case 93...: "A"
        case 90...: "A−"
        case 87...: "B+"
        case 83...: "B"
        case 80...: "B−"
        case 77...: "C+"
        case 73...: "C"
        case 70...: "C−"
        case 60...: "D"
        default: "F"
        }
    }

    private var mood: Mood { needed < 75 ? .happy : needed <= 95 ? .flat : .sad }

    private var scene: (sky: Color, ground: Color, accent: Color) {
        switch mood {
        case .happy: (Theme.hex(0x9FD3C0), Theme.hex(0x7DBEA6), G.green)
        case .flat:  (Theme.hex(0xF3D3A0), Theme.hex(0xE7BC7C), G.amber)
        case .sad:   (Theme.hex(0xF2B3AA), Theme.hex(0xE69A90), G.coral)
        }
    }

    private var resultColor: Color { needed > 100 ? G.red : needed > 90 ? G.amber : G.ink }

    private var verdict: String {
        switch needed {
        case ...0: "Already locked in. Enjoy the week."
        case ..<60: "Easy. Show up and breathe."
        case ..<75: "Very doable."
        case ..<85: "Doable with a solid study week."
        case ..<95: "Tough but possible."
        case ...100: "Everything on the line."
        default: "Not possible on the final alone. Ask about extra credit."
        }
    }

    private var bubble: String {
        switch needed {
        case ...0: "Nothing left to do. Rare."
        case ..<60: "You got this, easy."
        case ..<75: "Looking good."
        case ..<85: "Study week time."
        case ..<95: "Deep breath. Possible."
        case ...100: "All in on the final."
        default: "Let's rethink the goal."
        }
    }

    private var neededText: String {
        needed <= 0 ? "0%" : String(format: "%.1f%%", needed)
    }

    private var meterLabel: String {
        needed > 100 ? "Over 100" : "\(Int(max(0, needed).rounded())) / 100"
    }

    /// The course whose grade is prefilled into "Grade now", so the pill and the
    /// number always name the same class.
    private var course: CanvasCourse? { state.courses.first { $0.score != nil } }

    /// Canvas's `course_code` is only sometimes a code — plenty of schools put the
    /// full title in it — so the pill takes whichever label is shorter and lets the
    /// tail truncate.
    private var courseLabel: String {
        guard let c = course else { return "Final exam" }
        let short = c.code.isEmpty || c.code.count > c.name.count ? c.name : c.code
        return "\(short) · Final"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                navRow
                characterBlock
                resultCard
                stepperRow
                ladderCard
                termCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 60)
            .padding(.bottom, 56)
            .background(alignment: .top) { backdrop }
        }
        .scrollIndicators(.hidden)
        .background(G.page.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.easeInOut(duration: 0.4), value: mood)
        .task {
            if let score = course?.score { current = Int(score.rounded()) }
        }
    }

    // MARK: - Scene

    private var backdrop: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                scene.sky
                    .frame(height: 380)
                Circle()
                    .fill(G.cream.opacity(0.45))
                    .frame(width: 120, height: 120)
                    .offset(x: 48, y: 120)
                Ellipse()
                    .fill(scene.ground)
                    .frame(width: geo.size.width + 80, height: 400)
                    .offset(x: -40, y: 250)
            }
            .frame(width: geo.size.width, height: 450, alignment: .topLeading)
            .clipped()
        }
        .frame(height: 450)
        .allowsHitTesting(false)
    }

    private var navRow: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(G.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(G.cream.opacity(0.9)))
                    .shadow(color: G.ink.opacity(0.08), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(courseLabel)
                .font(Theme.font(13, .heavy))
                .foregroundStyle(G.ink)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(G.cream.opacity(0.9)))
                .shadow(color: G.ink.opacity(0.08), radius: 3, y: 2)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var characterBlock: some View {
        VStack(spacing: 10) {
            Text(bubble)
                .font(Theme.font(14, .heavy))
                .foregroundStyle(G.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(G.cream)
                        .shadow(color: G.ink.opacity(0.08), radius: 6, y: 4)
                )
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(G.cream)
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(45))
                        .offset(y: 6)
                }
            // The mascot is never redrawn — the kin the student already has stands in
            // for the handoff's placeholder bird.
            SproutImage(speciesID: state.activeChibiID,
                        level: state.activeChibi.level,
                        skin: state.activeChibi.skinID,
                        size: 112)
        }
        .padding(.top, 6)
    }

    // MARK: - Result

    private var resultCard: some View {
        VStack(spacing: 6) {
            Text("You need on the final")
                .font(Theme.font(13, .heavy))
                .kerning(0.78)
                .textCase(.uppercase)
                .foregroundStyle(G.muted)

            Text(neededText)
                .font(Theme.font(72, .black))
                .kerning(-2.16)
                .foregroundStyle(resultColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())

            Text(verdict)
                .font(Theme.font(16, .bold))
                .foregroundStyle(G.ink2)
                .multilineTextAlignment(.center)

            meter.padding(.top, 12)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(card(28))
        .padding(.top, 8)
    }

    private var meter: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(G.well)
                Capsule()
                    .fill(scene.accent)
                    .frame(width: geo.size.width * min(100, max(4, needed)) / 100)
                Text(meterLabel)
                    .font(Theme.font(12, .black))
                    .foregroundStyle(G.ink)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 22)
        .animation(.easeInOut(duration: 0.3), value: needed)
    }

    // MARK: - Steppers

    private var stepperRow: some View {
        HStack(spacing: 10) {
            stepper("Grade now", value: current, tint: G.ink,
                    minus: { current = clamp(current - 1, 0, 100) },
                    plus: { current = clamp(current + 1, 0, 100) })
            stepper("Goal", value: target, tint: G.coral,
                    minus: { target = clamp(target - 1, 0, 100) },
                    plus: { target = clamp(target + 1, 0, 100) })
            stepper("Final worth", value: weight, tint: G.ink,
                    minus: { weight = clamp(weight - 5, 5, 100) },
                    plus: { weight = clamp(weight + 5, 5, 100) })
        }
    }

    private func stepper(_ label: String, value: Int, tint: Color,
                         minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(Theme.font(11, .heavy))
                .kerning(0.44)
                .textCase(.uppercase)
                .foregroundStyle(G.muted)
                .lineLimit(1)
            HStack(spacing: 0) {
                Text("\(value)")
                    .font(Theme.font(26, .black))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                Text("%")
                    .font(Theme.font(14, .black))
                    .foregroundStyle(G.muted)
            }
            HStack(spacing: 6) {
                roundButton("−", action: minus)
                roundButton("+", action: plus)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(card(22))
    }

    // MARK: - What if

    private static let ladder = [100, 95, 90, 85, 80, 75, 70, 65, 60]

    private var ladderCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("If you score…")
                    .font(Theme.font(16, .heavy))
                    .foregroundStyle(G.ink)
                Spacer()
                Text("Goal \(target)% · \(letter(Double(target)))")
                    .font(Theme.font(12, .bold))
                    .foregroundStyle(G.coral)
            }
            .padding(.bottom, 4)

            HStack {
                Text("on the final").frame(maxWidth: .infinity, alignment: .leading)
                Text("course grade").frame(maxWidth: .infinity, alignment: .leading)
                Text("grade").frame(width: 44, alignment: .trailing)
            }
            .font(Theme.font(10.5, .heavy))
            .kerning(0.42)
            .textCase(.uppercase)
            .foregroundStyle(G.muted2)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            ForEach(Self.ladder, id: \.self) { score in
                let grade = course(ifFinal: score)
                let hit = grade >= Double(target)
                HStack {
                    Text("\(score)%")
                        .foregroundStyle(G.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(format: "%.1f%%", grade))
                        .foregroundStyle(G.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(letter(grade))
                        .font(Theme.font(15, .black))
                        .foregroundStyle(hit ? G.hitInk : G.muted2)
                        .frame(width: 44, alignment: .trailing)
                }
                .font(Theme.font(15, .heavy))
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(hit ? G.hitBg : .clear))
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card(28))
    }

    // MARK: - Your term

    /// One row under the free what-if: every course at once, on a 4.0 scale.
    ///
    /// The what-if above stays free and untouched. This is a tool and not a grade —
    /// it reads the percentages already on the phone and does arithmetic. Nothing
    /// here changes a mark or talks to Canvas.
    @ViewBuilder private var termCard: some View {
        let scored = state.courses.compactMap(\.score)
        if !scored.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Your term")
                        .font(Theme.font(15, .black))
                        .foregroundStyle(G.ink)
                    Spacer()
                    if state.isPlus, let gpa = GradeProjection.termGPA(scored) {
                        Text(GradeProjection.format(gpa))
                            .font(Theme.font(22, .black))
                            .foregroundStyle(G.ink)
                    }
                }

                if state.isPlus {
                    ForEach(state.courses.filter { $0.score != nil }, id: \.id) { c in
                        HStack(spacing: 8) {
                            Text(c.code.isEmpty ? c.name : c.code)
                                .font(Theme.font(12.5, .heavy))
                                .foregroundStyle(G.ink2)
                                .lineLimit(1)
                            Spacer(minLength: 6)
                            Text(GradeProjection.letter(forPercent: c.score ?? 0))
                                .font(Theme.fixedFont(11.5, .black))
                                .foregroundStyle(G.muted)
                            Text(String(format: "%.1f", GradeProjection.points(forPercent: c.score ?? 0)))
                                .font(Theme.fixedFont(11.5, .black))
                                .foregroundStyle(G.ink)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                    Text("Unweighted, every course once. Canvas does not send credit hours.")
                        .font(Theme.font(10.5, .heavy))
                        .foregroundStyle(G.muted2)
                        .fixedSize(horizontal: false, vertical: true)

                    goalRow
                } else {
                    Button { showingPlus = true } label: {
                        HStack(spacing: 8) {
                            Text("Your GPA for the term, and a target you set per course")
                                .font(Theme.font(12.5, .heavy))
                                .foregroundStyle(G.ink2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            Text("Plus")
                                .font(Theme.fixedFont(10, .black))
                                .foregroundStyle(G.coral)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(card(28))
            .sheet(isPresented: $showingPlus) { PlusSheet(reason: .grades) }
        }
    }

    /// A target for the course the what-if above is about, and what is still needed
    /// to land it. Three honest answers and no fourth: already there, this average,
    /// or out of reach — never a percentage over 100.
    @ViewBuilder private var goalRow: some View {
        if let c = course, let score = c.score {
            Divider().padding(.vertical, 2)
            HStack(spacing: 10) {
                Text("Aiming for")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(G.ink2)
                Spacer(minLength: 4)
                ForEach([90.0, 80.0, 70.0], id: \.self) { t in
                    Button { goal = (goal == t) ? nil : t } label: {
                        Text(GradeProjection.letter(forPercent: t))
                            .font(Theme.fixedFont(11, .black))
                            .foregroundStyle(goal == t ? .white : G.ink2)
                            .frame(width: 32, height: 26)
                            .background(Capsule().fill(goal == t ? G.coral : G.well))
                    }
                    .buttonStyle(.plain)
                }
            }
            if let goal {
                Text(GradeProjection.line(
                    GradeProjection.need(current: score, target: goal, remainingWeight: w),
                    target: goal
                ))
                .font(Theme.font(12, .heavy))
                .foregroundStyle(G.hitInk)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Shared bits

    private func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int { min(hi, max(lo, v)) }

    private func card(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Theme.card)
            .shadow(color: G.ink.opacity(0.10), radius: 12, y: 8)
    }

    private func roundButton(_ glyph: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(glyph)
                .font(Theme.font(17, .black))
                .foregroundStyle(G.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(G.well))
        }
        .buttonStyle(.plain)
    }
}
