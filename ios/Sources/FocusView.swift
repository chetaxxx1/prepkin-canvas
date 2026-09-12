import SwiftUI

/// Focus is a *shift*: Sprout clocks in and swims the Reef Route for 15, 25 or 45
/// minutes. Finishing pays 1 coin a minute. Clocking out early pays **nothing** —
/// all or nothing (Focus Friend's rule, George 2026-09-06). It is said plainly and
/// never scolded.
///
/// The screen's whole promise is that it can be put face down. Since 2026-09-10 the
/// phone keeps that promise on its own: `FocusLiveActivity` puts the kin and the
/// countdown on the lock screen, and `NotificationPlanner.shiftEnd` says when it is
/// over. So the clock lives in `FocusShift` — a plain value — and this file only
/// draws it and tells those two about it.
///
/// The running screen's chrome follows `design/handoff/focus-shift-van/README.md`
/// mapped onto the app's tokens; the van scene it drew was replaced by
/// `SwimSceneView` on 2026-09-03 — the kin is a fish, so the shift is a swim.
struct FocusView: View {
    @EnvironmentObject var state: AppState

    @State private var minutes = 25
    /// The custom length field. Separate from `minutes` so typing a 6 on the way to
    /// 60 does not start a six-minute shift.
    @State private var customMinutes = 60
    /// Non-nil while the Plus sheet is up, and it carries which chip was tapped.
    @State private var plusReason: PlusSheet.Reason?
    /// The More sheet: 60, 90 and a typed length.
    @State private var showMore = false
    /// Set when a Plus length was picked without Plus, read when More has closed.
    @State private var moreWantsPlus = false
    private var scene: Scene0 { Scene0.find(state.sceneID) }
    @State private var shift = FocusShift()
    @State private var confirmingClockOut = false
    @State private var now = Date()
    /// The shift that just ended. While it is set, the tab is the report and nothing
    /// else — the one beat between finishing and going back to Ready.
    @State private var report: ShiftResult?
    /// Bumped when the report appears, so the kin plays its emote there rather than
    /// arriving with it already over.
    @State private var reportReplay = 0
    @State private var workingOn: WorkingOn = .auto
    @State private var pickingWorkingOn = false
    /// Nobody has ever been asked about notifications. Checked once on appearing so
    /// the first Start can explain itself instead of throwing the system prompt.
    @State private var askAboutAlerts = false
    @State private var explainingAlerts = false
    /// The ledger key for the shift that is running, minted at Start and written down
    /// with it, so a shift restored after a kill pays exactly once.
    @State private var sessionID = UUID().uuidString

    private var kinName: String { state.activeChibi.displayName }
    private var workingOnTask: DailyTask? { workingOn.resolve(in: state.tasks) }

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if let report { reportScreen(report) }
                else if shift.phase == .ready { readyScreen }
                else { shiftScreen }
            }
            .background(shift.phase == .ready && report == nil ? Theme.paper : Theme.card)
            .toolbar(.hidden, for: .navigationBar)
            .onReceive(ticker) { t in
                now = t
                if shift.phase == .running && shift.remaining(at: t) <= 0 { finish() }
            }
            // The marker has just passed: one bounce, off the same tick the count
            // uses, so the two can never drift apart. The lock screen is not told —
            // it carries the whole swim's length, which never changes.
            .onChange(of: lengths) { old, new in
                if shift.phase == .running && new > old { state.play(.bounce) }
            }
            // The report is full screen too, so the bar has to stay down for it and
            // come back only when the tab is genuinely idle. Both cases are written
            // the same way; a report that only ever *raised* the flag left the tab
            // bar hidden after Done.
            .onChange(of: shift.phase) { _, _ in syncTabBar() }
            .onChange(of: report != nil) { _, _ in syncTabBar() }
            // On appearing, not on a timer: a table of three friends is not worth a
            // poll, and a row is filtered again on read so a stale one cannot show.
            .task {
                restoreShiftIfAny()
                // Leaving the tab puts the bar back; coming back to a shift that is
                // still running has to take it away again, and no phase changed in
                // between for `onChange` to notice.
                syncTabBar()
                await state.refreshFriendsFocusing()
                askAboutAlerts = await NotificationScheduler.shared.isUndecided()
                // A shift the app was killed in the middle of leaves a fish on the
                // lock screen with nothing behind it. Opening the tab clears it.
                if shift.phase == .ready { FocusLiveActivity.endStrays() }
            }
            // Sitting down with a friend, asked for on their card in the Friends
            // tab. Only from the ready screen: a shift already running is not
            // something another screen gets to restart.
            .onChange(of: state.joinShiftRequest) { _, new in
                guard let new, shift.phase == .ready, report == nil else { return }
                minutes = new
                state.joinShiftRequest = nil
                start()
            }
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
                        skin: state.activeChibi.skinID,
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
                .accessibilityHidden(true)

            Text("\(minutes) min")
                .font(Theme.font(56, .black))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .animation(.snappy, value: minutes)
                .padding(.top, 22)
                .accessibilityHidden(true)

            // Three free lengths, the same three the Canvas extension offers, with
            // 25 already chosen. The − / + steppers came out on 2026-09-06: a second
            // way to set the same number (design/hicks-law-plan.md). 60, 90 and the
            // typed length came off the row on 2026-09-12 and live behind "More":
            // Forest's timer screen is one control and one button (Mobbin
            // bb4f30bc-843c-4c56-bb8a-214f44561588), and five chips plus a link was
            // three.
            HStack(spacing: 7) {
                ForEach(Self.chipLengths, id: \.self) { m in
                    lengthChip(m, plus: false)
                }
            }
            .padding(.top, 14)

            Button { showMore = true } label: {
                Text("More")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .underline()
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More lengths")

            // "25" is said by the readout and by the chip; the pill says the coins
            // and no more than that.
            HStack(spacing: 6) {
                CoinDisc(size: 15)
                Text("+\(minutes) coins")
                    .font(Theme.font(13.5, .heavy))
                    .foregroundStyle(Theme.coinDark)
            }
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(Capsule().fill(Theme.coinSoft))
            .padding(.top, 6)
            .accessibilityElement(children: .combine)

            workingOnChip
                .padding(.top, 14)

            // One line of words for the week, for everybody. The seven-bar graph
            // that Plus drew here said the same thing a second time.
            if let week = weekLine {
                Text(week)
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.bagInk)
                    .padding(.top, 12)
            }

            Spacer()

            atTheTable

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
        .padding(.bottom, Theme.tabClearance)
        .sheet(isPresented: $pickingWorkingOn) { workingOnSheet }
        .sheet(item: $plusReason) { PlusSheet(reason: $0) }
        .sheet(isPresented: $explainingAlerts) { alertsSheet }
        // A Plus length picked without Plus: the More sheet closes first, then the
        // Plus sheet opens. Presenting one sheet while another is still on screen
        // drops the second one.
        .sheet(isPresented: $showMore, onDismiss: {
            if moreWantsPlus { moreWantsPlus = false; plusReason = .focus }
        }) { moreSheet }
    }

    // MARK: - Lengths

    /// Free, and untouched. These three were free before Plus existed and are
    /// checked by `PlusGateTests` on every build.
    static let freeLengths = [15, 25, 45]
    /// The chip row, for everybody. Three chips, never more; the rest is behind More.
    static let chipLengths = freeLengths
    /// What the More sheet holds: two longer shifts and a typed length, all Plus.
    enum MoreItem: Equatable { case minutes(Int), typed }
    static let moreItems: [MoreItem] = [.minutes(60), .minutes(90), .typed]

    private func lengthChip(_ m: Int, plus: Bool) -> some View {
        let on = minutes == m
        return Button {
            guard !plus || state.isPlus else { moreWantsPlus = true; showMore = false; return }
            minutes = m
            if plus { showMore = false }
        } label: {
            VStack(spacing: 2) {
                Text("\(m)")
                    .font(Theme.font(14.5, .black))
                    .foregroundStyle(on ? Theme.onDarkWarm : (plus ? Theme.coralShade : Theme.ink))
                if plus && !state.isPlus {
                    Text("Plus")
                        .font(Theme.fixedFont(8.5, .black))
                        .foregroundStyle(on ? Theme.onDarkWarm : Theme.coralShade)
                }
            }
            .frame(width: 50, height: 36)
            .background(Capsule().fill(on ? Theme.ink : (plus && !state.isPlus ? Theme.coralSoft : Theme.card))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2))
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(plus && !state.isPlus ? "\(m) minutes, in Plus" : "\(m) minutes")
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    // MARK: - More

    /// The two longer shifts and a typed length, on one small sheet, the shape of
    /// Tiimo's duration picker (Mobbin 1620305c-a020-4cf4-8c42-4b9040d4ec8a): a
    /// title, the choices, nothing else. Everything on it is Plus, drawn in full
    /// colour with "Plus" under it, never greyed and never a padlock (`PLUS-SPEC.md`
    /// section 4); picking one without Plus opens the Plus sheet rather than refusing.
    private var moreSheet: some View {
        VStack(spacing: 0) {
            Text("More")
                .font(Theme.font(20, .black))
                .foregroundStyle(Theme.ink)
                .padding(.top, 26)

            HStack(spacing: 7) {
                ForEach(Self.moreItems.indices, id: \.self) { i in
                    if case .minutes(let m) = Self.moreItems[i] {
                        lengthChip(m, plus: true)
                    }
                }
            }
            .padding(.top, 18)

            typedLengthRow.padding(.top, 14)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .presentationDetents([.height(206)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(26)
    }

    /// Any length you type, between five minutes and four hours.
    @ViewBuilder
    private var typedLengthRow: some View {
        if state.isPlus {
            HStack(spacing: 8) {
                Text("Any length")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
                TextField("", value: $customMinutes, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(Theme.font(13.5, .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 52, height: 44)
                    .background(Capsule().fill(Theme.card).padding(.vertical, 7)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2))
                    .onChange(of: customMinutes) { _, new in
                        // Clamped rather than validated with a message: a shift is
                        // between five minutes and four hours, and typing 900 gets
                        // you 240 rather than an error.
                        minutes = min(240, max(5, new))
                    }
                Text("min")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
            }
        } else {
            Button { moreWantsPlus = true; showMore = false } label: {
                Text("Any length you type · Plus")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.coralShade)
                    .underline()
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// "3 shifts · 1h 15m", off the ledger, absent for a week with nothing in it.
    private var weekLine: String? {
        let week = state.game.ledger.focusWeek()
        guard let body = FocusWeek.line(shifts: week.shifts, minutes: week.minutes) else { return nil }
        return "This week · \(body)"
    }

    /// What is riding along. Defaults to the next undone task and can be swapped for
    /// any other, or for nothing at all. It shows on the shift screen and on the
    /// report, and it never goes anywhere near a friend (`StudySync` rule 3).
    private var workingOnChip: some View {
        Button { pickingWorkingOn = true } label: {
            HStack(spacing: 7) {
                Text("Working on")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.bagInk)
                Text(workingOnTask?.title ?? "Nothing in particular")
                    .font(Theme.font(13, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Theme.bagInk)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Capsule().fill(Theme.checkFill))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Working on \(workingOnTask?.title ?? "nothing in particular"). Change")
    }

    private var workingOnSheet: some View {
        NavigationStack {
            List {
                ForEach(state.tasks.filter { !$0.done }) { task in
                    Button {
                        workingOn = .task(task.id)
                        pickingWorkingOn = false
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(Theme.font(15, .heavy))
                                    .foregroundStyle(Theme.ink)
                                if let detail = task.detail {
                                    Text(detail)
                                        .font(Theme.font(12, .bold))
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                            Spacer(minLength: 8)
                            if workingOnTask?.id == task.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(Theme.mintDark)
                            }
                        }
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    workingOn = .nothing
                    pickingWorkingOn = false
                } label: {
                    Text("Nothing in particular")
                        .font(Theme.font(15, .heavy))
                        .foregroundStyle(Theme.bagInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("Working on")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(26)
    }

    /// Asked once, before the first shift ever starts, in one line. The student did
    /// not ask for reminders — they asked for a timer — so the line says what the
    /// permission is actually for, and both buttons start the shift either way.
    private var alertsSheet: some View {
        VStack(spacing: 0) {
            Text("Let the phone tell you when it's over?")
                .font(Theme.font(20, .black))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .padding(.top, 30)

            Text("So you can put the phone down and still know when it's over.")
                .font(Theme.font(15, .bold))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.hex(0x7C6F68))
                .padding(.top, 10)

            Spacer(minLength: 16)

            Button {
                explainingAlerts = false
                Task {
                    _ = await NotificationScheduler.shared.requestAuthorization()
                    askAboutAlerts = false
                    beginShift()
                }
            } label: {
                Text("Yes, tell me")
                    .font(Theme.font(16, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())

            Button {
                explainingAlerts = false
                askAboutAlerts = false
                beginShift()
            } label: {
                Text("Start without it")
                    .font(Theme.font(14.5, .heavy))
                    .foregroundStyle(Theme.bagInk)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .presentationDetents([.height(268)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(26)
    }

    // MARK: - Study Together

    /// Friends who are working right now, and one tap to sit down with them.
    ///
    /// The cheap version of `FRIENDS-PLAN.md` §3: **two independent timers.** Join
    /// starts YOUR clock at the nearest offered length, and after that the two
    /// sessions have nothing to do with each other. Nobody is told if you stop, and
    /// nobody is paid differently for having company.
    ///
    /// Absent, not empty, when nobody is working. A row that says "no friends are
    /// focusing" would turn a calm screen into a report on how alone you are.
    @ViewBuilder private var atTheTable: some View {
        let table = state.liveFocusPresences
        if let first = table.first {
            HStack(spacing: 10) {
                HStack(spacing: -12) {
                    ForEach(table.prefix(3)) { who in
                        SproutImage(speciesID: who.speciesID, level: who.level,
                                    skin: who.lookID, size: 34)
                            .frame(width: 34, height: 34)
                    }
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(tableTitle(table))
                        .font(Theme.font(13.5, .heavy))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Text(StudyTogether.line(for: first, at: now))
                        .font(Theme.font(11.5, .bold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 4)
                if let length = StudyTogether.joinLength(minutesLeft: first.minutesLeft(at: now)) {
                    Button {
                        minutes = length
                        start()
                    } label: {
                        Text("Join")
                            .font(Theme.font(13.5, .black))
                            .foregroundStyle(Theme.onDarkWarm)
                            .padding(.horizontal, 16).frame(height: 44)
                            .background(Capsule().fill(Theme.ink))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Join \(first.displayName) for \(length) minutes")
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2))
            .padding(.bottom, 14)
        }
    }

    /// One name, or a count. Never a list of names running off the edge.
    private func tableTitle(_ table: [FocusPresence]) -> String {
        guard let first = table.first else { return "" }
        if table.count == 1 { return first.displayName }
        return "\(first.displayName) and \(table.count - 1) more"
    }

    // MARK: - On shift

    /// The handoff is drawn for a 390x844 phone, which leaves 781pt inside the
    /// safe area. Shorter phones shrink the gaps, the scene and the display type
    /// by the same factor so the rhythm survives instead of clipping; the button
    /// block never scales, so it stays tappable.
    ///
    /// The divisor was 646, measured before the count block grew a third line. On a
    /// 17 Pro that left the column six points taller than the safe area, so the coin
    /// line ended up flush against the Pause button with no air at all. 680 is the
    /// column's real height, which gives the `Spacer` something to hand out.
    private var shiftScreen: some View {
        GeometryReader { geo in
            let scale = max(0.6, min(1, (geo.size.height - 135) / 680))
            shiftContent(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func shiftContent(_ k: CGFloat) -> some View {
        VStack(spacing: 0) {
            // The handoff also puts a Strict / Sound off segment on the left of
            // this row. Sound does not exist (the app has no audio), and Strict is
            // not built — under all-or-nothing pay, clocking a student out for
            // checking a text costs them the whole shift. See the rewritten brief,
            // `design/CLAUDE-DESIGN-PROMPT-FOCUS-CLOCKOUT.md`.
            HStack {
                if let task = workingOnTask { ridingAlongChip(task) }
                Spacer(minLength: 8)
                bestShiftChip
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            Text("\(kinName) is on shift")
                .font(Theme.font(27 * k, .black))
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .padding(.top, 30 * k)
            Text(FocusCopy.waitLine(kinName: kinName))
                .font(Theme.font(14.5 * k, .heavy))
                .foregroundStyle(Theme.tabInk)
                .padding(.top, 7 * k)

            scene(k)
                .padding(.top, 28 * k)
                .accessibilityLabel("\(kinName) swimming the Reef Route")

            Text(clockText(Int(shift.remaining(at: now))))
                .font(Theme.font(66 * k, .black))
                .tracking(-3.2)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .padding(.top, 36 * k)
                .accessibilityLabel("\(Int(shift.remaining(at: now)) / 60) minutes left")

            progressBar(k)
                .padding(.top, 16 * k)
                .accessibilityHidden(true)

            countBlock(k)
                .padding(.top, 28 * k)

            Spacer(minLength: 14)

            VStack(spacing: 9) {
                Button { shift.phase == .running ? pause() : resume() } label: {
                    Text(shift.phase == .running ? "Pause" : "Resume")
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
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        // Dismissing the sheet any way — the button, a tap outside — leaves the
        // shift running, so only the clock-out button clocks out.
        .sheet(isPresented: $confirmingClockOut) { quitSheet }
    }

    /// The clock-out sheet.
    ///
    /// The line used to say the waiting coins "stay in the reef", which a tired
    /// reader hears as *kept for you*. They are not kept; the shift pays nothing.
    /// So it says both halves of the truth in two short sentences, and **Keep
    /// working is the coral one** — the app's one primary button per screen should
    /// not be on the choice that pays zero. Never red, never "are you sure".
    private var quitSheet: some View {
        VStack(spacing: 0) {
            Text("Clock out early?")
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
                .padding(.top, 32)

            Text("Clock out now and this shift pays nothing. Finish it and it pays \(shift.plannedMinutes).")
                .font(Theme.font(15, .bold))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.hex(0x7C6F68))
                .padding(.top, 10)
                .padding(.horizontal, 8)

            Spacer(minLength: 16)

            Button { confirmingClockOut = false } label: {
                Text("Keep working")
                    .font(Theme.font(16, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())

            Button { clockOut() } label: {
                Text("Clock out")
                    .font(Theme.font(14.5, .heavy))
                    .foregroundStyle(Theme.bagInk)
                    .frame(maxWidth: .infinity, minHeight: 48)
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
                SwimSceneView(time: shift.elapsed(at: ctx.date),
                              life: ctx.date.timeIntervalSinceReferenceDate,
                              speciesID: state.activeChibiID,
                              level: state.activeChibi.level,
                              skin: state.activeChibi.skinID,
                              animation: state.animation,
                              paused: shift.phase == .paused,
                              size: 250 * k)
            }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Best shift, \(state.bestShift) lengths")
    }

    /// What rode along into the shift. Display only here — the report is where it
    /// can be ticked off, because that is where the work has actually happened.
    private func ridingAlongChip(_ task: DailyTask) -> some View {
        Text(task.title)
            .font(Theme.font(11.5, .heavy))
            .foregroundStyle(Theme.bagInk)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Theme.checkFill))
            .accessibilityLabel("Working on \(task.title)")
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

    /// 250pt track to match the scene circle above it. The handoff's optional
    /// milestone tick is left off — there are no breaks inside a shift yet.
    private func progressBar(_ k: CGFloat) -> some View {
        let width: CGFloat = 250 * k
        let done = shift.progress(at: now)
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
                Text("\(lengths)")
                    .font(Theme.font(34 * k, .black))
                    .tracking(-1.4)
                    .foregroundStyle(Theme.ink)
                Text(lengths == 1 ? "length swum" : "lengths swum")
                    .font(Theme.font(14.5 * k, .heavy))
                    .foregroundStyle(Theme.tabInk)
            }
            // Was "NEXT IN 4:12", which is shorthand for something the screen never
            // says out loud. It says it now.
            Text("Next length in \(clockText(shift.nextLengthIn(at: now)))")
                .font(Theme.font(11.5 * k, .heavy))
                .foregroundStyle(Theme.bagInk)
            Text("\(shift.plannedMinutes) coins when the shift ends")
                .font(Theme.font(11.5 * k, .heavy))
                .foregroundStyle(Theme.coinDark)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - The report

    /// One beat between a shift and the ready screen. Shown after the timer runs out
    /// **and** after a clock-out, where the pay line reads zero — a student who quit
    /// deserves the same plain arithmetic as one who finished.
    private func reportScreen(_ r: ShiftResult) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            // `replay`, not `animation`. The emote is chosen in `settle`, before this
            // screen exists, so `SproutImage`'s change-watcher has nothing to see and
            // the kin arrives already finished — a celebration nobody watches. The
            // bump on appearing is what actually plays it.
            SproutImage(speciesID: state.activeChibiID,
                        level: state.activeChibi.level,
                        skin: state.activeChibi.skinID,
                        animation: state.animation,
                        replay: reportReplay,
                        size: 200)
                .onAppear { reportReplay += 1 }
                .accessibilityHidden(true)

            Text(ShiftReportCopy.title(r))
                .font(Theme.font(15, .heavy))
                .foregroundStyle(Theme.bagInk)
                .padding(.top, 18)

            // The arithmetic, visible. "25 minutes. 25 coins." is the whole honesty
            // of the feature: a student can check it against the clock they watched.
            Text(ShiftReportCopy.payLine(r))
                .font(Theme.font(r.finished ? 30 : 22, .black))
                .tracking(-0.8)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .padding(.top, 6)
                .padding(.horizontal, 18)

            if r.paid > 0 {
                HStack(spacing: 6) {
                    CoinDisc(size: 16)
                    Text("+\(r.paid)")
                        .font(Theme.font(15, .black))
                        .foregroundStyle(Theme.coinDark)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(Theme.coinSoft))
                .padding(.top, 14)
                .accessibilityLabel("\(r.paid) coins paid")
            }

            VStack(spacing: 3) {
                Text(ShiftReportCopy.lengthsLine(r))
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Theme.tabInk)
                if let best = ShiftReportCopy.bestLine(r) {
                    Text(best)
                        .font(Theme.font(12.5, .heavy))
                        .foregroundStyle(Theme.mintDark)
                }
            }
            .padding(.top, 16)

            if let task = r.workingOn { markItDoneRow(task) }

            Spacer(minLength: 12)

            VStack(spacing: 9) {
                Button { report = nil } label: {
                    Text("Done")
                        .font(Theme.font(17, .heavy))
                        .foregroundStyle(Theme.onDarkWarm)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.coral))
                }
                .buttonStyle(PressStyle())

                Button {
                    report = nil
                    start()
                } label: {
                    Text("Another shift")
                        .font(Theme.font(14.5, .heavy))
                        .foregroundStyle(Theme.bagInk)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
    }

    /// The task that rode along. A Canvas assignment has no checkbox: Canvas has to
    /// see the submission before the app will say it is done, and a checkbox that
    /// lied about that would be the one dishonest control on the tab.
    @ViewBuilder private func markItDoneRow(_ task: DailyTask) -> some View {
        let done = state.tasks.first { $0.id == task.id }?.done ?? task.done
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(Theme.font(14, .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(task.kind == .canvas
                     ? (task.detail ?? "Canvas") + " · marks itself off when Canvas sees it"
                     : "Worth \(task.reward) coins")
                    .font(Theme.font(11.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            if task.kind != .canvas {
                Button { state.complete(task) } label: {
                    Text(done ? "Done" : "Mark it done")
                        .font(Theme.font(13, .black))
                        .foregroundStyle(done ? Theme.mintDark : Theme.onDarkWarm)
                        .padding(.horizontal, 14).frame(height: 44)
                        .background(Capsule().fill(done ? Theme.mintSoft : Theme.ink))
                }
                .buttonStyle(.plain)
                .disabled(done)
                .accessibilityLabel(done ? "\(task.title), done" : "Mark \(task.title) done, \(task.reward) coins")
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2))
        .padding(.top, 18)
    }

    // MARK: - Shift clock

    private var lengths: Int { shift.lengths(at: now) }

    private func syncTabBar() {
        state.hideTabBar = report != nil || shift.phase != .ready
    }

    private func clockText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Actions

    /// The first Start ever explains the notification once, then starts the shift
    /// whichever way that goes. Every Start after it goes straight through.
    private func start() {
        if askAboutAlerts {
            explainingAlerts = true
            return
        }
        beginShift()
    }

    private func beginShift() {
        let at = Date()
        sessionID = UUID().uuidString
        shift.start(minutes: minutes, at: at)
        now = at
        report = nil
        writeDownShift()
        state.play(.wave)
        bookTheEnd(at: at)
        FocusLiveActivity.start(kinName: kinName, kinAsset: kinAsset, shift: shift, now: at)
        // Friends can see the row from here. Fire and forget: this clock never waits
        // on the bridge, and a session nobody could see still pays the same.
        state.announceFocus(minutes: minutes)
    }

    private func pause() {
        shift.pause(at: Date())
        writeDownShift()
        NotificationScheduler.shared.cancelShiftEnd()
        FocusLiveActivity.update(shift: shift)
    }

    private func resume() {
        let at = Date()
        shift.resume(at: at)
        now = at
        writeDownShift()
        state.play(.startle)
        bookTheEnd(at: at)
        FocusLiveActivity.update(shift: shift, now: at)
    }

    private func writeDownShift() {
        ShiftStore.save(SavedShift(id: sessionID,
                                   minutes: shift.plannedMinutes,
                                   banked: shift.banked,
                                   legStart: shift.legStart,
                                   workingOnID: {
                                       if case .task(let id) = workingOn { return id }
                                       return nil
                                   }(),
                                   workingOnCleared: workingOn == .nothing))
        // The widget's "On shift" line reads the same record.
        state.refreshWidget()
    }

    /// Picks the tab back up where it was.
    ///
    /// Three cases. Nothing written down: a normal open. A shift that still has time
    /// on it: put it back, with its lock screen and its alarm, because the student
    /// never ended it — the phone did. A shift whose time ran out while the app was
    /// gone: pay it and show the report, because the notification already told them
    /// it was paid and that has to be true.
    private func restoreShiftIfAny() {
        guard shift.phase == .ready, report == nil, let saved = ShiftStore.load() else { return }
        let at = Date()
        sessionID = saved.id
        workingOn = saved.workingOn
        shift = saved.shift()
        now = at

        if shift.remaining(at: at) <= 0 {
            settle(finished: true)
            return
        }
        FocusLiveActivity.start(kinName: kinName, kinAsset: kinAsset, shift: shift, now: at)
        bookTheEnd(at: at)
    }

    private var kinAsset: String {
        SproutImage.asset(speciesID: state.activeChibiID,
                          level: state.activeChibi.level,
                          skin: state.activeChibi.skinID)
    }

    /// Books — or re-books — the end of the shift. `shiftEnd` returns nil for
    /// anything that is not counting down, so a paused shift simply clears the queue.
    private func bookTheEnd(at date: Date) {
        guard let item = NotificationPlanner.shiftEnd(for: shift, kinName: kinName, now: date) else {
            NotificationScheduler.shared.cancelShiftEnd()
            return
        }
        Task { await NotificationScheduler.shared.scheduleShiftEnd(item, from: date) }
    }

    private func finish() {
        settle(finished: true)
    }

    /// Nothing is paid. The lengths still count, because that number only ever goes up.
    private func clockOut() {
        confirmingClockOut = false
        settle(finished: false)
    }

    /// Pays, banks the lengths, takes the shift off the lock screen and the
    /// notification queue, and hands the screen to the report.
    private func settle(finished: Bool) {
        let at = Date()
        let planned = shift.plannedMinutes
        let worked = Int(shift.elapsed(at: at) / 60)
        let swum = finished ? FocusShift.lengths(inMinutes: planned) : shift.lengths(at: at)
        let result = ShiftResult(minutes: finished ? planned : worked,
                                 paid: finished ? planned : 0,
                                 lengths: swum,
                                 finished: finished,
                                 beatBest: swum > state.bestShift,
                                 workingOn: workingOnTask)

        shift.clear()
        confirmingClockOut = false
        ShiftStore.clear()
        NotificationScheduler.shared.cancelShiftEnd()
        FocusLiveActivity.end()
        state.endFocusAnnouncement()
        state.recordShift(miles: swum)
        if result.paid > 0 {
            // `recordFocus` plays celebrate at 25 minutes or more, bounce below.
            // The session id is the ledger key, so a restored shift pays once.
            state.recordFocus(minutes: result.paid, sessionID: sessionID)
        } else {
            state.play(.wave)
        }
        report = result
    }
}
