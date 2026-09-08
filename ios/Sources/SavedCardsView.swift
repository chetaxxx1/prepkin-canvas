import SwiftUI

/// Your own highlights, not a list of rows.
///
/// Each saved card keeps the shape of the card it came from — a key idea stays mint
/// and all-caps — so the deck reads as things you chose. Newest first, no sort
/// control; the pile is short by nature.
struct SavedCardsView: View {
    let onRead: (ReadingRequest) -> Void

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    /// Saved references whose card still exists. A lesson rewritten shorter drops its
    /// orphans quietly rather than showing a blank row.
    private var saved: [(ref: SavedCard, lesson: Lesson, card: LessonCard)] {
        state.savedCards.compactMap { ref in
            guard let (lesson, card) = Catalog.card(ref) else { return nil }
            return (ref, lesson, card)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if saved.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(saved, id: \.ref.id) { row($0.lesson, $0.card) }
                    }
                    .padding(.horizontal, 20).padding(.top, 24)
                }
            }
            .padding(.bottom, 60)
        }
        .background(Theme.paper)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.card))
                    .padding(3)
                    .contentShape(Rectangle())
                    .padding(-3)
            }
            .accessibilityLabel("Back")
            .padding(.bottom, 12)

            Text("Saved cards")
                .font(Theme.font(30, .black))
                .foregroundStyle(Theme.ink)
            Text(saved.isEmpty ? "Nothing kept yet"
                 : "\(saved.count) card\(saved.count == 1 ? "" : "s") you kept")
                .font(Theme.font(13, .bold))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func row(_ lesson: Lesson, _ card: LessonCard) -> some View {
        Button { onRead(ReadingRequest(lesson: lesson, startAt: card.index)) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    if card.kind == .key {
                        Text("KEY IDEA")
                            .font(Theme.font(10.5, .heavy))
                            .tracking(1.5)
                            .foregroundStyle(Theme.mintDark)
                    } else {
                        Text(Catalog.track(lesson.trackID).name.uppercased())
                            .font(Theme.font(10.5, .heavy))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(trackPill(lesson.trackID).bg))
                            .foregroundStyle(trackPill(lesson.trackID).ink)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                }

                Text(card.kind == .key ? card.body.uppercased()
                     : card.kind == .check ? card.question : card.body)
                    .font(Theme.font(card.kind == .key ? 15.5 : 16,
                                     card.kind == .key ? .heavy : .bold))
                    .lineSpacing(16 * 0.45)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(card.kind == .key ? Theme.mintSoft : Theme.card))
        }
        .buttonStyle(PressStyle())
    }

    private func trackPill(_ id: String) -> (bg: Color, ink: Color) {
        switch id {
        case "finance": return (Theme.coinSoft, Theme.coinDark)
        case "study": return (Theme.mintSoft, Theme.mintDark)
        case "psychology": return (Theme.hex(0xE6F0FB), Theme.hex(0x3D6FA8))
        case "people": return (Theme.coralSoft, Theme.coralDeep)
        case "work": return (Theme.hex(0xEEF6E0), Theme.hex(0x5A7A2E))
        default: return (Theme.hex(0xF5EFE3), Theme.muted)
        }
    }

    /// Teaches the gesture by showing it — a card, a heart, a tap ripple — rather than
    /// describing it. The second line gives the deck a purpose instead of apologising
    /// for being empty.
    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach([1.0, 0.82, 0.5], id: \.self) { w in
                        Capsule().fill(Theme.hairline)
                            .frame(width: 222 * w, height: 11)
                    }
                }
                .padding(18)
                .frame(width: 258, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Theme.hex(0x2E2622).opacity(0.08), radius: 16, y: 4))

                ZStack {
                    Circle().strokeBorder(Theme.coral.opacity(0.45), lineWidth: 2)
                        .frame(width: 52, height: 52)
                    Circle().strokeBorder(Theme.coral.opacity(0.20), lineWidth: 2)
                        .frame(width: 72, height: 72)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                }
                .offset(x: 14, y: 18)
            }
            .padding(.top, 44)

            HStack {
                SproutImage(speciesID: state.activeChibiID,
                            level: state.activeChibi.level,
                            skin: state.activeChibi.skinID, size: 104)
                Spacer()
            }
            .padding(.leading, 2).padding(.top, 6)

            Text("Tap the heart on a card you want to keep.")
                .font(Theme.font(21, .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 34).padding(.top, 6)

            Text("They land here, and Kin will bring one back to you now and then.")
                .font(Theme.font(15, .bold))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 40).padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
    }
}
