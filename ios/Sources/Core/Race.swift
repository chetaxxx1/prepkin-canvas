import Foundation

// A race: one friend, one week, a pennant for whoever finishes ahead.
//
// Apple Watch's Activity competition, copied in shape: you invite one person, they
// accept, and for a fixed window the two of you are compared on the same capped
// score. Apple's window is seven days from tomorrow; ours is the ISO week the
// invite was sent in, which is the window both phones already score for the board
// (`WeekPoints`), so a race needs no clock of its own and no score on the bridge.
// The bridge holds the handshake (`bridge/schema-pacts.sql`); each phone works the
// race out from the day rows it already fetches.
//
// **Nothing here can lower anything.** Whoever finishes ahead keeps a race pennant.
// The other keeps everything they already had. A tie is two pennants.

/// One pact as the bridge sends it: the other person, who asked, the week, and
/// whether it is on.
struct Pact: Identifiable, Codable, Equatable {
    let id: String
    let kind: Int
    let week: WeekKey
    /// You proposed it.
    let mine: Bool
    let accepted: Bool
    let declined: Bool
    let other: Friend

    static let raceKind = 1

    /// Waiting on the other side.
    var pendingTheirs: Bool { !accepted && !declined && mine }
    /// Waiting on you.
    var pendingMine: Bool { !accepted && !declined && !mine }

    private enum CodingKeys: String, CodingKey { case id, kind, week, mine, accepted, declined, other }

    init(id: String, kind: Int = Pact.raceKind, week: WeekKey, mine: Bool,
         accepted: Bool, declined: Bool = false, other: Friend) {
        self.id = id
        self.kind = kind
        self.week = week
        self.mine = mine
        self.accepted = accepted
        self.declined = declined
        self.other = other
    }

    /// Tolerant, like every other friend row: a field the bridge did not send
    /// falls back rather than throwing the whole list away.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        kind = try c.decodeIfPresent(Int.self, forKey: .kind) ?? Pact.raceKind
        week = try c.decodeIfPresent(WeekKey.self, forKey: .week) ?? WeekKey(raw: "")
        mine = try c.decodeIfPresent(Bool.self, forKey: .mine) ?? false
        accepted = try c.decodeIfPresent(Bool.self, forKey: .accepted) ?? false
        declined = try c.decodeIfPresent(Bool.self, forKey: .declined) ?? false
        other = try c.decode(Friend.self, forKey: .other)
    }
}

/// Where a race stands, worked out on the phone from two week scores.
struct RaceStanding: Equatable {
    let pact: Pact
    let mine: Int
    let theirs: Int

    var lead: Int { mine - theirs }
    var ahead: Bool { lead > 0 }
    var level: Bool { lead == 0 }

    /// "You're ahead by 60", "Maya is ahead by 60", "Level".
    var line: String {
        if level { return "Level" }
        return ahead ? "You're ahead by \(lead)" : "\(pact.other.displayName) is ahead by \(-lead)"
    }
}

/// How a finished race is kept on the week's receipt.
struct RaceResult: Codable, Equatable {
    let otherName: String
    let mine: Int
    let theirs: Int
    /// Ahead or level. Level is a pennant for both — nothing here loses.
    var won: Bool { mine >= theirs }
}

enum RaceRules {
    /// The race this week's card is about: the one accepted pact for the week.
    /// One a week, so the first accepted one is the race.
    static func current(_ pacts: [Pact], week: WeekKey) -> Pact? {
        pacts.first { $0.week == week && $0.accepted && $0.kind == Pact.raceKind }
    }

    /// Invites waiting on you this week.
    static func invites(_ pacts: [Pact], week: WeekKey) -> [Pact] {
        pacts.filter { $0.week == week && $0.pendingMine && $0.kind == Pact.raceKind }
    }

    /// The invite you sent this week, if any.
    static func sent(_ pacts: [Pact], week: WeekKey) -> Pact? {
        pacts.first { $0.week == week && $0.pendingTheirs && $0.kind == Pact.raceKind }
    }

    /// Whether a new invite can go out: no race on, nothing already sent, and
    /// still this week. Sunday counts — a one-day race is still a race.
    static func canInvite(_ pacts: [Pact], week: WeekKey) -> Bool {
        current(pacts, week: week) == nil && sent(pacts, week: week) == nil
    }

    /// The standing, from the board's members. `nil` when the other person is not
    /// on the board yet — a race against somebody who has shared nothing this week
    /// is a race against nothing, and the card says so instead of showing a zero.
    static func standing(_ pact: Pact, members: [BoardMember]) -> RaceStanding? {
        guard let me = members.first(where: \.isYou),
              let them = members.first(where: { $0.id == pact.other.id }) else { return nil }
        return RaceStanding(pact: pact, mine: me.points, theirs: them.points)
    }
}
