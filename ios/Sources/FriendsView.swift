import SwiftUI

/// Friends tab, per `design/handoff-friends/README.md`.
///
/// Modelled on Finch's Friends rather than Duolingo's leagues: you see your
/// friends' kins, you cheer them, nobody loses. No stories row, no streaks, no
/// rank numerals, no promotion zone. Every number on this screen only goes up.
///
/// There is no friend bridge yet, so the list is whatever `state.friends` holds,
/// which on a real device is nothing. The two real things here are
/// `state.friendCode`, which persists so a code a student read out yesterday still
/// works today, and `state.pendingFriendCodes`, the codes they have typed in.
struct FriendsView: View {
    @EnvironmentObject var state: AppState

    #if DEBUG
    /// Set true to draw the four-friend layout from `sampleFriends`. Previews and
    /// design passes only — a shipped build reads `state.friends`, which is empty.
    var showSampleFriends = false

    /// Ordered by nothing the student can influence, so the board never reads as a
    /// ranking they slipped down.
    static let sampleFriends: [Friend] = [
        Friend(id: "maya", name: "Maya", speciesID: "ember", level: 3,
               weekCoins: 320, lastActivity: "Focused 45 min"),
        Friend(id: "josh", name: "Josh", speciesID: "droplet", level: 1,
               weekCoins: 280, lastActivity: "Solved the word in 3"),
        Friend(id: "ava", name: "Ava", speciesID: "sprout", level: 2,
               weekCoins: 210, lastActivity: "Finished Compound interest"),
        Friend(id: "sam", name: "Sam", speciesID: "slime", level: 1,
               weekCoins: 150, lastActivity: "4 tasks done"),
    ]
    #endif

    private var friends: [Friend] {
        #if DEBUG
        if showSampleFriends { return Self.sampleFriends }
        #endif
        return state.friends
    }

    private var pending: [String] { state.pendingFriendCodes }

    @State private var copied = false
    @State private var theirCode = ""
    @State private var requestSent = false
    @State private var cheered: Set<String> = []
    @State private var showAdd = false
    // The code field is UIKit's, so focus is a flag it reports back rather than
    // something @FocusState can reach into.
    @State private var typing = false

    /// The `DayEditorView` sheet's own tokens, matched 1:1. They are private to
    /// that file, and this handoff asks for the same six.
    private enum D {
        static let placeholder = Theme.hex(0xB6A79E)
        static let grabber = Theme.hex(0xE2D8C6)
        static let coralTint = Theme.hex(0xFDECEA)
        static let mintTint = Theme.hex(0xE8F7F0)
        static let cardShadow = Theme.hex(0x2E2622).opacity(0.05)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title
                    // The league sits above everything on both states. It is the one
                    // thing on this tab that works with nobody else in it, which is
                    // exactly the situation every real student is in today.
                    LeagueCard().padding(.top, 18)
                    if friends.isEmpty {
                        kinCard.padding(.top, 14)
                        if !pending.isEmpty { pendingCard.padding(.top, 14) }
                        sectionHeader
                        addFriendCard
                    } else {
                        kinRow.padding(.top, 22)
                        weekBoard.padding(.top, 22)
                        friendList.padding(.top, 20)
                    }
                }
                // The column never reports wider than the screen. A row that wanted
                // more made the ScrollView centre the page, so the title and every
                // card sat 3pt left of the gutter until that row went away.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.bottom, 104)
            }
            .background(Theme.paper)
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAdd) { addScreen }
        }
        .task { state.ensureFriendCode() }
    }

    // MARK: - Title

    private var title: some View {
        HStack(alignment: .bottom) {
            Text("Friends")
                .font(Theme.font(34, .black))
                .kerning(-0.9)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
            if !friends.isEmpty {
                Button { showAdd = true } label: {
                    AddFriendGlyph(size: 24)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Theme.card)
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a friend")
            }
        }
        .frame(height: 40, alignment: .bottom)
    }

    // MARK: - 1a, zero friends

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
            VStack(alignment: .leading, spacing: 4) {
                Text("Just us for now. That's fine by me.")
                    .font(Theme.font(17, .bold))
                    .kerning(-0.2)
                    .foregroundStyle(Theme.ink)
                Text("Swap codes with someone and their kin shows up here.")
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(cardBackground(28))
    }

    /// The codes they have typed in and nobody has answered. Same card as the rest
    /// of the tab, muted rather than loud: waiting is not an error.
    private var pendingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(pending.enumerated()), id: \.element) { _, code in
                pendingRow(code)
                if code != pending.last { hairline }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(cardBackground(26))
    }

    private func pendingRow(_ code: String) -> some View {
        HStack(spacing: 11) {
            Circle()
                .fill(D.grabber)
                .frame(width: 11, height: 11)
            Text("Waiting on")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
            Text(code)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .kerning(0.5)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeOut(duration: 0.18)) {
                    state.removePendingFriendCode(code)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stop waiting on \(code)")
        }
        .padding(.vertical, 2)
    }

    private var sectionHeader: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(D.coralTint)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.coral)
                )
            Text("Add a friend")
                .font(Theme.font(22, .heavy))
                .kerning(-0.3)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
        .padding(.top, 26)
        .padding(.bottom, 12)
    }

    /// The `+` in 1b pushes to the same card on its own screen. The handoff never
    /// drew this screen, so it borrows 1a's title row and carries its own back
    /// chevron — the app hides the system navigation bar everywhere else.
    private var addScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { showAdd = false } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Text("Add a friend")
                    .font(Theme.font(34, .black))
                    .kerning(-0.9)
                    .foregroundStyle(Theme.ink)
                    .frame(height: 40, alignment: .bottom)
                addFriendCard.padding(.top, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.bottom, 104)
        }
        .background(Theme.paper)
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder private var addFriendCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if requestSent { sentBody } else { formBody }
        }
        .padding(18)
        .background(cardBackground(26))
    }

    private var formBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("YOUR CODE", top: 0)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(Array(myCode.enumerated()), id: \.offset) { _, ch in
                        if ch == "-" {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(D.grabber)
                                .frame(width: 12, height: 3)
                        } else {
                            Text(String(ch))
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.ink)
                                // 27 is the drawn size. The tiles give ground on a
                                // narrower phone rather than push the page wider than
                                // the screen, which used to drag the whole tab left.
                                .frame(minWidth: 20, maxWidth: 27, minHeight: 44, maxHeight: 44)
                                .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Theme.paper))
                        }
                    }
                }
                // Holds the slack the Spacer held, without the second 12pt gap the
                // Spacer added between the tiles and the copy button.
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    UIPasteboard.general.string = myCode
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
                .accessibilityLabel("Copy your code")
            }
            Text(copied ? "Copied. Send it by text, or read it out."
                        : "Share this by text or in person.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
                .padding(.top, 12)

            hairline.padding(.vertical, 18)

            eyebrow("THEIR CODE", top: 0)
            ZStack(alignment: .leading) {
                if theirCode.isEmpty {
                    Text("XXXX-XXXX")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .kerning(1)
                        .foregroundStyle(D.placeholder)
                }
                CodeField(text: $theirCode, typing: $typing, onSubmit: send)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.paper))

            Text(codeLine)
                .font(Theme.font(14, .bold))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
                .padding(.horizontal, 4)
                .padding(.top, 12)
                .frame(minHeight: 32, alignment: .top)

            Button(action: send) {
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
            .padding(.top, 14)
        }
    }

    /// Nothing leaves the phone — `send()` only appends to `pendingFriendCodes` —
    /// so this card is worded as the "Waiting on" row it becomes, and reuses that
    /// row's quiet dot instead of the paired-and-live mint dot from DayEditorView.
    private var sentBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Circle()
                    .fill(D.grabber)
                    .frame(width: 11, height: 11)
                Text("Waiting on")
                    .font(Theme.font(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text(theirCode)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .kerning(0.5)
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)

            hairline.padding(.vertical, 16)
            Text("Saved on this phone. Nothing has been sent yet, so give them your code too. Their kin shows up here once we switch friends on.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
            hairline.padding(.vertical, 16)

            Button {
                theirCode = ""
                requestSent = false
            } label: {
                Text("Add another")
                    .font(Theme.font(17, .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 1b, four friends

    private var kinRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(friends) { f in
                    VStack(spacing: 6) {
                        SproutImage(speciesID: f.speciesID, level: f.level, size: 56)
                            .frame(width: 56, height: 56, alignment: .bottom)
                        Text(f.name)
                            .font(Theme.font(12, .bold))
                            .foregroundStyle(Theme.ink)
                    }
                    .frame(width: 64)
                }
            }
            .padding(.horizontal, 2)
        }
        // A four-kin row fits; the scroll only matters once a fifth arrives.
        .scrollDisabled(friends.count <= 5)
    }

    private var weekBoard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("This week")
                .font(Theme.font(17, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            boardRow(speciesID: state.activeChibiID, name: "You",
                     coins: state.week.coinsEarned, isYou: true)
            ForEach(friends) { f in
                boardRow(speciesID: f.speciesID, name: f.name,
                         coins: f.weekCoins, isYou: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground(26))
    }

    private func boardRow(speciesID: String, name: String,
                          coins: Int, isYou: Bool) -> some View {
        HStack(spacing: 12) {
            SproutFace(speciesID: speciesID, size: 26)
            Text(name)
                .font(Theme.font(15, isYou ? .black : .bold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                CoinDisc(size: 13)
                Text("\(coins)")
                    .font(Theme.font(13, .black))
                    .foregroundStyle(Theme.coinDark)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isYou ? Theme.paper : .clear))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(coins) coins this week")
    }

    private var friendList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Friends")
                .font(Theme.font(17, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)
            ForEach(friends) { f in
                friendRow(f)
                if f.id != friends.last?.id { hairline.padding(.leading, 52) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background(cardBackground(26))
    }

    private func friendRow(_ f: Friend) -> some View {
        HStack(spacing: 12) {
            SproutImage(speciesID: f.speciesID, level: f.level, size: 40)
                .frame(width: 40, height: 40, alignment: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(f.name)
                        .font(Theme.font(15.5, .black))
                        .foregroundStyle(Theme.ink)
                    StarPips(level: f.level, size: 12)
                }
                Text(f.lastActivity)
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
            cheerButton(f)
        }
        .padding(.vertical, 10)
    }

    private func cheerButton(_ f: Friend) -> some View {
        let on = cheered.contains(f.id)
        return Button {
            guard !on else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.18)) { _ = cheered.insert(f.id) }
        } label: {
            HStack(spacing: 6) {
                ClapGlyph(size: 22, tint: on ? .white : Theme.coral)
                Text(on ? "Cheered" : "Cheer")
                    .font(Theme.font(14, .heavy))
                    .foregroundStyle(on ? .white : Theme.coral)
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .frame(height: 44)
            .background(Capsule().fill(on ? Theme.mint : D.coralTint))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(on ? "You cheered \(f.name) today" : "Cheer \(f.name)")
    }

    // MARK: - Code entry

    private var myCode: String { state.friendCode ?? PairingCode.generate() }

    /// Uppercase, letters and digits only, eight of them, dash after the fourth.
    private static func format(_ input: String) -> String {
        let raw = input.uppercased().filter(isCodeChar).prefix(8)
        guard raw.count > 4 else { return String(raw) }
        return String(raw.prefix(4)) + "-" + String(raw.dropFirst(4))
    }

    /// What `format` keeps. The caret has to count the same characters the text
    /// does, or it drifts a place every time the dash appears.
    private static func isCodeChar(_ c: Character) -> Bool { c.isLetter || c.isNumber }

    /// Their code, wrapped from UIKit on purpose.
    ///
    /// A SwiftUI `TextField` cannot hold a separator. Reformatting the bound
    /// string lands a frame late, so a fast burst is typed into text SwiftUI is
    /// about to replace and everything past the dash is lost. UIKit hands the
    /// delegate each edit before it is committed, so the same formatting applied
    /// there survives a burst, a hardware keyboard and a paste alike.
    private struct CodeField: UIViewRepresentable {
        @Binding var text: String
        @Binding var typing: Bool
        var onSubmit: () -> Void

        func makeUIView(context: Context) -> UITextField {
            let field = UITextField()
            field.delegate = context.coordinator
            field.defaultTextAttributes = [
                .font: UIFont.monospacedSystemFont(ofSize: 17, weight: .bold),
                .foregroundColor: UIColor(Theme.ink),
                .kern: 1,
            ]
            field.autocapitalizationType = .allCharacters
            field.autocorrectionType = .no
            field.spellCheckingType = .no
            // Smart punctuation would rewrite the separator the moment we insert it.
            field.smartDashesType = .no
            field.smartQuotesType = .no
            field.smartInsertDeleteType = .no
            field.keyboardType = .asciiCapable
            field.returnKeyType = .done
            field.accessibilityLabel = "Their code"
            field.setContentHuggingPriority(.defaultLow, for: .horizontal)
            field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return field
        }

        func updateUIView(_ field: UITextField, context: Context) {
            context.coordinator.parent = self
            if field.text != text { field.text = text }
            if !typing, field.isFirstResponder { field.resignFirstResponder() }
        }

        func sizeThatFits(_ proposal: ProposedViewSize,
                          uiView: UITextField,
                          context: Context) -> CGSize? {
            CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width,
                   height: uiView.intrinsicContentSize.height)
        }

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        final class Coordinator: NSObject, UITextFieldDelegate {
            var parent: CodeField
            init(_ parent: CodeField) { self.parent = parent }

            func textField(_ field: UITextField,
                           shouldChangeCharactersIn range: NSRange,
                           replacementString string: String) -> Bool {
                let current = field.text ?? ""
                guard let edit = Range(range, in: current) else { return false }
                let formatted = FriendsView.format(
                    current.replacingCharacters(in: edit, with: string))
                // Where the caret belongs: after however many kept characters now
                // sit in front of it, plus one once the dash is standing between.
                let kept = min(8, current[..<edit.lowerBound]
                    .filter(FriendsView.isCodeChar).count
                    + string.filter(FriendsView.isCodeChar).count)
                field.text = formatted
                let caret = kept > 4 ? kept + 1 : kept
                if let spot = field.position(from: field.beginningOfDocument, offset: caret) {
                    field.selectedTextRange = field.textRange(from: spot, to: spot)
                }
                parent.text = formatted
                return false
            }

            // Guarded because `send()` clears the flag first and then makes us
            // resign, which would otherwise write state inside a view update.
            func textFieldDidBeginEditing(_ field: UITextField) {
                guard !parent.typing else { return }
                parent.typing = true
            }

            func textFieldDidEndEditing(_ field: UITextField) {
                guard parent.typing else { return }
                parent.typing = false
            }

            func textFieldShouldReturn(_ field: UITextField) -> Bool {
                parent.onSubmit()
                return false
            }
        }
    }

    private var typedLetters: String { theirCode.filter { $0 != "-" } }

    /// The four characters the alphabet drops, in the order they were typed.
    private var badChars: [Character] {
        typedLetters.filter { !PairingCode.alphabet.contains($0) }
    }

    private var canAdd: Bool { typedLetters.count == 8 && badChars.isEmpty }

    /// Muted, never red. A wrong character is a typo, not a failure.
    private var codeLine: String {
        if !badChars.isEmpty {
            let swaps = badChars.map { ($0 == "I" || $0 == "1") ? "L" : "Q" }
            return "Codes skip I, O, 0 and 1. Try \(swaps.joined(separator: ", "))."
        }
        if canAdd { return "Looks right." }
        if typedLetters.isEmpty { return "Eight letters and numbers, from their Friends tab." }
        return "\(8 - typedLetters.count) more to go."
    }

    private func send() {
        guard canAdd else { return }
        typing = false
        // No bridge to send to, so the request is only kept here. The tab says so.
        state.addPendingFriendCode(theirCode)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.18)) { requestSent = true }
    }

    // MARK: - Shared bits

    private var hairline: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1)
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

    private func cardBackground(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Theme.card)
            .shadow(color: D.cardShadow, radius: 11, y: 8)
    }
}
