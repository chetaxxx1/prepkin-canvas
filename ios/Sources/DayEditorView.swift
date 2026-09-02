import SwiftUI

/// The "Your day" sheet, per `design_handoff_your_day_sheet/README.md`.
///
/// Three jobs, top to bottom: pair the phone with the Chrome extension, let the
/// student type their own task, and switch the preset tasks on and off. The kin
/// card at the top is the only running total — no streak, no warning.
struct DayEditorView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle = ""
    @State private var copied = false
    @State private var newKind: TaskKind = .study
    @State private var newRecurrence: Recurrence = .daily
    @FocusState private var typing: Bool

    /// Sheet-only tokens. The rest of the app's cream, ink, muted, coral and mint
    /// are already `Theme`'s; these six are this handoff's own and are matched 1:1.
    private enum D {
        static let placeholder = Theme.hex(0xB6A79E)
        static let field = Theme.hex(0xF4EDE1)     // segmented-control track
        static let trackOff = Theme.hex(0xE6DDCE)  // toggle, off
        static let grabber = Theme.hex(0xE2D8C6)
        static let coralTint = Theme.hex(0xFDECEA)
        static let mintTint = Theme.hex(0xE8F7F0)
        static let mintIcon = Theme.hex(0x3FA681)
        static let goldTint = Theme.hex(0xFFF6E4)
        static let goldInk = Theme.hex(0xB07A16)
        static let gold = Theme.hex(0xF0AE2E)
        static let cardShadow = Theme.hex(0x2E2622).opacity(0.05)
    }

    private var mine: [TaskTemplate] {
        state.templates.filter { !$0.isPreset && $0.retiredOn == nil }
    }

    private func presets(_ kind: TaskKind) -> [TaskTemplate] {
        state.templates.filter { $0.isPreset && $0.kind == kind }
    }

    /// Everything the student could pick, and everything they have.
    private var choices: [TaskTemplate] {
        state.templates.filter { $0.retiredOn == nil }
    }
    private var picked: [TaskTemplate] { choices.filter(\.isActive) }
    private var coinsToday: Int { picked.reduce(0) { $0 + $1.kind.reward } }

    var body: some View {
        VStack(spacing: 0) {
            grabber
            header
            ScrollView {
                VStack(spacing: 0) {
                    kinCard
                    sectionHeader("Canvas", tint: D.mintTint) {
                        Image(systemName: "link")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(D.mintIcon)
                    }
                    canvasCard
                    sectionHeader("Add your own", tint: D.coralTint) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(Theme.coral)
                    }
                    addCard
                    sectionHeader("Presets", tint: D.goldTint) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(D.gold)
                            .frame(width: 11, height: 11)
                            .rotationEffect(.degrees(45))
                    }
                    if !mine.isEmpty {
                        eyebrow("YOUR TASKS", top: 0)
                        rows(mine)
                    }
                    eyebrow("STUDY IDEAS", top: mine.isEmpty ? 0 : 24)
                    rows(presets(.study))
                    eyebrow("LIFE CARE", top: 24)
                    rows(presets(.life))
                    sectionHeader("Reminders", tint: D.mintTint) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(D.mintIcon)
                    }
                    reminderCard
                }
                .padding(.horizontal, 22)
                // The handoff's 118pt clears a tab bar that shows through the sheet.
                // A UIKit sheet covers the tab bar, so that much slack is just a hole.
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.paper)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.paper)
        .task { state.ensurePairingCode() }
    }

    // MARK: - Chrome

    private var grabber: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(D.grabber)
            .frame(width: 38, height: 5)
            .frame(height: 24)
    }

    private var header: some View {
        HStack {
            Text("Your day")
                .font(Theme.font(34, .black))
                .kerning(-0.9)
                .foregroundStyle(Theme.ink)
            Spacer()
            Button { dismiss() } label: {
                Text("Done")
                    .font(Theme.font(17, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Capsule().fill(Theme.coral))
                    .shadow(color: Theme.coral.opacity(0.32), radius: 8, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
    }

    private func sectionHeader<Glyph: View>(_ title: String, tint: Color,
                                            @ViewBuilder glyph: () -> Glyph) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint)
                .frame(width: 28, height: 28)
                .overlay(glyph())
            Text(title)
                .font(Theme.font(22, .heavy))
                .kerning(-0.3)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
        .padding(.top, 26)
        .padding(.bottom, 12)
    }

    private func eyebrow(_ text: String, top: CGFloat) -> some View {
        Text(text)
            .font(Theme.font(12, .bold))
            .kerning(1.5)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.top, top)
            .padding(.bottom, 10)
    }

    // MARK: - Kin companion

    private var kinCard: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.paper)
                .frame(width: 92, height: 92)
                .overlay(
                    SproutImage(speciesID: state.activeChibiID,
                                level: state.activeChibi.level,
                                size: 84)
                        .padding(.bottom, 6)
                )
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Text(pickedLabel)
                        .font(Theme.font(17, .bold))
                        .kerning(-0.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    coinChip("\(coinsToday) today", size: 14).fixedSize()
                }
                Text("Pick a few things. Kin keeps you company.")
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .padding(.top, 4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hairline)
                        Capsule().fill(Theme.mint)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 10)
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .padding(18)
        .background(cardBackground(28))
    }

    private var pickedLabel: String {
        picked.isEmpty ? "Nothing picked yet" : "\(picked.count) of \(choices.count) picked"
    }

    private var progress: CGFloat {
        guard !choices.isEmpty else { return 0 }
        return CGFloat(picked.count) / CGFloat(choices.count)
    }

    // MARK: - Canvas

    /// Paired means the laptop has actually sent a list. A code on its own is only
    /// an invitation.
    private var isPaired: Bool { state.lastCanvasSyncAt != nil }

    @ViewBuilder private var canvasCard: some View {
        if isPaired { pairedCard } else { unpairedCard }
    }

    private var unpairedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(Array((state.pairingCode ?? "").enumerated()), id: \.offset) { _, ch in
                        if ch == "-" {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(D.grabber)
                                .frame(width: 12, height: 3)
                        } else {
                            Text(String(ch))
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 27, height: 44)
                                .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Theme.paper))
                        }
                    }
                }
                Spacer(minLength: 0)
                Button {
                    UIPasteboard.general.string = state.pairingCode
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.18)) { copied = true }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(copied ? Theme.mint : Theme.coral)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(copied ? D.mintTint : D.coralTint))
                }
                .buttonStyle(.plain)
            }
            hairline.padding(.vertical, 18)
            Text(state.isBridgeConfigured
                 ? "Type this into the Prepkin extension in Chrome."
                 : "This build has no bridge set up, so Canvas tasks are sample data.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
        }
        .padding(18)
        .background(cardBackground(26))
    }

    private var pairedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Circle()
                    .fill(Theme.mint)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().strokeBorder(Theme.mint.opacity(0.16), lineWidth: 4)
                        .padding(-4))
                Text("Connected")
                    .font(Theme.font(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text(syncLine)
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            hairline.padding(.vertical, 16)
            HStack(spacing: 26) {
                Button { Task { await state.syncCanvas() } } label: {
                    Text("Check now")
                        .font(Theme.font(17, .bold))
                        .foregroundStyle(Theme.ink)
                }
                Button { state.unpair() } label: {
                    Text("Disconnect")
                        .font(Theme.font(17, .bold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
            }
            .buttonStyle(.plain)
            hairline.padding(.vertical, 16)
            Text("Your Canvas login never leaves your laptop.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 22)
        .background(cardBackground(26))
    }

    private var syncLine: String {
        if let status = state.canvasStatus { return "· \(status)" }
        guard let at = state.lastCanvasSyncAt else { return "" }
        return "· list received \(at.formatted(.relative(presentation: .named)))"
    }

    // MARK: - Add your own

    private var addCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(D.mintTint)
                    .frame(width: 44, height: 44)
                    .overlay(
                        SproutImage(speciesID: state.activeChibiID,
                                    level: state.activeChibi.level,
                                    size: 34)
                            .padding(.bottom, 4)
                    )
                Text("What else is on your plate today?")
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 0)
            }

            ZStack(alignment: .leading) {
                if newTitle.isEmpty {
                    Text("Finish lab report")
                        .font(Theme.font(17, .bold))
                        .foregroundStyle(D.placeholder)
                }
                TextField("", text: $newTitle)
                    .font(Theme.font(17, .bold))
                    .foregroundStyle(Theme.ink)
                    .focused($typing)
                    .submitLabel(.done)
                    .onSubmit(add)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.paper))

            HStack(spacing: 10) {
                segmented(["Study", "Life"], selected: newKind == .study ? 0 : 1) { i in
                    newKind = i == 0 ? .study : .life
                }
                segmented(["Every day", "Just once"], selected: newRecurrence == .daily ? 0 : 1) { i in
                    newRecurrence = i == 0 ? .daily : .once
                }
            }

            HStack(spacing: 8) {
                CoinDisc(size: 15)
                Text("Study pays \(TaskKind.study.reward) coins. Life pays \(TaskKind.life.reward).")
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)

            Button(action: add) {
                Text("Add")
                    .font(Theme.font(17, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(canAdd ? Theme.coral : Theme.coral.opacity(0.4)))
                    .shadow(color: Theme.coral.opacity(canAdd ? 0.3 : 0), radius: 10, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
        }
        .padding(20)
        .background(cardBackground(26))
    }

    private var canAdd: Bool {
        !newTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func segmented(_ labels: [String], selected: Int,
                           pick: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                let on = i == selected
                Text(label)
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(on ? Theme.ink : Theme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .fill(on ? Theme.card : .clear)
                            .shadow(color: on ? Theme.hex(0x2E2622).opacity(0.12) : .clear,
                                    radius: 3, y: 2)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { pick(i) }
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(D.field))
    }

    // MARK: - Task rows

    private func rows(_ templates: [TaskTemplate]) -> some View {
        VStack(spacing: 10) {
            ForEach(templates) { t in
                row(t)
            }
        }
    }

    private func row(_ t: TaskTemplate) -> some View {
        let tint = rowTint(t)
        return HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(tint.bg)
                .frame(width: 50, height: 50)
                .overlay(CategoryIcon(category: category(t), size: 30))
            VStack(alignment: .leading, spacing: 4) {
                Text(t.title)
                    .font(Theme.font(17, .bold))
                    .kerning(-0.2)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    coinChip("+\(t.kind.reward) coins", size: 12.5)
                    HStack(spacing: 4) {
                        Image(systemName: t.recurrence == .daily
                              ? "arrow.triangle.2.circlepath" : "1.circle")
                            .font(.system(size: 11, weight: .bold))
                        Text(t.recurrence == .daily ? "daily" : "once")
                            .font(Theme.font(12.5, .bold))
                    }
                    .foregroundStyle(D.placeholder)
                }
            }
            Spacer(minLength: 0)
            pillToggle(on: t.isActive)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.card)
                .shadow(color: t.isActive ? Theme.mint.opacity(0.14) : D.cardShadow,
                        radius: 11, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(t.isActive ? Theme.mint : .clear, lineWidth: 2.5)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture { state.setTemplate(t.id, active: !t.isActive) }
        .animation(.easeInOut(duration: 0.18), value: t.isActive)
        .contextMenu {
            if !t.isPreset {
                Button("Delete", role: .destructive) { state.deleteTask(t.id) }
            }
        }
    }

    private func pillToggle(on: Bool) -> some View {
        Capsule()
            .fill(on ? Theme.mint : D.trackOff)
            .frame(width: 52, height: 32)
            .overlay(alignment: on ? .trailing : .leading) {
                Circle()
                    .fill(Theme.card)
                    .frame(width: 27, height: 27)
                    .shadow(color: Theme.hex(0x2E2622).opacity(0.22), radius: 3, y: 2)
                    .padding(2.5)
            }
    }

    private func category(_ t: TaskTemplate) -> TaskCategory {
        TaskCategory.of(DailyTask(id: t.id, title: t.title, kind: t.kind))
    }

    /// One tile tint per object, from the handoff's preset list.
    private func rowTint(_ t: TaskTemplate) -> (bg: Color, fg: Color) {
        switch category(t) {
        case .reading:            return (Theme.hex(0xECEFFC), Theme.hex(0x6B79D8))
        case .writing, .problemSet, .labs, .study:
            return (Theme.hex(0xFDF0E4), Theme.hex(0xE08A3C))
        case .lifeCare:           return (Theme.hex(0xE6F3FA), Theme.hex(0x4A9CC4))
        case .walk:               return (D.mintTint, D.mintIcon)
        case .sleep:              return (Theme.hex(0xF2ECFB), Theme.hex(0x8A6FC4))
        case .meal:               return (D.coralTint, Theme.hex(0xE8574A))
        }
    }

    // MARK: - Reminders
    //
    // Not in the handoff, which covers the sheet's three jobs only. Kept because
    // this is still the one place notifications can be turned off, and restyled so
    // it does not read as a leftover system screen.

    private var reminderCard: some View {
        VStack(spacing: 14) {
            settingRow("Reminders", isOn: Binding(
                get: { state.settings.remindersEnabled },
                set: { on in Task { await state.setRemindersEnabled(on) } }))

            if state.settings.remindersEnabled {
                hairline
                HStack {
                    Text("Evening check-in")
                        .font(Theme.font(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    Picker("", selection: Binding(get: { state.settings.nudgeHour },
                                                  set: state.setNudgeHour)) {
                        ForEach(Array(16...22), id: \.self) { Text(hourLabel($0)).tag($0) }
                    }
                    .tint(Theme.coral)
                }
                hairline
                settingRow("Assignment due dates", isOn: Binding(
                    get: { state.settings.dueRemindersEnabled },
                    set: state.setDueReminders))
                hairline
                settingRow("A note if you're away a few days", isOn: Binding(
                    get: { state.settings.comeBackRemindersEnabled },
                    set: state.setComeBackReminders))
            }

            Text("Nothing here counts a streak or warns you about losing anything.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(2)
        }
        .padding(20)
        .background(cardBackground(26))
    }

    private func settingRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(Theme.font(17, .bold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
            Button { isOn.wrappedValue.toggle() } label: {
                pillToggle(on: isOn.wrappedValue)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.18), value: isOn.wrappedValue)
        }
    }

    // MARK: - Shared bits

    private var hairline: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1)
    }

    private func cardBackground(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Theme.card)
            .shadow(color: D.cardShadow, radius: 11, y: 8)
    }

    private func coinChip(_ text: String, size: CGFloat) -> some View {
        HStack(spacing: 5) {
            CoinDisc(size: size)
            Text(text)
                .font(Theme.font(size, .bold))
                .foregroundStyle(D.goldInk)
        }
        .padding(.horizontal, size > 13 ? 10 : 8)
        .padding(.vertical, size > 13 ? 5 : 3)
        .background(RoundedRectangle(cornerRadius: size > 13 ? 14 : 11, style: .continuous)
            .fill(D.goldTint))
    }

    // MARK: - Behavior

    private func add() {
        guard canAdd else { return }
        state.addTask(title: newTitle, kind: newKind, recurrence: newRecurrence)
        newTitle = ""
        typing = false
    }

    private func hourLabel(_ hour: Int) -> String {
        var c = DateComponents()
        c.hour = hour
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour())
    }
}
