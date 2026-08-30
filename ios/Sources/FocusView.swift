import SwiftUI

/// Focus is a *shift*: Kin clocks into a delivery job and drives for as long as
/// the student stays off their phone. Finishing pays 1 coin a minute; clocking
/// out early pays for the minutes actually worked.
///
/// The running screen follows `design/handoff/focus-shift-van/README.md`, with
/// the handoff's amber-and-near-black chrome mapped onto the app's own tokens
/// (coral action, coin yellow fill). Deviations are noted at each site.
struct FocusView: View {
    @EnvironmentObject var state: AppState

    @State private var minutes = 25
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

    /// A mile every 90 seconds, from the handoff.
    private static let secondsPerMile: TimeInterval = 90

    var body: some View {
        NavigationStack {
            Group {
                if phase == .ready { readyScreen } else { shiftScreen }
            }
            .background(phase == .ready ? Theme.paper : Theme.card)
            .navigationTitle("Focus")
            .toolbar(phase == .ready ? .visible : .hidden, for: .navigationBar)
            .onReceive(ticker) { t in
                now = t
                if phase == .running && remaining <= 0 { finish() }
            }
            .onChange(of: phase) { _, new in state.hideTabBar = new != .ready }
            .onDisappear { state.hideTabBar = false }
        }
    }

    // MARK: - Ready

    private var readyScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            SlimeView(color: Theme.species(state.activeChibiID),
                      level: state.activeChibi.level,
                      animation: state.animation,
                      size: 160)

            Text("\(minutes) min")
                .font(Theme.font(56, .bold))
                .foregroundStyle(Theme.ink)
            Stepper("Session length", value: $minutes, in: 5...120, step: 5)
                .labelsHidden()
            Text("Finish and earn \(minutes) coins.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)

            Spacer()

            Button { start() } label: {
                Text("Start focus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.coral))
            }
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

            Text("\(state.activeChibi.species.name) is on shift")
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
        // The handoff hands clock-out to a quit sheet that has not been designed
        // yet; a confirmation dialog stands in and asks the same question.
        .confirmationDialog("Clock out early?", isPresented: $confirmingClockOut,
                            titleVisibility: .visible) {
            Button(payLabel) { clockOut() }
            Button("Keep working", role: .cancel) {}
        } message: {
            Text(paidMinutes > 0
                 ? "\(paidMinutes) min worked. That is what the shift pays."
                 : "The shift has not paid a minute yet.")
        }
    }

    /// The scene runs off its own timeline so the wheels and road are smooth,
    /// not once-a-second. Pausing the timeline freezes every part of the loop.
    private func scene(_ k: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            TimelineView(.animation(paused: phase != .running)) { ctx in
                ShiftSceneView(time: elapsed(at: ctx.date),
                               bodyColor: Theme.species(state.activeChibiID),
                               size: 250 * k)
            }
            if let task = pairedTask {
                taskPill(task).offset(y: 6)
            }
        }
    }

    private var payLabel: String {
        switch paidMinutes {
        case 0: return "Clock out — no pay yet"
        case 1: return "Clock out — keep 1 coin"
        default: return "Clock out — keep \(paidMinutes) coins"
        }
    }

    private var bestShiftChip: some View {
        HStack(spacing: 6) {
            parcelIcon
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

    private var parcelIcon: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(ShiftScene.parcel)
            .frame(width: 12, height: 9)
            .overlay(alignment: .leading) {
                Rectangle().fill(ShiftScene.cream)
                    .frame(width: 1.6)
                    .offset(x: 5.2)
            }
    }

    /// The handoff pairs the shift with a Canvas task and never wraps the pill, so
    /// the strings are cut to length here rather than left to the layout — that
    /// keeps the pill hugging its content the way the frame draws it.
    private func taskPill(_ task: DailyTask) -> some View {
        HStack(spacing: 8) {
            Circle().fill(ShiftScene.van).frame(width: 7, height: 7)
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
                Text(miles == 1 ? "mile driven" : "miles driven")
                    .font(Theme.font(14.5 * k, .heavy))
                    .foregroundStyle(Theme.tabInk)
            }
            Text("NEXT IN \(clockText(nextMileIn)) · BEST SHIFT \(state.bestShift)")
                .font(Theme.font(11.5 * k, .heavy))
                .tracking(0.3)
                .foregroundStyle(Theme.bagInk)
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
    }

    private func pause() {
        banked = elapsed(at: Date())
        legStart = nil
        phase = .paused
    }

    private func resume() {
        legStart = Date()
        phase = .running
    }

    private func finish() {
        settle(minutes: minutes, miles: Int(total / Self.secondsPerMile))
    }

    private func clockOut() {
        settle(minutes: paidMinutes, miles: miles)
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
