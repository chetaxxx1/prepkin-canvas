import SwiftUI

/// What friends can see, in two switches and four plain sentences.
///
/// There are only two because there are only two things a friend could be shown
/// beyond the fish. Everything else this app knows — your assignments, your grades,
/// your school, what a lesson was called — never leaves the phone at all, so there
/// is no switch for it and the block at the bottom says so out loud rather than
/// leaving a student to wonder.
///
/// `share_today` starts **off**. There is no accept step, so anybody handed a code
/// becomes a friend on the spot; a fortnight of somebody's study log should not be
/// readable before they have seen this screen.
struct PrivacySheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var shareToday = false
    @State private var shareBoard = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("What friends see")
                    .font(Theme.font(28, .black))
                    .kerning(-0.6)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)

                VStack(spacing: 0) {
                    row("What you did today",
                        "Four numbers: tasks, focus minutes, lessons and games. Never what a task said or what a lesson was called.",
                        isOn: $shareToday)
                    hairline
                    row("Your times on the daily games",
                        "The board you and your friends are already playing the same day.",
                        isOn: $shareBoard)
                }
                .background(card)
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Friends can never see your assignments, your grades, or your school.")
                    Text("Nobody can add you unless you give them your code, and a new code stops the old one working.")
                    Text("Your fish, its stars and whether you are on shift are always visible to a friend. That is what a code is for.")
                }
                .font(Theme.font(14, .semibold))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(card)
                .padding(.top, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 32)
        }
        .background(Theme.paper)
        .presentationDragIndicator(.visible)
        .tint(Theme.coral)
        .onAppear {
            shareToday = state.game.shareToday
            shareBoard = state.game.shareBoard
        }
        // Published on every flip rather than on dismiss: a student who swipes the
        // sheet away has still made the choice.
        .onChange(of: shareToday) { _, _ in publish() }
        .onChange(of: shareBoard) { _, _ in publish() }
    }

    private func publish() {
        state.setSharing(today: shareToday, board: shareBoard)
    }

    private func row(_ title: String, _ note: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(Theme.ink)
                Text(note)
                    .font(Theme.font(12.5, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Theme.mint))
        .padding(.horizontal, 16)
        .frame(minHeight: 66)
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
