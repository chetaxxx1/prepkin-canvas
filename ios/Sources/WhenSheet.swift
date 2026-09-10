import SwiftUI

/// Things 3's "When", for the Date chip on quick add.
///
/// Two pre-answered rows, a compact month grid, and one time control. Tapping a
/// day is the whole interaction — it sets the day and closes. There is no
/// "Someday": every task in this app lands on a day. There is no reminder line
/// either, because reminders for typed tasks are not built.
struct WhenSheet: View {
    @Binding var day: DayKey
    @Binding var minute: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var month: Date = Date()
    @State private var time = Date()

    private let cal = Calendar.current
    /// What "this evening" means. 6 PM, and nothing else.
    private static let evening = 18 * 60

    var body: some View {
        VStack(spacing: 0) {
            header
            quickRows
            grid
            timeRow
            Spacer(minLength: 0)
        }
        .background(Theme.paper)
        .presentationBackground(Theme.paper)
        // 33 header + 117 rows + 339 grid + 68 time + the home indicator. Short
        // by even ten and the "When?" line crops off the top of the sheet.
        .presentationDetents([.height(600)])
        .presentationCornerRadius(Theme.Radius.sheet)
        .presentationDragIndicator(.hidden)
        .onAppear(perform: load)
    }

    private var header: some View {
        ZStack {
            Text("When?")
                .font(Theme.font(17, .black))
                .foregroundStyle(Theme.ink)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(Theme.font(15, .heavy))
                    .foregroundStyle(Theme.muted)
                    .frame(minWidth: 60, minHeight: 44, alignment: .trailing)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var quickRows: some View {
        VStack(spacing: 0) {
            row(glyph: "sun.max.fill", tint: Theme.coin, title: "Today",
                trailing: shortDate(.today())) {
                pick(.today(), minute: minute)
            }
            Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 56)
            row(glyph: "moon.fill", tint: Theme.lavender, title: "This evening",
                trailing: eveningLabel) {
                pick(.today(), minute: Self.evening)
            }
        }
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Theme.card))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func row(glyph: String, tint: Color, title: String, trailing: String,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: glyph)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(tint)
                    .frame(width: 28)
                Text(title)
                    .font(Theme.font(15.5, .black))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Text(trailing)
                    .font(Theme.font(13.5, .heavy))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - The grid

    private var grid: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(Theme.font(14.5, .black))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                step("chevron.left", -1)
                step("chevron.right", 1)
            }
            .padding(.horizontal, 4)

            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                    Text(s)
                        .font(Theme.fixedFont(10.5, .black))
                        .foregroundStyle(Theme.inactive)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                      spacing: 2) {
                ForEach(cells, id: \.self) { date in cell(date) }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Theme.card))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func step(_ glyph: String, _ by: Int) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.16)) {
                month = cal.date(byAdding: .month, value: by, to: month) ?? month
            }
        } label: {
            Image(systemName: glyph)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .frame(width: 44, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(by < 0 ? "Earlier month" : "Later month")
    }

    /// Six rows of seven so the sheet never changes height between months.
    private var cells: [Date] {
        let first = cal.dateInterval(of: .month, for: month)?.start ?? month
        let start = cal.dateInterval(of: .weekOfYear, for: first)?.start ?? first
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func cell(_ date: Date) -> some View {
        let key = DayKey(date)
        let inMonth = cal.isDate(date, equalTo: month, toGranularity: .month)
        let isToday = key == .today()
        let isPicked = key == day
        let isPast = key < .today()
        // Things marks the first of a month inside its cell, so a grid that runs
        // past the end of the month still says where it is.
        let rollover = cal.component(.day, from: date) == 1 && !inMonth
        return Button {
            pick(key, minute: minute)
        } label: {
            VStack(spacing: 0) {
                if rollover {
                    Text(date.formatted(.dateTime.month(.abbreviated)))
                        .font(Theme.fixedFont(8.5, .black))
                        .foregroundStyle(Theme.dim)
                }
                Text(date.formatted(.dateTime.day()))
                    .font(Theme.fixedFont(15, .black))
                    .foregroundStyle(ink(isToday: isToday, isPicked: isPicked,
                                         inMonth: inMonth, isPast: isPast))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .fill(isPicked ? Theme.coral : (isToday ? Theme.coralSoft : .clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityAddTraits(isPicked ? [.isSelected, .isButton] : .isButton)
    }

    private func ink(isToday: Bool, isPicked: Bool, inMonth: Bool, isPast: Bool) -> Color {
        if isPicked { return .white }
        if isToday { return Theme.coralShade }
        if !inMonth { return Theme.hex(0xD8CFC0) }
        return isPast ? Theme.dim : Theme.ink
    }

    private var weekdaySymbols: [String] {
        let all = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(all[first...] + all[..<first])
    }

    // MARK: - The time

    private var timeRow: some View {
        HStack {
            Toggle(isOn: Binding(get: { minute != nil }, set: { on in
                withAnimation(.snappy(duration: 0.2)) { minute = on ? minuteOf(time) : nil }
            })) {
                Text("At a time")
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.mint)
            .fixedSize()
            Spacer(minLength: 8)
            if minute != nil {
                DatePicker("", selection: Binding(get: { time }, set: {
                    time = $0
                    minute = minuteOf($0)
                }), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(Theme.coral)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Theme.card))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var eveningLabel: String {
        let base = cal.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        return base.formatted(.dateTime.hour().minute())
    }

    private func shortDate(_ d: DayKey) -> String {
        (d.date() ?? Date()).formatted(.dateTime.month(.abbreviated).day())
    }

    private func minuteOf(_ d: Date) -> Int {
        let c = cal.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func pick(_ key: DayKey, minute newMinute: Int?) {
        UISelectionFeedbackGenerator().selectionChanged()
        day = key
        minute = newMinute
        dismiss()
    }

    private func load() {
        month = day.date() ?? Date()
        let m = minute ?? 17 * 60
        time = cal.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
    }
}
