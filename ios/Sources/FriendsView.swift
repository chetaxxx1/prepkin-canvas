import SwiftUI

/// Friends tab: the weekly board, and the people on it.
///
/// Rebuilt 2026-09-12 (artifact "The Weekly Board"). The tab opens on the board —
/// you and your friends ranked by the week, scored like an Apple Watch competition
/// (`Core/WeekBoard.swift`) — then the group quest, then the strangers pod for
/// anyone who joined one. Finch is still the model for everything about a friend
/// (their kin, a free wave, a card you visit); Duolingo's is for the week (a Monday
/// result, a quest with a shared bar). Rank numerals are on, by George's call; a
/// promotion zone, a demotion zone and a countdown are still out, and no number a
/// student keeps ever goes down.
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
    /// The settled week whose sheet is up. Set on appear from `state.mondayCard`,
    /// so the sheet opens once per settled week and never over another sheet.
    @State private var monday: LeagueWeekResult?
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
            GeometryReader { geo in
            ScrollView {
                // The page opens on the scene, Finch's way: the water runs under the
                // status bar and everything else sits below it in the gutter. Read
                // the board once per body — it walks the ledger.
                let board = state.weekBoard
                FriendsWater(tier: state.league.tier, rows: board.rows,
                             topInset: geo.safeAreaInsets.top,
                             onEmptyTap: { showAdd = true },
                             onTap: { row in
                                 if let f = friends.first(where: { $0.id == row.id }) { showing = f }
                             })
                VStack(alignment: .leading, spacing: 0) {
                    // Somebody typed your code. It sits first under the water because
                    // it is the only thing on this tab that is news, and it is gone
                    // the moment you have looked at it.
                    if !addedYou.isEmpty { addedYouCard.padding(.top, 14) }
                    // Somebody said hello. Same shape as the card above it, and it
                    // ends the same way: by being looked at.
                    if !waved.isEmpty { wavedCard.padding(.top, 14) }
                    // Somebody wants a race. Two answers, and it stays until one is given.
                    ForEach(state.raceInvites) { invite in
                        raceInviteCard(invite).padding(.top, 14)
                    }
                    // The race that is on. Apple's competition card: two sides, a
                    // split bar, one line saying who is ahead.
                    if let race = state.currentRace { raceCard(race).padding(.top, 14) }

                    // Friends cannot see you on their board until you share your
                    // week. Asked here, where the reason is on screen, and only
                    // once there is somebody to share with.
                    if !friends.isEmpty, !state.game.shareToday { sharePrompt.padding(.top, 14) }

                    if board.rows.count > 3 { boardRows(Array(board.rows.dropFirst(3))).padding(.top, 14) }

                    if let quest = state.groupQuest {
                        questCard(quest, members: board.rows.map(\.member)).padding(.top, 14)
                    }

                    if !board.off.isEmpty { offBoard(board.off).padding(.top, 14) }

                    // The strangers pod, on the tab once you are in one. Before
                    // that it is a row: the offer is long, and it belongs where the
                    // ladder can explain it.
                    if state.podOptIn {
                        PodSection()
                            .padding(16)
                            .background(cardBackground(Theme.Radius.card))
                            .padding(.top, 14)
                    }

                    linkRows.padding(.top, 14)
                }
                // The column never reports wider than the screen. A row that wanted
                // more made the ScrollView centre the page, so the title and every
                // card sat 3pt left of the gutter until that row went away.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, Theme.tabClearance)
            }
            .ignoresSafeArea(edges: .top)
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
        // Last week, once. Duolingo's Monday screen: the trophy, the line, Continue.
        .sheet(item: $monday, onDismiss: { state.dismissMondayCard() }) { last in
            MondaySheet(last: last) { monday = nil }
        }
        .onAppear { monday = state.mondayCard }
        .task {
            await state.refreshFriends()
            // All three are silent on failure and all three are cheap. They run
            // after the list because none of them means anything without it.
            await state.refreshWaves()
            await state.refreshToday()
            await state.refreshRaces()
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
                        Text("\(f.displayName) \(state.vibeReceived(from: f).sent)")
                            .font(Theme.font(15.5, .heavy))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 8)
                        IconTile(icon: state.vibeReceived(from: f).icon, size: 36)
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

    // MARK: - The race

    /// "Crisp Harbor wants to race you this week." Apple's competition invite,
    /// as a card in the tab's news slot: accept, or not this week. A declined
    /// invite tells nobody — it simply stops being drawn, on both phones.
    private func raceInviteCard(_ invite: Pact) -> some View {
        let who = state.friend(for: invite)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                SproutImage(speciesID: who.speciesID, level: who.level, skin: who.lookID, size: 44)
                    .frame(width: 44, height: 44, alignment: .bottom)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(who.displayName) wants to race you this week")
                        .font(Theme.font(15.5, .heavy))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Same scoring as the board. Ahead on Sunday night keeps a pennant. Nobody loses anything.")
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await state.answerRace(invite, accept: true) }
                } label: {
                    HStack(spacing: 6) {
                        BadgeMark(icon: "raceFlags", height: 16)
                        Text("Race")
                    }
                    .font(Theme.font(14, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Theme.coral)
                        .shadow(color: Theme.coral.opacity(0.28), radius: 10, y: 5))
                }
                .buttonStyle(.plain)
                Button {
                    Task { await state.answerRace(invite, accept: false) }
                } label: {
                    Text("Not this week")
                        .font(Theme.font(14, .heavy))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Theme.tile)
                            .overlay(Capsule().strokeBorder(Theme.tileRing, lineWidth: 1)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(cardBackground(Theme.Radius.card))
    }

    /// Apple Watch's competition card: your side, their side, a bar split by the
    /// two scores, and the one line that says who is ahead. No countdown; the week
    /// settles Monday like everything else.
    private func raceCard(_ race: Pact) -> some View {
        let who = state.friend(for: race)
        let standing = state.raceStanding
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    BadgeMark(icon: "raceFlags", height: 16)
                    Text("Race with \(who.displayName)")
                        .font(Theme.font(15, .black))
                        .foregroundStyle(Theme.ink)
                }
                Spacer(minLength: 8)
                Text("SETTLES MONDAY")
                    .font(Theme.font(11, .black))
                    .kerning(0.6)
                    .foregroundStyle(Theme.dim)
            }
            HStack(alignment: .bottom) {
                raceSide(speciesID: state.activeChibiID, level: state.activeChibi.level,
                         skin: state.activeChibi.skinID, points: standing?.mine, name: "You")
                Spacer(minLength: 0)
                Text(standing?.line ?? "Waiting on their week")
                    .font(Theme.font(12.5, .black))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 120)
                    .padding(.bottom, 26)
                Spacer(minLength: 0)
                raceSide(speciesID: who.speciesID, level: who.level, skin: who.lookID,
                         points: standing?.theirs, name: who.displayName)
            }
            .padding(.top, 12)
            if let standing {
                let total = max(1, standing.mine + standing.theirs)
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        Capsule().fill(state.league.tier.color)
                            .frame(width: geo.size.width * CGFloat(standing.mine) / CGFloat(total))
                        Capsule().fill(Theme.coral)
                    }
                }
                .frame(height: 12)
                .padding(.top, 12)
                .accessibilityHidden(true)
            }
            Text(standing == nil
                 ? "\(who.displayName) hasn't shared a day this week yet. The race starts counting the moment they do."
                 : "Same scoring as the board, capped at \(WeekPoints.dayMax) a day. Ahead on Sunday night keeps a race pennant. Level is a pennant each.")
                .font(Theme.font(11.5, .heavy))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .padding(16)
        .background(cardBackground(Theme.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Race with \(who.displayName). \(standing?.line ?? "Waiting on their week")")
    }

    private func raceSide(speciesID: String, level: Int, skin: String, points: Int?, name: String) -> some View {
        VStack(spacing: 2) {
            SproutImage(speciesID: speciesID, level: level, skin: skin, size: 76)
                .frame(width: 76, height: 76, alignment: .bottom)
            Text(points.map { "\($0)" } ?? "—")
                .font(Theme.font(20, .black))
                .foregroundStyle(Theme.ink)
            Text(name)
                .font(Theme.font(12, .bold))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
        }
        .frame(width: 104)
    }

    // MARK: - Share my week

    /// Apple's "Share activity", asked where the board makes the reason obvious.
    /// Four counts and nothing else, said in the same words the privacy sheet uses.
    private var sharePrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Friends can't see you on their board yet")
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)
            Text("Sharing shows them four counts: tasks, focus minutes, lessons, games. Not what they were, not coins, not grades.")
                .font(Theme.font(12.5, .bold))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeOut(duration: 0.22)) {
                    state.setSharing(today: true, board: state.game.shareBoard)
                }
            } label: {
                Text("Show my week")
                    .font(Theme.font(15, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Theme.coral)
                        .shadow(color: Theme.coral.opacity(0.28), radius: 12, y: 5))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground(Theme.Radius.card))
    }

    // MARK: - The rows

    /// Fourth place down, Duolingo's league list (Mobbin aea875c3): a coloured
    /// numeral, the avatar, the name, the number on the right, your own row tinted.
    /// The podium holds three; these are everybody else. Tapping a row opens the
    /// person; the clap is the same one-a-day wave the card sends, one tap closer.
    private func boardRows(_ rows: [BoardRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                boardRow(row)
                if row.id != rows.last?.id { hairline.padding(.leading, 68) }
            }
        }
        .background(cardBackground(Theme.Radius.card))
    }

    private func boardRow(_ row: BoardRow) -> some View {
        let friend = friends.first { $0.id == row.id }
        let m = row.member
        return HStack(spacing: 12) {
            Text("\(row.place)")
                .font(Theme.font(15, .black))
                .foregroundStyle(state.league.tier.edge)
                .frame(width: 22)
            SproutImage(speciesID: m.speciesID, level: m.level, skin: m.lookID, size: 40)
                .frame(width: 40, height: 40, alignment: .bottom)
                .overlay(alignment: .bottomTrailing) {
                    if friend?.minutesLeftOnShift(at: clock) ?? 0 > 0 {
                        Circle().fill(Theme.mint)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            .accessibilityHidden(true)
                    }
                }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(m.name)
                        .font(Theme.font(15.5, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    StarPips(level: m.level, size: 10, spacing: 2.5)
                    if m.isYou {
                        Text("You")
                            .font(Theme.font(9.5, .black))
                            .foregroundStyle(Theme.coralShade)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Theme.coralSoft))
                    }
                }
                if let line = friend?.shiftLine(at: clock) {
                    Text(line)
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            Text("\(m.points)")
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)
            if let friend {
                clapButton(friend)
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .background(m.isYou ? state.league.tier.color.opacity(0.14) : .clear)
        .contentShape(Rectangle())
        .onTapGesture { if let friend { showing = friend } }
        .contextMenu { if let friend { menuItems(friend) } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(m.isYou ? "You" : m.name), \(FriendsWater.ordinal(row.place)), \(m.points) points")
    }

    /// The wave, from the row. Settles on the phone the moment it is tapped.
    private func clapButton(_ f: Friend) -> some View {
        let sent = state.hasWaved(at: f)
        return Button {
            guard !sent else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) { state.wave(at: f) }
        } label: {
            BadgeMark(icon: "wave", height: 20)
                .saturation(sent ? 0.3 : 1)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(sent ? Theme.mintSoft : Theme.coralSoft))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sent ? "Waved at \(f.displayName) today" : "Wave at \(f.displayName)")
    }

    // MARK: - The quest

    /// Duolingo's Friends Quest card (Mobbin db515e34), line for line: an eyebrow
    /// with the time on the right, a picture band with the people in it, the goal
    /// in bold, a bar with the fraction inside it, a row per person with a coloured
    /// dot and their share, and a button row. Ours is for the whole board, the
    /// picture is the kin, the time is "Settles Monday", and Gift is not a thing.
    private func questCard(_ q: GroupQuest.Status, members: [BoardMember]) -> some View {
        let nudge = GroupQuest.nudge(q, members: members)
        let nudgeFriend = nudge.flatMap { n in friends.first { $0.id == n.id } }
        let ranked = members.sorted { q.kind.count(in: $0.counts) > q.kind.count(in: $1.counts) }
        let tint = q.cleared ? Theme.mint : state.league.tier.color
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("THIS WEEK, TOGETHER")
                    .font(Theme.font(12, .black))
                    .kerning(1.2)
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 8)
                Text(q.cleared ? "CLEARED" : "SETTLES MONDAY")
                    .font(Theme.font(11, .black))
                    .kerning(0.6)
                    .foregroundStyle(q.cleared ? Theme.mintDark : Theme.dim)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // The picture band: everybody on the board, in a row, on a wash of the
            // tier's water. Duolingo's is a scene; ours is the people themselves.
            HStack(spacing: -6) {
                ForEach(ranked.prefix(6)) { m in
                    SproutImage(speciesID: m.speciesID, level: m.level, skin: m.lookID, size: 54)
                        .frame(width: 54, height: 54, alignment: .bottom)
                }
                if ranked.count > 6 {
                    Text("+\(ranked.count - 6)")
                        .font(Theme.font(13, .black))
                        .foregroundStyle(state.league.tier.edge)
                        .padding(.leading, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(state.league.tier.color.opacity(0.16)))
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .accessibilityHidden(true)

            Text(GroupQuest.line(q))
                .font(Theme.font(17, .black))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            // The bar, with the fraction inside it, Duolingo's way.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline)
                    Capsule().fill(tint)
                        .frame(width: max(0, geo.size.width * min(1, Double(q.progress) / Double(max(1, q.goal)))))
                    Text(GroupQuest.progressLine(q))
                        .font(Theme.font(11.5, .black))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 20)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(GroupQuest.progressLine(q))

            // One row per person, most first. A dot in the water's colour for you,
            // Duolingo's dark one for everybody else.
            VStack(spacing: 6) {
                ForEach(ranked.prefix(4)) { m in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(m.isYou ? state.league.tier.color : Theme.ink.opacity(0.55))
                            .frame(width: 9, height: 9)
                        Text(m.isYou ? "You" : m.name)
                            .font(Theme.font(14.5, .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(questShare(q.kind, m))
                            .font(Theme.font(14, .bold))
                            .foregroundStyle(Theme.muted)
                    }
                    .accessibilityElement(children: .combine)
                }
                if ranked.count > 4 {
                    Text("\(ranked.count - 4) more on the board")
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.dim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 19)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if let nudgeFriend {
                let sent = state.hasWaved(at: nudgeFriend)
                Button {
                    guard !sent else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) { state.wave(at: nudgeFriend) }
                } label: {
                    HStack(spacing: 8) {
                        BadgeMark(icon: "wave", height: 18)
                        Text(sent ? "Nudged \(nudgeFriend.displayName)" : "Nudge \(nudgeFriend.displayName)")
                            .font(Theme.font(13.5, .black))
                    }
                    .foregroundStyle(sent ? Theme.mintDark : Theme.coral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(sent ? Theme.mint : Theme.coral.opacity(0.5), lineWidth: 1.6))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }

            Text(q.cleared ? "A quest pennant for the \(q.headcount) of you, kept on the ladder."
                           : "Clears by Sunday night, a quest pennant for everybody on the board.")
                .font(Theme.font(11.5, .heavy))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(Theme.Radius.card))
    }

    /// "9 tasks", "1h 20m", "2 lessons", "5 games".
    private func questShare(_ kind: GroupQuest.Kind, _ m: BoardMember) -> String {
        let n = kind.count(in: m.counts)
        switch kind {
        case .tasks: return "\(n) \(n == 1 ? "task" : "tasks")"
        case .focus: return n == 0 ? "0 min" : TodayLines.clock(n)
        case .lessons: return "\(n) \(n == 1 ? "lesson" : "lessons")"
        case .games: return "\(n) \(n == 1 ? "game" : "games")"
        }
    }

    // MARK: - Not on the board

    /// Friends with no shared day this week. Sharing off and nothing done look the
    /// same here on purpose, and the line says the thing that is true of both.
    private func offBoard(_ list: [Friend]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Not on the board this week")
                .font(Theme.font(12, .bold))
                .kerning(1.5)
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            ForEach(list) { f in
                friendRow(f)
                if f.id != list.last?.id { hairline.padding(.leading, 52) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(cardBackground(26))
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

    // MARK: - The one action, and the two rows

    /// The ladder and the privacy row. Duolingo's league tab has one entry that is
    /// the league itself (Mobbin 3ca570fe-9e97-4e65-85eb-3e544a7eacab); ours had
    /// two rows that both opened `LeagueLadderView`, the pod and the ladder. The
    /// pod is a Join button inside the ladder screen (`PodSection`), where the
    /// rules are, so its row here went on 2026-09-12.
    private var linkRows: some View {
        VStack(spacing: 0) {
            ForEach(Self.links, id: \.self) { link in
                switch link {
                case .ladder:
                    linkRow(title: "The whole ladder",
                            note: ladderNote,
                            tint: D.mintTint) {
                        TierPennant(tier: state.league.tier, earned: true, height: 20)
                    }
                    hairline
                case .privacy:
                    // Sharing today's work starts off, so this row is also the only
                    // way it ever gets turned on. It sits here rather than behind a
                    // gear on the title row because a setting nobody can find is
                    // not a choice.
                    Button { showPrivacy = true } label: {
                        privacyRowLabel
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(cardBackground(Theme.Radius.card))
    }

    /// The rows under the board, in order. One of them opens the league.
    enum Link: Hashable, CaseIterable {
        case ladder, privacy
        var opensLeague: Bool { self == .ladder }
    }
    static let links: [Link] = [.ladder, .privacy]

    private var privacyRowLabel: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: Theme.Radius.tile(38), style: .continuous)
                .fill(IconTint.of("eye").soft)
                .frame(width: 38, height: 38)
                .overlay(BadgeMark(icon: "eye", height: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text("What friends see")
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(Theme.ink)
                Text(state.game.shareToday ? "Your fish, and your week"
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

    /// "Shallows, second of six waters · 2 weeks won". The count only when there is one.
    private var ladderNote: String {
        var s = "\(state.league.tier.name), \(placeInLadder) of six waters"
        let won = state.league.weeksWon
        if won > 0 { s += " · \(won) \(won == 1 ? "week" : "weeks") won" }
        return s
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

    /// What a typed I, O, 0 or 1 gets. It used to guess a swap ("Try L, Q"), which
    /// was a second fact on a line that only has room for one.
    static let badCharLine = "Codes skip I, O, 0 and 1."

    /// Muted, never red. A wrong character is a typo, not a failure.
    private var codeLine: String {
        if let line = state.friendStatus { return line }
        // The same words for a typo, a code that has been replaced, a code that was
        // never real and somebody who blocked you. Saying which one it is would let
        // a stranger use this screen to find out whether a code is live.
        if addFailed { return "That code didn't open anything. Check it with them." }
        if adding { return "Looking." }
        if !badChars.isEmpty { return Self.badCharLine }
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
