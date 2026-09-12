import Foundation

/// The weekly league: six depths of water, and a pennant kept forever for each depth
/// reached.
///
/// **Why there is no demotion, written down so nobody has to re-derive it.**
/// George asked for the Duolingo shape: a pod of twenty, top seven up, bottom seven
/// down. The pod half of that is now real — `LeagueSync` puts other students on the
/// board and the bridge ranks them. The demotion half is not, and it is not coming.
///
/// Rank is the one rule that would make the bridge authoritative over a number only
/// the phone can see. Every coin here is an honour-system check-off made offline, so
/// the bridge cannot verify a score; the most it can do is refuse a number no person
/// could have earned in a week. Under a fixed bar a forged score only fast-forwards
/// the liar. Under demotion the same lie pushes a *real* student down.
///
/// So the ladder is climbed against the bar in `LeagueRules`, the pod is company and
/// comparison, and nothing anywhere lowers a tier or takes a pennant back. `settle`
/// keeps a `demoted` branch so that promise is enforced in one readable place rather
/// than by its absence.

// MARK: - The ladder

/// Named `LeagueTier`, not `Tier`: `ChibiSpecies.tier` already owns that word for kin
/// rarity, and the two must never be mistaken for each other on screen or in code.
enum LeagueTier: Int, Codable, CaseIterable, Identifiable, Comparable {
    case tidepool = 0, shallows, reef, kelp, openWater, deep

    var id: Int { rawValue }
    static func < (a: LeagueTier, b: LeagueTier) -> Bool { a.rawValue < b.rawValue }

    var next: LeagueTier? { LeagueTier(rawValue: rawValue + 1) }
    var previous: LeagueTier? { LeagueTier(rawValue: rawValue - 1) }

    var name: String {
        switch self {
        case .tidepool:  return "Tidepool"
        case .shallows:  return "Shallows"
        case .reef:      return "Reef"
        case .kelp:      return "Kelp"
        case .openWater: return "Open water"
        case .deep:      return "Deep"
        }
    }

    /// One line about the water, never about the student. A tier is a place, not a
    /// verdict, and the bottom of the ladder has to read as somewhere worth being.
    var water: String {
        switch self {
        case .tidepool:  return "Sunlit rock pools at the tide line."
        case .shallows:  return "Sand you can still stand on."
        case .reef:      return "Warm water over living coral."
        case .kelp:      return "Green forest, light in columns."
        case .openWater: return "No bottom under you."
        case .deep:      return "Cold, quiet, a long way down."
        }
    }
}

// MARK: - How a week is judged

/// The bar for leaving each tier, in coins earned that week.
///
/// Sized against the real pay table: three study tasks a day is 420 a week, the
/// Daily Word another 210, a 25-minute shift 25, a lesson 20. Tidepool's bar is
/// about two light days, so the first pennant is reachable by anyone who turns up;
/// Deep's is a genuinely full week and has no bar past it.
///
/// The pod does not change any of this. Where you finish among strangers is company,
/// not a judgement — the bar is the same bar whether the pod holds twenty people or
/// only you, so nobody's tier depends on how busy a week other people had. The
/// friends board can only *add* a way up (`winPromotes`), never take one away.
enum LeagueRules {
    static let bars: [LeagueTier: Int] = [
        .tidepool: 150, .shallows: 300, .reef: 500, .kelp: 750, .openWater: 1100,
    ]

    /// `nil` at Deep, which is the top — there is nothing above it to charge for.
    static func bar(for tier: LeagueTier) -> Int? { bars[tier] }

    /// What a finished week did. Climb-only: falling short holds you where you are,
    /// it never moves you down. `demoted` exists so the promise that nothing lowers
    /// a tier is enforced in one readable place instead of by its absence.
    enum Outcome: Equatable { case promoted(LeagueTier), held, demoted(LeagueTier) }

    static func settle(tier: LeagueTier, coinsEarned: Int) -> Outcome {
        guard let bar = bar(for: tier), coinsEarned >= bar, let next = tier.next else {
            return .held
        }
        return .promoted(next)
    }

    /// The second way up: winning the week on the friends board. Duolingo's "top
    /// N advance", cut to the one place that cannot be a tie for last. Three is
    /// the smallest board where a win means beating more than one person, and a
    /// board of two is a race, which has its own pennant.
    static let boardSizeToPromote = 3

    static func winPromotes(_ p: BoardPlacement) -> Bool {
        p.place == 1 && p.of >= boardSizeToPromote
    }
}

/// One finished week, kept as a receipt. Never a leaderboard row — the pod is a week
/// long and its standings go with it.
struct LeagueWeekResult: Codable, Equatable, Identifiable {
    let week: WeekKey
    /// The tier the week was *played in*, not the one it ended at.
    let tier: LeagueTier
    let coinsEarned: Int
    var promoted: Bool
    /// Where the friends board left you, filled in by `LeagueState.award` once the
    /// week's rows have been fetched. `nil` until then, and forever when the rows
    /// never came (no friends, or the fortnight the bridge keeps has passed).
    var placement: BoardPlacement?
    /// The race that week, if one was on, settled alongside the placement.
    var race: RaceResult?

    var id: String { week.raw }

    init(week: WeekKey, tier: LeagueTier, coinsEarned: Int, promoted: Bool,
         placement: BoardPlacement? = nil, race: RaceResult? = nil) {
        self.week = week
        self.tier = tier
        self.coinsEarned = coinsEarned
        self.promoted = promoted
        self.placement = placement
        self.race = race
    }
}

// MARK: - The saved state

struct LeagueState: Codable, Equatable {
    var tier: LeagueTier = .tidepool
    /// The week the current run of points belongs to. Only ever moves forward.
    var weekStart = WeekKey(.today())

    /// One per tier actually *earned* by clearing a bar. Tidepool is deliberately not
    /// in here at the start: a keepsake handed out for existing is worth nothing next
    /// to the track badges, which mean eight finished lessons.
    var pennants: Set<LeagueTier> = []

    /// Finished weeks, newest first. Capped so the save file cannot grow without end.
    var history: [LeagueWeekResult] = []
    static let historyKept = 12

    var deepestReached: LeagueTier { pennants.max() ?? .tidepool }

    // MARK: The shelf

    /// Pennants from the friends board, kept forever. Each only ever goes up, and
    /// each is counted here rather than read off `history`, which is capped.
    var weeksWon = 0
    var weeksSecond = 0
    var weeksThird = 0
    /// Group quests cleared, one a week at most.
    var questsCleared = 0
    /// Races finished ahead or level. One a week at most.
    var racesWon = 0
    /// The pacts the bridge last sent, this week's and last week's. Kept so the
    /// race card draws on a train, and so Monday can settle a race whose rows
    /// arrive before the pacts do.
    var races: [Pact] = []
    /// The week whose quest has already been counted, so a board redrawn twenty
    /// times on a Sunday credits it once.
    var questWeek: WeekKey?
    /// The settled week whose Monday card has been looked at. The card shows for
    /// the newest settled week until this names it.
    var boardSeen: WeekKey?

    /// Records where the friends board left you for a settled week, and moves you
    /// up if you won it against enough people. Returns whether that happened.
    ///
    /// **Up only, like everything else here.** A placement fills in a receipt and
    /// bumps a counter; the only thing it can do to a tier is raise it, and only
    /// when the week settled as `held` — a week the bar already cleared has
    /// nothing left to give. Called once per week: a receipt that already has a
    /// placement keeps it, so a second fetch cannot count a medal twice.
    @discardableResult
    mutating func award(_ placement: BoardPlacement, for week: WeekKey) -> Bool {
        guard let i = history.firstIndex(where: { $0.week == week }),
              history[i].placement == nil else { return false }
        history[i].placement = placement
        switch placement.medal {
        case 1: weeksWon += 1
        case 2: weeksSecond += 1
        case 3: weeksThird += 1
        default: break
        }
        guard LeagueRules.winPromotes(placement), !history[i].promoted,
              tier == history[i].tier, let up = tier.next else { return false }
        tier = up
        pennants.insert(up)
        history[i].promoted = true
        return true
    }

    /// Settles last week's race onto its receipt, once, and counts a win. Level
    /// counts: nothing in a race loses anybody anything.
    @discardableResult
    mutating func settleRace(_ result: RaceResult, for week: WeekKey) -> Bool {
        guard let i = history.firstIndex(where: { $0.week == week }),
              history[i].race == nil else { return false }
        history[i].race = result
        if result.won { racesWon += 1 }
        return result.won
    }

    /// Credits a cleared quest, once per week.
    @discardableResult
    mutating func creditQuest(_ week: WeekKey) -> Bool {
        guard questWeek != week else { return false }
        questWeek = week
        questsCleared += 1
        return true
    }

    /// The Monday card's week: the newest settled week not yet looked at. `nil`
    /// when there is nothing to say — no placement worth a card and no promotion.
    var unseenSettledWeek: LeagueWeekResult? {
        guard let last = history.first, boardSeen != last.week else { return nil }
        let placed = (last.placement?.of ?? 0) >= 2
        return placed || last.promoted || last.race != nil ? last : nil
    }

    // MARK: The pod

    /// Off until the student says yes, and off again the moment they leave. While it
    /// is false nothing in the app reaches the pod bridge and no player is ever
    /// minted — a student who never opts in has no row out there at all.
    var podOptIn = false

    /// Who this phone is on the bridge: a random id, a random token, and two indices
    /// into the shipped word lists. `nil` until the first opt-in. No name, no email,
    /// nothing anybody typed. See `LeagueSync.swift`.
    var identity: LeagueIdentity?

    /// The pod this phone is in, and the week that pod belongs to. A pod lasts one
    /// week; when the week turns over these clear and a new pod is joined.
    var podID: String?
    var podWeek: WeekKey?

    /// The last board the bridge sent. Kept so opening the tab on a train shows the
    /// standings it last saw rather than a blank card, and so a dropped connection
    /// never empties somebody's pod on screen.
    var lastPod: PodSnapshot?

    /// True while `podID` names a pod for the week being asked about. The sync uses
    /// it to decide whether to join before pushing.
    func isPodCurrent(for week: WeekKey) -> Bool {
        podID != nil && podWeek == week
    }

    // MARK: Settling

    /// Closes `weekStart` with the coins earned inside it and opens `week`.
    /// Returns what happened, so the UI can mark the moment once.
    @discardableResult
    mutating func settle(into week: WeekKey, coinsEarned: Int) -> LeagueRules.Outcome {
        let played = tier
        let outcome = LeagueRules.settle(tier: played, coinsEarned: coinsEarned)
        var promoted = false
        switch outcome {
        case .promoted(let up):
            tier = up
            pennants.insert(up)
            promoted = true
        case .demoted:
            // Unreachable, and kept unreachable on purpose. A pod is for company and
            // comparison; nothing in it may cost a student a tier, so this branch
            // moves nobody. If a future rule ever wants to fill it in, that is a
            // product decision, not a patch.
            break
        case .held:
            break
        }
        history.insert(LeagueWeekResult(week: weekStart, tier: played,
                                        coinsEarned: coinsEarned, promoted: promoted),
                       at: 0)
        history = Array(history.prefix(Self.historyKept))
        weekStart = week

        // A pod lasts exactly one week. Last week's standings are not this week's, so
        // they go with the week instead of sitting on the board looking current. The
        // identity stays — it is this phone, not this pod, and re-using it on Monday
        // is what stops a second row being minted every week.
        podID = nil
        podWeek = nil
        lastPod = nil
        return outcome
    }

    // MARK: - Decoding

    private enum CodingKeys: String, CodingKey {
        case tier, weekStart, pennants, history
        case weeksWon, weeksSecond, weeksThird, questsCleared, questWeek, boardSeen
        case racesWon, races
        case podOptIn, identity, podID, podWeek, lastPod
    }

    init() {}

    /// Hand-written for the same reason `GameState.init(from:)` is, and it matters
    /// more here: `GameState` reads this with `decodeIfPresent`, which still throws
    /// if *this* decoder throws. The synthesized one throws on the first key an older
    /// save does not have — and a throw here means the whole save file is unreadable,
    /// which reads to the student as every coin gone. Every field falls back to its
    /// default, so adding one stays free.
    ///
    /// A save written before the pod existed opens opted out, with no identity and no
    /// board. That is the correct answer, not a gap to fill: opting in is a thing a
    /// student does, never a thing a migration does for them.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let blank = LeagueState()
        tier = try c.decodeIfPresent(LeagueTier.self, forKey: .tier) ?? blank.tier
        weekStart = try c.decodeIfPresent(WeekKey.self, forKey: .weekStart) ?? blank.weekStart
        pennants = try c.decodeIfPresent(Set<LeagueTier>.self, forKey: .pennants) ?? blank.pennants
        history = try c.decodeIfPresent([LeagueWeekResult].self, forKey: .history) ?? blank.history
        weeksWon = try c.decodeIfPresent(Int.self, forKey: .weeksWon) ?? blank.weeksWon
        weeksSecond = try c.decodeIfPresent(Int.self, forKey: .weeksSecond) ?? blank.weeksSecond
        weeksThird = try c.decodeIfPresent(Int.self, forKey: .weeksThird) ?? blank.weeksThird
        questsCleared = try c.decodeIfPresent(Int.self, forKey: .questsCleared) ?? blank.questsCleared
        questWeek = try c.decodeIfPresent(WeekKey.self, forKey: .questWeek)
        racesWon = try c.decodeIfPresent(Int.self, forKey: .racesWon) ?? blank.racesWon
        races = try c.decodeIfPresent([Pact].self, forKey: .races) ?? blank.races
        boardSeen = try c.decodeIfPresent(WeekKey.self, forKey: .boardSeen)
        podOptIn = try c.decodeIfPresent(Bool.self, forKey: .podOptIn) ?? blank.podOptIn
        identity = try c.decodeIfPresent(LeagueIdentity.self, forKey: .identity)
        podID = try c.decodeIfPresent(String.self, forKey: .podID)
        podWeek = try c.decodeIfPresent(WeekKey.self, forKey: .podWeek)
        lastPod = try c.decodeIfPresent(PodSnapshot.self, forKey: .lastPod)
    }
}
