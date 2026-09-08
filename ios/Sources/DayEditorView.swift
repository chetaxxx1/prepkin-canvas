import SwiftUI

/// The "Your day" sheet, per `design_handoff_your_day_sheet/README.md`.
///
/// Three jobs, top to bottom: pair the phone with the Chrome extension, let the
/// student type their own task, and switch the preset tasks on and off. The kin
/// card at the top is the only running total — no streak, no warning.
struct DayEditorView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var newTitle = ""
    @State private var copied = false
    @State private var newKind: TaskKind = .study
    @State private var newRecurrence: Recurrence = .daily
    @FocusState private var typing: Bool
    @State private var isEditingMine = false
    @State private var confirmingRemoveID: String?
    /// Which preset lists are unfolded past their first three.
    @State private var expanded: Set<TaskKind> = []

    /// Read from iOS's own answer, never from the switch, so a fresh install —
    /// which has never been asked — stays quiet.
    @State private var remindersBlocked = false

    /// Sheet-only tokens. The rest of the app's cream, ink, muted, coral and mint
    /// are already `Theme`'s; these six are this handoff's own and are matched 1:1.
    enum D {
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
                        mineEyebrow
                        rows(mine, editable: isEditingMine)
                    }
                    eyebrow("STUDY IDEAS", top: mine.isEmpty ? 0 : 24)
                    presetRows(.study)
                    eyebrow("LIFE CARE", top: 24)
                    presetRows(.life)
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
        .task {
            state.ensurePairingCode()
            remindersBlocked = await NotificationScheduler.shared.isDenied()
        }
        .onChange(of: mine.isEmpty) { _, empty in
            if empty { isEditingMine = false; confirmingRemoveID = nil }
        }
        // Coming back from Settings is the only way this can change while the
        // sheet is up, so the note clears itself instead of going stale.
        .onChange(of: scenePhase) { _, new in
            guard new == .active else { return }
            Task { remindersBlocked = await NotificationScheduler.shared.isDenied() }
        }
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

    /// The one eyebrow that carries a button. STUDY IDEAS and LIFE CARE never do.
    /// EDIT swaps each custom row's toggle for a minus, so no row grows a button
    /// it only needs once.
    private var mineEyebrow: some View {
        HStack(spacing: 0) {
            Text("YOUR TASKS")
                .font(Theme.font(12, .bold))
                .kerning(1.5)
                .foregroundStyle(Theme.muted)
                .padding(.leading, 4)
            Spacer(minLength: 0)
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isEditingMine.toggle()
                    confirmingRemoveID = nil
                }
            } label: {
                Text(isEditingMine ? "DONE" : "EDIT")
                    .font(Theme.font(12, .bold))
                    .kerning(1.5)
                    .foregroundStyle(Theme.coral)
                    // A 44pt target, taken back out of the layout so the eyebrow
                    // keeps its own height.
                    .padding(.horizontal, 8)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .padding(.horizontal, -8)
                    .padding(.vertical, -14)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
        }
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
                                skin: state.activeChibi.skinID,
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
                        // Same three-child spacing trap as FirstRunView's copy of
                        // this card: the Spacer cost a second 10pt gap and pushed the
                        // label just under the scale floor, so it truncated.
                        .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    coinChip("\(coinsToday) today", size: 14).fixedSize()
                }
                Text(picked.isEmpty
                     ? "A quiet day is fine. \(state.activeChibi.displayName) is still here."
                     : "Pick a few things. \(state.activeChibi.displayName) keeps you company.")
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
                                // Ranged, not rigid: eight fixed 27pt tiles plus the
                                // dash overflow a 402pt phone by a few points, and an
                                // over-wide row makes the ScrollView centre the whole
                                // column and draw the page a few points off-centre.
                                .frame(minWidth: 20, maxWidth: 27, minHeight: 44, maxHeight: 44)
                                .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Theme.paper))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                 : "This build is not connected to Canvas, so the tasks here are sample data.")
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
                    .fill(linkDot)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().strokeBorder(linkDot.opacity(0.16), lineWidth: 4)
                        .padding(-4))
                Text(linkTitle)
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
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                Button { state.unpair() } label: {
                    Text("Disconnect")
                        .font(Theme.font(17, .bold))
                        .foregroundStyle(Theme.muted)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
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

    /// Dot and title follow `canvasLink`, never the paired flag. No amber here:
    /// PRODUCT.md keeps amber for "still counts", and a missed check loses nothing.
    private var linkDot: Color {
        switch state.canvasLink {
        case .connected, .notSetUp: return Theme.mint   // notSetUp = not checked yet this launch
        case .waitingForLaptop, .offline: return Theme.dim
        }
    }
    private var linkTitle: String {
        switch state.canvasLink {
        case .connected, .notSetUp: return "Connected"
        case .waitingForLaptop: return "Waiting for your laptop"
        case .offline: return "Showing your last list"
        }
    }
    private var syncLine: String {
        switch state.canvasLink {
        case .waitingForLaptop: return "· nothing received yet"
        case .offline: return "· could not check just now"
        case .connected, .notSetUp:
            guard let at = state.lastCanvasSyncAt else { return "" }
            return "· list received \(at.formatted(.relative(presentation: .named)))"
        }
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
                                    skin: state.activeChibi.skinID,
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
            if !canAdd {
                Text("Type a task first.")
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
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

    private func rows(_ templates: [TaskTemplate], editable: Bool = false) -> some View {
        VStack(spacing: 10) {
            ForEach(templates) { t in
                row(t, editable: editable && !t.isPreset)
            }
        }
    }

    /// Three presets per kind, plus any past the third that are already on, then
    /// one quiet row for the rest. Twelve equal toggles at once was the densest
    /// choice in the app (design/hicks-law-plan.md).
    private func presetRows(_ kind: TaskKind) -> some View {
        let all = presets(kind)
        let open = expanded.contains(kind)
        let shown = open ? all : Array(all.prefix(3)) + all.dropFirst(3).filter(\.isActive)
        let hidden = all.count - shown.count
        return VStack(spacing: 10) {
            rows(shown)
            if hidden > 0 || open {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        if open { expanded.remove(kind) } else { expanded.insert(kind) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(open ? "Show fewer" : "\(hidden) more")
                            .font(Theme.font(14, .heavy))
                        Image(systemName: open ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(open ? "Show fewer presets" : "Show \(hidden) more presets")
            }
        }
    }

    private func row(_ t: TaskTemplate, editable: Bool = false) -> some View {
        let tint = Self.rowTint(t)
        let confirming = editable && confirmingRemoveID == t.id
        return HStack(spacing: 14) {
            if editable {
                Circle()
                    .fill(D.coralTint)
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Theme.coral)
                            .frame(width: 12, height: 3)
                    )
                    // Trim the spacing so the row does not get wider in edit mode.
                    .padding(.trailing, -4)
                    .contentShape(Circle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.18)) { confirmingRemoveID = t.id }
                    }
            }
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(tint.bg)
                .frame(width: 50, height: 50)
                .overlay(CategoryIcon(category: Self.category(t), size: 30))
            VStack(alignment: .leading, spacing: 4) {
                Text(t.title)
                    .font(Theme.font(17, .bold))
                    .kerning(-0.2)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    // Fixed so the chips never wrap inside themselves when Remove
                    // takes the trailing edge.
                    coinChip("+\(t.kind.reward) coins", size: 12.5).fixedSize()
                    HStack(spacing: 4) {
                        Image(systemName: t.recurrence == .daily
                              ? "arrow.triangle.2.circlepath" : "1.circle")
                            .font(.system(size: 11, weight: .bold))
                        Text(t.recurrence == .daily ? "daily" : "once")
                            .font(Theme.font(12.5, .bold))
                    }
                    .foregroundStyle(D.placeholder)
                    .fixedSize()
                }
            }
            // The text column takes every point the tile, minus and trailing
            // control leave, so a title only wraps when it truly cannot fit.
            .frame(maxWidth: .infinity, alignment: .leading)
            if confirming {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        state.deleteTask(t.id)
                        confirmingRemoveID = nil
                    }
                } label: {
                    Text("Remove")
                        .font(Theme.font(14, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.coral))
                        .shadow(color: Theme.coral.opacity(0.32), radius: 6, y: 4)
                }
                .buttonStyle(.plain)
            } else if !editable {
                pillToggle(on: t.isActive)
            }
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
        .onTapGesture {
            if editable {
                withAnimation(.easeInOut(duration: 0.18)) { confirmingRemoveID = nil }
            } else {
                state.setTemplate(t.id, active: !t.isActive)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: t.isActive)
        .animation(.easeInOut(duration: 0.18), value: editable)
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

    static func category(_ t: TaskTemplate) -> TaskCategory {
        TaskCategory.of(DailyTask(id: t.id, title: t.title, kind: t.kind))
    }

    /// One tile tint per object, from the handoff's preset list. Shared with the
    /// first run's pick screen, which draws the same rows.
    static func rowTint(_ t: TaskTemplate) -> (bg: Color, fg: Color) {
        switch category(t) {
        case .reading:            return (Theme.hex(0xECEFFC), Theme.hex(0x6B79D8))
        case .writing, .problemSet, .labs, .study:
            return (Theme.hex(0xFDF0E4), Theme.hex(0xE08A3C))
        case .lifeCare:           return (Theme.hex(0xE6F3FA), Theme.hex(0x4A9CC4))
        case .walk, .stretch:     return (D.mintTint, D.mintIcon)
        case .outdoors:           return (Theme.hex(0xE9F5E2), Theme.hex(0x6BA04A))
        case .sleep:              return (Theme.hex(0xF2ECFB), Theme.hex(0x8A6FC4))
        case .connect:            return (Theme.hex(0xFDF0E4), Theme.hex(0xE08A3C))
        case .tidy:               return (Theme.hex(0xEFEFEA), Theme.hex(0x8A8577))
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
                set: { on in
                    Task { @MainActor in
                        await state.setRemindersEnabled(on)
                        remindersBlocked = await NotificationScheduler.shared.isDenied()
                    }
                }))

            if remindersBlocked && !state.settings.remindersEnabled {
                blockedNote
            }

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

            Text("Nothing here is a countdown, and nothing warns you about losing something.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(2)
        }
        .padding(20)
        .background(cardBackground(26))
        .animation(.easeInOut(duration: 0.18), value: remindersBlocked)
    }

    /// Only after iOS has been asked and told no. Says what is true and leaves the
    /// door open — the row stays tappable, so allowing it in Settings and coming
    /// back just works.
    private var blockedNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notifications are off for Prepkin in iOS Settings, so this switch can't turn them on yet.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            } label: {
                Text("Open Settings")
                    .font(Theme.font(15, .bold))
                    .foregroundStyle(Theme.coral)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(Capsule().fill(D.coralTint))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(Theme.font(17, .bold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
            Button { isOn.wrappedValue.toggle() } label: {
                pillToggle(on: isOn.wrappedValue)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .padding(.vertical, -6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
            .accessibilityAddTraits(.isToggle)
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
