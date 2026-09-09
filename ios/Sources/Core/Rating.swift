import Foundation

/// A rating, copied from chess.com's puzzle rating rather than from a chess ladder.
///
/// The difference matters more than it sounds. A ladder rating needs an opponent;
/// a puzzle rating needs a puzzle. Every board in `balance.json` and its four
/// siblings carries its own rating (dealt by `design/games/rate.py`), so solving a
/// hard one moves you up and losing to an easy one moves you down — on a phone,
/// offline, with nobody else on the app. That is the only competitive number this
/// app can honestly show on day one, because it is the only one that does not
/// depend on a second person existing.
///
/// It is also the one number here that can go DOWN. The league cannot: coins are an
/// honour-system check-off, so a forged score there would push a real student down
/// (see `LeagueState`). A puzzle cannot be lied to in the same way — the app deals
/// the board, the app checks the answer — so this is where losing is allowed to live.
///
/// Time is deliberately not in this file. The clock is a `Date` on the phone and a
/// phone can be told any time you like; solved-or-not is the part that cannot be
/// forged against yourself. Times belong on the friend board, where the stake is
/// bragging (design/SOCIAL-PLAN.md §3).
enum Rating {
    /// Everyone starts here. Below the median puzzle so the first week climbs.
    static let start = 800
    /// A puzzle the content file has no rating for — a fallback board, or JSON
    /// written before `rate.py` existed. It scores nothing rather than guessing.
    static let unrated = 0
    /// A rating never drops through the floor. A student who has a bad fortnight
    /// should not end up with a number that reads like a verdict.
    static let floor = 100
    /// While the rating is still finding you it moves at double speed, the same
    /// provisional window chess sites use.
    static let provisionalResults = 20
    static let provisionalK = 32.0
    static let settledK = 16.0

    static func k(settled: Int) -> Double {
        settled < provisionalResults ? provisionalK : settledK
    }

    /// The Elo expectation: the share of a point a player of `player` is expected
    /// to take off a puzzle of `puzzle`. 400 points of gap is 10:1 odds.
    static func expected(player: Int, puzzle: Int) -> Double {
        1 / (1 + pow(10, Double(puzzle - player) / 400))
    }

    /// One result. `puzzle` at `unrated` changes nothing at all.
    static func after(_ current: PlayerRating, puzzle: Int, solved: Bool,
                      day: DayKey) -> PlayerRating {
        guard puzzle > unrated else { return current }
        let score = solved ? 1.0 : 0.0
        let move = k(settled: current.settled) * (score - expected(player: current.value, puzzle: puzzle))
        var next = current
        // Rounded away from zero, so a result that earned a fraction of a point
        // still shows as ±1 rather than as nothing happening.
        let delta = Int(move < 0 ? (move - 0.5).rounded(.up) : (move + 0.5).rounded(.down))
        next.value = max(floor, current.value + delta)
        next.lastDelta = next.value - current.value
        next.settled = current.settled + 1
        next.lastResultDay = day
        return next
    }
}

/// A puzzle that can move a rating. `rating` is `Rating.unrated` for the built-in
/// fallback boards, which is why nothing in this protocol promises it is nonzero.
protocol RatedPuzzle {
    var rating: Int { get }
}

/// The player's side of it. One number, the way a chess profile carries one number.
struct PlayerRating: Codable, Equatable {
    var value = Rating.start
    /// How many results have counted, for the provisional window. Not a streak and
    /// not a score — it only decides how fast the number moves.
    var settled = 0
    /// The last change, for the "+8" on the end card. Zero before the first result.
    var lastDelta = 0
    var lastResultDay: DayKey?

    /// Shown with a question mark, the way every chess site marks one.
    var isProvisional: Bool { settled < Rating.provisionalResults }

    /// `1214` or `1214?`.
    var display: String { isProvisional ? "\(value)?" : "\(value)" }

    private enum CodingKeys: String, CodingKey { case value, settled, lastDelta, lastResultDay }

    init(value: Int = Rating.start, settled: Int = 0, lastDelta: Int = 0,
         lastResultDay: DayKey? = nil) {
        self.value = value
        self.settled = settled
        self.lastDelta = lastDelta
        self.lastResultDay = lastResultDay
    }

    /// Tolerant for the reason the rest of the save file is: one missing key must
    /// never cost a student their kin.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(value: try c.decodeIfPresent(Int.self, forKey: .value) ?? Rating.start,
                  settled: try c.decodeIfPresent(Int.self, forKey: .settled) ?? 0,
                  lastDelta: try c.decodeIfPresent(Int.self, forKey: .lastDelta) ?? 0,
                  lastResultDay: try c.decodeIfPresent(DayKey.self, forKey: .lastResultDay))
    }
}
