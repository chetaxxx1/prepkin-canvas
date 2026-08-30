import SwiftUI

/// Where the user decides what "today" is made of, and whether the app is allowed
/// to speak up. Plain system styling on purpose — this is the plumbing screen for
/// the task engine, meant to be restyled once the visual pass reaches it.
struct DayEditorView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle = ""
    @State private var copied = false
    @State private var newKind: TaskKind = .study
    @State private var newRecurrence: Recurrence = .daily

    private var mine: [TaskTemplate] {
        state.templates.filter { !$0.isPreset && $0.retiredOn == nil }
    }

    private func presets(_ kind: TaskKind) -> [TaskTemplate] {
        state.templates.filter { $0.isPreset && $0.kind == kind }
    }

    var body: some View {
        NavigationStack {
            List {
                connectSection
                addSection
                if !mine.isEmpty { mineSection }
                presetSection("Study ideas", kind: .study)
                presetSection("Life care", kind: .life)
                reminderSection
            }
            .navigationTitle("Your day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    /// Setup for the Canvas bridge. The code is the only thing tying this phone to
    /// the laptop — no account, no email, and the Canvas login stays in Chrome.
    private var connectSection: some View {
        Section {
            if let code = state.pairingCode {
                HStack {
                    Text(code)
                        .font(.system(size: 21, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .textSelection(.enabled)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = code
                        copied = true
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(copied ? Theme.mint : Theme.coral)
                    }
                    .buttonStyle(.borderless)
                }
                Text(syncLine).font(.caption).foregroundStyle(Theme.muted)
                Button("Check for new assignments") {
                    Task { await state.syncCanvas() }
                }
                Button("Disconnect", role: .destructive) { state.unpair() }
            } else {
                Button("Show my pairing code") { state.ensurePairingCode() }
            }
        } header: {
            Text("Canvas")
        } footer: {
            Text(state.isBridgeConfigured
                 ? "Type this code into the Prepkin extension in Chrome. Your Canvas login never leaves your laptop."
                 : "This build has no bridge set up, so Canvas tasks are sample data.")
        }
    }

    private var syncLine: String {
        if let status = state.canvasStatus { return status }
        guard let at = state.lastCanvasSyncAt else { return "No list received yet." }
        return "Last list received \(at.formatted(.relative(presentation: .named)))."
    }

    private var addSection: some View {
        Section("Add your own") {
            TextField("e.g. Finish lab report", text: $newTitle)
                .submitLabel(.done)
                .onSubmit(add)
            Picker("Kind", selection: $newKind) {
                Text("Study").tag(TaskKind.study)
                Text("Life").tag(TaskKind.life)
            }
            .pickerStyle(.segmented)
            Picker("Repeat", selection: $newRecurrence) {
                Text("Every day").tag(Recurrence.daily)
                Text("Just once").tag(Recurrence.once)
            }
            .pickerStyle(.segmented)
            Button("Add task", action: add)
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var mineSection: some View {
        Section("Your tasks") {
            ForEach(mine) { t in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.title)
                        Text("\(t.kind.label) · \(t.recurrence == .daily ? "every day" : "once") · +\(t.kind.reward)")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { t.isActive },
                        set: { state.setTemplate(t.id, active: $0) }))
                    .labelsHidden()
                }
            }
            .onDelete { offsets in
                offsets.map { mine[$0].id }.forEach { state.deleteTask($0) }
            }
        }
    }

    private func presetSection(_ title: String, kind: TaskKind) -> some View {
        Section(title) {
            ForEach(presets(kind)) { t in
                Toggle(isOn: Binding(
                    get: { t.isActive },
                    set: { state.setTemplate(t.id, active: $0) })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.title)
                        Text("+\(t.kind.reward) coins").font(.caption).foregroundStyle(Theme.muted)
                    }
                }
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Reminders", isOn: Binding(
                get: { state.settings.remindersEnabled },
                set: { on in Task { await state.setRemindersEnabled(on) } }))

            if state.settings.remindersEnabled {
                Picker("Evening check-in", selection: Binding(
                    get: { state.settings.nudgeHour },
                    set: state.setNudgeHour)) {
                    ForEach(Array(16...22), id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                Toggle("Assignment due dates", isOn: Binding(
                    get: { state.settings.dueRemindersEnabled },
                    set: state.setDueReminders))
                Toggle("A note if you're away a few days", isOn: Binding(
                    get: { state.settings.comeBackRemindersEnabled },
                    set: state.setComeBackReminders))
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Nothing here counts a streak or warns you about losing anything.")
        }
    }

    // MARK: - Behavior

    private func add() {
        state.addTask(title: newTitle, kind: newKind, recurrence: newRecurrence)
        newTitle = ""
    }

    private func hourLabel(_ hour: Int) -> String {
        var c = DateComponents()
        c.hour = hour
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour())
    }
}
