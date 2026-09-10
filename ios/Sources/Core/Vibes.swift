import Foundation

// A vibe: one tap that puts a small fixed thing on somebody else's screen.
//
// **One card ships.** `design/CLAUDE-DESIGN-PROMPT-FRIENDS-V3-A` asks for six drawn
// faces and they do not exist yet, so the wave is the whole vocabulary for now and
// indices 1 to 5 are held open. That is not only an art decision: `design/PLUS-SPEC.md`
// signature 8 says the six have to ship as three free and three paid on the day they
// arrive, and six placeholders shipped free first would take that choice away for good.
//
// The bridge accepts 0 to 15 (`vibes_kind` in bridge/schema-social.sql), so the other
// five are a data change later, not a wire change and not a migration.

/// One fixed card. There is no free text here and there never will be — that is the
/// whole of `design/SOCIAL-PLAN.md` F6, and it is what keeps this out of being a
/// moderated product.
struct VibeCard: Identifiable, Equatable {
    /// The index on the wire. Fixed forever once it ships: a card that changed
    /// meaning would rewrite what somebody already sent.
    let kind: Int
    let label: String

    var id: Int { kind }
}

enum Vibes {
    /// The one that exists. Drawn with `ClapGlyph`, which is already in the app and
    /// already signed off, so nothing new is drawn and nothing animates.
    static let wave = VibeCard(kind: 0, label: "High five")

    /// What this build can draw. The picker is a row of these; today it is a row of
    /// one, which reads as a button rather than a choice, and that is honest.
    static let all: [VibeCard] = [wave]

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
