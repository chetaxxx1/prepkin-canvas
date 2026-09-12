import SwiftUI

/// One friend, up close.
///
/// **Their kin is a still over their tank plate, not a live tank.** `SproutView`
/// keeps one `WKWebView` for the whole app run and Home is its only host, so a
/// second one in a sheet either steals Home's (a one-second boot on open and
/// another on close) or spends a second web process — which is exactly what got a
/// live tank pulled off the Focus screen on 2026-09-05. This is the composition
/// Focus and Home's own cover already use, and it works offline, opens instantly
/// and costs one image decode.
///
/// What is on it is what the wire actually carries: a fish, stars, when the pair
/// was made, what they did today if they share it, and whether they are at a desk
/// right now. No coins (`design/SOCIAL-PLAN.md` F5), nothing they did not do
/// (`design/FRIENDS-BUILD-PLAN.md` section 7), and no free text anywhere.
///
/// The actions are Finch's friend-profile tiles
/// (`design/reference/finch/09-friend-profile-actions.png`): a row of square white
/// tiles under the pet, each an icon over two words. Ours are "Good vibes" (the
/// picker) and "Sit down" (a shift beside them, only while they are at a desk).
/// Finch's third tile is a paid gift, which this app does not have.
struct FriendCardSheet: View {
    @EnvironmentObject var state: AppState
    let friend: Friend
    /// Starts a shift alongside them. `nil` when they are not working.
    var onJoin: ((Int) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var blocking = false
    @State private var reporting = false
    @State private var picking = false
    /// Ticks once a minute so the shift clock counts down while the sheet is open.
    @State private var clock = Date()

    private var scene: Scene0 { Scene0.find(friend.sceneID) }
    private var today: TodayCounts? { state.today(for: friend) }
    private var minutesLeft: Int { friend.minutesLeftOnShift(at: clock) }
    private var joinLength: Int? {
        minutesLeft > 0 ? StudyTogether.joinLength(minutesLeft: minutesLeft) : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                tank
                name.padding(.top, 16)
                if let line = friend.shiftLine(at: clock) {
                    Text(line)
                        .font(Theme.font(14, .bold))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 5)
                }
                since.padding(.top, 3)
                if let place = boardLine {
                    Text(place)
                        .font(Theme.font(14, .bold))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 3)
                }
                // What they sent today, Finch's "FROM" line, in the card's own words.
                if state.game.wavesIn.contains(friend.id), state.game.wavesDay == state.game.effectiveDay {
                    let card = state.vibeReceived(from: friend)
                    HStack(spacing: 8) {
                        Image("icon-" + card.icon)
                            .resizable().scaledToFit().frame(width: 22, height: 22)
                        Text("\(friend.displayName) \(card.sent) today")
                            .font(Theme.font(14, .heavy))
                            .foregroundStyle(Theme.mintDark)
                    }
                    .padding(.top, 8)
                }

                tiles.padding(.top, 18)

                if let today { todayCard(today).padding(.top, 14) }

                quietRow.padding(.top, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.paper)
        .presentationDragIndicator(.visible)
        .tint(Theme.coral)
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { clock = $0 }
        .sheet(isPresented: $picking) { VibePickerSheet(friend: friend).environmentObject(state) }
        .confirmationDialog("Block \(friend.displayName)", isPresented: $blocking,
                            titleVisibility: .visible) {
            Button("Block") {
                state.blockFriend(friend.id)
                dismiss()
            }
            Button("Keep them", role: .cancel) {}
        } message: {
            Text("They leave your friends, and neither of you can add the other again.")
        }
        .confirmationDialog("Report \(friend.displayName)", isPresented: $reporting,
                            titleVisibility: .visible) {
            Button("Report") { state.reportFriend(friend.id) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We look at the pair of you by hand. They are not told, and they stay on your list until you remove them.")
        }
    }

    // MARK: - Their kin, on their water

    private var tank: some View {
        SproutImage(speciesID: friend.speciesID, level: friend.level,
                    skin: friend.lookID, size: 176)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Image(scene.asset)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.55)
                    .overlay(LinearGradient(
                        colors: [Theme.paper, Theme.paper.opacity(0),
                                 Theme.paper.opacity(0), Theme.paper],
                        startPoint: .top, endPoint: .bottom))
                    .clipped()
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(friend.displayName), \(friend.level) stars, in \(scene.name)")
    }

    private var name: some View {
        HStack(spacing: 10) {
            Text(friend.displayName)
                .font(Theme.font(28, .black))
                .kerning(-0.6)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            StarPips(level: friend.level, size: 15)
            Spacer(minLength: 0)
        }
    }

    private var since: some View {
        Text("Friends since \(Self.since.string(from: friend.friendsSince))")
            .font(Theme.font(14, .semibold))
            .foregroundStyle(Theme.muted)
    }

    private static let since: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    // MARK: - What they did today

    /// At most three lines, and the card is absent rather than empty when there are
    /// none. A friend with sharing off and a friend who has not started today look
    /// exactly the same here, which is the point.
    private func todayCard(_ counts: TodayCounts) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(Theme.font(12, .bold))
                .kerning(1.5)
                .foregroundStyle(Theme.muted)
            ForEach(TodayLines.lines(counts), id: \.self) { line in
                Text(line)
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    // MARK: - The tiles

    /// "3rd on your board this week · 610". Only against somebody: a board of two
    /// is you and them, which is still a place.
    private var boardLine: String? {
        let rows = state.weekBoard.rows
        guard rows.count >= 2, let mine = rows.first(where: { $0.id == friend.id }) else { return nil }
        return "\(FriendsWater.ordinal(mine.place)) on your board this week · \(mine.member.points)"
    }

    private var tiles: some View {
        let sent = state.hasWaved(at: friend)
        return HStack(spacing: 12) {
            tile(icon: sent ? "highFive" : "wave",
                 title: sent ? "Sent today" : "Good vibes",
                 note: sent ? "One a day" : "Six cards, one a day",
                 tint: sent ? Theme.mintSoft : Theme.coralSoft) {
                guard !sent else { return }
                picking = true
            }
            if let joinLength {
                tile(icon: "tabFocus", title: "Sit down",
                     note: "Your own \(joinLength) min", tint: Theme.hex(0xFCEFD3)) {
                    onJoin?(joinLength)
                    dismiss()
                }
            }
            raceTile
        }
    }

    /// Apple's "Compete with…": invite this friend to race the week. Three states
    /// and no fourth: invite, invited, racing. When a race with somebody else is
    /// already on there is no tile — one a week, and a dead control says nothing.
    @ViewBuilder private var raceTile: some View {
        let racing = state.currentRace.map { $0.other.id == friend.id } ?? false
        let invited = state.raceSent.map { $0.other.id == friend.id } ?? false
        let invitedYou = state.raceInvites.contains { $0.other.id == friend.id }
        if racing {
            tile(icon: "raceFlags", title: "Racing", note: "Settles Monday", tint: Theme.mintSoft) { dismiss() }
        } else if invited {
            tile(icon: "raceFlags", title: "Invited", note: "Waiting on them", tint: Theme.mintSoft) {}
        } else if invitedYou {
            tile(icon: "raceFlags", title: "Wants to race", note: "Answer on the tab", tint: Theme.coralSoft) { dismiss() }
        } else if state.canInviteToRace {
            tile(icon: "raceFlags", title: "Race", note: "This week, one on one", tint: Theme.coralSoft) {
                Task { await state.inviteToRace(friend) }
            }
        }
    }

    /// Finch's tile: white, square-ish, the icon over two short lines. The whole
    /// tile is the button.
    private func tile(icon: String, title: String, note: String, tint: Color,
                      action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            VStack(spacing: 8) {
                IconTile(icon: icon, size: 44)
                VStack(spacing: 2) {
                    Text(title)
                        .font(Theme.font(14.5, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(note)
                        .font(Theme.font(11.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.hex(0x2E2622).opacity(0.06), radius: 11, y: 8))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(tint, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(note)")
    }

    // MARK: - The quiet three

    private var quietRow: some View {
        VStack(spacing: 0) {
            quiet("Remove", "They come off your list. Nobody is told.") {
                state.removeFriend(friend.id)
                dismiss()
            }
            hairline
            quiet("Block", "They leave, and neither of you can add the other again.") {
                blocking = true
            }
            hairline
            quiet("Report", "Sends the pair of you to be looked at by hand.") {
                reporting = true
            }
        }
        .background(card)
    }

    private func quiet(_ title: String, _ note: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(Theme.coral)
                Text(note)
                    .font(Theme.font(12.5, .semibold))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var hairline: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 16)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Theme.card)
            .shadow(color: Theme.hex(0x2E2622).opacity(0.05), radius: 11, y: 8)
    }
}
