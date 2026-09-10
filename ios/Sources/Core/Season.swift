import Foundation

/// A term-long ladder with a Free column and a Plus column.
///
/// Finch's monthly event, ours, and the shape is the whole point: **both columns
/// move on the same day, for the same reason.** Finishing something real claims the
/// day; Free takes coins, Plus takes coins and a costume. A student who never pays
/// still climbs every rung.
///
/// The three things it is not, each one a rule from `PLUS-SPEC.md` it had to clear:
///
/// - **It is not a streak.** A rung is claimed by *count*, never by calendar
///   position, so a missed day costs nothing at all. Miss ten days of a
///   twenty-one-day season, claim seven, and you finish it. `NoStreakTests` and
///   `testAGapCostsNothing` both hold this down.
/// - **It takes nothing away.** Every costume on the Plus track is also on the
///   shelf at its coin price, today and forever. Nothing moved behind money.
/// - **It does not count down.** The card says "Ends Oct 12", a date. There is no
///   clock, and no number on it goes down.
struct Season: Identifiable, Equatable {
    let id: String
    let name: String
    /// First and last day it can be claimed on, inclusive.
    let start: DayKey
    let end: DayKey
    let rungs: [Rung]

    struct Rung: Equatable {
        /// What anyone gets for claiming this rung.
        let free: Reward
        /// What a Plus student gets *as well*. Never instead.
        let plus: Reward
    }

    /// The only two things a rung can hand over. Coins on the free track are coins
    /// earned by finishing work, which is what every coin in the app means. There
    /// are no coins on the Plus track: a coin that arrives because a card was
    /// charged is a coin that was sold (`PLUS-SPEC.md` signature 9).
    enum Reward: Equatable {
        case coins(Int)
        case costume(String)

        var costumeID: String? {
            if case .costume(let id) = self { return id }
            return nil
        }
    }

    func contains(_ day: DayKey) -> Bool { day >= start && day <= end }

    /// The costume the last Plus rung hands over. The one the card promises.
    var headline: Costume? { rungs.last?.plus.costumeID.flatMap(Costume.find) }

    // MARK: - The seeded season

    /// Runs from the day the stores go public to three weeks later.
    ///
    /// Seven rungs over twenty-one days, so a student claiming a third of the days
    /// finishes it. The Plus track is the cheap end of the rack plus Grad at the
    /// end, which is the "guaranteed the whole outfit" promise made of art that
    /// already exists — no new drawing is owed for the first season.
    static let midterms = Season(
        id: "midterms-2026",
        name: "Midterms",
        start: DayKey(raw: "2026-09-22"),
        end: DayKey(raw: "2026-10-12"),
        rungs: [
            Rung(free: .coins(30),  plus: .costume("hoodie")),
            Rung(free: .coins(40),  plus: .costume("flannel")),
            Rung(free: .coins(50),  plus: .costume("barista")),
            Rung(free: .coins(60),  plus: .costume("pajamas")),
            Rung(free: .coins(70),  plus: .costume("varsity")),
            Rung(free: .coins(80),  plus: .costume("keynote")),
            Rung(free: .coins(120), plus: .costume("grad")),
        ]
    )

    static let all: [Season] = [midterms]

    static func current(on day: DayKey) -> Season? { all.first { $0.contains(day) } }
}

/// Which days of a season have been claimed on this phone.
///
/// A set of days rather than a rung number, because the set is what makes the claim
/// idempotent: opening the card twice on a Tuesday cannot climb twice. The rung a
/// student is on is `claimedDays.count`, which is why a gap costs nothing.
struct SeasonProgress: Codable, Equatable {
    var claimedDays: Set<String> = []

    var rungsClaimed: Int { claimedDays.count }
    func hasClaimed(_ day: DayKey) -> Bool { claimedDays.contains(day.raw) }
}

// MARK: - The claim rule

enum SeasonClaim {

    /// Why a day cannot be claimed, or that it can.
    enum Verdict: Equatable {
        case ready(rung: Int)
        /// Nothing real has been finished today. The ladder never pays for opening
        /// the app.
        case nothingFinishedToday
        case alreadyClaimedToday
        /// Every rung is claimed. The season is done, and it stays done.
        case ladderFinished
        case outOfSeason
    }

    /// One claim per local day, only on a day something real was finished, and only
    /// inside the season's dates.
    ///
    /// `finishedToday` is a count of real work — tasks checked off and shifts
    /// finished — not app opens. That is the sentence that keeps this a reward for
    /// doing the thing rather than a reward for being logged in.
    static func check(
        season: Season,
        progress: SeasonProgress,
        day: DayKey,
        finishedToday: Int
    ) -> Verdict {
        guard season.contains(day) else { return .outOfSeason }
        if progress.hasClaimed(day) { return .alreadyClaimedToday }
        guard progress.rungsClaimed < season.rungs.count else { return .ladderFinished }
        guard finishedToday > 0 else { return .nothingFinishedToday }
        return .ready(rung: progress.rungsClaimed)
    }
}
