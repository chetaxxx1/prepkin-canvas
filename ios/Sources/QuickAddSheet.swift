import SwiftUI

/// Todoist's quick add. One field above the keyboard, and the date typed into it
/// in plain words: "Bio quiz fri 4pm". The phrase lights up inside the field as
/// it is recognised and repeats itself as a chip underneath, so the student can
/// see what the app understood before they commit.
///
/// This is the whole add flow for most tasks. The full editor — notes, repeat,
/// delete — is one more tap behind **More**, and never the default.
struct QuickAddSheet: View {
    /// The day the `+` was pressed on. Typing a date beats it.
    let day: DayKey
    /// Opens the full editor with whatever has been typed so far.
    var onMore: (DatedTask) -> Void = { _ in }
    /// Opens the syllabus reader. Only reachable once it is deployed.
    var onPhoto: () -> Void = {}
    var isPlus = false

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var kind: TaskKind = .study
    /// Set by the When sheet. A date typed into the field wins over it, so this
    /// is cleared the moment the field parses one.
    @State private var pickedDay: DayKey?
    @State private var pickedMinute: Int?
    @State private var showWhen = false
    @FocusState private var typing: Bool

    private var phrase: DatePhrase? { DatePhrase.parse(text) }
    private var title: String { DatePhrase.title(text, without: phrase) }
    private var canAdd: Bool { !title.isEmpty }

    /// What the task will land on: the typed phrase, then the When sheet, then
    /// the day the student was looking at.
    private var landsOn: DayKey { phrase?.day ?? pickedDay ?? day }
    private var landsAt: Int? { phrase?.minute ?? pickedMinute }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Theme.hex(0xE2D8C6))
                .frame(width: 38, height: 4.5)
                .padding(.top, 9)
                .padding(.bottom, 12)

            field
            chips
            Rectangle().fill(Theme.hairline).frame(height: 1).padding(.top, 12)
            bottom
        }
        .background(Theme.card)
        .presentationBackground(Theme.card)
        .presentationDetents([.height(236)])
        .presentationCornerRadius(Theme.Radius.sheet)
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showWhen) {
            WhenSheet(day: Binding(get: { landsOn }, set: setDay),
                      minute: Binding(get: { landsAt }, set: { pickedMinute = $0 }))
        }
        .onAppear { typing = true }
    }

    // MARK: - The field

    /// The lit phrase is a `Text` sitting under a field whose own glyphs are
    /// clear. Both use the same font and the same width, so the two layers land
    /// on each other; only the caret and the highlight come from the top layer.
    private var field: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Bio quiz, ch. 3–4")
                    .font(Theme.font(18, .bold))
                    .foregroundStyle(Theme.hex(0xB6A79E))
            }
            Text(lit)
                .font(Theme.font(18, .bold))
                .foregroundStyle(Theme.ink)
            TextField("", text: $text, axis: .vertical)
                .font(Theme.font(18, .bold))
                .foregroundStyle(.clear)
                .tint(Theme.coral)
                .lineLimit(1...3)
                // Autocorrect eats the date. "mon" becomes "mom", "tue" becomes
                // "the", and the phrase stops parsing in front of the student.
                // Todoist turns it off on this field for the same reason.
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
                .focused($typing)
                .submitLabel(.done)
                .onSubmit(add)
                .accessibilityLabel("What is due")
                .accessibilityValue(chipLabel)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20)
    }

    /// The typed text with the date phrase on a coral-soft ground.
    private var lit: AttributedString {
        var out = AttributedString(text)
        guard let phrase else { return out }
        let from = text.distance(from: text.startIndex, to: phrase.range.lowerBound)
        let to = text.distance(from: text.startIndex, to: phrase.range.upperBound)
        let low = out.characters.index(out.startIndex, offsetBy: from)
        let high = out.characters.index(out.startIndex, offsetBy: to)
        out[low..<high].backgroundColor = Theme.coralSoft
        out[low..<high].foregroundColor = Theme.coralShade
        return out
    }

    /// Picking a day by hand takes the phrase out of the field. Leaving both in
    /// would show a date in the text that the chip no longer agrees with.
    private func setDay(_ picked: DayKey) {
        text = title
        pickedDay = picked
    }

    // MARK: - The chips

    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                chip(chipLabel, glyph: "calendar", on: hasDate) { showWhen = true }
                chip("Study", on: kind == .study) { kind = .study }
                chip("Life", on: kind == .life) { kind = .life }
                if ScanClient.isDeployed && isPlus {
                    chip("Photo", glyph: "camera.fill", on: false) {
                        dismiss()
                        onPhoto()
                    }
                }
                chip("More", glyph: "ellipsis", on: false) { more() }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .frame(height: 44)
        .padding(.top, 10)
    }

    private var hasDate: Bool { phrase != nil || pickedDay != nil || pickedMinute != nil }

    private var chipLabel: String {
        hasDate ? DatePhrase.label(day: landsOn, minute: landsAt) : "Date"
    }

    private func chip(_ label: String, glyph: String? = nil, on: Bool,
                      _ tap: @escaping () -> Void) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.snappy(duration: 0.2)) { tap() }
        } label: {
            HStack(spacing: 5) {
                if let glyph {
                    Image(systemName: glyph).font(.system(size: 11.5, weight: .black))
                }
                Text(label).font(Theme.font(13.5, .black))
            }
            .foregroundStyle(on ? Theme.coralShade : Theme.ink.opacity(0.75))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(Capsule().fill(on ? Theme.coralSoft : Theme.paperSunk))
            .overlay(Capsule().strokeBorder(on ? Theme.coral.opacity(0.55) : .clear, lineWidth: 1.5))
            // Paint 34, take 44: the target is not the paint.
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .padding(.vertical, -5)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - The bottom row

    private var bottom: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                CoinDisc(size: 13)
                Text("\(kind.reward)")
                    .font(Theme.font(13, .black))
                    .foregroundStyle(Theme.coinDark)
                    .contentTransition(.numericText())
            }
            Text("·")
                .font(Theme.font(13, .black))
                .foregroundStyle(Theme.dim)
            Text(DatePhrase.label(day: landsOn, minute: landsAt))
                .font(Theme.font(13, .heavy))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button(action: add) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(canAdd ? Theme.coral : Theme.coral.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
            .accessibilityLabel("Add it")
        }
        .animation(.snappy(duration: 0.2), value: kind)
        .padding(.horizontal, 20)
        .frame(height: 60)
    }

    // MARK: - Doing it

    private var draft: DatedTask {
        DatedTask(title: title, kind: kind, source: .mine, day: landsOn, minute: landsAt)
    }

    private func add() {
        guard canAdd else { return }
        state.addDated(draft)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func more() {
        typing = false
        dismiss()
        onMore(draft)
    }
}
