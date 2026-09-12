import Foundation

// A vibe: one tap that puts a small fixed thing on somebody else's screen.
//
// **Six cards, Finch's Good Vibes** (`design/reference/finch/11-good-vibes-picker.png`):
// a fixed grid of named cards, free to send, one per friend per day. The pictures
// are the app's own icons, so nothing new was drawn for this and the picker looks
// like the rest of the app. Three are free and three come with Plus — `PLUS-SPEC.md`
// signature 8, which George signed on 2026-09-10, and `PlusGate.vibeCards` holds
// the split. A Plus card *received* by a free phone still draws; the gate is on
// sending only.
//
// The bridge accepts 0 to 15 (`vibes_kind` in bridge/schema-social.sql), so the rest
// of the range is a data change later, not a wire change and not a migration.

/// One fixed card. There is no free text here and there never will be — that is the
/// whole of `design/SOCIAL-PLAN.md` F6, and it is what keeps this out of being a
/// moderated product.
struct VibeCard: Identifiable, Equatable {
    /// The index on the wire. Fixed forever once it ships: a card that changed
    /// meaning would rewrite what somebody already sent.
    let kind: Int
    let label: String
    /// The icon in the catalogue, `icon-<name>`. From the shared set, never a
    /// one-off drawing.
    let icon: String
    /// "sent you a high five". What the received card says after the name.
    let sent: String

    var id: Int { kind }
}

enum Vibes {
    /// The one-tap wave, from a board row. Kind 0 is the card every build has.
    static let wave = VibeCard(kind: 0, label: "Hello", icon: "wave", sent: "waved")

    /// The six, in the order the picker draws them. The first `PlusGate.vibeCards.free`
    /// are free; the rest carry a Plus tag until the student has it.
    static let all: [VibeCard] = [
        wave,
        VibeCard(kind: 1, label: "High five", icon: "highFive", sent: "sent you a high five"),
        VibeCard(kind: 2, label: "Nice one", icon: "star", sent: "said nice one"),
        VibeCard(kind: 3, label: "Drink water", icon: "lifeCare", sent: "says drink some water"),
        VibeCard(kind: 4, label: "Stretch", icon: "stretch", sent: "says take a stretch"),
        VibeCard(kind: 5, label: "Sleep well", icon: "sleep", sent: "says sleep well"),
    ]

    /// Whether a card is free to send, or a Plus one, for a student with `isPlus`.
    static func canSend(_ card: VibeCard, isPlus: Bool) -> Bool {
        let n = PlusGate.value(.vibeCards, isPlus: isPlus)
        return all.firstIndex(of: card).map { $0 < n } ?? false
    }

    /// What the wire will accept. Wider than `all` on purpose.
    static let reserved = 0...15

    /// The card to draw for an index.
    ///
    /// **An index this build has no picture for falls back to the wave.** A phone
    /// that has not been updated will one day be waved at with card 4, and the
    /// honest answer is the card it has, not a hole where a friend's hello was.
    static func card(kind: Int) -> VibeCard {
        all.first { $0.kind == kind } ?? wave
    }

    /// One row per sender, newest kept.
    ///
    /// `fetch_visits` returns yesterday and today (see the window in
    /// bridge/schema-social.sql and why it is two days), oldest first, so anybody
    /// who waved on both days appears twice. Nobody is drawn twice.
    static func newest(_ visits: [VibeVisit]) -> [VibeVisit] {
        var byID: [String: VibeVisit] = [:]
        for v in visits { byID[v.sender.id] = v }
        return visits.reduce(into: [VibeVisit]()) { out, v in
            guard let newest = byID[v.sender.id], !out.contains(where: { $0.sender.id == v.sender.id })
            else { return }
            out.append(newest)
        }
    }
}

/// Somebody waved at you: who, and which card.
struct VibeVisit: Equatable, Decodable {
    let sender: Friend
    let kind: Int

    private enum CodingKeys: String, CodingKey { case kind }

    init(sender: Friend, kind: Int) {
        self.sender = sender
        self.kind = kind
    }

    /// The row is `public_player(sender)` with a `kind` added, so the sender decodes
    /// with the same tolerant reader every other friend row uses.
    init(from decoder: Decoder) throws {
        sender = try Friend(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(Int.self, forKey: .kind) ?? 0
    }
}
