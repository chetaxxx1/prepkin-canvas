import SwiftUI

/// Friends tab, per `design/handoff-friends/README.md`.
///
/// Modelled on Finch's Friends rather than Duolingo's leagues: you see your
/// friends' kins, you cheer them, nobody loses. No stories row, no streaks, no
/// rank numerals, no promotion zone. Every number on this screen only goes up.
///
/// Every row is a real person now. `state.friends` is what `fetch_friends` last
/// sent, folded together with the two things only this phone knows: what you call
/// them, and whether it has told you about them yet (`FriendSync.swift`).
///
/// `state.friendCode` is the code the bridge minted for this player, cached so the
/// screen has something to draw before the call comes back.
struct FriendsView: View {
    @EnvironmentObject var state: AppState

    private var friends: [Friend] { state.friends }

    /// The people this tab has not shown you yet. No count anywhere, no badge — a
    /// card each, at the top, and looking at one is what ends it.
    private var addedYou: [Friend] { state.friendsWhoAddedYou }

    @State private var copied = false
    @State private var theirCode = ""
    @State private var adding = false
    @State private var addFailed = false
    /// The friend a nickname is being typed for, straight after they were added.
    @State private var naming: Friend?
    /// The friend a confirm is open for. Both are one tap from the quiet menu and
    /// both ask first, because neither can be undone from inside this app.
    @State private var blocking: Friend?
    @State private var reporting: Friend?
    /// The friend whose card is open.
    @State private var showing: Friend?
    @State private var showPrivacy = false
    @State private var showAdd = false
    @State private var showLadder = false
    /// Ticks once a minute so "12 min left" counts down while the tab is open.
    @State private var clock = Date()
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
                    // Somebody typed your code. It sits above everything because it
                    // is the only thing on this tab that is news, and it is gone the
                    // moment you have looked at it.
                    if !addedYou.isEmpty { addedYouCard.padding(.top, 14) }
                    // Somebody said hello. Same shape as the card above it, and it
                    // ends the same way: by being looked at.
                    if !waved.isEmpty { wavedCard.padding(.top, 14) }
                    // The page opens on a picture, not a paragraph. Everything this
                    // tab used to explain in three blocks of prose — the tier, the
                    // bar, the pod, the ladder — is one tap away in `linkRows`, and
                    // the two empty slots in the water say the rest.
                    FriendsWater(tier: state.league.tier,
                                 speciesID: state.activeChibiID,
                                 level: state.activeChibi.level,
                                 skin: state.activeChibi.skinID,
                                 points: state.leaguePoints,
                                 friends: friends,
                                 onEmptyTap: { showAdd = true })
                        .padding(.top, 16)

                    // One primary action, and it is the honest one: a code works on
                    // this phone today. Joining a pod needs the bridge, so it is a
                    // row that explains itself rather than a second coral button
                    // competing with this one.
                    if friends.isEmpty { addButton.padding(.top, 14) }

                    linkRows.padding(.top, 14)

                    weekCard.padding(.top, 14)

                    if !friends.isEmpty {
                        if let together = state.weeklyTogether {
                            togetherCard(together).padding(.top, 14)
                        }
                        friendList.padding(.top, 20)
                    }
                }
                // The column never reports wider than the screen. A row that wanted
                // more made the ScrollView centre the page, so the title and every
                // card sat 3pt left of the gutter until that row went away.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, Theme.tabClearance)
            }
            .background(Theme.paper)
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAdd) { addScreen }
            .navigationDestination(isPresented: $showLadder) { LeagueLadderView() }
        }
        // The only system-coloured things on this tab are the quiet menu and the
        // two confirms below. Coral is the app's action colour, and it is what
        // keeps Block off the red every other app puts it on.
        .tint(Theme.coral)
        .sheet(item: $naming) { friend in
            NicknameSheet(friend: friend) { typed in
                state.setNickname(typed, for: friend.id)
                naming = nil
                showAdd = false
            } onSkip: {
                naming = nil
                showAdd = false
            }
        }
        // Coral, never red. Nothing in this app shouts at a student, least of all
        // the screen where they are ending something.
        .confirmationDialog("Block \(blocking?.displayName ?? "")",
                            isPresented: Binding(get: { blocking != nil },
                                                 set: { if !$0 { blocking = nil } }),
                            titleVisibility: .visible) {
            Button("Block") {
                if let f = blocking { state.blockFriend(f.id) }
                blocking = nil
            }
            Button("Keep them", role: .cancel) { blocking = nil }
        } message: {
            Text("They leave your friends, and neither of you can add the other again.")
        }
        .confirmationDialog("Report \(reporting?.displayName ?? "")",
                            isPresented: Binding(get: { reporting != nil },
                                                 set: { if !$0 { reporting = nil } }),
                            titleVisibility: .visible) {
            Button("Report") {
                if let f = reporting { state.reportFriend(f.id) }
                reporting = nil
            }
            Button("Cancel", role: .cancel) { reporting = nil }
        } message: {
            Text("We look at the pair of you by hand. They are not told, and they stay on your list until you remove them.")
        }
        .sheet(item: $showing) { friend in
            FriendCardSheet(friend: friend) { length in
                state.joinShiftRequest = length
            }
            .environmentObject(state)
        }
        .sheet(isPresented: $showPrivacy) { PrivacySheet().environmentObject(state) }
        .task {
            await state.refreshFriends()
            // Both are silent on failure and both are cheap. They run after the
            // list because neither means anything without it.
            await state.refreshWaves()
            await state.refreshToday()
        }
        // Only while the tab is on screen, and only once a minute: the one thing
        // that goes stale here is a shift clock, and it is measured in minutes.
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { clock = $0 }
    }

    // MARK: - Somebody waved

    private var waved: [Friend] { state.unseenWaves }

    /// No buttons, and no way to wave back from here — waving back belongs on their
    /// card, where you can see who you are waving at.
    private var wavedCard: some View {
        VStack(spacing: 0) {
            ForEach(waved) { f in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    state.markWaveSeen(f.id)
                    showing = f
                } label: {
                    HStack(spacing: 12) {
                        SproutImage(speciesID: f.speciesID, level: f.level,
                                    skin: f.lookID, size: 40)
                            .frame(width: 40, height: 40, alignment: .bottom)
                        Text("\(f.displayName) waved")
                            .font(Theme.font(15.5, .heavy))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 8)
                        ClapGlyph(size: 20, tint: Theme.coral)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 62)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if f.id != waved.last?.id { hairline.padding(.leading, 68) }
            }
        }
        .background(cardBackground(Theme.Radius.card))
    }

    // MARK: - This week, together

    /// One sentence, and it is absent rather than empty when there is nothing in it.
    /// No coins on it, ever.
    private func togetherCard(_ sentence: String) -> some View {
        Text(sentence)
            .font(Theme.font(14.5, .heavy))
            .foregroundStyle(Theme.ink)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(cardBackground(Theme.Radius.card))
    }

    // MARK: - Somebody added you

    /// One card per person, no buttons on it. Tapping says you have seen it, which
    /// is the whole interaction — their row is already in the list below, and there
    /// is nothing here to accept or refuse.
    private var addedYouCard: some View {
        VStack(spacing: 0) {
            ForEach(addedYou) { f in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.22)) { state.markFriendSeen(f.id) }
                } label: {
                    HStack(spacing: 12) {
                        SproutImage(speciesID: f.speciesID, level: f.level, size: 40)
                            .frame(width: 40, height: 40, alignment: .bottom)
                        Text("\(f.displayName) added you")
                            .font(Theme.font(15.5, .heavy))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 62)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if f.id != addedYou.last?.id { hairline.padding(.leading, 68) }
            }
        }
        .background(cardBackground(Theme.Radius.card))
    }

    // MARK: - This week

    /// The bar toward the next water, and nothing else. The long version — what a
    /// quiet week does, what settles on Monday — is on the ladder screen, where
    /// somebody who wants it has asked for it.
    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                CoinDisc(size: 15)
                Text("\(state.leaguePoints) earned this week")
                    .font(Theme.font(14.5, .black))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }
            if let toGo = state.leaguePointsToNextTier,
               let next = state.league.tier.next,
               let bar = LeagueRules.bar(for: state.league.tier) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hairline)
                        Capsule().fill(state.league.tier.color)
                            .frame(width: geo.size.width
                                   * min(1, Double(state.leaguePoints) / Double(bar)))
                    }
                }
                .frame(height: 8)
                Text(toGo == 0
                     ? "That clears it. \(next.name) on Monday."
                     : "\(toGo) more and you're in \(next.name) on Monday.")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
            } else {
                Text("Deep is the last one. Nothing below it, and nothing to lose.")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground(Theme.Radius.card))
    }

    // MARK: - The one action, and the two rows

    private var addButton: some View {
        Button { showAdd = true } label: {
            Text("Add a friend")
                .font(Theme.font(17, .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.sheet,
                                             style: .continuous)
                    .fill(Theme.coral))
                .shadow(color: Theme.coral.opacity(0.3), radius: 10, y: 8)
        }
        .buttonStyle(.plain)
    }

    /// The pod and the ladder, as two rows. Both open `LeagueLadderView`; the pod row
    /// is the one that used to be ninety words and a coral button at the top of this
    /// tab. A student who wants the rules taps once and gets all of them.
    private var linkRows: some View {
        VStack(spacing: 0) {
            linkRow(title: state.podOptIn ? "Your pod" : "Swim with a pod",
                    note: state.podOptIn ? "The board, and how to leave"
                                         : "Twenty students, nobody knows anybody",
                    tint: D.coralTint) {
                SproutFace(speciesID: state.activeChibiID, size: 22)
            }
            hairline
            linkRow(title: "The whole ladder",
                    note: "\(state.league.tier.name), \(placeInLadder) of six waters",
                    tint: D.mintTint) {
                TierPennant(tier: state.league.tier, earned: true, height: 20)
            }
            hairline
            // Sharing today's work starts off, so this row is also the only way it
            // ever gets turned on. It sits here rather than behind a gear on the
            // title row because a setting nobody can find is not a choice.
            Button { showPrivacy = true } label: {
                privacyRowLabel
            }
            .buttonStyle(.plain)
        }
        .background(cardBackground(Theme.Radius.card))
    }

    private var privacyRowLabel: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: Theme.Radius.tile(38), style: .continuous)
                .fill(D.mintTint)
                .frame(width: 38, height: 38)
                .overlay(Image(systemName: "eye")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.mintDark))
            VStack(alignment: .leading, spacing: 2) {
                Text("What friends see")
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(Theme.ink)
                Text(state.game.shareToday ? "Your fish, and what you did today"
                                           : "Your fish, and nothing else")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 62)
        .contentShape(Rectangle())
    }

    private var placeInLadder: String {
        ["first", "second", "third", "fourth", "fifth", "sixth"][state.league.tier.rawValue]
    }

    private func linkRow<V: View>(title: String, note: String, tint: Color,
                                  @ViewBuilder glyph: () -> V) -> some View {
        Button { showLadder = true } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: Theme.Radius.tile(38), style: .continuous)
                    .fill(tint)
                    .frame(width: 38, height: 38)
                    .overlay(glyph())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.font(15.5, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(note)
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    // MARK: - Add a friend

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
            .padding(.bottom, Theme.tabClearance)
        }
        .background(Theme.paper)
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
        // The first time this screen opens is the first time a student has asked
        // for anything social, so it is where this phone gets an id at all.
        .task { await state.loadMyCode() }
    }

    private var addFriendCard: some View {
        VStack(alignment: .leading, spacing: 0) { formBody }
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
                .disabled(!hasCode)
                .accessibilityLabel("Copy your code")
                // The plain code, not a link. A link needs the file on the site
                // that tells iOS this app owns that address, and it is not up yet.
                ShareLink(item: myCode) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.coral)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(D.coralTint))
                }
                .buttonStyle(.plain)
                .disabled(!hasCode)
                .accessibilityLabel("Share your code")
            }
            Text(copied ? "Copied. Send it by text, or read it out."
                        : "Share this by text or in person.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
                .padding(.top, 12)

            hairline.padding(.vertical, 18)

            newCodeRow

            hairline.padding(.vertical, 18)

            eyebrow("THEIR CODE", top: 0)
            ZStack(alignment: .leading) {
                if theirCode.isEmpty {
                    Text("XXXX-XXXX")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .kerning(1)
                        .foregroundStyle(D.placeholder)
                }
                CodeField(text: $theirCode, typing: $typing,
                          onSubmit: { Task { await send() } })
                    .frame(maxWidth: .infinity)
                    .onChange(of: theirCode) { _, _ in
                        addFailed = false
                        state.friendStatus = nil
                    }
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

            Button { Task { await send() } } label: {
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
            .disabled(!canAdd || adding)
            .padding(.top, 14)
        }
    }

    /// Replacing the code is the thing that stands in for a Remove on a code you
    /// already read out to a room. One row, one line saying exactly what it costs.
    private var newCodeRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            copied = false
            Task { await state.rotateMyCode() }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text("Get a new code")
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(Theme.coral)
                Text("The old one stops working. Friends you already have stay.")
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasCode)
    }

    // MARK: - The list

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

    /// The name you gave them, their stars, and one line only while they are at a
    /// desk. Nothing else: a friend who is not working has no second line, because
    /// "no session" and "hasn't studied" would be the same sentence.
    ///
    /// Cheer is a vibe, and vibes are the next phase. The button stays in the file
    /// rather than being drawn as a dead control.
    private func friendRow(_ f: Friend) -> some View {
        HStack(spacing: 12) {
            SproutImage(speciesID: f.speciesID, level: f.level, skin: f.lookID, size: 40)
                .frame(width: 40, height: 40, alignment: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(f.displayName)
                        .font(Theme.font(15.5, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    StarPips(level: f.level, size: 12)
                }
                if let line = f.shiftLine(at: clock) {
                    Text(line)
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer(minLength: 0)
            quietMenu(f)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { showing = f }
        .contextMenu { menuItems(f) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(f.shiftLine(at: clock).map { "\(f.displayName), \($0)" } ?? f.displayName)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens their card")
    }

    /// Grey, small, and off to the side, because none of it is a thing a student
    /// should be nudged toward. Long-pressing the row opens the same three.
    private func quietMenu(_ f: Friend) -> some View {
        Menu {
            menuItems(f)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.dim)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More for \(f.displayName)")
    }

    /// One line under each, saying exactly what it does. None of the three is
    /// destructive in the red-button sense the system means by that word, so none
    /// of them is red.
    @ViewBuilder private func menuItems(_ f: Friend) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { state.removeFriend(f.id) }
        } label: {
            Text("Remove")
            Text("They come off your list. Nobody is told.")
        }
        Button { blocking = f } label: {
            Text("Block")
            Text("They leave, and neither of you can add the other again.")
        }
        Button { reporting = f } label: {
            Text("Report")
            Text("Sends the pair of you to be looked at by hand.")
        }
    }

    // MARK: - Code entry

    /// The code the bridge minted for this player. Dashes for the moment before the
    /// call comes back, so the tiles keep their place rather than the card resizing
    /// under the reader's thumb.
    private var myCode: String { state.friendCode ?? "····-····" }
    private var hasCode: Bool { state.friendCode != nil }

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
        if let line = state.friendStatus { return line }
        // The same words for a typo, a code that has been replaced, a code that was
        // never real and somebody who blocked you. Saying which one it is would let
        // a stranger use this screen to find out whether a code is live.
        if addFailed { return "That code didn't open anything. Check it with them." }
        if adding { return "Looking." }
        if !badChars.isEmpty {
            let swaps = badChars.map { ($0 == "I" || $0 == "1") ? "L" : "Q" }
            return "Codes skip I, O, 0 and 1. Try \(swaps.joined(separator: ", "))."
        }
        if canAdd { return "Looks right." }
        if typedLetters.isEmpty { return "Eight letters and numbers, from their Friends tab." }
        return "\(8 - typedLetters.count) more to go."
    }

    private func send() async {
        guard canAdd, !adding else { return }
        typing = false
        adding = true
        addFailed = false
        state.friendStatus = nil
        switch await state.addFriend(code: theirCode) {
        case .added(let friend):
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            theirCode = ""
            // Straight into "what do you call them", because the word-list name is
            // the one thing about this person a student will not recognise.
            naming = friend
        case .nothing:
            addFailed = true
        case .couldNotReach:
            state.friendStatus = "Could not reach anyone just now. Try again in a moment."
        }
        adding = false
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

// MARK: - What do you call them

/// The one place a student types a person's name, and it never leaves this phone.
///
/// The wire carries two numbers into shipped word lists, so a friend arrives as
/// "Brisk Otter" — fine for a pod of strangers, useless for a roommate. This is the
/// same trade a contact name makes in Phone: your screen says Maya, their screen
/// says whatever they typed for you, and nobody has anything to moderate.
///
/// Skippable, because the word-list name already works.
struct NicknameSheet: View {
    let friend: Friend
    let onSave: (String) -> Void
    let onSkip: () -> Void

    @State private var typed = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SproutImage(speciesID: friend.speciesID, level: friend.level,
                        skin: friend.lookID, size: 96)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Text("What do you call them?")
                .font(Theme.font(24, .black))
                .kerning(-0.5)
                .foregroundStyle(Theme.ink)
                .padding(.top, 14)

            Text("Just on your phone. They never see it.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)

            TextField(friend.displayName, text: $typed)
                .font(Theme.font(19, .bold))
                .foregroundStyle(Theme.ink)
                .focused($focused)
                .submitLabel(.done)
                .autocorrectionDisabled()
                .onSubmit { onSave(typed) }
                .onChange(of: typed) { _, new in
                    if new.count > Friend.nicknameLimit {
                        typed = String(new.prefix(Friend.nicknameLimit))
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.paper))
                .padding(.top, 20)

            Button { onSave(typed) } label: {
                Text("Save")
                    .font(Theme.font(17, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(canSave ? Theme.coral : Theme.coral.opacity(0.4)))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .padding(.top, 16)

            Button(action: onSkip) {
                Text("Skip")
                    .font(Theme.font(16, .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .background(Theme.card)
        .presentationDetents([.height(470)])
        .presentationDragIndicator(.visible)
        .onAppear { focused = true }
    }

    private var canSave: Bool { Friend.cleanNickname(typed) != nil }
}
