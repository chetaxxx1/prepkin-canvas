import SwiftUI

/// Finch's Good Vibes picker (`design/reference/finch/11-good-vibes-picker.png`,
/// `13-…-highfive.png`), copied in shape: a coloured sheet, your kin at the top
/// with a bubble that names what you are about to send, a grid of round cards
/// with a label under each, the chosen one lit, and one button that says exactly
/// what it will do. Finch pads its locked cards with a padlock; ours carry the
/// Plus tag and open the Plus sheet, because nothing in this app is padlocked.
///
/// One per friend per day. The sheet only opens when today's is still unsent,
/// so there is no "already sent" state to draw in here.
struct VibePickerSheet: View {
    @EnvironmentObject var state: AppState
    let friend: Friend
    @Environment(\.dismiss) private var dismiss

    @State private var chosen: VibeCard = Vibes.wave
    @State private var plusReason: PlusSheet.Reason?
    @State private var sent = false

    private var tier: LeagueTier { state.league.tier }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            kin.padding(.top, 26)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Vibes.all) { card in
                    tile(card)
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 22)

            Spacer(minLength: 12)

            Button {
                guard !sent else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.easeOut(duration: 0.2)) { sent = true }
                state.send(chosen, to: friend)
                state.show("Sent \(friend.displayName) a \(chosen.label.lowercased()).")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { dismiss() }
            } label: {
                Text(sent ? "Sent" : "Send \(chosen.label.lowercased())")
                    .font(Theme.font(17, .black))
                    .foregroundStyle(sent ? Theme.mintDark : tier.edge)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous)
                        .fill(sent ? Theme.mintSoft : .white)
                        .shadow(color: Theme.hex(0x281923).opacity(0.14), radius: 10, y: 6))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [tier.color.opacity(0.55), tier.color, tier.color],
                           startPoint: .top, endPoint: .bottom)
                .background(Theme.card)
        )
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
        .sheet(item: $plusReason) { PlusSheet(reason: $0) }
    }

    // MARK: - The kin and the bubble

    /// Finch: "Let's give Diana a big high five!" over the bird. Ours, without the
    /// exclamation mark, over the fish.
    private var kin: some View {
        VStack(spacing: 6) {
            Text(bubble)
                .font(Theme.font(14.5, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.10), radius: 10, y: 3))
                .padding(.horizontal, 30)
                .animation(.easeOut(duration: 0.18), value: chosen)
            SproutImage(speciesID: state.activeChibiID, level: state.activeChibi.level,
                        skin: state.activeChibi.skinID, size: 104)
                .frame(width: 104, height: 104, alignment: .bottom)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bubble)
    }

    private var bubble: String {
        switch chosen.kind {
        case 0: return "Say hello to \(friend.displayName)?"
        case 1: return "A high five for \(friend.displayName)?"
        case 2: return "Tell \(friend.displayName) nice one?"
        case 3: return "Remind \(friend.displayName) to drink water?"
        case 4: return "Send \(friend.displayName) a stretch break?"
        default: return "Wish \(friend.displayName) a good sleep?"
        }
    }

    // MARK: - One card

    private func tile(_ card: VibeCard) -> some View {
        let on = card == chosen
        let plus = !Vibes.canSend(card, isPlus: state.isPlus)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if plus { plusReason = .vibe; return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { chosen = card }
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle().fill(.white)
                    Image("icon-" + card.icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                .frame(width: 66, height: 66)
                .overlay(Circle().strokeBorder(on ? Theme.ink : .clear, lineWidth: 3))
                .scaleEffect(on ? 1.06 : 1)
                .shadow(color: .black.opacity(on ? 0.16 : 0.08), radius: on ? 10 : 6, y: 3)
                Text(card.label)
                    .font(Theme.font(12, .black))
                    .foregroundStyle(on ? Theme.ink : tier.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if plus { PlusTag() }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(on ? .white.opacity(0.35) : .clear))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(plus ? "\(card.label), in Plus" : card.label)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }
}
