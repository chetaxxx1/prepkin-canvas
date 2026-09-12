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
struct FriendCardSheet: View {
    @EnvironmentObject var state: AppState
    let friend: Friend
    /// Starts a shift alongside them. `nil` when they are not working.
    var onJoin: ((Int) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var blocking = false
    @State private var reporting = false
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

                if let today { todayCard(today).padding(.top, 18) }

                waveRow.padding(.top, 14)
                if let joinLength { joinRow(joinLength).padding(.top, 10) }

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

    // MARK: - The two things you can do

    /// One card, not a picker. The six faces are not drawn yet, so this is a button
    /// that says what it does; when the rest arrive it becomes a row of them and
    /// nothing else here changes.
    private var waveRow: some View {
        let sent = state.hasWaved(at: friend)
        return Button {
            guard !sent else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) { state.wave(at: friend) }
        } label: {
            HStack(spacing: 10) {
                BadgeMark(icon: "wave", height: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sent ? "Waved" : Vibes.wave.label)
                        .font(Theme.font(16, .heavy))
                        .foregroundStyle(sent ? .white : Theme.coral)
                    Text(sent ? "They see it next time they open Prepkin."
                              : "One a day, and they see it when they next open Prepkin.")
                        .font(Theme.font(12.5, .semibold))
                        .foregroundStyle(sent ? .white.opacity(0.9) : Theme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(sent ? Theme.mint : Theme.coralSoft))
        }
        .buttonStyle(.plain)
        // Not `.disabled`: that dims the whole label, and the settled state is the
        // one a student actually reads. The guard above is what stops a second send.
        .accessibilityLabel(sent ? "You waved at \(friend.displayName) today"
                                 : "Wave at \(friend.displayName)")
    }

    /// Two independent clocks, never one shared room. Joining links nothing: quitting
    /// early costs you nothing extra and they are never told.
    private func joinRow(_ length: Int) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onJoin?(length)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sit down with them")
                    .font(Theme.font(16, .heavy))
                    .foregroundStyle(.white)
                Text("Starts your own \(length) minutes. Yours is yours.")
                    .font(Theme.font(12.5, .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.coral))
        }
        .buttonStyle(.plain)
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
