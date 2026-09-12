import SwiftUI

/// The Calendar tab: what is coming, on days. Home is "what do I do right now";
/// this is the same work laid out on its due days, plus the course calendar's
/// events and anything the student put on a day themselves.
///
/// Built to `design/handoff-calendar-v2/README.md` (turn 3 of the prototype).
/// The spine is Things 3's Upcoming: **only days with something on them exist
/// on screen**, and a run of empty days is one folded line. Over it, Outlook's
/// month name as the title and a seven-day ticker whose load marks are the
/// course-coloured objects themselves (Structured). The month opens as a sheet
/// — no drag handle, no Week · Month switch — and a day opens into a timeline
/// with class blocks and a now-line (Structured, Saturn). Anything still open
/// from earlier sits in one **Still counts** group at the top, the way Todoist
/// groups overdue. One floating `+` opens quick add; no camera anywhere,
/// because the reader is not deployed (`ScanClient.isDeployed`).
struct CalendarView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var plus: PlusStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The day the month grid, the agenda scroll and the `+` agree on.
    @State private var selected: DayKey = .today()
    /// The week the ticker shows, as any date inside it; paged by swipe.
    @State private var tickerWeek: Date = Date()
    @State private var monthSheet = false
    /// Non-nil while the day timeline is pushed.
    @State private var timelineDay: DayKey?
    /// The one overdue row whose Move action is showing.
    @State private var swipedRowID: String?
    /// The typed task the Move action is re-dating.
    @State private var moving: DatedTask?
    /// Folded runs the student opened in place.
    @State private var opened: Set<String> = []
    /// Bumped whenever the agenda should bring `selected` to the top.
    @State private var scrollTick = 0
    /// The day the `+` sheet is adding to. Non-nil while that sheet is up.
    @State private var adding: AddTarget?
    @State private var editing: TaskEditorSheet.Mode?
    @State private var showScan = false
    @State private var showPlus = false
    /// Which entry point opened the sheet. The top third of it changes with this.
    @State private var plusReason: PlusSheet.Reason = .scan
    @State private var exportFile: ExportFile?
    @State private var showCalc = false
    @State private var showPairing = false
    @State private var flights: [CoinFlight] = []
    @State private var walletFrame: CGRect = .zero
    @State private var rewardFrames: [String: CGRect] = [:]

    private let cal = Calendar.current

    /// The tab bar's own height above the safe area, and the values the handoff
    /// measures from the bottom of the screen, less the home indicator.
    private enum L {
        static let tabBar: CGFloat = 58
        static let scrollInset: CGFloat = 200
        static let fabBottom: CGFloat = 78
    }

    private var feed: CalendarFeed { CalendarFeed(state: state) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    titleRow
                    ticker
                    agenda
                }

                fade
                fab
            }
            .coordinateSpace(name: "calendar")
            .onPreferenceChange(WalletFrameKey.self) { walletFrame = $0 }
            .onPreferenceChange(RewardFrameKey.self) { rewardFrames = $0 }
            .overlay {
                ForEach(flights) { flight in
                    FlyingCoin(flight: flight)
                }
                .allowsHitTesting(false)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $timelineDay) { day in
                DayTimelineView(day: day)
            }
        }
        .sheet(isPresented: $monthSheet, onDismiss: followSelected) {
            MonthSheet(selected: $selected,
                       onOpenDay: { day in
                           monthSheet = false
                           later { timelineDay = day }
                       },
                       onAdd: { day in
                           monthSheet = false
                           later { adding = AddTarget(day: day) }
                       },
                       onCheck: toggle)
            .environmentObject(state)
        }
        .sheet(item: $adding) { target in
            QuickAddSheet(day: target.day, minute: target.minute, onMore: { draft in
                adding = nil
                later { editing = .draft(draft) }
            }, onPhoto: {
                adding = nil
                openScan()
            }, isPlus: isPlus)
            .environmentObject(state)
        }
        .sheet(item: $editing) { mode in
            TaskEditorSheet(mode: mode) { day in
                // Land on the day it went on, so the new row is on screen.
                withAnimation(pageMotion) { land(on: day) }
            }
            .environmentObject(state)
        }
        .sheet(item: $moving) { task in
            WhenSheet(day: Binding(get: { moving?.day ?? task.day }, set: { move(task, to: $0) }),
                      minute: Binding(get: { moving?.minute ?? task.minute }, set: { move(task, at: $0) }))
        }
        .sheet(isPresented: $showScan) {
            ScanSheet(onType: { showScan = false; openAdd(on: selected) })
                .environmentObject(state).environmentObject(plus)
        }
        .sheet(isPresented: $showPlus) {
            PlusSheet(reason: plusReason).environmentObject(plus)
        }
        .sheet(item: $exportFile) { file in
            ShareLinkSheet(url: file.url)
        }
        .sheet(isPresented: $showCalc) { GradeCalcView().environmentObject(state) }
        .sheet(isPresented: $showPairing) { DayEditorView().environmentObject(state) }
        .onAppear { land(onRequestedDay: true) }
        // Home's Tomorrow line asked for a day. Arriving while this tab is already
        // on screen has no onAppear, so the change is watched too.
        .onChange(of: state.openCalendarOn) { _, _ in land(onRequestedDay: false) }
    }

    /// Move to the day Home asked for, and clear the request so a later visit to
    /// this tab opens on today again.
    private func land(onRequestedDay immediate: Bool) {
        guard let day = state.openCalendarOn else { return }
        if immediate { land(on: day) } else { withAnimation(pageMotion) { land(on: day) } }
        state.openCalendarOn = nil
    }

    private func land(on day: DayKey) {
        selected = day
        if let d = day.date() { tickerWeek = d }
        scrollTick += 1
    }

    /// Something presented from inside a sheet that is on its way out — a sheet
    /// raised in the same turn as another is dropped.
    private func later(_ work: @escaping () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            work()
        }
    }

    // MARK: - Title row

    /// The month, not the word "Calendar" — the tab bar already says that, and the
    /// ticker under it can show you days but never which month they are in. The
    /// chevron opens the month; the pill comes back when the ticker has left
    /// today's week.
    private var titleRow: some View {
        HStack(spacing: 6) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                monthSheet = true
            } label: {
                HStack(alignment: .lastTextBaseline, spacing: 7) {
                    Text(monthName(tickerMiddle))
                        .font(Theme.font(34, .black))
                        .foregroundStyle(Theme.ink)
                        // One line, always: when the Today pill is up beside a fat
                        // coin badge, "September" shrinks rather than breaks or
                        // trails off — Outlook's header does the same.
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Theme.muted)
                }
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(monthName(tickerMiddle)). Opens the month.")

            Spacer(minLength: 4)

            // The pill takes the share button's slot while the ticker is away
            // from today's week, so the title never has to shrink past reading
            // size to make room for both beside a fat coin badge.
            if !tickerHoldsToday {
                Button {
                    goToday()
                } label: {
                    Text("Today")
                        .font(Theme.font(12.5, .black))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 13)
                        .frame(height: 32)
                        .background(Capsule().fill(Theme.paperSunk))
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel("Back to today")
            } else {
                exportButton
            }
            CoinBadge(coins: state.coins)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: WalletFrameKey.self,
                                           value: geo.frame(in: .named("calendar")))
                })
        }
        .animation(pageMotion, value: tickerHoldsToday)
        .padding(.horizontal, Theme.gutter)
        .frame(height: 44)
        .padding(.bottom, 4)
    }

    // MARK: - Out to a real calendar

    /// Dated work, sent out to the calendar the student already uses.
    ///
    /// Two ways and no third: Apple Calendar through EventKit, and a file any other
    /// calendar imports — Google's included. There is no Google account anywhere in
    /// this, which is the point (`PLUS-SPEC.md` signature 5).
    private var exportButton: some View {
        Menu {
            Button("Add to Apple Calendar") { sendToCalendar() }
                .disabled(state.game.datedTasks.isEmpty)
            Button("Save a calendar file") { shareFile() }
                .disabled(state.game.datedTasks.isEmpty)
            // The grade calculator's second door (`GradeCalcView.doors`), since
            // it came off Home. The two export rows still need dated work; this
            // one never did, so the menu itself stays open.
            if GradeCalcView.doors.contains(.calendarExport) {
                Divider()
                Button("Grade calculator") { showCalc = true }
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(Theme.muted)
                .frame(width: 40, height: 44)
        }
        .accessibilityLabel("Send to a calendar, or the grade calculator")
    }

    /// Everything with a date on it. Undated work has nowhere to land in a calendar,
    /// so it is not sent and not mentioned.
    private var datedForExport: [DatedTask] { state.game.datedTasks }

    private func sendToCalendar() {
        guard isPlus else { showPlusFor(.calendarExport); return }
        Task { @MainActor in
            do {
                let n = try await CalendarExport.send(datedForExport)
                state.show(n == 1 ? "1 thing added to your calendar."
                                  : "\(n) things added to your calendar.")
            } catch CalendarExport.Failure.notAllowed {
                state.show("Prepkin can't add to your calendar yet. Turn it on in Settings.")
            } catch {
                state.show("That didn't go through. Nothing was added.")
            }
        }
    }

    private func shareFile() {
        guard isPlus else { showPlusFor(.calendarExport); return }
        do {
            exportFile = ExportFile(url: try CalendarExport.writeFile(datedForExport))
        } catch {
            state.show("That didn't go through. Nothing was saved.")
        }
    }

    private func showPlusFor(_ reason: PlusSheet.Reason) {
        plusReason = reason
        showPlus = true
    }

    // MARK: - The ticker

    /// Seven days, no card. Today is the one raised white card, so it still reads
    /// while the days already gone sit at 45%. The load under each number is the
    /// day's objects in course colour, chronological. A tap opens the day.
    private var ticker: some View {
        HStack(alignment: .top, spacing: 3) {
            ForEach(weekDays(from: tickerWeek), id: \.raw) { tickerDay($0) }
        }
        .padding(.horizontal, 12)
        .frame(height: 84, alignment: .top)
        .contentShape(Rectangle())
        .gesture(swipe)
        .animation(pageMotion, value: startOfWeek(tickerWeek))
    }

    private func tickerDay(_ day: DayKey) -> some View {
        let date = day.date() ?? Date()
        let isToday = day == .today()
        let isPast = day < .today()
        let marks = feed.load(on: day)
        return Button { open(day) } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(Theme.fixedFont(10, .black))
                    .tracking(0.4)
                    .foregroundStyle(isToday ? Theme.coralShade : Theme.muted)
                Text(date.formatted(.dateTime.day()))
                    .font(Theme.fixedFont(17, .black))
                    .foregroundStyle(isPast ? Theme.muted : Theme.ink)
                DayLoadGlyphs(marks: marks)
                    .frame(height: 14)
            }
            .padding(.top, 8).padding(.bottom, 9)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .fill(isToday ? Theme.card : .clear))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .strokeBorder(isToday ? Theme.cardEdge : .clear, lineWidth: 1))
            .opacity(isPast ? 0.45 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityValue(feed.loadLabel(on: day))
        .accessibilityHint("Opens the day")
    }

    /// True while the week on screen is the one today sits in.
    private var tickerHoldsToday: Bool { weekDays(from: tickerWeek).contains(.today()) }

    /// The middle of the week names the month, so a week that straddles two
    /// months is titled by the one most of it is in.
    private var tickerMiddle: Date { cal.date(byAdding: .day, value: 3, to: startOfWeek(tickerWeek)) ?? tickerWeek }

    // MARK: - Paging

    private func page(_ step: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(pageMotion) {
            let start = cal.date(byAdding: .weekOfYear, value: step, to: startOfWeek(tickerWeek)) ?? tickerWeek
            tickerWeek = start
            let days = weekDays(from: start)
            selected = days.contains(.today()) ? .today() : DayKey(start)
            scrollTick += 1
        }
    }

    private func goToday() {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(pageMotion) { land(on: .today()) }
    }

    /// The month sheet closed: the ticker follows the day picked in it, and the
    /// agenda brings that day to the top.
    private func followSelected() {
        withAnimation(pageMotion) { land(on: selected) }
    }

    private func open(_ day: DayKey) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        timelineDay = day
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { v in
                guard abs(v.translation.width) > abs(v.translation.height) * 1.4 else { return }
                page(v.translation.width < 0 ? 1 : -1)
            }
    }

    private var pageMotion: Animation { reduceMotion ? .easeInOut(duration: 0.12) : .easeInOut(duration: 0.18) }
    private var selectMotion: Animation { reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.4, dampingFraction: 0.9) }

    private func startOfWeek(_ d: Date) -> Date { cal.dateInterval(of: .weekOfYear, for: d)?.start ?? d }

    private func weekDays(from start: Date) -> [DayKey] {
        let s = startOfWeek(start)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: s) }.map { DayKey($0) }
    }

    private func monthName(_ d: Date) -> String { d.formatted(.dateTime.month(.wide)) }

    // MARK: - Agenda

    private var agenda: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    stillCounts
                    ForEach(blocks(weekDays(from: tickerWeek))) { block in
                        switch block {
                        case .folded(let run):
                            foldedRun(run, id: block.id)
                        case .day(let d):
                            daySection(d).id(d.raw)
                        }
                    }
                    nextWeek
                    farAhead
                    notPaired
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 6)
                .padding(.bottom, L.scrollInset)
            }
            .scrollIndicators(.hidden)
            .onChange(of: scrollTick) { _, _ in
                withAnimation(selectMotion) { proxy.scrollTo(anchorID(for: selected), anchor: .top) }
            }
        }
    }

    /// The grouping rules live in `Upcoming` so they can be tested without a
    /// screen. This is just the view's read of them.
    private func blocks(_ days: [DayKey]) -> [Upcoming.Block] {
        Upcoming.blocks(days, dropPast: tickerHoldsToday) { feed.entries(on: $0).isEmpty }
    }

    /// The view a pick should scroll to: the day itself, or the folded line
    /// that swallowed it.
    private func anchorID(for day: DayKey) -> String {
        for block in blocks(weekDays(from: tickerWeek)) {
            switch block {
            case .day(let d) where d == day: return d.raw
            case .folded(let run) where run.contains(day): return block.id
            default: continue
            }
        }
        return day.raw
    }

    /// A run of empty days is one line, and the line opens in place: each day
    /// comes out as its own "Nothing due" row, which is how a task lands on a
    /// Thursday nobody had typed a date for.
    @ViewBuilder
    private func foldedRun(_ run: [DayKey], id: String) -> some View {
        let isOpen = opened.contains(id)
        FoldedDaysStrip(days: run, isOpen: isOpen) {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(selectMotion) {
                if isOpen { opened.remove(id) } else { opened.insert(id) }
            }
        }
        .id(id)
        if isOpen {
            ForEach(run, id: \.raw) { day in
                EmptyDayLine(day: day) { openAdd(on: day) }
            }
        }
    }

    /// When this week and the next have nothing on them, the next dated thing,
    /// however far out, under its own day header — the way Things 3's Upcoming
    /// shows next month's items under a month header (Mobbin
    /// 590f4dd6-1a6d-45a3-91c3-3508a762b041). Past a fortnight the header's lead
    /// is already the month.
    @ViewBuilder
    private var farAhead: some View {
        let thisWeek = weekDays(from: tickerWeek).filter { !(tickerHoldsToday && $0 < .today()) }
        let nextStart = cal.date(byAdding: .weekOfYear, value: 1, to: startOfWeek(tickerWeek)) ?? tickerWeek
        let both = thisWeek + weekDays(from: nextStart)
        if both.allSatisfy({ feed.entries(on: $0).isEmpty }),
           let last = both.last,
           let day = Upcoming.nextDated(after: last, isEmpty: { feed.entries(on: $0).isEmpty }) {
            daySection(day).id(day.raw)
        }
    }

    /// Todoist and ClickUp both put overdue in its own group at the top. Ours is
    /// amber and says "still counts", never red and never a count in a badge.
    /// Only on the week that holds today: an October week does not owe September.
    @ViewBuilder
    private var stillCounts: some View {
        let rows = overdue
        if !rows.isEmpty {
            StillCountsHeader()
            VStack(spacing: 8) {
                ForEach(rows, id: \.id) { overdueRow($0) }
            }
            .padding(.bottom, 6)
        }
    }

    /// Everything from the last fortnight that is open and was due. Read off the
    /// same day lists the agenda reads, so a Canvas row and a typed row land in
    /// it the same way, oldest first.
    private var overdue: [DailyTask] {
        guard tickerHoldsToday else { return [] }
        return Upcoming.stillCounts { state.tasks(on: $0) }
    }

    /// A typed row can be moved, so it swipes. A Canvas row cannot — a Canvas
    /// date is not ours to change — so it does not.
    private func overdueRow(_ task: DailyTask) -> some View {
        let dated = task.isDated ? state.datedTask(task.id) : nil
        return SwipeToMove(isOpen: swipedRowID == task.id, enabled: dated != nil) {
            withAnimation(selectMotion) { swipedRowID = task.id }
        } onClose: {
            if swipedRowID == task.id { withAnimation(selectMotion) { swipedRowID = nil } }
        } onMove: {
            withAnimation(selectMotion) { swipedRowID = nil }
            moving = dated
        } content: {
            CalendarTaskRow(task: task, tint: feed.tint(task), note: dated?.notes,
                            overdue: true, onCheck: { toggle(task) }) {
                if let dated { editing = .edit(dated) }
            }
        }
    }

    /// "What is coming" should not stop at a grid boundary that only exists because
    /// weeks start on Sunday, so anything on the next week's days carries on under a
    /// divider. The ticker still pages one week at a time.
    @ViewBuilder
    private var nextWeek: some View {
        let start = cal.date(byAdding: .weekOfYear, value: 1, to: startOfWeek(tickerWeek)) ?? tickerWeek
        let days = weekDays(from: start).filter { !feed.entries(on: $0).isEmpty }
        if !days.isEmpty {
            HStack(spacing: 10) {
                Rectangle().fill(Theme.chipDivider).frame(height: 1)
                Text("NEXT WEEK")
                    .font(Theme.fixedFont(10, .black))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dim)
                Rectangle().fill(Theme.chipDivider).frame(height: 1)
            }
            .padding(.top, 22)
            ForEach(days, id: \.raw) { daySection($0).id($0.raw) }
        }
    }

    @ViewBuilder
    private func daySection(_ day: DayKey) -> some View {
        let entries = feed.entries(on: day)
        if entries.isEmpty {
            EmptyDayLine(day: day) { openAdd(on: day) }
        } else {
            dayHeader(day)
            VStack(spacing: 8) {
                ForEach(entries) { row($0) }
            }
        }
    }

    /// A 44pt row, not a rule: it is the tap that opens the day.
    private func dayHeader(_ day: DayKey) -> some View {
        let summary = feed.summary(on: day)
        return Button { open(day) } label: {
            HStack(spacing: 8) {
                DayHeading(day: day, size: 15)
                Spacer(minLength: 8)
                Text(summary)
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(DayHeading.spoken(day)). \(summary)")
        .accessibilityHint("Opens the day")
    }

    @ViewBuilder
    private func row(_ entry: CalendarEntry) -> some View {
        switch entry {
        case .task(let t):
            CalendarTaskRow(task: t, tint: feed.tint(t), note: state.datedTask(t.id)?.notes,
                            onCheck: { toggle(t) }) {
                if t.isDated, let d = state.datedTask(t.id) { editing = .edit(d) }
            }
        case .event(let e):
            EventRow(event: e, tint: feed.tint(e))
        }
    }

    /// Saturn's "Got your class schedule?" card, at the end of the list and only
    /// while no laptop has sent a list. It points at pairing, never at a form.
    @ViewBuilder
    private var notPaired: some View {
        if state.lastCanvasSyncAt == nil {
            NotPairedCard { showPairing = true }
                .padding(.top, 14)
        }
    }

    // MARK: - Doing things

    private func toggle(_ task: DailyTask) {
        guard !task.isLocked else { return }
        if task.done {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            state.uncomplete(task)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            state.complete(task)
            flyCoins(from: task.id)
        }
    }

    /// Three discs from the row's checkbox to the coin badge, as Home does it.
    private func flyCoins(from taskID: String) {
        // Reduce Motion: the badge still counts up; nothing crosses the screen.
        guard !reduceMotion else { return }
        guard let from = rewardFrames[taskID], walletFrame != .zero else { return }
        let start = CGPoint(x: from.midX, y: from.midY)
        let end = CGPoint(x: walletFrame.minX + 20, y: walletFrame.midY)
        let batch = (0..<3).map { CoinFlight(index: $0, from: start, to: end) }
        flights += batch
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            flights.removeAll { f in batch.contains { $0.id == f.id } }
        }
    }

    private func move(_ task: DatedTask, to day: DayKey) {
        var t = moving ?? task
        t.day = day
        moving = t
        state.updateDated(t)
    }

    private func move(_ task: DatedTask, at minute: Int?) {
        var t = moving ?? task
        t.minute = minute
        moving = t
        state.updateDated(t)
    }

    /// One read, through `AppState`, so the gift week and the debug flag are in it
    /// too. A view that spells this out for itself is a view that will one day
    /// disagree with the Shop about whether a student is Plus.
    private var isPlus: Bool { state.isPlus }

    private func openAdd(on day: DayKey) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        adding = AddTarget(day: day < .today() ? .today() : day)
    }

    private func openScan() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        later { if isPlus { showScan = true } else { showPlus = true } }
    }

    // MARK: - What floats

    /// The last row would otherwise half-disappear behind the tab bar and read as a
    /// clipping bug.
    private var fade: some View {
        LinearGradient(colors: [Theme.paper.opacity(0), Theme.paper],
                       startPoint: .top, endPoint: .bottom)
            .frame(height: 64)
            .padding(.bottom, L.tabBar)
            .allowsHitTesting(false)
    }

    private var fab: some View {
        // A Spacer rather than a full-width frame: a button's frame is its tap
        // target, and a 402-wide one would eat every tap in the bottom band.
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button {
                openAdd(on: selected)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Theme.coral)
                        .shadow(color: Theme.coralShade.opacity(0.34), radius: 9, y: 6))
            }
            .buttonStyle(FabPressStyle())
            .accessibilityLabel("Add something")
        }
        .padding(.trailing, Theme.gutter)
        .padding(.bottom, L.fabBottom)
    }
}

/// The day (and, from a gap on the timeline, the minute) quick add opens on.
struct AddTarget: Identifiable {
    let day: DayKey
    var minute: Int? = nil
    var id: String { "\(day.raw)-\(minute ?? -1)" }
}

// MARK: - What is on a day

/// A task and an event share a day but not a shape, so a day's list is one
/// sorted run of both rather than two stacks.
enum CalendarEntry: Identifiable {
    case task(DailyTask)
    case event(CanvasEvent)

    var id: String {
        switch self {
        case .task(let t): return "t-\(t.id)"
        case .event(let e): return "e-\(e.id)"
        }
    }
}

/// One mark in a day's load: the course colour, and whether it is a class (a
/// disc) or something to hand in (a chip).
struct LoadMark: Hashable {
    let color: Color
    let isEvent: Bool
}

/// The one way every screen on this tab reads a day, so the ticker, the month
/// sheet and the timeline can never disagree about what is on it.
@MainActor
struct CalendarFeed {
    let state: AppState
    private let cal = Calendar.current

    /// All-day events, then all-day tasks, then everything timed in time order
    /// with tasks and events interleaved.
    func entries(on day: DayKey) -> [CalendarEntry] {
        let entries = state.events(on: day).map(CalendarEntry.event) + state.tasks(on: day).map(CalendarEntry.task)
        return entries.sorted { order($0) < order($1) }
    }

    private func order(_ e: CalendarEntry) -> (Int, Int, Int) {
        switch e {
        case .event(let ev):
            return ev.allDay ? (0, 0, 0) : (1, DayTimeline.minute(of: ev.startAt), 0)
        case .task(let t):
            guard let m = timedMinute(t) else { return (0, 1, 0) }
            return (1, m, 1)
        }
    }

    /// The minute a task is due at, or nil when it is all day. Canvas's own
    /// end-of-day default (23:59) is a minute that means nothing, so it is nil too.
    func timedMinute(_ t: DailyTask) -> Int? {
        guard let due = t.dueAt else { return nil }
        let m = DayTimeline.minute(of: due)
        return m >= 23 * 60 + 59 ? nil : m
    }

    /// One mark per open thing on a day, in course colour, chronological. Done
    /// work drops its mark, so a busy day thins out as it gets done.
    func load(on day: DayKey) -> [LoadMark] {
        entries(on: day).compactMap { e in
            switch e {
            case .task(let t): return t.done ? nil : LoadMark(color: tint(t), isEvent: false)
            case .event(let ev): return LoadMark(color: tint(ev), isEvent: true)
            }
        }
    }

    func loadLabel(on day: DayKey) -> String {
        let n = entries(on: day).count
        if n == 0 { return "Free" }
        return n == 1 ? "1 thing" : "\(n) things"
    }

    /// The right-hand end of a day header: what the day's clock looks like.
    /// Classes if there are any, with the time they take; else what is due; and
    /// today with no classes says so, because that is the thing a student wants
    /// to know about today that its rows do not already say.
    func summary(on day: DayKey) -> String {
        let events = state.events(on: day).filter { !$0.allDay }
        if !events.isEmpty {
            let booked = events.reduce(0) { $0 + minutes(of: $1) }
            let n = events.count
            return "\(n) \(n == 1 ? "class" : "classes") · \(DayTimeline.length(booked))"
        }
        if day == .today() { return "no classes" }
        let open = state.tasks(on: day).filter { !$0.done }.count
        if open > 0 { return open == 1 ? "1 due" : "\(open) due" }
        return "done"
    }

    /// How long a class runs, in minutes. An event with no end, or an all-day
    /// one, takes no time on the clock.
    func minutes(of e: CanvasEvent) -> Int {
        guard !e.allDay, let end = e.endAt, end > e.startAt else { return 0 }
        return Int(end.timeIntervalSince(e.startAt) / 60)
    }

    /// Colour means *course* on this screen. A task with no course gets a warm
    /// grey, never coral — coral is the button. A `DatedTask` has no course
    /// colour, so grey is the only truthful option.
    func tint(_ t: DailyTask) -> Color {
        Theme.color(t.colorHex) ?? Theme.dim
    }

    func tint(_ e: CanvasEvent) -> Color {
        Theme.color(e.colorHex) ?? Theme.sky
    }
}

// MARK: - Load

/// A day's load as the objects themselves: one 12pt chip per thing to hand in,
/// one disc per class, in course colour, chronological. Three at most; a fourth
/// becomes a count, because four marks under a 17pt number stop being countable.
struct DayLoadGlyphs: View {
    let marks: [LoadMark]
    var size: CGFloat = 12

    private var shown: [LoadMark] { marks.count > 3 ? Array(marks.prefix(2)) : marks }
    private var overflow: Int { marks.count > 3 ? marks.count - 2 : 0 }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, m in
                RoundedRectangle(cornerRadius: m.isEvent ? size / 2 : size / 3, style: .continuous)
                    .fill(m.color)
                    .frame(width: size, height: size)
                    .overlay {
                        // The line on a chip is the paper in the object; a disc is
                        // a class and carries nothing.
                        if !m.isEvent && size >= 12 {
                            Capsule().fill(.white).frame(width: 6, height: 1.6)
                        }
                    }
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(Theme.fixedFont(8.5, .black))
                    .foregroundStyle(Theme.dim)
            }
        }
        .frame(height: size + 2)
        .accessibilityHidden(true)
    }
}

// MARK: - Small parts

/// "Today," in coral then the date; "Saturday," then the date in grey; and past
/// a fortnight the month with the day number, since a weekday stops helping.
struct DayHeading: View {
    let day: DayKey
    var size: CGFloat = 15

    var body: some View {
        let heading = Upcoming.heading(for: day)
        let date = day.date() ?? Date()
        let far = heading.lead == date.formatted(.dateTime.month(.wide))
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(far ? heading.lead : "\(heading.lead),")
                .font(Theme.font(size, .black))
                .foregroundStyle(heading.isToday ? Theme.coralShade : Theme.ink)
            Text(far ? date.formatted(.dateTime.day()) : heading.date)
                .font(Theme.font(size, .black))
                .foregroundStyle(heading.isToday ? Theme.ink : Theme.muted)
        }
        .lineLimit(1)
    }

    static func spoken(_ day: DayKey) -> String {
        let heading = Upcoming.heading(for: day)
        return "\(heading.lead), \(heading.date)"
    }
}

/// The box on a row. `size` 33 on a card, 30 on a compact row; the target is
/// 44 either way.
struct CheckBox: View {
    let done: Bool
    var locked = false
    var size: CGFloat = 33
    let onTap: () -> Void

    @State private var nudge: CGFloat = 0

    var body: some View {
        Button {
            guard !locked else {
                // Canvas owns this one. Say so on the box, not with an error.
                withAnimation(.easeInOut(duration: 0.06)) { nudge = 3 }
                withAnimation(.easeInOut(duration: 0.06).delay(0.06)) { nudge = 0 }
                return
            }
            onTap()
        } label: {
            RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                .fill(done ? Theme.check : Theme.checkFill)
                .overlay {
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.45, weight: .black))
                            .foregroundStyle(.white)
                            .transition(.opacity)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                            .strokeBorder(Theme.checkBorder, lineWidth: 2.5)
                    }
                }
                .frame(width: size, height: size)
                .offset(x: nudge)
                .animation(.easeOut(duration: 0.18), value: done)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locked ? "Handed in on Canvas" : (done ? "Done" : "Mark done"))
    }
}

// MARK: - Rows

/// A task on a day: a white card, one hairline, no shadow. Home's `TaskRow`
/// anatomy — tile, title, caption, 33pt box — with the course colour in the
/// tile and the coins folded into the caption, so a row is four things, not
/// six. Done is 45% and stays in place; never a strikethrough.
struct CalendarTaskRow: View {
    let task: DailyTask
    let tint: Color
    var note: String?
    /// In the Still counts group: no tile, a rail in the course colour down the
    /// left edge, and the caption in amber.
    var overdue = false
    let onCheck: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if !overdue {
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .fill(Theme.soft(tint))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image("icon-" + task.category.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    )
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(Theme.font(15.5, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(caption)
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(overdue ? Theme.coinInk : Theme.muted)
                    .lineLimit(1)
                if let note, !note.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 9, weight: .black))
                        Text(note)
                            .font(Theme.font(11.5, .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Theme.dim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)

            if task.isLocked {
                KinIcon(.lock, size: 12, color: Theme.dim)
            }
            CheckBox(done: task.done, locked: task.isLocked, onTap: onCheck)
                .padding(.trailing, -5)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: RewardFrameKey.self,
                                           value: [task.id: geo.frame(in: .named("calendar"))])
                })
        }
        .padding(.leading, 12).padding(.trailing, 14).padding(.vertical, 9)
        .frame(minHeight: 62)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .strokeBorder(Theme.cardEdge, lineWidth: 1))
        .overlay(alignment: .leading) {
            if overdue { Rectangle().fill(tint).frame(width: 4) }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .opacity(task.done ? 0.45 : 1)
        .animation(.easeOut(duration: 0.2), value: task.done)
    }

    private var caption: String { Self.caption(for: task) }

    /// `{course} · all day · 30` · `{course} · 8:00 AM · 30` · `{course} · handed in`
    /// · `{course} · was due Tue · 30` · `{kind} · 7:30 PM · 20`. The coins ride in
    /// the caption rather than in a chip of their own, which is one thing fewer
    /// on every row.
    static func caption(for task: DailyTask) -> String {
        let who = task.detail ?? task.kind.label
        if task.isLocked { return "\(who) · handed in" }
        return "\(who) · \(when(task)) · \(task.reward)"
    }

    private static func when(_ task: DailyTask) -> String {
        guard let due = task.dueAt else { return "all day" }
        let cal = Calendar.current
        if !task.done && due < Date() && !cal.isDateInToday(due) {
            return "was due \(due.formatted(.dateTime.weekday(.abbreviated)))"
        }
        let c = cal.dateComponents([.hour, .minute], from: due)
        // Canvas's own end-of-day default: the student is not told a minute that
        // means nothing.
        if c.hour == 23 && c.minute == 59 { return "all day" }
        return due.formatted(.dateTime.hour().minute())
    }
}

/// Something that happens rather than gets handed in: a tinted block on the
/// paper, the course as a disc, and the start time over how long it runs.
/// No checkbox and no coins — it is not work, it is where you will be.
struct EventRow: View {
    let event: CanvasEvent
    let tint: Color

    var body: some View {
        HStack(spacing: 11) {
            Circle().fill(tint).frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(Theme.font(14, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if !place.isEmpty {
                    Text(place)
                        .font(Theme.font(12, .heavy))
                        .foregroundStyle(Theme.mutedDeep)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(start)
                    .font(Theme.font(12.5, .black))
                    .foregroundStyle(Theme.deep(tint))
                if let length {
                    Text(length)
                        .font(Theme.font(11, .heavy))
                        .foregroundStyle(Theme.mutedDeep)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .fill(Theme.soft(tint)))
        .accessibilityElement(children: .combine)
    }

    /// `Intro Psych · Moore 202`.
    private var place: String {
        [event.courseName, event.location ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var start: String {
        event.allDay ? "All day" : event.startAt.formatted(.dateTime.hour().minute())
    }

    private var length: String? {
        guard !event.allDay, let end = event.endAt, end > event.startAt else { return nil }
        return DayTimeline.length(Int(end.timeIntervalSince(event.startAt) / 60))
    }
}

/// A row with no card: a 3pt rail in the course colour, a title and a caption,
/// and a 30pt box when it is something to finish. The month sheet's list and
/// the timeline's all-day line are both made of these.
struct CompactRow: View {
    let title: String
    let caption: String
    let tint: Color
    var done = false
    var locked = false
    /// Nil for a class, which has nothing to tick.
    var onCheck: (() -> Void)? = nil
    var onOpen: () -> Void = {}

    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(tint)
                .frame(width: 3, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.font(14.5, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(caption)
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            if let onCheck {
                CheckBox(done: done, locked: locked, size: 30, onTap: onCheck)
                    .padding(.trailing, -7)
            }
        }
        .frame(minHeight: 44)
        .opacity(done ? 0.45 : 1)
        .animation(.easeOut(duration: 0.2), value: done)
    }
}

/// A day with nothing on it costs one line, and the line is the way in — Google
/// Calendar's "Nothing planned. Tap to create." Today always draws it; other
/// empty days only when a folded run is opened or the month sheet lands on one.
struct EmptyDayLine: View {
    let day: DayKey
    let onTap: () -> Void

    var body: some View {
        let past = day < .today()
        Button(action: onTap) {
            HStack(spacing: 8) {
                DayHeading(day: day, size: 15)
                Spacer(minLength: 8)
                Text("Nothing due.")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
                if !past {
                    Text("Tap to add.")
                        .font(Theme.font(12.5, .black))
                        .foregroundStyle(Theme.coralShade)
                }
            }
            .lineLimit(1)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(past)
        .accessibilityLabel("\(DayHeading.spoken(day)). Nothing due.\(past ? "" : " Tap to add.")")
    }
}

/// Seven headers for three items becomes one line for a run of empty days —
/// Google Calendar folds an empty stretch the same way. It opens in place.
struct FoldedDaysStrip: View {
    let days: [DayKey]
    var isOpen = false
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 9) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Theme.muted)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                Text(label)
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 0)
            }
            .frame(height: 44)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(isOpen ? "Folds the days back up" : "Shows each day")
    }

    private var label: String { Upcoming.foldLabel(days) }
}

/// Overdue is amber and reads "still counts" — never red, never a count in a
/// badge, never "you missed".
struct StillCountsHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Still counts")
                .font(Theme.font(14, .black))
                .foregroundStyle(Theme.coinInk)
            Rectangle().fill(Theme.coinHairline).frame(height: 1)
        }
        .frame(height: 44)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Saturn's "Got your class schedule?" — one card, pointing at the laptop
/// pairing, shown only until a laptop has sent a list.
struct NotPairedCard: View {
    let onShow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Got your class schedule?")
                .font(Theme.font(16, .black))
                .foregroundStyle(Theme.ink)
            Text("Open Prepkin on your laptop and your classes land here.")
                .font(Theme.font(12.5, .heavy))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onShow) {
                Text("Show me how")
                    .font(Theme.font(13, .black))
                    .foregroundStyle(Theme.coralShade)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// A row that swipes to show one action, `Move`, 96pt wide. The action slides
/// in over the row's right end rather than pushing the row off the left, so
/// the title and the "was due" stay readable while it is open. Only a typed
/// task gets it; a Canvas row does not swipe at all, because a Canvas date is
/// not ours to change. One row open at a time, which the parent keeps.
struct SwipeToMove<Content: View>: View {
    let isOpen: Bool
    let enabled: Bool
    let onOpen: () -> Void
    let onClose: () -> Void
    let onMove: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var drag: CGFloat = 0

    private let width: CGFloat = 96

    var body: some View {
        if enabled {
            content()
                .overlay(alignment: .trailing) {
                    Button(action: onMove) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .bold))
                            Text("Move")
                                .font(Theme.font(12, .black))
                        }
                        .foregroundStyle(Theme.mutedInk)
                        .frame(width: width)
                        .frame(maxHeight: .infinity)
                        .background(Theme.paperSunk)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(x: width + offset)
                    .accessibilityLabel("Move to another day")
                    .accessibilityHidden(!isOpen)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .gesture(swipe)
                .accessibilityAction(named: "Move to another day", onMove)
        } else {
            content()
        }
    }

    /// How far the action has come in: 0 shut, `-width` open, with a little
    /// give past either end.
    private var offset: CGFloat {
        let base: CGFloat = isOpen ? -width : 0
        return min(12, max(-width - 12, base + drag))
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 14, coordinateSpace: .local)
            .onChanged { v in
                // A mostly vertical drag is the list scrolling; leave it alone.
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                drag = v.translation.width
            }
            .onEnded { v in
                let landed = (isOpen ? -width : 0) + v.translation.width
                drag = 0
                if landed < -width / 2 { onOpen() } else { onClose() }
            }
    }
}

// MARK: - The month sheet

/// The month, over the agenda: scan the load, pick a day. Six rows of seven
/// always, so the grid never changes height between months; the day picked
/// lists its things under the grid, inside the same scroll, so they are
/// reachable with the grid still in view.
struct MonthSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selected: DayKey
    /// A day header tap: the sheet closes and the day opens.
    let onOpenDay: (DayKey) -> Void
    /// "Tap to add" on an empty day: the sheet closes and quick add opens.
    let onAdd: (DayKey) -> Void
    let onCheck: (DailyTask) -> Void

    /// The month the grid shows. Independent of the selected day.
    @State private var cursor: Date

    private let cal = Calendar.current

    init(selected: Binding<DayKey>, onOpenDay: @escaping (DayKey) -> Void,
         onAdd: @escaping (DayKey) -> Void, onCheck: @escaping (DailyTask) -> Void) {
        _selected = selected
        self.onOpenDay = onOpenDay
        self.onAdd = onAdd
        self.onCheck = onCheck
        _cursor = State(initialValue: selected.wrappedValue.date() ?? Date())
    }

    private var feed: CalendarFeed { CalendarFeed(state: state) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                weekdayRow
                grid
                    .contentShape(Rectangle())
                    .gesture(swipe)
                Rectangle().fill(Theme.hairline).frame(height: 1)
                    .padding(.top, 10)
                dayList
                    .padding(.top, 4)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Theme.card)
        .presentationBackground(Theme.card)
        .presentationDetents([.fraction(0.83)])
        .presentationCornerRadius(Theme.Radius.sheet)
        .presentationDragIndicator(.hidden)
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Text(cursor.formatted(.dateTime.month(.wide)))
                    .font(Theme.font(22, .black))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text(cursor.formatted(.dateTime.year()))
                    .font(Theme.font(22, .black))
                    .foregroundStyle(Theme.muted)
                    .contentTransition(.numericText())
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            Button(action: goToday) {
                Text("Today")
                    .font(Theme.font(12, .black))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 13)
                    .frame(height: 44)
                    .background(Capsule().fill(Theme.paperSunk))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Today")
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Theme.mutedInk)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.paperSunk))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 14)
    }

    private var weekdayRow: some View {
        HStack(spacing: 2) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                Text(s)
                    .font(Theme.fixedFont(10, .black))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 6)
        .accessibilityHidden(true)
    }

    private var grid: some View {
        let cells = monthCells(for: cursor)
        return Grid(horizontalSpacing: 2, verticalSpacing: 2) {
            ForEach(0..<6, id: \.self) { r in
                GridRow {
                    ForEach(cells[(r * 7)..<(r * 7 + 7)]) { cell($0) }
                }
            }
        }
        .animation(pageMotion, value: cursor)
    }

    private struct Cell: Identifiable {
        let key: DayKey
        let date: Date
        var id: String { key.raw }
    }

    /// Six rows of seven, starting on the calendar's first weekday.
    private func monthCells(for d: Date) -> [Cell] {
        let gridStart = startOfWeek(startOfMonth(d))
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }
            .map { Cell(key: DayKey($0), date: $0) }
    }

    private func cell(_ cell: Cell) -> some View {
        let inMonth = cal.isDate(cell.date, equalTo: cursor, toGranularity: .month)
        let isToday = cell.key == .today()
        let isSelected = cell.key == selected
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeOut(duration: 0.12)) {
                selected = cell.key
                if !inMonth { cursor = startOfMonth(cell.date) }
            }
        } label: {
            VStack(spacing: 5) {
                Text(cell.date.formatted(.dateTime.day()))
                    .font(Theme.fixedFont(15, .black))
                    .foregroundStyle(isToday ? .white : (inMonth ? Theme.ink : Theme.inactive))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(isToday ? Theme.coral : .clear))
                DayLoadGlyphs(marks: inMonth ? feed.load(on: cell.key) : [], size: 11)
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 60, alignment: .top)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                .fill(isSelected ? Theme.coralSoft : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cell.date.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityValue(feed.loadLabel(on: cell.key))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The picked day's things, under the grid. Swaps with a cross-fade.
    @ViewBuilder
    private var dayList: some View {
        let entries = feed.entries(on: selected)
        Group {
            if entries.isEmpty {
                EmptyDayLine(day: selected) { onAdd(selected) }
            } else {
                Button { onOpenDay(selected) } label: {
                    HStack(spacing: 8) {
                        DayHeading(day: selected, size: 14)
                        Spacer(minLength: 8)
                        Text(feed.loadLabel(on: selected))
                            .font(Theme.font(12, .heavy))
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(DayHeading.spoken(selected)). \(feed.loadLabel(on: selected))")
                .accessibilityHint("Opens the day")
                VStack(spacing: 2) {
                    ForEach(entries) { entry in
                        switch entry {
                        case .task(let t):
                            CompactRow(title: t.title, caption: CalendarTaskRow.caption(for: t),
                                       tint: feed.tint(t), done: t.done, locked: t.isLocked,
                                       onCheck: { onCheck(t) })
                        case .event(let e):
                            CompactRow(title: e.title, caption: caption(e), tint: feed.tint(e))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .id(selected)
        .transition(.opacity)
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    private func caption(_ e: CanvasEvent) -> String {
        var parts: [String] = []
        if !e.courseName.isEmpty { parts.append(e.courseName) }
        if e.allDay {
            parts.append("all day")
        } else {
            parts.append(e.startAt.formatted(.dateTime.hour().minute()))
            let m = feed.minutes(of: e)
            if m > 0 { parts.append(DayTimeline.length(m)) }
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Moving about

    private func goToday() {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeOut(duration: 0.25)) {
            cursor = Date()
            selected = .today()
        }
    }

    private func page(_ step: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(pageMotion) {
            cursor = cal.date(byAdding: .month, value: step, to: startOfMonth(cursor)) ?? cursor
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { v in
                guard abs(v.translation.width) > abs(v.translation.height) * 1.4 else { return }
                page(v.translation.width < 0 ? 1 : -1)
            }
    }

    private var pageMotion: Animation { reduceMotion ? .easeInOut(duration: 0.12) : .easeInOut(duration: 0.18) }

    private var weekdaySymbols: [String] {
        let all = cal.shortStandaloneWeekdaySymbols.map { $0.uppercased() }
        let first = cal.firstWeekday - 1
        return Array(all[first...] + all[..<first])
    }

    private func startOfWeek(_ d: Date) -> Date { cal.dateInterval(of: .weekOfYear, for: d)?.start ?? d }
    private func startOfMonth(_ d: Date) -> Date { cal.dateInterval(of: .month, for: d)?.start ?? d }
}

// MARK: - The day timeline

/// One day on a clock: "I have office hours 2 to 3 and the problem set is due
/// at 5." Pushed from a ticker day or a day header; the tab bar hides.
///
/// All-day work is one line above the axis. On the axis, 48pt per hour: a
/// class takes its true height, a due time is a pin, and free time between
/// them is a row that says how long (`DayTimeline` has the rules). On today
/// a coral line says where now is, with the word `now` in the hour column —
/// a word, not a time, so it never collides with an hour label.
struct DayTimelineView: View {
    let day: DayKey

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var now = Date()
    @State private var adding: AddTarget?
    @State private var editing: TaskEditorSheet.Mode?

    private let cal = Calendar.current
    private let minute = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    /// Points per hour on the axis.
    static let hour: CGFloat = 48
    /// The hour column.
    static let column: CGFloat = 30

    private var feed: CalendarFeed { CalendarFeed(state: state) }
    private var isToday: Bool { day == .today() }
    private var isPast: Bool { day < .today() }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 0) {
                    allDay
                    axis
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 10)
                .padding(.bottom, 170)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .hidesTabBar()
        .onReceive(minute) { now = $0 }
        .sheet(item: $adding) { target in
            QuickAddSheet(day: target.day, minute: target.minute, onMore: { draft in
                adding = nil
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(260))
                    editing = .draft(draft)
                }
            })
            .environmentObject(state)
        }
        .sheet(item: $editing) { mode in
            TaskEditorSheet(mode: mode) { _ in }
                .environmentObject(state)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(Theme.cardEdge, lineWidth: 1))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, -4)
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.font(21, .black))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
            }
            .lineLimit(1)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.gutter)
        .frame(height: 44)
        .padding(.bottom, 4)
    }

    private var title: String {
        let heading = Upcoming.heading(for: day)
        if heading.isToday || heading.lead == "Tomorrow" { return heading.lead }
        return (day.date() ?? Date()).formatted(.dateTime.weekday(.wide))
    }

    /// `Thursday, Sep 10 · 2h 30m booked · 1 due`. The weekday only when the
    /// title did not already say it.
    private var subtitle: String {
        let date = day.date() ?? Date()
        let heading = Upcoming.heading(for: day)
        let short = date.formatted(.dateTime.month(.abbreviated).day())
        var parts = [heading.isToday || heading.lead == "Tomorrow"
                     ? "\(date.formatted(.dateTime.weekday(.wide))), \(short)" : short]
        let booked = state.events(on: day).reduce(0) { $0 + feed.minutes(of: $1) }
        if booked > 0 { parts.append("\(DayTimeline.length(booked)) booked") }
        let open = state.tasks(on: day).filter { !$0.done }.count
        if open > 0 { parts.append(open == 1 ? "1 due" : "\(open) due") }
        return parts.joined(separator: " · ")
    }

    // MARK: - What is on the clock

    private struct Timed: Identifiable {
        let entry: CalendarEntry
        let span: DayTimeline.Span
        var id: String { entry.id }
    }

    private var timed: [Timed] {
        feed.entries(on: day).compactMap { entry in
            switch entry {
            case .event(let e):
                guard !e.allDay else { return nil }
                let start = DayTimeline.minute(of: e.startAt)
                return Timed(entry: entry, span: .init(start: start, end: start + feed.minutes(of: e)))
            case .task(let t):
                guard let m = feed.timedMinute(t) else { return nil }
                return Timed(entry: entry, span: .init(start: m))
            }
        }
    }

    private var untimed: [CalendarEntry] {
        feed.entries(on: day).filter { entry in
            switch entry {
            case .event(let e): return e.allDay
            case .task(let t): return feed.timedMinute(t) == nil
            }
        }
    }

    private var nowMinute: Int? { isToday ? DayTimeline.minute(of: now) : nil }

    // MARK: - All day

    @ViewBuilder
    private var allDay: some View {
        let rows = untimed
        if !rows.isEmpty {
            VStack(spacing: 2) {
                ForEach(rows) { compact($0) }
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
            .padding(.bottom, 10)
        }
    }

    private func compact(_ entry: CalendarEntry) -> some View {
        Group {
            switch entry {
            case .task(let t):
                CompactRow(title: t.title, caption: CalendarTaskRow.caption(for: t), tint: feed.tint(t),
                           done: t.done, locked: t.isLocked, onCheck: { toggle(t) },
                           onOpen: { openEditor(t) })
            case .event(let e):
                CompactRow(title: e.title, caption: eventPlace(e, allDay: true), tint: feed.tint(e))
            }
        }
    }

    // MARK: - The axis

    private var axis: some View {
        let items = timed
        let segments = DayTimeline.segments(items.map(\.span), now: nowMinute)
        return VStack(spacing: 4) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .item(let i, let nowAt):
                    itemRow(items[i], nowAt: nowAt)
                case .gap(let from, let to):
                    // A gap that starts now starts at 12:49; the task it invites
                    // lands on the next five minutes, which is what a person types.
                    GapRow(from: from, to: to, canAdd: !isPast) { add(at: (from + 4) / 5 * 5) }
                case .now:
                    NowRow(reduceMotion: reduceMotion)
                case .rest(let from):
                    // A pin is a point, so the rest of the day starts on the
                    // minute the pin already labelled; saying it twice is noise.
                    restRow(from: from, labelled: from != items.last(where: { $0.span.minutes == 0 })?.span.start)
                }
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: Timed, nowAt: Double?) -> some View {
        switch item.entry {
        case .task(let t):
            TimelinePin(label: DayTimeline.hourLabel(item.span.start),
                        title: t.title, caption: pinCaption(t), tint: feed.tint(t),
                        done: t.done, locked: t.isLocked,
                        onCheck: { toggle(t) }, onOpen: { openEditor(t) })
        case .event(let e):
            TimelineBlock(label: DayTimeline.hourLabel(item.span.start),
                          title: e.title, place: eventPlace(e, allDay: false),
                          minutes: item.span.minutes, tint: feed.tint(e),
                          nowAt: nowAt, reduceMotion: reduceMotion)
        }
    }

    /// `Free the rest of the day`, with a place to put something; `Free all
    /// day` on a day with nothing timed. A day already gone offers nothing.
    private func restRow(from: Int?, labelled: Bool = true) -> some View {
        AxisRow(label: labelled ? (from.map { DayTimeline.hourLabel($0) } ?? "") : "", height: 44) {
            HStack(spacing: 10) {
                DottedRail(height: 34)
                Text(from == nil ? "Free all day" : "Free the rest of the day")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 0)
                if !isPast {
                    Button { add(at: from) } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Theme.mutedInk)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.paperSunk))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a task")
                }
            }
        }
    }

    // MARK: - Words

    /// The time is on the axis, so the pin only says whose it is and what it pays.
    private func pinCaption(_ t: DailyTask) -> String {
        let who = t.detail ?? t.kind.label
        if t.isLocked { return "\(who) · handed in" }
        return "\(who) · pays \(t.reward)"
    }

    private func eventPlace(_ e: CanvasEvent, allDay: Bool) -> String {
        var parts: [String] = []
        if !e.courseName.isEmpty { parts.append(e.courseName) }
        if allDay { parts.append("all day") }
        if let loc = e.location, !loc.isEmpty { parts.append(loc) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Doing things

    private func toggle(_ task: DailyTask) {
        guard !task.isLocked else { return }
        if task.done {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            state.uncomplete(task)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            state.complete(task)
        }
    }

    private func openEditor(_ task: DailyTask) {
        guard task.isDated, let d = state.datedTask(task.id) else { return }
        editing = .edit(d)
    }

    private func add(at minute: Int?) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        adding = AddTarget(day: day, minute: minute)
    }
}

/// One row of the axis: the hour column on the left, the content beside it.
private struct AxisRow<Content: View>: View {
    let label: String
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(Theme.fixedFont(10.5, .heavy))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .frame(width: DayTimelineView.column, alignment: .topLeading)
                .padding(.top, 2)
                .accessibilityHidden(true)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: height, alignment: .top)
    }
}

private struct DottedRail: View {
    let height: CGFloat
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 1, y: 0))
            p.addLine(to: CGPoint(x: 1, y: height))
        }
        .stroke(Theme.inactive, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 4]))
        .frame(width: 2, height: height)
        .accessibilityHidden(true)
    }
}

/// A due time on the axis: an 11pt dot in the course colour centred on the
/// column edge, the title, and the box.
struct TimelinePin: View {
    let label: String
    let title: String
    let caption: String
    let tint: Color
    var done = false
    var locked = false
    let onCheck: () -> Void
    var onOpen: () -> Void = {}

    var body: some View {
        AxisRow(label: label, height: 40) {
            HStack(spacing: 10) {
                Circle().fill(tint).frame(width: 11, height: 11)
                    .padding(.leading, -5.5)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Theme.font(14.5, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(caption)
                        .font(Theme.font(11.5, .heavy))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onOpen)
                CheckBox(done: done, locked: locked, size: 30, onTap: onCheck)
                    .padding(.trailing, -7)
            }
            .frame(minHeight: 40)
            .opacity(done ? 0.45 : 1)
            .animation(.easeOut(duration: 0.2), value: done)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(label), \(title). \(caption)")
    }
}

/// A class on the axis: a tinted block as tall as it is long (48pt an hour,
/// never under 34), the duration inside it at the right so no caption line is
/// spent on the range. Under half an hour it drops its location line.
struct TimelineBlock: View {
    let label: String
    let title: String
    let place: String
    let minutes: Int
    let tint: Color
    /// Where the now-line crosses, 0...1 of the height, when now is inside it.
    var nowAt: Double? = nil
    var reduceMotion = false

    private var height: CGFloat { max(34, CGFloat(minutes) / 60 * DayTimelineView.hour) }
    private var short: Bool { minutes < 30 }
    /// The hour label gives way to `now` when the line lands on the block's top.
    private var labelHidden: Bool { nowAt.map { $0 * Double(height) < 14 } ?? false }

    var body: some View {
        AxisRow(label: labelHidden ? "" : label, height: height) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Theme.font(14, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    if !short && !place.isEmpty {
                        Text(place)
                            .font(Theme.font(11.5, .heavy))
                            .foregroundStyle(Theme.mutedDeep)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(DayTimeline.length(minutes))
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.mutedDeep)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, short ? 7 : 9)
            .frame(height: height, alignment: .top)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                .fill(Theme.soft(tint)))
        }
        .overlay(alignment: .topLeading) {
            if let nowAt {
                NowLine(reduceMotion: reduceMotion)
                    .offset(y: CGFloat(nowAt) * height - 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(title), \(DayTimeline.length(minutes)). \(place)")
    }
}

/// Free time between two things. Under two hours: a short row that says how
/// long. Two hours or more: a full row that names the wait and offers a place
/// to put something, with the gap's start already filled in.
struct GapRow: View {
    let from: Int
    let to: Int
    var canAdd = true
    let onAdd: () -> Void

    private var minutes: Int { to - from }
    private var long: Bool { minutes >= DayTimeline.longGap }

    var body: some View {
        AxisRow(label: "", height: long ? 44 : 22) {
            HStack(spacing: 10) {
                DottedRail(height: long ? 34 : 18)
                Text(long ? "\(DayTimeline.length(minutes)) free until \(DayTimeline.clock(to))"
                          : DayTimeline.length(minutes))
                    .font(Theme.font(long ? 12.5 : 12, .heavy))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if long && canAdd {
                    Button(action: onAdd) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .black))
                            Text("Add task")
                                .font(Theme.font(11.5, .black))
                        }
                        .foregroundStyle(Theme.mutedInk)
                        .padding(.horizontal, 11)
                        .frame(height: 44)
                        .background(Capsule().fill(Theme.paperSunk))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a task at \(DayTimeline.clock(from))")
                }
            }
            .frame(height: long ? 44 : 22)
        }
    }
}

/// The now-line between two things on the axis.
private struct NowRow: View {
    var reduceMotion = false

    var body: some View {
        NowLine(reduceMotion: reduceMotion)
            .frame(height: 20)
    }
}

/// A 1.5pt coral line from the column edge to the right margin, a dot just
/// inside the column, and the word `now` — a word, not a time. The line
/// breathes (2.4s, 1 → .42); the dot and the word do not. Under Reduce Motion
/// it holds still at full strength.
private struct NowLine: View {
    var reduceMotion = false
    @State private var breathe = false

    var body: some View {
        ZStack(alignment: .leading) {
            Text("now")
                .font(Theme.fixedFont(11, .black))
                .foregroundStyle(Theme.coralShade)
                .frame(width: DayTimelineView.column, alignment: .leading)
                .offset(y: -11)
            Circle().fill(Theme.coral).frame(width: 9, height: 9)
                .offset(x: DayTimelineView.column - 6)
            Rectangle().fill(Theme.coral)
                .frame(height: 1.5)
                .padding(.leading, DayTimelineView.column)
                .opacity(breathe ? 0.42 : 1)
        }
        .frame(height: 20)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { breathe = true }
        }
        .accessibilityLabel("Now")
    }
}

// MARK: - Bits

private struct FabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The tag that says a thing costs money. It sits on the label, never on the row:
/// the row is never disabled, greyed or padlocked.
struct PlusTag: View {
    var body: some View {
        Text("PLUS")
            .font(Theme.fixedFont(9, .black))
            .tracking(0.4)
            .foregroundStyle(Theme.coinDark)
            .padding(.horizontal, 6).padding(.vertical, 2.5)
            .background(Capsule().fill(Theme.coinSoft))
            .overlay(Capsule().strokeBorder(Theme.coinBorder.opacity(0.5), lineWidth: 1))
    }
}

extension Theme {
    /// "#FF6F61" → a colour; nil for anything that is not a hex colour.
    static func color(_ hex: String?) -> Color? {
        guard var s = hex?.trimmingCharacters(in: .whitespaces) else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        return Theme.hex(v)
    }

    /// A course colour as a tint: the colour at 16% over white, which is what
    /// `coralSoft`, `mintSoft` and the sky tile all are. Opaque, so it looks the
    /// same on the paper and on a card.
    static func soft(_ c: Color) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        let k: CGFloat = 0.16
        return Color(red: 1 - (1 - r) * k, green: 1 - (1 - g) * k, blue: 1 - (1 - b) * k)
    }

    /// A course colour as ink: darker and a little more saturated, so a time
    /// written in it reads on the colour's own tint (`coralShade` is this for
    /// coral).
    static func deep(_ c: Color) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: min(1, s + 0.15), brightness: b * 0.78)
    }
}

/// A day is identified by the day it is, which is what lets a `DayKey` drive a
/// sheet or a push directly.
extension DayKey: Identifiable {
    var id: String { raw }
}

/// A written calendar file, on its way to the share sheet.
struct ExportFile: Identifiable {
    let url: URL
    var id: String { url.path }
}

/// The system share sheet, for the calendar file. `ShareLink` would do, but this is
/// presented from a menu action rather than tapped directly, so it needs to be a
/// sheet that can be raised from code.
struct ShareLinkSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
