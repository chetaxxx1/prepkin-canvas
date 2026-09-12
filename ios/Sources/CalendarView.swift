import SwiftUI

/// The Calendar tab: what is coming, by week or by month. Home is "what do I do
/// right now"; this is the same work laid out on days, plus the course
/// calendar's events and anything the student put on a day themselves.
///
/// `design/CLAUDE-DESIGN-PROMPT-CALENDAR.md` is the brief this is built to.
/// The spine is Things 3's "Upcoming": **only days with something on them exist
/// on screen**. A run of empty days is one folded line (Google Calendar's
/// schedule view), today with nothing on it is one inline line, and anything
/// still open from earlier sits in one **Still counts** group at the top, the
/// way Todoist groups overdue. The `+` opens Todoist-style quick add, where the
/// date is typed in words. One floating button; no camera anywhere, because the
/// reader is not deployed (`ScanClient.isDeployed`).
struct CalendarView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var plus: PlusStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Zoom: String, CaseIterable { case week, month }

    @State private var zoom: Zoom = .week
    @State private var selected: DayKey = .today()
    /// The first day of the visible week / month, as the student paged to it.
    @State private var anchor: Date = Date()
    /// The count line under the title goes once the agenda scrolls.
    @State private var captionVisible = true
    /// The day the `+` sheet is adding to. Non-nil while that sheet is up.
    @State private var adding: DayKey?
    @State private var editing: TaskEditorSheet.Mode?
    @State private var showScan = false
    @State private var showPlus = false
    /// Which entry point opened the sheet. The top third of it changes with this.
    @State private var plusReason: PlusSheet.Reason = .scan
    @State private var exportFile: ExportFile?
    @State private var showCalc = false
    /// Ticks so "happening now" stops being true when the hour is over.
    @State private var now = Date()
    @State private var todayPulse: CGFloat = 1

    private let cal = Calendar.current
    private let minute = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    /// The tab bar's own height above the safe area, and the values the handoff
    /// measures from the bottom of the screen, less the home indicator.
    private enum L {
        static let tabBar: CGFloat = 58
        static let scrollInset: CGFloat = 172
        static let fabBottom: CGFloat = 78
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                titleBand
                switch zoom {
                case .week: stripCard
                case .month: gridCard
                }
                agenda
            }

            fade

            fab
        }
        .onReceive(minute) { now = $0 }
        .sheet(item: $adding) { day in
            QuickAddSheet(day: day, onMore: { draft in
                adding = nil
                openEditor(with: draft)
            }, onPhoto: {
                adding = nil
                openScan()
            }, isPlus: isPlus)
            .environmentObject(state)
        }
        .sheet(item: $editing) { mode in
            TaskEditorSheet(mode: mode) { day in
                // Land on the day it went on, so the new row is on screen.
                withAnimation(pageMotion) {
                    selected = day
                    if let d = day.date() { anchor = d; snapAnchor() }
                }
            }
            .environmentObject(state)
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
        .onAppear {
            snapAnchor()
            land(onRequestedDay: true)
        }
        // Home's Tomorrow line asked for a day. Arriving while this tab is already
        // on screen has no onAppear, so the change is watched too.
        .onChange(of: state.openCalendarOn) { _, _ in land(onRequestedDay: false) }
    }

    /// Move to the day Home asked for, and clear the request so a later visit to
    /// this tab opens on today again.
    private func land(onRequestedDay immediate: Bool) {
        guard let day = state.openCalendarOn else { return }
        zoom = .week
        if immediate {
            selected = day
            if let d = day.date() { anchor = d; snapAnchor() }
        } else {
            withAnimation(pageMotion) {
                selected = day
                if let d = day.date() { anchor = d; snapAnchor() }
            }
        }
        state.openCalendarOn = nil
    }

    // MARK: - Title band

    private var titleBand: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                // The month, not the word "Calendar" — the tab bar already says that, and
                // the day strip underneath can show you days but never which month they
                // are in. Same job Apple Calendar gives its big line.
                Text(monthName(anchor))
                    .font(Theme.font(34, .black))
                    .foregroundStyle(Theme.ink)
                    // One line, always. At the largest type "September" wrapped to
                    // "Septembe / r"; Outlook's header shrinks before it breaks
                    // (Mobbin a6fd424b-68a6-40e5-ad65-e0257449ff2a).
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                if captionVisible {
                    Text(countLine)
                        .font(Theme.font(12.5, .heavy))
                        .foregroundStyle(Theme.muted)
                        .contentTransition(.numericText())
                }
            }
            Spacer(minLength: 8)
            exportButton.padding(.top, 6)
            CoinBadge(coins: state.coins)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
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
                .frame(width: 44, height: 44)
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

    /// One line, about the range on screen. Says what is left, never a ratio.
    private var countLine: String {
        let days = visibleDays
        let open = days.flatMap { state.tasks(on: $0) }.filter { !$0.done }.count
        let events = days.flatMap { state.events(on: $0) }.count
        let range = zoom == .week ? "this week" : monthName(anchor)
        var parts: [String] = []
        if open > 0 { parts.append(open == 1 ? "1 thing due \(range)" : "\(open) things due \(range)") }
        if events > 0 { parts.append(events == 1 ? "1 event" : "\(events) events") }
        if parts.isEmpty { return zoom == .week ? "Nothing due this week" : "Nothing due this month" }
        return parts.joined(separator: " · ")
    }

    // MARK: - The strip card, which is the chrome

    private var stripCard: some View {
        VStack(spacing: 2) {
            controlRow
            HStack(spacing: 2) {
                ForEach(weekDays(from: anchor), id: \.raw) { stripDay($0) }
            }
        }
        .padding(.top, 6).padding(.horizontal, 10).padding(.bottom, 8)
        .background(cardBackground)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .gesture(swipe)
        .animation(pageMotion, value: anchor)
    }

    private func stripDay(_ day: DayKey) -> some View {
        let date = day.date() ?? Date()
        let isToday = day == .today()
        let isSelected = day == selected
        let isPast = day < .today()
        return Button { select(day) } label: {
            VStack(spacing: 3) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(Theme.fixedFont(10.5, .black))
                    .foregroundStyle(isToday ? Theme.coralShade : Theme.dim)
                Text(date.formatted(.dateTime.day()))
                    .font(Theme.fixedFont(17, .black))
                    .foregroundStyle(isToday ? .white : (isPast ? Theme.dim : Theme.ink))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(isToday ? Theme.coral : .clear))
                DayLoadStack(colors: load(on: day), past: isPast)
            }
            .padding(.top, 5).padding(.bottom, 6)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .fill(isSelected ? Theme.coralSoft : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityValue(loadLabel(on: day))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Week · Month on the left, ‹ Today › on the right — both inside the card, which
    /// is what buys the 100-odd points the old third band was spending.
    private var controlRow: some View {
        HStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Zoom.allCases, id: \.self) { z in segment(z) }
            }
            .padding(2)
            .background(Capsule().fill(Theme.paperSunk))
            Spacer(minLength: 0)
            chevron("chevron.left", -1)
            Button { goToday() } label: {
                Text("Today")
                    .font(Theme.font(13, .black))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(Capsule().fill(Theme.paperSunk))
                    .padding(.top, 12).padding(.bottom, 4)
                    .contentShape(Rectangle())
                    .padding(.top, -12).padding(.bottom, -4)
            }
            .buttonStyle(.plain)
            .scaleEffect(todayPulse)
            .accessibilityLabel("Today")
            chevron("chevron.right", 1)
        }
        .frame(height: 32)
        .padding(.horizontal, 2)
    }

    private func segment(_ z: Zoom) -> some View {
        let on = z == zoom
        return Text(z == .week ? "Week" : "Month")
            .font(Theme.font(13, .black))
            .foregroundStyle(on ? Theme.ink : Theme.muted)
            .frame(width: 66, height: 28)
            .background(
                Capsule()
                    .fill(on ? Theme.card : .clear)
                    .shadow(color: on ? Theme.hex(0x2E2622).opacity(0.10) : .clear, radius: 3, y: 1)
            )
            // Paint 28, take 44. The bleed goes mostly upward, into the card's
            // own padding, so it cannot steal the top of a day cell.
            .padding(.top, 12).padding(.bottom, 4)
            .contentShape(Rectangle())
            .padding(.top, -12).padding(.bottom, -4)
            .onTapGesture {
                guard !on else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(pageMotion) { zoom = z; snapAnchor() }
            }
            .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }

    private func chevron(_ glyph: String, _ step: Int) -> some View {
        Button { page(step) } label: {
            Image(systemName: glyph)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .frame(width: 26, height: 28)
                // Paint 26, take 46: the target is not the ink. 9 lands on 43.7
                // once the row divides its width, which the sweep counts as a miss.
                .padding(10)
                .contentShape(Rectangle())
                .padding(-10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(step < 0 ? "Earlier" : "Later")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Theme.card)
            .shadow(color: Theme.hex(0x2E2622).opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - The month grid

    private var gridCard: some View {
        let cells = monthCells(for: anchor)
        return VStack(spacing: 0) {
            controlRow
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                    Text(s)
                        .font(Theme.fixedFont(10.5, .black))
                        .foregroundStyle(Theme.inactive)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 18)
            .padding(.top, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(cells) { cell in monthCell(cell) }
            }
        }
        .padding(.top, 6).padding(.horizontal, 10).padding(.bottom, 10)
        .background(cardBackground)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .gesture(swipe)
        .animation(pageMotion, value: anchor)
    }

    private struct Cell: Identifiable {
        let key: DayKey
        let date: Date
        var id: String { key.raw }
    }

    /// Six rows of seven, starting on the calendar's first weekday, so the grid
    /// never jumps in height between months.
    private func monthCells(for d: Date) -> [Cell] {
        let gridStart = startOfWeek(startOfMonth(d))
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }
            .map { Cell(key: DayKey($0), date: $0) }
    }

    private func monthCell(_ cell: Cell) -> some View {
        let inMonth = cal.isDate(cell.date, equalTo: anchor, toGranularity: .month)
        let isToday = cell.key == .today()
        let isSelected = cell.key == selected
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(selectMotion) {
                selected = cell.key
                if !inMonth { anchor = startOfMonth(cell.date) }
            }
        } label: {
            VStack(spacing: 0) {
                Text(cell.date.formatted(.dateTime.day()))
                    .font(Theme.fixedFont(15, .black))
                    .foregroundStyle(isToday ? .white : (inMonth ? Theme.ink : Theme.hex(0xD8CFC0)))
                    .frame(width: 25, height: 25)
                    .background(Circle().fill(isToday ? Theme.coral : .clear))
                MonthLoadBars(colors: load(on: cell.key), faded: !inMonth)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .fill(isSelected && !isToday ? Theme.coralSoft : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cell.date.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityValue(loadLabel(on: cell.key))
    }

    private var weekdaySymbols: [String] {
        let all = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(all[first...] + all[..<first])
    }

    // MARK: - Paging

    private var visibleDays: [DayKey] {
        switch zoom {
        case .week: return weekDays(from: anchor)
        case .month:
            return monthCells(for: anchor)
                .filter { cal.isDate($0.date, equalTo: anchor, toGranularity: .month) }
                .map(\.key)
        }
    }

    /// Moves the anchor to the start of its week or month, so paging by one unit
    /// lands cleanly after a tap on some other day.
    private func snapAnchor() {
        switch zoom {
        case .week: anchor = startOfWeek(anchor)
        case .month: anchor = startOfMonth(anchor)
        }
    }

    private func page(_ step: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(pageMotion) {
            switch zoom {
            case .week:
                anchor = cal.date(byAdding: .weekOfYear, value: step, to: startOfWeek(anchor)) ?? anchor
                selected = DayKey(anchor)
            case .month:
                anchor = cal.date(byAdding: .month, value: step, to: startOfMonth(anchor)) ?? anchor
                // Land on today when paging home, else the first day with anything on it.
                let today = Date()
                if cal.isDate(anchor, equalTo: today, toGranularity: .month) {
                    selected = DayKey(today)
                } else {
                    let days = monthCells(for: anchor)
                        .filter { cal.isDate($0.date, equalTo: anchor, toGranularity: .month) }
                    selected = days.first { !agendaEntries(on: $0.key).isEmpty }?.key
                        ?? DayKey(anchor)
                }
            }
        }
    }

    private func goToday() {
        UISelectionFeedbackGenerator().selectionChanged()
        let today = DayKey.today()
        let granularity: Calendar.Component = zoom == .week ? .weekOfYear : .month
        let onIt = selected == today && cal.isDate(anchor, equalTo: Date(), toGranularity: granularity)
        guard !onIt else {
            // Already here. A 0.2s pulse and nothing else, so the tap is answered.
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.1)) { todayPulse = 1.04 }
            withAnimation(.easeOut(duration: 0.1).delay(0.1)) { todayPulse = 1 }
            return
        }
        withAnimation(pageMotion) {
            selected = today
            anchor = Date()
            snapAnchor()
        }
    }

    private func select(_ day: DayKey) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(selectMotion) { selected = day }
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
    private func startOfMonth(_ d: Date) -> Date { cal.dateInterval(of: .month, for: d)?.start ?? d }

    private func weekDays(from start: Date) -> [DayKey] {
        let s = startOfWeek(start)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: s) }.map { DayKey($0) }
    }

    private func monthName(_ d: Date) -> String { d.formatted(.dateTime.month(.wide)) }

    // MARK: - Agenda

    private var agenda: some View {
        // The offset is the content's top against the scroll view's own top, both
        // read in global space. A named coordinate space would do the same job in
        // one reader, but this pair also survives the title band collapsing under
        // it — both frames move together, so the difference does not wobble.
        GeometryReader { outer in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        GeometryReader { inner in
                            Color.clear.preference(
                                key: AgendaTopKey.self,
                                value: inner.frame(in: .global).minY - outer.frame(in: .global).minY)
                        }
                        .frame(height: 0)
                        switch zoom {
                        case .week: weekAgenda
                        case .month: daySection(selected).padding(.top, 4)
                        }
                    }
                    .padding(.bottom, L.scrollInset)
                }
                .scrollIndicators(.hidden)
                .onPreferenceChange(AgendaTopKey.self) { y in
                    let show = y > -10
                    guard show != captionVisible else { return }
                    withAnimation(.easeOut(duration: 0.18)) { captionVisible = show }
                }
                .onChange(of: selected) { _, day in
                    guard zoom == .week else { return }
                    withAnimation(selectMotion) { proxy.scrollTo(anchorID(for: day), anchor: .top) }
                }
            }
        }
    }

    /// True while the week on screen is the one today sits in.
    private var weekHoldsToday: Bool { weekDays(from: anchor).contains(.today()) }

    /// The grouping rules live in `Upcoming` so they can be tested without a
    /// screen. This is just the view's read of them.
    private func blocks(_ days: [DayKey]) -> [Upcoming.Block] {
        Upcoming.blocks(days, dropPast: weekHoldsToday) { agendaEntries(on: $0).isEmpty }
    }

    /// The view a tap on the strip should scroll to: the day itself, or the
    /// folded line that swallowed it.
    private func anchorID(for day: DayKey) -> String {
        for block in blocks(weekDays(from: anchor)) {
            switch block {
            case .day(let d) where d == day: return d.raw
            case .folded(let run) where run.contains(day): return block.id
            default: continue
            }
        }
        return day.raw
    }

    private var weekAgenda: some View {
        VStack(spacing: 0) {
            stillCounts
            ForEach(blocks(weekDays(from: anchor))) { block in
                switch block {
                case .folded(let run):
                    FoldedDaysStrip(days: run).id(block.id)
                case .day(let d):
                    daySection(d).id(d.raw)
                }
            }
            nextWeek
            farAhead
        }
    }

    /// When this week and the next have nothing on them, the next dated thing,
    /// however far out, under its own day header — the way Things 3's Upcoming
    /// shows next month's items under a month header (Mobbin
    /// 590f4dd6-1a6d-45a3-91c3-3508a762b041). Past a fortnight the header's lead
    /// is already the month. Before this the end of an empty week was a fish
    /// peeking over the edge of a void.
    @ViewBuilder
    private var farAhead: some View {
        let thisWeek = weekDays(from: anchor).filter { !(weekHoldsToday && $0 < .today()) }
        let nextStart = cal.date(byAdding: .weekOfYear, value: 1, to: startOfWeek(anchor)) ?? anchor
        let both = thisWeek + weekDays(from: nextStart)
        if both.allSatisfy({ agendaEntries(on: $0).isEmpty }),
           let last = both.last,
           let day = Upcoming.nextDated(after: last) { agendaEntries(on: $0).isEmpty } {
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
            HStack(spacing: 8) {
                Text("Still counts")
                    .font(Theme.font(14, .black))
                    .foregroundStyle(Theme.coinDark)
                Rectangle().fill(Theme.coinBorder.opacity(0.35)).frame(height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 9)
            VStack(spacing: 8) {
                ForEach(rows, id: \.id) { row(.task($0)) }
            }
            .padding(.horizontal, 16)
        }
    }

    /// Everything from the last fortnight that is open and was due. Read off the
    /// same day lists the agenda reads, so a Canvas row and a typed row land in
    /// it the same way, oldest first.
    private var overdue: [DailyTask] {
        guard zoom == .week, weekHoldsToday else { return [] }
        return Upcoming.stillCounts { state.tasks(on: $0) }
    }

    /// "What is coming" should not stop at a grid boundary that only exists because
    /// weeks start on Sunday, so anything on the next week's days carries on under a
    /// divider. The strip still pages one week at a time.
    @ViewBuilder
    private var nextWeek: some View {
        let start = cal.date(byAdding: .weekOfYear, value: 1, to: startOfWeek(anchor)) ?? anchor
        let days = weekDays(from: start).filter { !agendaEntries(on: $0).isEmpty }
        if !days.isEmpty {
            HStack(spacing: 10) {
                Rectangle().fill(Theme.chipDivider).frame(height: 1)
                Text("NEXT WEEK")
                    .font(Theme.fixedFont(10, .black))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dim)
                Rectangle().fill(Theme.chipDivider).frame(height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 26)
            ForEach(days, id: \.raw) { daySection($0).id($0.raw) }
        }
    }

    @ViewBuilder
    private func daySection(_ day: DayKey) -> some View {
        let entries = agendaEntries(on: day)
        if entries.isEmpty {
            EmptyDayLine(day: day, past: day < .today()) { openAdd(on: day) }
        } else {
            dayHeader(day)
            VStack(spacing: 8) {
                ForEach(entries) { row($0) }
            }
            .padding(.horizontal, 16)
        }
    }

    private func dayHeader(_ day: DayKey) -> some View {
        let heading = Upcoming.heading(for: day)
        let isPast = day < .today()
        return HStack(spacing: 8) {
            Text(heading.lead)
                .font(Theme.font(14, .black))
                .foregroundStyle(heading.isToday ? Theme.coralShade : (isPast ? Theme.muted : Theme.ink))
            Text(heading.date)
                .font(Theme.font(13, .heavy))
                .foregroundStyle(Theme.dim)
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 9)
    }

    @ViewBuilder
    private func row(_ entry: Entry) -> some View {
        switch entry {
        case .task(let t):
            CalendarTaskRow(task: t, tint: tint(t), note: state.datedTask(t.id)?.notes,
                            onCheck: { toggle(t) }) {
                if t.isDated, let d = state.datedTask(t.id) { editing = .edit(d) }
            }
        case .event(let e):
            EventRow(event: e, tint: eventTint(e), now: now, reduceMotion: reduceMotion)
        }
    }

    // MARK: - What is on a day

    /// A task and an event share a day but not a shape, so the list is one sorted
    /// run of both rather than two stacks.
    private enum Entry: Identifiable {
        case task(DailyTask)
        case event(CanvasEvent)

        var id: String {
            switch self {
            case .task(let t): return "t-\(t.id)"
            case .event(let e): return "e-\(e.id)"
            }
        }
    }

    /// All-day events, then all-day and undated tasks, then everything timed in time
    /// order with tasks and events interleaved.
    private func agendaEntries(on day: DayKey) -> [Entry] {
        let entries = state.events(on: day).map(Entry.event) + state.tasks(on: day).map(Entry.task)
        return entries.sorted { order($0) < order($1) }
    }

    private func order(_ e: Entry) -> (Int, Int, Int) {
        switch e {
        case .event(let ev):
            return ev.allDay ? (0, 0, 0) : (1, minuteOf(ev.startAt), 0)
        case .task(let t):
            guard let due = t.dueAt else { return (0, 1, 0) }
            let m = minuteOf(due)
            // Canvas's own end-of-day default. A minute that means nothing is not shown.
            return m >= 23 * 60 + 59 ? (0, 1, 0) : (1, m, 1)
        }
    }

    private func minuteOf(_ d: Date) -> Int {
        let c = cal.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// One bar per open thing on a day, in course colour, chronological. Done work
    /// drops its bar, so a busy day thins out as it gets done.
    private func load(on day: DayKey) -> [Color] {
        agendaEntries(on: day).compactMap { e in
            switch e {
            case .task(let t): return t.done ? nil : tint(t)
            case .event(let ev): return eventTint(ev)
            }
        }
    }

    private func loadLabel(on day: DayKey) -> String {
        let n = agendaEntries(on: day).count
        if n == 0 { return "Free" }
        return n == 1 ? "1 thing" : "\(n) things"
    }

    /// Colour means *course* on this screen. A task with no course gets a warm grey,
    /// never coral — coral is the button.
    private func tint(_ t: DailyTask) -> Color {
        Theme.color(t.colorHex) ?? Theme.dim
    }

    private func eventTint(_ e: CanvasEvent) -> Color {
        Theme.color(e.colorHex) ?? Theme.sky
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

    /// One read, through `AppState`, so the gift week and the debug flag are in it
    /// too. A view that spells this out for itself is a view that will one day
    /// disagree with the Shop about whether a student is Plus.
    private var isPlus: Bool { state.isPlus }

    private func openAdd(on day: DayKey) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        adding = day < .today() ? .today() : day
    }

    /// Both of these are called from inside a sheet that is on its way out — a
    /// sheet presented in the same turn as another is dropped.
    private func openEditor(with draft: DatedTask) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            editing = .draft(draft)
        }
    }

    private func openScan() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            if isPlus { showScan = true } else { showPlus = true }
        }
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
                        .shadow(color: Theme.coral.opacity(0.4), radius: 12, y: 7))
            }
            .buttonStyle(FabPressStyle())
            .accessibilityLabel("Add something")
        }
        .padding(.trailing, 20)
        .padding(.bottom, L.fabBottom)
    }
}

// MARK: - Load

private struct AgendaTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    /// Every sibling in the scroll content hands up the default, so a plain
    /// `value = nextValue()` ends the walk on a 0 and the offset never moves.
    /// Only a real reading counts.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next != 0 { value = next }
    }
}

/// A day's load as a bar chart standing on the bottom of the column: three items
/// are visibly taller than one from across the room, and the bars are countable in
/// a way a tinted cell is not.
struct DayLoadStack: View {
    let colors: [Color]
    var past = false

    private var shown: [Color] { colors.count > 4 ? Array(colors.prefix(3)) : colors }
    private var overflow: Int { colors.count > 4 ? colors.count - 3 : 0 }

    var body: some View {
        VStack(spacing: 2.5) {
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(Theme.fixedFont(8.5, .black))
                    .foregroundStyle(Theme.dim)
            }
            ForEach(Array(shown.enumerated().reversed()), id: \.offset) { _, c in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(c.opacity(past ? 0.4 : 1))
                    .frame(width: 20, height: 3)
            }
        }
        .frame(height: 20, alignment: .bottom)
    }
}

/// The same language, laid horizontally, for a month cell.
struct MonthLoadBars: View {
    let colors: [Color]
    var faded = false

    private var shown: [Color] { colors.count > 3 ? Array(colors.prefix(2)) : colors }
    private var overflow: Int { colors.count > 3 ? colors.count - 2 : 0 }

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, c in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(c.opacity(faded ? 0.4 : 1))
                    .frame(width: 11, height: 3)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(Theme.fixedFont(8.5, .black))
                    .foregroundStyle(Theme.dim)
            }
        }
        .frame(height: 9)
    }
}

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

// MARK: - Rows

/// A task on a day: a white card floating on the paper, with the course's colour
/// as a rail down its left edge. Home's `TaskRow` anatomy — tile, title, caption,
/// coin column, 33pt box, 62% fade when done, never a strikethrough.
struct CalendarTaskRow: View {
    let task: DailyTask
    let tint: Color
    var note: String?
    let onCheck: () -> Void
    let onOpen: () -> Void

    @State private var nudge: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            IconTile(icon: task.category.rawValue, size: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(Theme.font(15.5, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(caption)
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
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
                    .padding(.top, 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)

            HStack(spacing: 8) {
                if task.isLocked {
                    KinIcon(.lock, size: 12, color: Theme.dim)
                        .offset(x: nudge)
                }
                HStack(spacing: 3) {
                    CoinDisc(size: 13)
                    Text("\(task.reward)")
                        .font(Theme.font(13, .black))
                        .foregroundStyle(Theme.coinDark)
                }
                checkbox
            }
        }
        .padding(.leading, 13).padding(.trailing, 13).padding(.vertical, 10)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.card)
                .overlay(alignment: .leading) { Rectangle().fill(tint).frame(width: 4) }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .shadow(color: Theme.hex(0x2E2622).opacity(0.07), radius: 3, y: 2)
        )
        // Finished rows just fade. No strikethrough — done is not cancelled.
        .opacity(task.done ? 0.62 : 1)
        .animation(.easeOut(duration: 0.2), value: task.done)
    }

    private var checkbox: some View {
        Button {
            guard !task.isLocked else {
                // Canvas owns this one. Say so on the lock, not with an error.
                withAnimation(.easeInOut(duration: 0.06)) { nudge = 3 }
                withAnimation(.easeInOut(duration: 0.06).delay(0.06)) { nudge = 0 }
                return
            }
            onCheck()
        } label: {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(task.done ? Theme.check : Theme.checkFill)
                .overlay {
                    if task.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.white)
                    } else {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(Theme.checkBorder, lineWidth: 2.5)
                    }
                }
                .frame(width: 33, height: 33)
                .padding(5.5)
                .contentShape(Rectangle())
                .padding(-5.5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isLocked ? "Handed in on Canvas" : (task.done ? "Done" : "Mark done"))
    }

    /// `{course} · all day` · `{course} · due 8:00 AM` · `{course} · handed in` ·
    /// `{course} · was due Tue` · `{kind} · 7:30 PM`.
    private var caption: String {
        let who = task.detail ?? task.kind.label
        if task.isLocked { return "\(who) · handed in" }
        guard let due = task.dueAt else { return "\(who) · all day" }
        let cal = Calendar.current
        if !task.done && due < Date() && !cal.isDateInToday(due) {
            return "\(who) · was due \(due.formatted(.dateTime.weekday(.abbreviated)))"
        }
        let c = cal.dateComponents([.hour, .minute], from: due)
        // Canvas's own end-of-day default: the student is not told a minute that
        // means nothing.
        if c.hour == 23 && c.minute == 59 { return "\(who) · all day" }
        let time = due.formatted(.dateTime.hour().minute())
        return task.kind == .canvas ? "\(who) · due \(time)" : "\(who) · \(time)"
    }
}

/// Something that happens rather than gets handed in. Not a card: a ruled entry on
/// the paper, with a rail as long as the event is. Two hours is visibly bigger than
/// one, and the size comes from `startAt`/`endAt` rather than from a guess.
struct EventRow: View {
    let event: CanvasEvent
    let tint: Color
    var now: Date = Date()
    var reduceMotion = false

    @State private var pulse = false

    /// "2:00" — the hour without its AM/PM, which rides in its own line under it
    /// and in the second half of a range. Built from the locale's own time pattern
    /// with the meridiem struck out, so a 12-hour locale keeps `h:mm` (no leading
    /// zero) and a 24-hour one still reads `14:00`.
    private static let clockFormat: DateFormatter = {
        let f = DateFormatter()
        let pattern = DateFormatter.dateFormat(fromTemplate: "jmm", options: 0, locale: .current) ?? "h:mm"
        f.dateFormat = pattern.replacingOccurrences(of: "a", with: "")
            .trimmingCharacters(in: .whitespaces)
        return f
    }()

    private func clock(_ d: Date) -> String { Self.clockFormat.string(from: d) }

    private static let meridiem: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("a")
        return f
    }()

    private var isNow: Bool {
        guard !event.allDay, let end = event.endAt else { return false }
        return event.startAt <= now && now <= end
    }

    /// 44pt for the first hour, 20 more for every hour after it.
    private var rail: CGFloat {
        guard !event.allDay, let end = event.endAt, end > event.startAt else { return 44 }
        let hours = end.timeIntervalSince(event.startAt) / 3600
        return min(44 + max(0, hours - 1) * 20, 140)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            time
                .frame(width: 46, alignment: .trailing)
            mark
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(Theme.font(15, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    if isNow {
                        Text("NOW")
                            .font(Theme.fixedFont(9, .black))
                            .tracking(0.6)
                            .foregroundStyle(Theme.coralShade)
                            .padding(.horizontal, 6).padding(.vertical, 2.5)
                            .background(Capsule().fill(Theme.coralSoft))
                    }
                }
                Text(caption)
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var time: some View {
        if event.allDay {
            Text("ALL DAY")
                .font(Theme.fixedFont(9.5, .black))
                .foregroundStyle(Theme.dim)
                .padding(.top, 3)
        } else {
            VStack(alignment: .trailing, spacing: 0) {
                Text(clock(event.startAt))
                    .font(Theme.fixedFont(13, .black))
                    .foregroundStyle(Theme.ink)
                Text(Self.meridiem.string(from: event.startAt))
                    .font(Theme.fixedFont(9.5, .heavy))
                    .foregroundStyle(Theme.dim)
            }
        }
    }

    private var mark: some View {
        VStack(spacing: 0) {
            dot
            if !event.allDay {
                Capsule().fill(tint.opacity(0.45)).frame(width: 2)
            }
        }
        .frame(width: 10, height: event.allDay ? 10 : rail, alignment: .top)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var dot: some View {
        if isNow {
            ZStack {
                Circle().strokeBorder(Theme.coral, lineWidth: 2.5).frame(width: 10, height: 10)
                Circle().fill(Theme.coral).frame(width: 4, height: 4)
            }
            .opacity(pulse ? 0.45 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
            }
        } else if event.allDay {
            Circle().strokeBorder(tint, lineWidth: 2.5).frame(width: 10, height: 10)
        } else {
            Circle().fill(tint).frame(width: 10, height: 10)
        }
    }

    /// `{course} · 2:00–3:00 PM · Moore 202`, and mid-event the one thing a student
    /// actually wants: when it ends.
    private var caption: String {
        var parts: [String] = []
        if !event.courseName.isEmpty { parts.append(event.courseName) }
        if event.allDay {
            parts.append("all day")
        } else if isNow, let end = event.endAt {
            parts.append("until \(end.formatted(.dateTime.hour().minute()))")
        } else if let end = event.endAt, end > event.startAt {
            parts.append("\(clock(event.startAt))–\(end.formatted(.dateTime.hour().minute()))")
        } else {
            parts.append(event.startAt.formatted(.dateTime.hour().minute()))
        }
        if let loc = event.location, !loc.isEmpty { parts.append(loc) }
        return parts.joined(separator: " · ")
    }
}

/// A day with nothing on it costs one line, and the line is the way in — Google
/// Calendar's "Nothing planned. Tap to create." Only today and the day picked in
/// the month grid ever draw it; every other empty day folds into the strip below.
struct EmptyDayLine: View {
    let day: DayKey
    var past = false
    let onTap: () -> Void

    private var sentence: String { past ? "Nothing due." : "Nothing due. Tap to add." }

    var body: some View {
        let date = day.date() ?? Date()
        let isToday = day == .today()
        return Button(action: onTap) {
            HStack(spacing: 7) {
                Text(isToday ? "Today" : date.formatted(.dateTime.weekday(.wide)))
                    .font(Theme.font(14, .black))
                    .foregroundStyle(isToday ? Theme.coralShade : Theme.muted)
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Theme.dim)
                Spacer(minLength: 8)
                Text(sentence)
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.inactive)
                    .lineLimit(1)
            }
            .frame(height: 34)
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(past)
        .accessibilityLabel("\(date.formatted(.dateTime.weekday(.wide).month().day())). \(sentence)")
    }
}

/// Seven headers for three items becomes one line for a run of empty days —
/// Google Calendar folds an empty stretch the same way. It is a label, not a
/// control: there is nothing under it to open, and a date typed into quick add
/// reaches any of these days in one line.
struct FoldedDaysStrip: View {
    let days: [DayKey]

    var body: some View {
        HStack(spacing: 9) {
            Text(label)
                .font(Theme.font(13, .heavy))
                .foregroundStyle(Theme.muted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .fill(Theme.paperSunk))
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    private var label: String { Upcoming.foldLabel(days) }
}

extension Theme {
    /// "#FF6F61" → a colour; nil for anything that is not a hex colour.
    static func color(_ hex: String?) -> Color? {
        guard var s = hex?.trimmingCharacters(in: .whitespaces) else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        return Theme.hex(v)
    }
}

/// A day is identified by the day it is, which is what lets a `DayKey` drive a
/// sheet directly.
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
