import SwiftUI

/// Add or change a task on a day. One field, one date, one kind. The date is
/// pre-answered (the day the student was looking at), so typing a title and
/// hitting Add is a complete answer.
struct TaskEditorSheet: View {
    enum Mode: Identifiable {
        case new(DayKey)
        /// A new task that quick add already started: the title, day, time and
        /// kind come in filled, and **More** is what opened this.
        case draft(DatedTask)
        case edit(DatedTask)

        var id: String {
            switch self {
            case .new(let d): return "new-\(d.raw)"
            case .draft(let t): return "draft-\(t.id)"
            case .edit(let t): return "edit-\(t.id)"
            }
        }
    }

    let mode: Mode
    /// Called with the day the task landed on, after a save.
    var onSaved: (DayKey) -> Void = { _ in }

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var kind: TaskKind = .study
    @State private var day: DayKey = .today()
    @State private var hasTime = false
    @State private var time = Date()
    @State private var repeats = false
    @State private var notes = ""
    @State private var showPicker = false
    @State private var confirmingDelete = false
    @FocusState private var typing: Bool

    private enum D {
        static let field = Theme.hex(0xF4EDE1)
        static let placeholder = Theme.hex(0xB6A79E)
        static let grabber = Theme.hex(0xE2D8C6)
        static let shadow = Theme.hex(0x2E2622).opacity(0.05)
    }

    private var isNew: Bool {
        switch mode {
        case .new, .draft: return true
        case .edit: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(D.grabber)
                .frame(width: 38, height: 5)
                .frame(height: 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(isNew ? "New task" : "Edit task")
                            .font(Theme.font(26, .black))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        if !isNew {
                            Button {
                                confirmingDelete = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.coralDeep)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Theme.coralSoft))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete task")
                        }
                    }

                    titleField

                    section("When") {
                        whenChips
                        if showPicker {
                            DatePicker("", selection: dayBinding, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(Theme.coral)
                                .padding(.horizontal, 6)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        timeRow
                    }

                    section("Kind") {
                        HStack(spacing: 10) {
                            segmented(["Study", "Life"], selected: kind == .study ? 0 : 1) { i in
                                kind = i == 0 ? .study : .life
                            }
                            .frame(maxWidth: 220)
                            Spacer(minLength: 0)
                            HStack(spacing: 5) {
                                CoinDisc(size: 14)
                                Text("\(kind.reward)")
                                    .font(Theme.font(14, .black))
                                    .foregroundStyle(Theme.coinDark)
                                    .contentTransition(.numericText())
                            }
                            .animation(.snappy, value: kind)
                        }
                        if isNew {
                            Toggle(isOn: $repeats) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Every day from now on")
                                        .font(Theme.font(15, .bold))
                                        .foregroundStyle(Theme.ink)
                                    Text("Comes back each morning, like a habit.")
                                        .font(Theme.font(12.5, .bold))
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                            .tint(Theme.mint)
                        }
                    }

                    section("Notes") {
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Chapters, room, anything to remember")
                                    .font(Theme.font(15, .bold))
                                    .foregroundStyle(D.placeholder)
                                    .padding(.horizontal, 5).padding(.top, 8)
                            }
                            TextEditor(text: $notes)
                                .font(Theme.font(15, .bold))
                                .foregroundStyle(Theme.ink)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 64)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.paper))
                    }

                    Button(action: save) {
                        Text(isNew ? "Add" : "Save")
                            .font(Theme.font(17, .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(canSave ? Theme.coral : Theme.coral.opacity(0.4)))
                            .shadow(color: Theme.coral.opacity(canSave ? 0.3 : 0), radius: 10, y: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.paper)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.paper)
        .presentationDetents([.large])
        .onAppear(perform: load)
        .confirmationDialog("Delete this task?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if case .edit(let t) = mode { state.deleteDated(t.id) }
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        }
    }

    // MARK: - Pieces

    private var titleField: some View {
        ZStack(alignment: .leading) {
            if title.isEmpty {
                Text("Bio quiz, ch. 3–4")
                    .font(Theme.font(19, .bold))
                    .foregroundStyle(D.placeholder)
            }
            TextField("", text: $title)
                .font(Theme.font(19, .bold))
                .foregroundStyle(Theme.ink)
                .focused($typing)
                .submitLabel(.done)
                .onSubmit { if canSave { save() } }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Theme.card)
            .shadow(color: D.shadow, radius: 11, y: 8))
    }

    private func section<C: View>(_ name: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(name.uppercased())
                .font(Theme.font(11.5, .black))
                .foregroundStyle(Theme.muted)
                .kerning(0.8)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 12) { content() }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: D.shadow, radius: 11, y: 8))
        }
    }

    private var whenChips: some View {
        let today = DayKey.today()
        let tomorrow = today.adding(days: 1)
        let custom = day != today && day != tomorrow
        return HStack(spacing: 8) {
            chip("Today", on: day == today && !showPicker) { day = today; showPicker = false }
            chip("Tomorrow", on: day == tomorrow && !showPicker) { day = tomorrow; showPicker = false }
            chip(custom || showPicker ? shortDate(day) : "Pick a day", on: custom || showPicker, glyph: "calendar") {
                withAnimation(.snappy(duration: 0.25)) { showPicker.toggle() }
            }
        }
    }

    private func chip(_ label: String, on: Bool, glyph: String? = nil, _ tap: @escaping () -> Void) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.snappy(duration: 0.22)) { tap() }
        } label: {
            HStack(spacing: 5) {
                if let glyph {
                    Image(systemName: glyph).font(.system(size: 12, weight: .black))
                }
                Text(label).font(Theme.font(14, .black))
            }
            .foregroundStyle(on ? Theme.coralShade : Theme.ink.opacity(0.8))
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(Capsule().fill(on ? Theme.coralSoft : D.field))
            .overlay(Capsule().strokeBorder(on ? Theme.coral.opacity(0.6) : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var timeRow: some View {
        HStack {
            Toggle(isOn: $hasTime.animation(.snappy(duration: 0.22))) {
                Text("At a time")
                    .font(Theme.font(15, .bold))
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.mint)
            .fixedSize()
            Spacer()
            if hasTime {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(Theme.coral)
                    .transition(.opacity)
            }
        }
    }

    private func segmented(_ labels: [String], selected: Int, pick: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                let on = i == selected
                Text(label)
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(on ? Theme.ink : Theme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(on ? Theme.card : .clear)
                            .shadow(color: on ? Theme.hex(0x2E2622).opacity(0.12) : .clear, radius: 3, y: 2)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UISelectionFeedbackGenerator().selectionChanged()
                        pick(i)
                    }
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 21, style: .continuous).fill(D.field))
    }

    // MARK: - Data

    private var dayBinding: Binding<Date> {
        Binding(get: { day.date() ?? Date() }, set: { day = DayKey($0) })
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    private func shortDate(_ d: DayKey) -> String {
        (d.date() ?? Date()).formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private func load() {
        switch mode {
        case .new(let d):
            day = d
            time = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
            typing = true
        case .draft(let t):
            title = t.title
            kind = t.kind
            day = t.day
            if let m = t.minute {
                hasTime = true
                time = Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
            } else {
                time = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
            }
            typing = title.isEmpty
        case .edit(let t):
            title = t.title
            kind = t.kind
            day = t.day
            notes = t.notes ?? ""
            if let m = t.minute {
                hasTime = true
                time = Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        let minute = hasTime ? (c.hour ?? 0) * 60 + (c.minute ?? 0) : nil
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .new, .draft:
            if repeats {
                state.addTask(title: title, kind: kind, recurrence: .daily)
            } else {
                state.addDated(DatedTask(title: title, kind: kind, source: .mine, day: day,
                                         minute: minute, notes: cleanNotes.isEmpty ? nil : cleanNotes))
            }
        case .edit(var t):
            t.title = title
            t.kind = kind
            t.day = day
            t.minute = minute
            t.notes = cleanNotes.isEmpty ? nil : cleanNotes
            state.updateDated(t)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved(repeats && isNew ? .today() : day)
        dismiss()
    }
}
