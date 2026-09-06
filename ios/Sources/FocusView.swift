import SwiftUI

/// Focus is a *shift*: Sprout clocks in and swims upstream in his own lagoon for
/// as long as the student stays off their phone. Finishing pays 1 coin a minute.
/// Clocking out early pays nothing: the coins stay in the reef (Focus Friend's
/// rule, George 2026-09-06). It is said plainly and never scolded.
///
/// The running screen's layout follows `design/handoff/focus-shift-van/README.md`
/// (chrome mapped onto the app's own tokens); the van scene it drew was replaced
/// by `SwimSceneView` on 2026-09-03 — the kin is a fish, so the shift is a swim.
struct FocusView: View {
    @EnvironmentObject var state: AppState

    @State private var minutes = 25
    private var scene: Scene0 { Scene0.find(state.sceneID) }
    @State private var phase: Phase = .ready
    /// Shift time from legs already finished, plus when the current leg started.
    /// Split this way so a pause freezes both the clock and the scene, and a
    /// resume carries on without a jump.
    @State private var banked: TimeInterval = 0
    @State private var legStart: Date?
    @State private var total: TimeInterval = 0
    @State private var pairedTask: DailyTask?
    @State private var confirmingClockOut = false
    @State private var now = Date()

    private enum Phase { case ready, running, paused }

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// A length every 90 seconds. The scene's float passes Sprout on this tick.
    private static let secondsPerMile: TimeInterval = SwimSceneView.secondsPerLength

    var body: some View {
        NavigationStack {
            Group {
                if phase == .ready { readyScreen } else { shiftScreen }
            }
            .background(phase == .ready ? Theme.paper : Theme.card)
            .toolbar(.hidden, for: .navigationBar)
            .onReceive(ticker) { t in
                now = t
                if phase == .running && remaining <= 0 { finish() }
            }
            // The float has just passed: one bounce, off the same tick the count
            // uses, so the two can never drift apart.
            .onChange(of: miles) { old, new in
                if phase == .running && new > old { state.play(.bounce) }
            }
            .onChange(of: phase) { _, new in state.hideTabBar = new != .ready }
            .onDisappear { state.hideTabBar = false }
        }
    }

    // MARK: - Ready

    private var readyScreen: some View {
        VStack(spacing: 0) {
            Text("Focus")
                .font(Theme.font(34, .black))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Sprout on a still, low-contrast band of the student's own tank, so
            // Focus reads as the same world as Home and Kin without a second live
            // tank. Idle stays plain on purpose: the scene belongs to the shift
            // (design/handoff/focus-shift-van).
            SproutImage(speciesID: state.activeChibiID,
                        level: state.activeChibi.level,
                        animation: state.animation,
                        size: 190)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Image(scene.asset)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.5)
                        .overlay(LinearGradient(
                            colors: [Theme.paper, Theme.paper.opacity(0), Theme.paper.opacity(0), Theme.paper],
                            startPoint: .top, endPoint: .bottom))
                )
                .clipped()
                .padding(.horizontal, -24)

            Text("\(minutes) min")
                .font(Theme.font(56, .black))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .animation(.snappy, value: minutes)
                .padding(.top, 22)

            // Three lengths, the same three the Canvas extension offers, with 25
            // already chosen. The − / + steppers came out on 2026-09-06: a second
            // way to set the same number (design/hicks-law-plan.md).
            HStack(spacing: 8) {
                ForEach([15, 25, 45], id: \.self) { m in
                    Button { minutes = m } label: {
                        Text("\(m)")
                            .font(Theme.font(14.5, .black))
                            .foregroundStyle(minutes == m ? Theme.onDarkWarm : Theme.ink)
                            .frame(width: 56, height: 36)
                            .background(Capsule().fill(minutes == m ? Theme.ink : Theme.card)
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2))
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 14)

            HStack(spacing: 6) {
                CoinDisc(size: 15)
                Text("+\(minutes) coins for finishing")
                    .font(Theme.font(13.5, .heavy))
                    .foregroundStyle(Theme.coinDark)
            }
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(Capsule().fill(Theme.coinSoft))
            .padding(.top, 16)

            Spacer()

            Button { start() } label: {
                Text("Start focus")
                    .font(Theme.font(17, .heavy))
                    .foregroundStyle(Theme.onDarkWarm)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
        }
        .padding(24)
        .padding(.bottom, 104)
    }

    // MARK: - On shift

    /// The handoff is drawn for a 390x844 phone, which leaves 781pt inside the
    /// safe area. Shorter phones shrink the gaps, the scene and the display type
    /// by the same factor so the rhythm survives instead of clipping; the button
    /// block never scales, so it stays tappable.
    private var shiftScreen: some View {
        GeometryReader { geo in
            let scale = max(0.6, min(1, (geo.size.height - 135) / 646))
            shiftContent(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func shiftContent(_ k: CGFloat) -> some View {
        VStack(spacing: 0) {
            // The handoff also puts a Strict / Sound off segment on the left of
            // this row. Both are pre-session settings that do not exist yet and
            // are display-only during a shift, so the row carries the one live
            // chip rather than two dead ones.
            HStack {
                Spacer()
                bestShiftChip
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            Text("\(state.activeChibi.displayName) is on shift")
                .font(Theme.font(27 * k, .black))
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .padding(.top, 30 * k)
            Text("Put the phone down and let them work")
                .font(Theme.font(14.5 * k, .heavy))
                .foregroundStyle(Theme.tabInk)
                .padding(.top, 7 * k)

            scene(k)
                .padding(.top, 28 * k)

            Text(clockText(Int(remaining)))
                .font(Theme.font(66 * k, .black))
                .tracking(-3.2)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .padding(.top, 36 * k)

            progressBar(k)
                .padding(.top, 16 * k)

            countBlock(k)
                .padding(.top, 28 * k)

            Spacer(minLength: 0)

            VStack(spacing: 9) {
                Button { phase == .running ? pause() : resume() } label: {
                    Text(phase == .running ? "Pause" : "Resume")
                        .font(Theme.font(16, .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.coral))
                }
                Button { confirmingClockOut = true } label: {
                    Text("Clock out early")
                        .font(Theme.font(14.5, .heavy))
                        .foregroundStyle(Theme.bagInk)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        // The handoff's quit sheet. Dismissing it any way — the button, a tap
        // outside — leaves the shift running, so only the pay button clocks out.
        .sheet(isPresented: $confirmingClockOut) { quitSheet }
    }

    private var quitSheet: some View {
        VStack(spacing: 0) {
            Text("Clock out early?")
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
                .padding(.top, 32)

            Text(paidMinutes > 0
                 ? "\(paidMinutes) coin\(paidMinutes == 1 ? "" : "s") waiting for the end of this shift. Clock out now and they stay in the reef."
                 : "Nothing is waiting yet. Coins are paid when the shift ends.")
                .font(Theme.font(15, .bold))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.hex(0x7C6F68))
                .padding(.top, 10)
                .padding(.horizontal, 8)

            Spacer(minLength: 16)

            Button { clockOut() } label: {
                Text("Clock out early")
                    .font(Theme.font(16, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())

            Button { confirmingClockOut = false } label: {
                Text("Keep working")
                    .font(Theme.font(14.5, .heavy))
                    .foregroundStyle(Theme.bagInk)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .presentationDetents([.height(256)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(26)
    }

    /// The scene runs off its own timeline so the water is smooth, not once-a-second.
    private func scene(_ k: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Always animating: the reef's own life (bubbles, fish, crabs) keeps
            // moving while he sleeps. `elapsed` freezes on pause, so the floor holds.
            TimelineView(.animation) { ctx in
                SwimSceneView(time: elapsed(at: ctx.date),
                              life: ctx.date.timeIntervalSinceReferenceDate,
                              speciesID: state.activeChibiID,
                              level: state.activeChibi.level,
                              animation: state.animation,
                              paused: phase == .paused,
                              size: 250 * k)
            }
            if let task = pairedTask {
                taskPill(task).offset(y: 6)
            }
        }
    }

    /// Coins earned so far. They are only paid if the whole shift finishes.
    private var waitingLine: String {
        switch paidMinutes {
        case 0: return "Coins are paid when the shift ends"
        case 1: return "1 coin waiting · paid when the shift ends"
        default: return "\(paidMinutes) coins waiting · paid when the shift ends"
        }
    }

    private var bestShiftChip: some View {
        HStack(spacing: 6) {
            lengthsIcon
            Text("\(state.bestShift)")
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.ink)
            Text("best shift")
                .font(Theme.font(11, .heavy))
                .foregroundStyle(Theme.bagInk)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Theme.checkFill))
    }

    /// A best shift counts lengths, not coins. The chip used to wear the scene's
    /// float, and the float is coin gold — beside a bare number that made the
    /// record read as a wallet. These are the scene's own current lines instead:
    /// water gone by, in the lagoon's green, which no one reads as pay.
    private var lengthsIcon: some View {
        VStack(alignment: .leading, spacing: 2.5) {
            Capsule().fill(Theme.mintDark).frame(width: 13, height: 2)
            Capsule().fill(Theme.mintDark).frame(width: 8, height: 2)
            Capsule().fill(Theme.mintDark).frame(width: 11, height: 2)
        }
        .frame(width: 13, height: 11, alignment: .leading)
    }

    /// The handoff pairs the shift with a Canvas task and never wraps the pill, so
    /// the strings are cut to length here rather than left to the layout — that
    /// keeps the pill hugging its content the way the frame draws it.
    private func taskPill(_ task: DailyTask) -> some View {
        HStack(spacing: 8) {
            Circle().fill(Reef.float).frame(width: 7, height: 7)
            Text(clipped(task.title, to: 22))
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.ink)
            if let code = courseCode(for: task) {
                Text(code)
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.bagInk)
            }
        }
        .lineLimit(1)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Theme.card)
                .shadow(color: Color.black.opacity(0.13), radius: 5, y: 3)
        )
    }

    /// Only a genuine course code goes in the pill. Canvas course *names* run to
    /// whole sentences ("Thayer Welcome and Orientation"), and a sentence sliced
    /// to nine characters tells the student nothing — the title alone is better.
    private func courseCode(for task: DailyTask) -> String? {
        guard let name = task.detail,
              let code = state.courses.first(where: { $0.name == name })?.code,
              !code.isEmpty, code.count <= 12
        else { return nil }
        return code
    }

    private func clipped(_ text: String, to limit: Int) -> String {
        text.count <= limit ? text
            : text.prefix(limit).trimmingCharacters(in: .whitespaces) + "…"
    }

    /// 250pt track to match the scene circle above it. The handoff's optional
    /// milestone tick is left off — there are no breaks inside a shift yet.
    private func progressBar(_ k: CGFloat) -> some View {
        let width: CGFloat = 250 * k
        let done = total > 0 ? min(1, elapsed(at: now) / total) : 0
        return ZStack(alignment: .leading) {
            Capsule().fill(Theme.checkBorder)
                .frame(width: width, height: 9)
            Capsule().fill(Theme.coin)
                .frame(width: width * done, height: 9)
            Circle().fill(Theme.card)
                .frame(width: 17, height: 17)
                .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
                .overlay(Circle().fill(Theme.coinBorder).frame(width: 7, height: 7))
                .offset(x: width * done - 8.5)
        }
        .frame(width: width, height: 17)
    }

    private func countBlock(_ k: CGFloat) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("\(miles)")
                    .font(Theme.font(34 * k, .black))
                    .tracking(-1.4)
                    .foregroundStyle(Theme.ink)
                Text(miles == 1 ? "length swum" : "lengths swum")
                    .font(Theme.font(14.5 * k, .heavy))
                    .foregroundStyle(Theme.tabInk)
            }
            Text("NEXT IN \(clockText(nextMileIn))")
                .font(Theme.font(11.5 * k, .heavy))
                .tracking(0.3)
                .foregroundStyle(Theme.bagInk)
            Text(waitingLine)
                .font(Theme.font(11.5 * k, .heavy))
                .foregroundStyle(Theme.coinDark)
        }
    }

    // MARK: - Shift clock

    private func elapsed(at date: Date) -> TimeInterval {
        let live = legStart.map { date.timeIntervalSince($0) } ?? 0
        return min(total, banked + max(0, live))
    }

    private var remaining: TimeInterval { max(0, total - elapsed(at: now)) }
    private var miles: Int { Int(elapsed(at: now) / Self.secondsPerMile) }
    private var paidMinutes: Int { Int(elapsed(at: now) / 60) }

    private var nextMileIn: Int {
        let into = elapsed(at: now).truncatingRemainder(dividingBy: Self.secondsPerMile)
        return Int((Self.secondsPerMile - into).rounded(.up))
    }

    private func clockText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Actions

    private func start() {
        total = TimeInterval(minutes * 60)
        banked = 0
        legStart = Date()
        now = Date()
        // Whatever is next on today's list rides along, so the shift is tied to a
        // real piece of work rather than an anonymous timer.
        pairedTask = state.tasks.first { !$0.done }
        phase = .running
        state.play(.wave)
    }

    private func pause() {
        banked = elapsed(at: Date())
        legStart = nil
        phase = .paused
    }

    private func resume() {
        legStart = Date()
        phase = .running
        state.play(.startle)
    }

    private func finish() {
        settle(minutes: minutes, miles: Int(total / Self.secondsPerMile))
    }

    /// Nothing is paid: the coins stay in the reef. The lengths still count,
    /// because that number only ever goes up.
    private func clockOut() {
        settle(minutes: 0, miles: miles)
    }

    /// Pays wages, banks the miles, and hands the screen back to the ready state.
    private func settle(minutes paid: Int, miles driven: Int) {
        legStart = nil
        banked = 0
        total = 0
        phase = .ready
        pairedTask = nil
        // The timer can run out while "Clock out early?" is still up.
        confirmingClockOut = false
        state.recordShift(miles: driven)
        if paid > 0 {
            state.recordFocus(minutes: paid)
        } else {
            state.play(.wave)
        }
    }
}
