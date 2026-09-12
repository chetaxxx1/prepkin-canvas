import Foundation

/// User-controlled switches. Reminders default to off — nothing asks for a
/// notification permission until the user turns it on themselves.
struct AppSettings: Codable, Equatable {
    var remindersEnabled = false
    /// Hour of the local evening nudge, when tasks are still open.
    var nudgeHour = 19
    var dueRemindersEnabled = true
    var comeBackRemindersEnabled = true
    /// The student has read the line about a photo going to the server, once.
    var scanConsentGiven = false

    init() {}

    /// Every field optional on the way in, so adding one never breaks an old save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? false
        nudgeHour = try c.decodeIfPresent(Int.self, forKey: .nudgeHour) ?? 19
        dueRemindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .dueRemindersEnabled) ?? true
        comeBackRemindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .comeBackRemindersEnabled) ?? true
        scanConsentGiven = try c.decodeIfPresent(Bool.self, forKey: .scanConsentGiven) ?? false
    }
}

/// A friend, as the Friends tab draws them.
///
/// Everything down to `onShiftUntil` is what `fetch_friends` sends: two indices for a
/// name, four ids for a picture, a level, a water, when the pair was made, and when
/// their current shift runs out. **No coins and no string a student typed** — see
/// `design/SOCIAL-PLAN.md` F5 and F6 for why those two are the whole safety model.
///
/// The last two fields never leave this phone. `nickname` is what you call them, the
/// way a contact name works in Phone: it is stored in the save file, shown on your
/// screen, and there is no call that could send it anywhere. `seenAt` is how the tab
/// knows whether it has already told you about them.
struct Friend: Identifiable, Codable, Equatable {
    /// The other player's id on the bridge. The one thing that goes back out, in
    /// Remove, Block and Report.
    let id: String
    /// Index into `Catalog.podNames.adjectives`.
    let adjective: Int
    /// Index into `Catalog.podNames.nouns`.
    let noun: Int
    let speciesID: String
    let lookID: String
    let costumeID: String
    let sceneID: String
    /// `OwnedChibi.level`, 1…3, drawn as `StarPips`.
    let level: Int
    /// The deepest water they have reached. Company, never a ranking.
    let tier: LeagueTier
    let friendsSince: Date
    /// When their current shift ends, if they are working right now.
    let onShiftUntil: Date?

    /// What you call them, on this phone only. `nil` means the word-list name shows.
    var nickname: String?
    /// When this phone last put them in front of you. `never` until it has, which
    /// is exactly what makes the "added you" card appear once and then stop.
    var seenAt: Date

    /// Fourteen characters, the same rule as naming a kin.
    static let nicknameLimit = 14

    /// The stamp that means "this phone has not shown them to you yet". The epoch
    /// rather than `distantPast` because this value is written to the save file as
    /// a date string and read back, and year one is a bad thing to rely on.
    static let never = Date(timeIntervalSince1970: 0)

    var displayName: String {
        if let nickname, !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nickname
        }
        return PodName.name(adjective: adjective, noun: noun)
    }

    /// This phone has never shown them to you. Drives the "added you" card and
    /// nothing else — there is no unread count anywhere in this app.
    ///
    /// Anything at or before the epoch counts, so a stamp that came back from a
    /// save file a shade off is still read as never rather than as this morning.
    var isNew: Bool { seenAt.timeIntervalSince1970 <= 0 }

    /// Trimmed and cut to length, and empty means none. `GameState.rename` does the
    /// same to a kin's name, so a nickname cannot be longer than a kin can be.
    static func cleanNickname(_ raw: String) -> String? {
        let clean = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(nicknameLimit))
        return clean.isEmpty ? nil : clean
    }

    /// Whole minutes left in their shift, rounded up so "1 min left" is not shown
    /// as none. Zero once the clock has run out.
    func minutesLeftOnShift(at date: Date = Date()) -> Int {
        guard let onShiftUntil else { return 0 }
        return max(0, Int(ceil(onShiftUntil.timeIntervalSince(date) / 60)))
    }

    /// The one line under a name, or nothing at all.
    ///
    /// Absent, not empty, when they are not working: a friend who is not at a desk
    /// has no line, because "no session" and "hasn't studied" are the same sentence
    /// and this app does not write the second one.
    func shiftLine(at date: Date = Date()) -> String? {
        let left = minutesLeftOnShift(at: date)
        guard left > 0 else { return nil }
        return "on shift · \(left) min left"
    }

    init(id: String, adjective: Int, noun: Int, speciesID: String, lookID: String,
         costumeID: String, sceneID: String, level: Int, tier: LeagueTier,
         friendsSince: Date, onShiftUntil: Date?,
         nickname: String? = nil, seenAt: Date = Friend.never) {
        self.id = id
        self.adjective = adjective
        self.noun = noun
        self.speciesID = speciesID
        self.lookID = lookID
        self.costumeID = costumeID
        self.sceneID = sceneID
        self.level = min(max(level, 1), 3)
        self.tier = tier
        self.friendsSince = friendsSince
        self.onShiftUntil = onShiftUntil
        self.nickname = nickname
        self.seenAt = seenAt
    }

    /// The wire keys, short because a whole list comes down on every open. The two
    /// local fields are in here too, because this same shape is what the save file
    /// holds; a row read from the bridge simply has neither.
    private enum CodingKeys: String, CodingKey {
        case id, adj, noun, species, look, costume, scene, level, tier, since, shift
        case nickname, seenAt
    }

    /// Tolerant for the reason `PodMember`'s decoder is: this shape is also what a
    /// cached list decodes from, and one missing key must never cost the save file.
    /// A level outside 1…3 is clamped rather than trusted — the art only has three
    /// evolutions, and a friend list is not the place to find that out.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let since = try c.decodeIfPresent(String.self, forKey: .since) ?? ""
        let shift = try c.decodeIfPresent(String.self, forKey: .shift) ?? ""
        self.init(id: try c.decodeIfPresent(String.self, forKey: .id) ?? "",
                  adjective: try c.decodeIfPresent(Int.self, forKey: .adj) ?? 0,
                  noun: try c.decodeIfPresent(Int.self, forKey: .noun) ?? 0,
                  speciesID: try c.decodeIfPresent(String.self, forKey: .species) ?? "slime",
                  lookID: try c.decodeIfPresent(String.self, forKey: .look) ?? "classic",
                  costumeID: try c.decodeIfPresent(String.self, forKey: .costume) ?? "none",
                  sceneID: try c.decodeIfPresent(String.self, forKey: .scene) ?? "lagoon",
                  level: try c.decodeIfPresent(Int.self, forKey: .level) ?? 1,
                  tier: LeagueTier(rawValue: try c.decodeIfPresent(Int.self, forKey: .tier) ?? 0) ?? .tidepool,
                  // A friendship with no date is one that was just made: `add_friend`
                  // answers with a public row and no date on it.
                  friendsSince: Friend.wireDate.date(from: since) ?? Date(),
                  onShiftUntil: Friend.wireDate.date(from: shift),
                  nickname: try c.decodeIfPresent(String.self, forKey: .nickname),
                  seenAt: try c.decodeIfPresent(Date.self, forKey: .seenAt) ?? Friend.never)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(adjective, forKey: .adj)
        try c.encode(noun, forKey: .noun)
        try c.encode(speciesID, forKey: .species)
        try c.encode(lookID, forKey: .look)
        try c.encode(costumeID, forKey: .costume)
        try c.encode(sceneID, forKey: .scene)
        try c.encode(level, forKey: .level)
        try c.encode(tier.rawValue, forKey: .tier)
        try c.encode(Friend.wireDate.string(from: friendsSince), forKey: .since)
        if let onShiftUntil {
            try c.encode(Friend.wireDate.string(from: onShiftUntil), forKey: .shift)
        }
        try c.encodeIfPresent(nickname, forKey: .nickname)
        try c.encode(seenAt, forKey: .seenAt)
    }

    /// Postgres hands back ISO 8601 with fractional seconds, the same spelling
    /// `FocusPresence` reads.
    static let wireDate: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

/// Everything that survives a relaunch. Pure value type with no UI and no I/O, so
/// every rule in it can be tested directly.
struct GameState: Codable, Equatable {
    var ledger = Ledger()
    var owned: [OwnedChibi] = [OwnedChibi(speciesID: "slime", level: 1)]
    var activeChibiID = "slime"
    var sceneID = "lagoon"
    var ownedScenes: Set<String> = ["lagoon"]
    var completedLessons: Set<String> = []
    /// When this phone first ran Prepkin. Read only by `PlusGate.value`, to keep a
    /// student on the free number a later release lowered. Nothing lowers one today
    /// (`PlusGate.restriction` is nil for every gate), so nothing reads it yet —
    /// it is here because the promise has to be recorded on the day the student
    /// arrives, not on the day someone decides to break it. `nil` on saves written
    /// before it existed; the v6 migration fills those from the oldest ledger line.
    var installedAt: Date?

    /// The gift week's dates, what the season has paid out, and the looks that were
    /// saved. One property rather than six, because this file has more than one
    /// editor. Nothing in it is an entitlement — that is StoreKit's, read through
    /// `PlusAccess` — and everything in it survives a lapse untouched.
    var plus = PlusLocal()

    /// Whether this student is Plus right now, cached for the shop.
    ///
    /// Deliberately **not** in `CodingKeys`. An entitlement written into the save
    /// file is an entitlement that outlives the subscription, and the only honest
    /// source is StoreKit plus the gift week. `AppState.syncPlus` sets this on every
    /// change; a fresh decode starts it false and the first refresh corrects it.
    var plusIsOn = false

    /// How far into each deck the student has read, by lesson id. Drives Continue on
    /// Learn, the current node on a track map, and where Resume puts you back.
    /// Cleared on finish, so a finished lesson stops asking to be continued.
    var deckProgress: [String: Int] = [:]
    /// Hearted cards, newest first. Stored as pointers into the catalogue, never as
    /// copies of the prose — rewriting a lesson updates what the student kept.
    var savedCards: [SavedCard] = []
    /// Cards the student flagged as broken, newest first. Local only — there is
    /// nowhere to send a report yet, so this is a note to self.
    var cardReports: [CardReport] = []
    /// The tap-zone coach is shown once, ever.
    var hasSeenTapCoach = false
    /// The two-screen first run (name the kin, pick three) has been completed.
    /// A save written before the first run existed decodes as `true`: whoever
    /// wrote it has already been using the app, and must not be sent back to
    /// the start.
    var firstRunDone = false
    /// The Day 1 offer cards on Home (notifications, then Canvas) have been
    /// answered or dismissed. Same rule for older saves.
    var firstRunOffersDone = false

    var templates: [TaskTemplate] = TaskTemplate.starterSet()
    var canvasItems: [CanvasItem] = []
    var canvasCourses: [CanvasCourse] = []
    /// Course-calendar events from the last sync. Shown on the calendar only.
    var canvasEvents: [CanvasEvent] = []
    /// Tasks the student put on a day themselves, typed or scanned.
    var datedTasks: [DatedTask] = []

    /// The day the list on screen was last built for.
    var currentDay: DayKey = .today()
    /// The furthest day this install has ever seen. Rewards key off this, never off
    /// the raw clock, so winding the device date backwards can't re-open a paid day.
    var maxDayReached: DayKey = .today()

    var settings = AppSettings()
    var lastOpenedAt = Date()

    /// Most miles Kin has driven in a single focus shift. A target to beat, never
    /// spendable — the coins for a shift come out of the ledger like any other pay.
    var bestShift = 0

    /// The weekly league: which water the student is in, and the pennants they have
    /// kept. Sits beside `lifetime` because it makes the same promise — a pennant,
    /// once earned, is never taken back.
    var league = LeagueState()

    /// Lifetime totals for the Kin tab's "together since" strip.
    ///
    /// Stored, not derived from `Ledger.entries`, because the ledger folds lines
    /// older than its window into the opening balance — a derived count would go
    /// DOWN over time, and the one promise this strip makes is that it only goes up.
    var lifetime = LifetimeStats()

    /// Things that happened once and stay, with the day they did — the Firsts list
    /// on a kin's card. Stamped where each thing happens (`wear`, `equipScene`,
    /// `addFriend`, `recordFocus`, `upgradeActiveChibi`), never derived.
    var firsts = Firsts()

    /// What stands in each tank's two prop slots. Empty until the Decorate door
    /// opens (`KinFlags.decorate`); kept here so a placed prop survives a relaunch.
    var decor = TankDecor()

    /// Today's shop picks, up to five, as `"kin:ember"` / `"scene:meadow"`.
    var shopPicks: [String] = []
    var shopPickDay: DayKey = DayKey(raw: "")
    /// How many times today's row has been rerolled. Seeds the draw, and caps it at
    /// `rerollsPerDay`. Resets with the row at the day boundary.
    var rerollCount = 0
    /// A slot the student is holding. Survives every reroll and the day boundary.
    /// The old single hold. Kept only so a save written before three holds shipped
    /// still decodes; `lockedPicks` is seeded from it and this is left nil after.
    var lockedPick: String?
    /// Slots held through a reroll and overnight. Free holds one, Plus holds three
    /// (`PlusGate.shopHolds`). A hold can only ever help: it never costs a coin and
    /// it never blocks a draw.
    var lockedPicks: Set<String> = []

    /// Daily Word record, kept here rather than derived from the ledger because the
    /// ledger compacts lines older than 90 days and these should never go down.
    var wordleSolved = 0
    /// Fewest guesses ever. `nil` until the first solve.
    var wordleBest: Int?
    /// The last day a word was solved.
    var wordleLastDay: DayKey?
    /// Today's board, so leaving mid-puzzle and coming back finds the same guesses —
    /// and a solved board stays solved instead of dealing the same word again.
    var wordleGuesses: [String] = []
    var wordleGuessDay: DayKey?

    /// Number Line record. Rounds can be played any time; coins come once a day.
    var numberLinePlayed = 0
    /// Best round accuracy, 0–100. `nil` until the first round.
    var numberLineBest: Int?

    /// The Play puzzles added 2026-09-08 (design/GAMES-PLAN.md). Same shape as
    /// the Daily Word record above, one struct each instead of five fields each.
    var balancePlay = PlayRecord<[Int]>()
    var pearlsPlay = PlayRecord<[Int]>()
    /// Trace (2026-09-08) replaced Number Line on the rail; the old fields stay for old saves.
    var tracePlay = PlayRecord<[Int]>()
    /// Sort and Weave (2026-09-10) replaced Ladder and Thread. Sort keeps its guesses,
    /// four word indices at a time; Weave keeps a line per find.
    var sortPlay = PlayRecord<[Int]>()
    var weavePlay = PlayRecord<[String]>()
    /// Ladder and Thread, retired 2026-09-10. Read so an old save still opens; never written.
    var ladderPlay = PlayRecord<[String]>()
    var threadPlay = PlayRecord<[String]>()

    /// The code the student types into the Chrome extension. Optional on purpose:
    /// nothing is created until they actually open the connect screen, and the app
    /// works fully without one.
    var pairingCode: String?
    /// This phone's own bridge token, handed out once when the code was claimed.
    /// The code is only good for the few minutes it takes a laptop to pair; every
    /// read and write after that needs this.
    var pairingToken: String?
    /// Looks bought in the extension's shop. The catalog lives on the laptop; the
    /// phone only records what was paid for, because the ledger is the truth.
    var ownedLooks: Set<String> = ["classic"]
    /// The newest laptop request this phone has paid. Published back so the
    /// extension knows what it can stop re-sending.
    var requestsAppliedAt: Date?
    var lastCanvasSyncAt: Date?

    /// The code a student reads out to a friend, as the bridge last handed it out.
    ///
    /// **A cache, not a source.** The bridge mints it (`my_code`) and the bridge can
    /// replace it (`rotate_code`); this phone only remembers the last one it was
    /// given so the screen has something to draw before the call comes back. It used
    /// to be generated here, which meant nobody could look it up.
    ///
    /// Separate from `pairingCode` on purpose: that one ties this phone to one
    /// laptop and is revoked by `unpair()`; this one is the person, and
    /// disconnecting Canvas must not change it.
    var friendCode: String?

    /// The puzzle rating. See `Rating.swift` for why this is the one number in the
    /// app that is allowed to go down.
    var rating = PlayerRating()

    /// What friends are allowed to see beyond the fish. Mirrors the two flags on
    /// the bridge so the toggles have something to draw before a call returns.
    ///
    /// **Sharing today is off until a student turns it on.** There is no accept
    /// step, so anybody handed a code is a friend on the spot; a fortnight of
    /// somebody's study log should not be readable before they have seen a screen
    /// about it. The board is the fish and a solve time, which is the thing the
    /// code was handed over for, so that one starts on.
    var shareToday = false
    var shareBoard = true

    /// The day the three wave sets below belong to. They are all one day long.
    var wavesDay: DayKey = .today()
    /// Friends you have waved at today, so the button shows its settled state
    /// without asking the bridge friend by friend.
    var wavesSent: Set<String> = []
    /// Friends who have waved at you today.
    var wavesIn: Set<String> = []
    /// The ones you have already been shown. What is in `wavesIn` and not in here
    /// is what the card at the top of the tab is about.
    var wavesSeen: Set<String> = []

    /// The friends whose kins show on the tab, as `fetch_friends` last sent them,
    /// with this phone's own nicknames carried across. Kept so opening the tab with
    /// no signal shows the list it last saw rather than a blank card.
    ///
    /// Empty until somebody real is in it: a student must never see a person who
    /// does not exist.
    var friends: [Friend] = []

    // MARK: - Decoding

    private enum CodingKeys: String, CodingKey {
        case ledger, owned, activeChibiID, sceneID, ownedScenes, completedLessons, installedAt
        case templates, canvasItems, canvasCourses, currentDay, maxDayReached
        case canvasEvents, datedTasks
        case settings, lastOpenedAt, pairingCode, lastCanvasSyncAt, bestShift, friendCode, rating
        case pairingToken, ownedLooks, requestsAppliedAt
        case friends, wavesDay, wavesSent, wavesIn, wavesSeen
        case shareToday, shareBoard
        case deckProgress, savedCards, cardReports, hasSeenTapCoach, firstRunDone, firstRunOffersDone
        case lifetime, shopPicks, shopPickDay, rerollCount, lockedPick, lockedPicks, firsts, decor
        case wordleSolved, wordleBest, wordleLastDay, wordleGuesses, wordleGuessDay
        case numberLinePlayed, numberLineBest
        case ladderPlay, threadPlay, balancePlay, pearlsPlay, tracePlay, sortPlay, weavePlay
        case league
        case plus
    }

    init() {}

    /// Every field is read with `decodeIfPresent` and falls back to its default.
    ///
    /// The synthesized decoder would throw on the first key a older save does not
    /// have, and a throw here means the whole file is unreadable — which reads to
    /// the student as every coin gone. Adding a field should never be able to do
    /// that, so adding one is free from here on.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let blank = GameState()
        ledger = try c.decodeIfPresent(Ledger.self, forKey: .ledger) ?? blank.ledger
        owned = try c.decodeIfPresent([OwnedChibi].self, forKey: .owned) ?? blank.owned
        activeChibiID = try c.decodeIfPresent(String.self, forKey: .activeChibiID) ?? blank.activeChibiID
        // Kin that left the catalogue (the orca and axolotls, 2026-09-10) drop out
        // of a save rather than draw as a blank. Nothing shipped with them, so no
        // refund is owed; the starter stays if that leaves nothing.
        owned.removeAll { kin in ChibiSpecies.catalog.first(where: { $0.id == kin.speciesID }) == nil }
        if owned.isEmpty { owned = blank.owned }
        if !owned.contains(where: { $0.speciesID == activeChibiID }) { activeChibiID = owned[0].speciesID }
        sceneID = try c.decodeIfPresent(String.self, forKey: .sceneID) ?? blank.sceneID
        ownedScenes = try c.decodeIfPresent(Set<String>.self, forKey: .ownedScenes) ?? blank.ownedScenes
        // Land scenes became tanks. Carry over anything already paid for.
        sceneID = Scene0.find(sceneID).id
        ownedScenes = Set(ownedScenes.map { Scene0.find($0).id })
        ownedScenes.insert(Scene0.all[0].id)
        completedLessons = try c.decodeIfPresent(Set<String>.self, forKey: .completedLessons) ?? blank.completedLessons
        installedAt = try c.decodeIfPresent(Date.self, forKey: .installedAt)
        templates = try c.decodeIfPresent([TaskTemplate].self, forKey: .templates) ?? blank.templates
        templates = TaskTemplate.addingMissingPresets(to: templates)
        canvasItems = try c.decodeIfPresent([CanvasItem].self, forKey: .canvasItems) ?? blank.canvasItems
        canvasCourses = try c.decodeIfPresent([CanvasCourse].self, forKey: .canvasCourses) ?? blank.canvasCourses
        canvasEvents = try c.decodeIfPresent([CanvasEvent].self, forKey: .canvasEvents) ?? blank.canvasEvents
        datedTasks = try c.decodeIfPresent([DatedTask].self, forKey: .datedTasks) ?? blank.datedTasks
        currentDay = try c.decodeIfPresent(DayKey.self, forKey: .currentDay) ?? blank.currentDay
        maxDayReached = try c.decodeIfPresent(DayKey.self, forKey: .maxDayReached) ?? blank.maxDayReached
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? blank.settings
        lastOpenedAt = try c.decodeIfPresent(Date.self, forKey: .lastOpenedAt) ?? blank.lastOpenedAt
        pairingCode = try c.decodeIfPresent(String.self, forKey: .pairingCode)
        pairingToken = try c.decodeIfPresent(String.self, forKey: .pairingToken)
        ownedLooks = try c.decodeIfPresent(Set<String>.self, forKey: .ownedLooks) ?? blank.ownedLooks
        requestsAppliedAt = try c.decodeIfPresent(Date.self, forKey: .requestsAppliedAt)
        lastCanvasSyncAt = try c.decodeIfPresent(Date.self, forKey: .lastCanvasSyncAt)
        friendCode = try c.decodeIfPresent(String.self, forKey: .friendCode)
        rating = try c.decodeIfPresent(PlayerRating.self, forKey: .rating) ?? blank.rating
        friends = try c.decodeIfPresent([Friend].self, forKey: .friends) ?? blank.friends
        shareToday = try c.decodeIfPresent(Bool.self, forKey: .shareToday) ?? blank.shareToday
        shareBoard = try c.decodeIfPresent(Bool.self, forKey: .shareBoard) ?? blank.shareBoard
        wavesDay = try c.decodeIfPresent(DayKey.self, forKey: .wavesDay) ?? blank.wavesDay
        wavesSent = try c.decodeIfPresent(Set<String>.self, forKey: .wavesSent) ?? blank.wavesSent
        wavesIn = try c.decodeIfPresent(Set<String>.self, forKey: .wavesIn) ?? blank.wavesIn
        wavesSeen = try c.decodeIfPresent(Set<String>.self, forKey: .wavesSeen) ?? blank.wavesSeen
        bestShift = try c.decodeIfPresent(Int.self, forKey: .bestShift) ?? blank.bestShift
        deckProgress = try c.decodeIfPresent([String: Int].self, forKey: .deckProgress) ?? blank.deckProgress
        savedCards = try c.decodeIfPresent([SavedCard].self, forKey: .savedCards) ?? blank.savedCards
        cardReports = try c.decodeIfPresent([CardReport].self, forKey: .cardReports) ?? blank.cardReports
        hasSeenTapCoach = try c.decodeIfPresent(Bool.self, forKey: .hasSeenTapCoach) ?? blank.hasSeenTapCoach
        firstRunDone = try c.decodeIfPresent(Bool.self, forKey: .firstRunDone) ?? true
        firstRunOffersDone = try c.decodeIfPresent(Bool.self, forKey: .firstRunOffersDone) ?? true
        lifetime = try c.decodeIfPresent(LifetimeStats.self, forKey: .lifetime) ?? blank.lifetime
        shopPicks = try c.decodeIfPresent([String].self, forKey: .shopPicks) ?? blank.shopPicks
        shopPickDay = try c.decodeIfPresent(DayKey.self, forKey: .shopPickDay) ?? blank.shopPickDay
        rerollCount = try c.decodeIfPresent(Int.self, forKey: .rerollCount) ?? blank.rerollCount
        lockedPick = try c.decodeIfPresent(String.self, forKey: .lockedPick)
        // A save from before three holds carries one id in `lockedPick`. Seed the
        // set from it and clear it, so the hold survives the upgrade rather than
        // being silently dropped on the student's first open.
        if let set = try c.decodeIfPresent(Set<String>.self, forKey: .lockedPicks) {
            lockedPicks = set
        } else {
            lockedPicks = Set([lockedPick].compactMap { $0 })
            lockedPick = nil
        }
        wordleSolved = try c.decodeIfPresent(Int.self, forKey: .wordleSolved) ?? blank.wordleSolved
        wordleBest = try c.decodeIfPresent(Int.self, forKey: .wordleBest)
        wordleLastDay = try c.decodeIfPresent(DayKey.self, forKey: .wordleLastDay)
        wordleGuesses = try c.decodeIfPresent([String].self, forKey: .wordleGuesses) ?? blank.wordleGuesses
        wordleGuessDay = try c.decodeIfPresent(DayKey.self, forKey: .wordleGuessDay)
        numberLinePlayed = try c.decodeIfPresent(Int.self, forKey: .numberLinePlayed) ?? blank.numberLinePlayed
        numberLineBest = try c.decodeIfPresent(Int.self, forKey: .numberLineBest)
        ladderPlay = try c.decodeIfPresent(PlayRecord<[String]>.self, forKey: .ladderPlay) ?? blank.ladderPlay
        threadPlay = try c.decodeIfPresent(PlayRecord<[String]>.self, forKey: .threadPlay) ?? blank.threadPlay
        balancePlay = try c.decodeIfPresent(PlayRecord<[Int]>.self, forKey: .balancePlay) ?? blank.balancePlay
        pearlsPlay = try c.decodeIfPresent(PlayRecord<[Int]>.self, forKey: .pearlsPlay) ?? blank.pearlsPlay
        tracePlay = try c.decodeIfPresent(PlayRecord<[Int]>.self, forKey: .tracePlay) ?? blank.tracePlay
        sortPlay = try c.decodeIfPresent(PlayRecord<[Int]>.self, forKey: .sortPlay) ?? blank.sortPlay
        weavePlay = try c.decodeIfPresent(PlayRecord<[String]>.self, forKey: .weavePlay) ?? blank.weavePlay
        // A save written before the league existed opens in Tidepool with no
        // pennants. There is no history to reconstruct and inventing one would be a
        // keepsake nobody earned.
        league = try c.decodeIfPresent(LeagueState.self, forKey: .league) ?? blank.league
        plus = try c.decodeIfPresent(PlusLocal.self, forKey: .plus) ?? blank.plus
        // A save from before the Firsts list keeps what it can prove — done, date
        // unknown — rather than stamping a costume worn last week with today.
        if let kept = try c.decodeIfPresent(Firsts.self, forKey: .firsts) {
            firsts = kept
        } else {
            firsts = Firsts.inferred(from: self)
        }
        decor = try c.decodeIfPresent(TankDecor.self, forKey: .decor) ?? blank.decor
    }

    // MARK: - Day

    /// The day rewards are keyed to. Equal to today, except while the device clock
    /// is behind a day this install already reached. Travelling backwards across the
    /// date line pins you to the later day for a day; no coins are ever lost.
    var effectiveDay: DayKey { DayKey.latest(currentDay, maxDayReached) }

    /// Rolls the list over to `day` if it isn't already there. Safe to call on every
    /// foreground, midnight tick, and time-zone change.
    mutating func advance(to day: DayKey = .today()) {
        // While the clock is rolled back, a completion is keyed to this later day,
        // not to `currentDay` — the retirement check below has to look at both.
        let paidDay = effectiveDay
        maxDayReached = DayKey.latest(maxDayReached, day)
        guard day != currentDay else { return }
        // A finished one-off is done with; retire it rather than deleting, so the
        // ledger line it produced still has something to point at.
        for i in templates.indices where templates[i].recurrence == .once {
            if templates[i].retiredOn == nil,
               isDone(templateID: templates[i].id, on: currentDay)
                || isDone(templateID: templates[i].id, on: paidDay) {
                templates[i].retiredOn = currentDay
                templates[i].isActive = false
            }
        }
        currentDay = day
        settleLeagueWeekIfNeeded()
        settleRatingIfNeeded(to: day)
    }

    // MARK: - The league week

    /// Coins earned so far in the week the league is counting. Earned, never held —
    /// buying a kin does not cost you a place.
    var leaguePoints: Int { ledger.coinsEarned(inWeek: league.weekStart) }

    /// The bar left to clear this week, or `nil` at the top of the ladder.
    var leaguePointsToNextTier: Int? {
        LeagueRules.bar(for: league.tier).map { max(0, $0 - leaguePoints) }
    }

    /// Closes the old week if the calendar has turned over.
    ///
    /// Hung off `advance(to:)` rather than a timer of its own, so it fires on exactly
    /// the four moments the day already rolls: launch, foreground, midnight, and a
    /// time-zone change. A student away for three weeks settles the week they were
    /// last active in and lands in the current one; the empty weeks between earned
    /// nothing, and nothing is what they change.
    @discardableResult
    mutating func settleLeagueWeekIfNeeded() -> LeagueRules.Outcome? {
        let week = WeekKey(effectiveDay)
        guard !week.raw.isEmpty, week > league.weekStart else { return nil }
        return league.settle(into: week, coinsEarned: ledger.coinsEarned(inWeek: league.weekStart))
    }

    // MARK: - Today's list

    func taskKey(_ id: String, on day: DayKey) -> String { "task:\(id):\(day.raw)" }

    /// Assignments are one-shot, so their pay is keyed without a day. A submitted
    /// item that stays in the extension's feed across midnight, or a hand-ticked
    /// one still open tomorrow, must not pay a second time.
    func canvasKey(_ id: String) -> String { "task:\(id)" }

    /// A dated task is one-shot too: finished on the 12th, it stays finished.
    func datedKey(_ id: String) -> String { "dated:\(id)" }

    func isDatedDone(_ id: String) -> Bool { ledger.isClaimed(datedKey(id)) }

    /// Ever paid, under the day-less key or under a day-keyed line written before
    /// day-less keys existed.
    private func isCanvasPaid(_ id: String) -> Bool {
        ledger.entries.contains { $0.key == canvasKey(id) || $0.key.hasPrefix("task:\(id):") }
    }

    func isDone(templateID: String, on day: DayKey) -> Bool {
        ledger.isClaimed(taskKey(templateID, on: day))
    }

    /// Today's list, rebuilt from templates plus the Canvas feed. Never stored.
    var tasks: [DailyTask] {
        let day = effectiveDay
        // Canvas can hand back the same quiz several times under different ids
        // (one per section copy). One row per title, course and due date; a
        // weekly quiz with fresh dates stays a separate row each week.
        var seen: Set<String> = []
        let canvas = canvasItems
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            .filter { item in
                let key = "\(item.title)|\(item.courseName)|\(item.dueAt?.timeIntervalSince1970 ?? -1)"
                return seen.insert(key).inserted
            }
            .map { item in
                DailyTask(id: item.id, title: item.title, kind: .canvas,
                          detail: item.courseName, dueAt: item.dueAt,
                          done: item.isSubmitted || isCanvasPaid(item.id),
                          isLocked: item.isSubmitted)
            }
        // Your own dated work joins today when it is due today, or is overdue
        // and still open. Finished overdue rows stay on their own day.
        let dated = datedTasks
            .filter { $0.day == day || ($0.day < day && $0.day >= day.adding(days: -7) && !isDatedDone($0.id)) }
            .sorted { ($0.day, $0.minute ?? 1439) < ($1.day, $1.minute ?? 1439) }
            .map { datedRow($0) }
        let mine = templates
            .filter { $0.isActive && $0.retiredOn == nil }
            .map { t in
                DailyTask(id: t.id, title: t.title, kind: t.kind,
                          done: ledger.isClaimed(taskKey(t.id, on: day)))
            }
        return canvas + dated + mine
    }

    private func datedRow(_ t: DatedTask) -> DailyTask {
        DailyTask(id: t.id, title: t.title, kind: t.kind, detail: t.detail,
                  dueAt: t.dueAt(), done: isDatedDone(t.id), isLocked: false,
                  colorHex: nil, isDated: true)
    }

    /// The list for any one day, for the calendar: Canvas work on its due day
    /// and dated tasks on their day. The daily templates stay off it — a habit
    /// that comes back every morning is Home's, and seven copies of "drink
    /// water" drown the week.
    func tasks(on day: DayKey, calendar: Calendar = .current) -> [DailyTask] {
        var seen: Set<String> = []
        let canvas = canvasItems
            .filter { item in
                guard let due = item.dueAt else { return false }
                return DayKey(due, calendar: calendar) == day
            }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            .filter { item in
                let key = "\(item.title)|\(item.courseName)|\(item.dueAt?.timeIntervalSince1970 ?? -1)"
                return seen.insert(key).inserted
            }
            .map { item in
                DailyTask(id: item.id, title: item.title, kind: .canvas,
                          detail: item.courseName, dueAt: item.dueAt,
                          done: item.isSubmitted || isCanvasPaid(item.id),
                          isLocked: item.isSubmitted,
                          colorHex: item.colorHex ?? courseColor(item.courseName))
            }
        let dated = datedTasks
            .filter { $0.day == day }
            .sorted { ($0.minute ?? 1439) < ($1.minute ?? 1439) }
            .map { datedRow($0) }
        return canvas + dated
    }

    /// The one-line preview of tomorrow, or `nil` when tomorrow is empty.
    ///
    /// Two titles and then a count, never a second list. The question Home answers
    /// at 11 PM is "is tonight the last chance", not "what does the whole week look
    /// like". It reads the same two sources today's list reads — Canvas work and
    /// your own dated tasks — and leaves out the daily habits, which are on every
    /// tomorrow there will ever be. Anything already finished is not coming.
    func tomorrowLine(calendar: Calendar = .current) -> String? {
        let titles = tasks(on: effectiveDay.adding(days: 1), calendar: calendar)
            .filter { !$0.done }
            .map(\.title)
        guard let first = titles.first else { return nil }
        let shown = titles.count == 1 ? first : "\(first), \(titles[1])"
        let more = titles.count - min(2, titles.count)
        return more > 0 ? "Tomorrow: \(shown) and \(more) more" : "Tomorrow: \(shown)"
    }

    /// Course-calendar events on one day, earliest first.
    func events(on day: DayKey, calendar: Calendar = .current) -> [CanvasEvent] {
        canvasEvents
            .filter { DayKey($0.startAt, calendar: calendar) == day }
            .sorted { ($0.allDay ? 0 : 1, $0.startAt) < ($1.allDay ? 0 : 1, $1.startAt) }
    }

    private func courseColor(_ name: String) -> String? {
        canvasCourses.first { $0.name == name }?.colorHex
    }

    // MARK: - Dated tasks

    mutating func addDated(_ task: DatedTask) {
        var t = task
        t.title = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.title.isEmpty else { return }
        datedTasks.append(t)
    }

    mutating func updateDated(_ task: DatedTask) {
        guard let i = datedTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var t = task
        t.title = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.title.isEmpty else { return }
        datedTasks[i] = t
    }

    /// Deleting a finished task keeps the coins. It was done; the student is only
    /// tidying the list.
    mutating func deleteDated(_ id: String) {
        datedTasks.removeAll { $0.id == id }
    }

    var allDone: Bool { !tasks.isEmpty && tasks.allSatisfy(\.done) }

    var week: WeekStats { ledger.stats() }

    var activeChibi: OwnedChibi {
        owned.first { $0.speciesID == activeChibiID } ?? owned[0]
    }

    /// Puts a costume on the active kin.
    ///
    /// Only a costume the student owns, and `classic` — which is not a costume but the
    /// absence of a choice, and leaves the page to dress the kin in its coat's default.
    /// Stage is not checked here: a two-star kin can be dressed, and simply does not
    /// show it until it grows into the costume slot.
    mutating func wear(_ costumeID: String, now: Date = Date()) {
        guard costumeID == "classic" || ownedLooks.contains(costumeID) else { return }
        guard let i = owned.firstIndex(where: { $0.speciesID == activeChibiID }) else { return }
        owned[i].skinID = costumeID
        if Costume.ids.contains(costumeID) { firsts.mark(Firsts.costume, at: now) }
    }

    /// The Wardrobe editor's tiles. `Costume.none` writes `classic`, which is no costume.
    mutating func wear(_ costume: Costume, now: Date = Date()) {
        wear(costume.id, now: now)
    }

    /// Buys a costume off the rack at its coin price. Owning it is what `wear` checks,
    /// so this is the only way a coin costume gets onto the kin. The key matches the
    /// one the laptop's shop uses for the same look, so nothing pays twice.
    @discardableResult
    mutating func buyCostume(_ costume: Costume, now: Date = Date()) -> Bool {
        guard Costume.ids.contains(costume.id), !ownedLooks.contains(costume.id) else { return false }
        guard ledger.post(CoinEntry(key: "look:\(costume.id)", amount: -costume.price,
                                    reason: .upgrade, day: effectiveDay, at: now)) else { return false }
        ownedLooks.insert(costume.id)
        return true
    }

    /// What the active kin is wearing, as a friend's screen names it.
    ///
    /// The phone stores one id for how a kin looks (`OwnedChibi.skinID`) and the
    /// costume rack is still only in the web build, so anything that is not Classic
    /// *is* the costume. `none` is the id the bridge uses for a plain kin.
    var activeCostumeID: String {
        let skin = activeChibi.skinID
        return skin == "classic" ? "none" : skin
    }

    // MARK: - Tasks

    /// Pays for a finished task, once. Returns what was paid, or 0 if it was already
    /// checked off — today for a daily task, ever for a Canvas assignment.
    @discardableResult
    mutating func complete(taskID: String, reward: Int, now: Date = Date()) -> Int {
        let day = effectiveDay
        if canvasItems.contains(where: { $0.id == taskID }) {
            guard !isCanvasPaid(taskID) else { return 0 }
            let posted = ledger.post(CoinEntry(key: canvasKey(taskID), amount: reward,
                                               reason: .task, day: day, at: now))
            if posted {
                lifetime.tasksFinished += 1
                lifetime.canvasFinished += 1
                // The gift week arrives here rather than on a screen, so it lands on
                // the third finished task whether or not anyone is looking at the
                // tab that would have noticed. It is never announced beforehand.
                armGiftWeekIfEarned(now: now)
            }
            return posted ? reward : 0
        }
        if datedTasks.contains(where: { $0.id == taskID }) {
            let posted = ledger.post(CoinEntry(key: datedKey(taskID), amount: reward,
                                               reason: .task, day: day, at: now))
            if posted { lifetime.tasksFinished += 1 }
            return posted ? reward : 0
        }
        let posted = ledger.post(CoinEntry(key: taskKey(taskID, on: day), amount: reward,
                                           reason: .task, day: day, at: now))
        if posted { lifetime.tasksFinished += 1 }
        return posted ? reward : 0
    }

    mutating func addTask(title: String, kind: TaskKind, recurrence: Recurrence, id: String = UUID().uuidString) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        templates.append(TaskTemplate(id: "u-\(id)", title: clean, kind: kind, recurrence: recurrence))
    }

    mutating func setTemplate(_ id: String, active: Bool) {
        guard let i = templates.firstIndex(where: { $0.id == id }) else { return }
        templates[i].isActive = active
    }

    /// Deletes a task the user made. Presets can only be switched off, never removed.
    mutating func deleteTask(_ id: String) {
        guard let i = templates.firstIndex(where: { $0.id == id }), !templates[i].isPreset else { return }
        templates.remove(at: i)
    }

    // MARK: - Other earnings

    @discardableResult
    mutating func recordFocus(minutes: Int, sessionID: String = UUID().uuidString, now: Date = Date()) -> Int {
        let day = effectiveDay
        let ok = ledger.post(CoinEntry(key: "focus:\(sessionID)", amount: minutes,
                                       reason: .focus, units: minutes, day: day, at: now))
        if ok {
            lifetime.focusMinutes += minutes
            firsts.mark(Firsts.shift, at: now)
        }
        return ok ? minutes : 0
    }

    /// Pays what the laptop asked for: focus sessions that finished there, and
    /// looks bought in its shop.
    ///
    /// Every request carries its own ledger key, so the extension can keep
    /// re-sending one until this phone confirms it without ever paying twice. A
    /// purchase the balance cannot cover is simply refused — `Ledger.post` will
    /// not overdraw — and the look stays unowned, which is the honest answer.
    ///
    /// Returns the newest request it actually looked at, which is what the
    /// extension needs back to stop re-sending.
    @discardableResult
    mutating func applyBridgeRequests(_ requests: [BridgeRequest], now: Date = Date()) -> Date? {
        let day = effectiveDay
        var newest = requestsAppliedAt
        for request in requests.sorted(by: { $0.at < $1.at }) {
            // Already settled in an earlier sync.
            if let seen = requestsAppliedAt, request.at <= seen { continue }
            switch request.kind {
            case "focus":
                let minutes = request.minutes ?? 0
                guard (1...240).contains(minutes) else { break }
                if ledger.post(CoinEntry(key: request.ledgerKey, amount: minutes,
                                         reason: .focus, units: minutes, day: day, at: now)) {
                    lifetime.focusMinutes += minutes
                    firsts.mark(Firsts.shift, at: now)
                }
            case "look":
                guard let lookId = request.lookId, !lookId.isEmpty,
                      let price = request.price, (0...5000).contains(price) else { break }
                if ownedLooks.contains(lookId) { break }
                if price == 0 {
                    ownedLooks.insert(lookId)
                } else if ledger.post(CoinEntry(key: request.ledgerKey, amount: -price,
                                                reason: .upgrade, day: day, at: now)) {
                    ownedLooks.insert(lookId)
                }
            default:
                break
            }
            newest = max(newest ?? request.at, request.at)
        }
        requestsAppliedAt = newest
        return newest
    }

    /// What the extension is told after a sync.
    var bridgeState: BridgeState {
        BridgeState(coins: ledger.balance, owned: Array(ownedLooks).sorted(),
                    requestsAppliedAt: requestsAppliedAt, league: bridgeLeague,
                    kin: BridgeKin(species: activeChibi.speciesID, level: activeChibi.level,
                                   skin: activeChibi.skinID, scene: Scene0.find(sceneID).id))
    }

    /// The league flattened for the laptop. The board rides along only when the pod
    /// is this week's, so a stale week's strangers never show up on a Canvas page.
    var bridgeLeague: BridgeLeague {
        let pod = league.lastPod.flatMap { $0.week == league.weekStart ? $0 : nil }
        return BridgeLeague(
            tier: league.tier.rawValue,
            points: leaguePoints,
            bar: LeagueRules.bar(for: league.tier),
            week: league.weekStart.raw,
            pennants: league.pennants.map(\.rawValue).sorted(),
            board: pod.map { $0.members.map {
                BridgeLeagueMember(you: $0.isYou, adjective: $0.adjective, noun: $0.noun,
                                   points: $0.points, level: $0.level,
                                   species: $0.speciesID, look: $0.lookID)
            } })
    }

    /// Keeps the best single shift. Miles are cosmetic, so this is a plain max with
    /// no ledger entry behind it.
    mutating func recordShift(miles: Int) {
        bestShift = max(bestShift, miles)
    }

    // MARK: - The Play pool

    /// Play pays once a day: the first game finished banks `playReward`, and every
    /// game after that posts a zero line, so it still counts as played and its
    /// solved count still moves. One pool keeps six games from out-earning real work,
    /// and one number is easier to read than six (design/GAMES-PLAN.md §4).
    static let playReward = 30
    static let playReasons: Set<CoinReason> = [.wordle, .numberLine, .ladder, .thread, .balance, .pearls, .trace, .sort, .weave]

    /// The game that banked `day`'s coins, or nil while the pool is still open.
    func playBanked(on day: DayKey) -> CoinReason? {
        ledger.entries.first { $0.day == day && $0.amount > 0 && Self.playReasons.contains($0.reason) }?.reason
    }

    var playClaimedToday: Bool { playBanked(on: effectiveDay) != nil }

    /// A lesson finished today. The Play tab's switch marks whichever half still
    /// has its daily thing open, and this is the lesson half's answer.
    var lessonDoneToday: Bool {
        ledger.entries.contains { $0.reason == .lesson && $0.day == effectiveDay }
    }

    /// Posts one game's line for `day`, paid only while the pool is open. Returns
    /// what it paid. A key already posted pays nothing and changes nothing.
    private mutating func postPlay(_ reason: CoinReason, key: String, day: DayKey, now: Date) -> Int {
        let amount = playBanked(on: day) == nil ? Self.playReward : 0
        let ok = ledger.post(CoinEntry(key: key, amount: amount, reason: reason, day: day, at: now))
        return ok ? amount : 0
    }

    /// Marks one of the four new games solved for `day`, once per day, and pays the
    /// pool if it is still open. `day` is the day the puzzle was dealt. No streak:
    /// the only counter is `solved`, and it only goes up (PRODUCT.md).
    @discardableResult
    mutating func recordPlaySolve<P>(_ path: WritableKeyPath<GameState, PlayRecord<P>>, reason: CoinReason,
                                     day: DayKey? = nil, now: Date = Date()) -> Int {
        let day = day ?? effectiveDay
        guard self[keyPath: path].lastDay != day else { return 0 }
        self[keyPath: path].solved += 1
        self[keyPath: path].lastDay = day
        // A win on the board that was dealt, before the record is cleared by the
        // next day's settle. An unrated board scores nothing (`Rating.after`).
        rating = Rating.after(rating, puzzle: self[keyPath: path].puzzleRating ?? Rating.unrated,
                              solved: true, day: day)
        return postPlay(reason, key: "\(reason.rawValue):\(day.raw)", day: day, now: now)
    }

    /// Today's board, so leaving mid-puzzle and coming back finds it. Good only for
    /// the day it was dealt; any other day reads as a fresh board.
    func playProgress<P>(_ path: KeyPath<GameState, PlayRecord<P>>, for day: DayKey) -> P? {
        self[keyPath: path].progressDay == day ? self[keyPath: path].progress : nil
    }

    mutating func savePlayProgress<P>(_ path: WritableKeyPath<GameState, PlayRecord<P>>, _ progress: P,
                                      startedAt: Date? = nil, day: DayKey,
                                      puzzleRating: Int = Rating.unrated) {
        self[keyPath: path].progress = progress
        self[keyPath: path].progressDay = day
        self[keyPath: path].startedAt = startedAt
        // Saved on the first move, not on opening the screen: this is what makes
        // an unfinished board count as an attempt tomorrow, and looking at one and
        // walking away count as nothing.
        self[keyPath: path].puzzleRating = puzzleRating > Rating.unrated ? puzzleRating : nil
    }

    // MARK: - The rating

    /// Settles yesterday's boards: any game whose last saved board was a day the
    /// student never solved is a loss, once, at the rating that board was worth.
    ///
    /// Hung off `advance(to:)` beside the league week, for the same reason — it
    /// fires on the four moments the day already rolls and needs no timer. Opening
    /// a game and leaving without a move is not a loss, because nothing was saved.
    ///
    /// The five games a rating is kept for are named here one by one. Daily Word is
    /// not among them: a word guessed from five letters has a luck in it that a
    /// Takuzu grid does not, and `words.json` carries no per-word difficulty to
    /// rate against. A heterogeneous list of key paths is not a thing Swift will
    /// hold, so five lines it is.
    @discardableResult
    mutating func settleRatingIfNeeded(to day: DayKey = .today()) -> Int {
        settleRating(\.balancePlay, to: day)
            + settleRating(\.pearlsPlay, to: day)
            + settleRating(\.tracePlay, to: day)
            + settleRating(\.sortPlay, to: day)
            + settleRating(\.weavePlay, to: day)
    }

    private mutating func settleRating<P>(_ path: WritableKeyPath<GameState, PlayRecord<P>>,
                                          to day: DayKey) -> Int {
        let record = self[keyPath: path]
        guard let dealt = record.progressDay, dealt < day,
              let worth = record.puzzleRating, record.lastDay != dealt else { return 0 }
        rating = Rating.after(rating, puzzle: worth, solved: false, day: dealt)
        // Cleared so the same unfinished board cannot be settled twice.
        self[keyPath: path].puzzleRating = nil
        return 1
    }

    /// Pays for the daily word through the pool, once per day. `day` is the day the
    /// puzzle was dealt — a solve finished just past midnight still settles the
    /// word it was.
    @discardableResult
    mutating func recordWordleWin(guesses: Int = 6, day: DayKey? = nil,
                                  now: Date = Date(), calendar: Calendar = .current) -> Int {
        let day = day ?? effectiveDay
        guard !ledger.isClaimed("wordle:\(day.raw)") else { return 0 }
        wordleSolved += 1
        wordleBest = min(wordleBest ?? guesses, guesses)
        wordleLastDay = day
        return postPlay(.wordle, key: "wordle:\(day.raw)", day: day, now: now)
    }

    static func dayBefore(_ day: DayKey, calendar: Calendar = .current) -> DayKey? {
        let parts = day.raw.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              let before = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
        return DayKey(before, calendar: calendar)
    }

    var wordleClaimedToday: Bool { ledger.isClaimed("wordle:\(effectiveDay.raw)") }

    /// A finished Number Line round. Paid through the pool once a day, whatever the
    /// accuracy — the score is a number to beat, never the thing that decides the coins.
    @discardableResult
    mutating func recordNumberLineRound(accuracy: Int, day: DayKey? = nil, now: Date = Date()) -> Int {
        let day = day ?? effectiveDay
        numberLinePlayed += 1
        numberLineBest = max(numberLineBest ?? 0, accuracy)
        return postPlay(.numberLine, key: "numberline:\(day.raw)", day: day, now: now)
    }

    var numberLineClaimedToday: Bool { ledger.isClaimed("numberline:\(effectiveDay.raw)") }

    /// Pays for a finished deck, once ever. A re-read is free to do and pays nothing,
    /// which is the same rule every other earning path in the app follows.
    @discardableResult
    mutating func completeLesson(id: String, reward: Int, now: Date = Date()) -> Int {
        let day = effectiveDay
        let ok = ledger.post(CoinEntry(key: "lesson:\(id)", amount: reward,
                                       reason: .lesson, day: day, at: now))
        completedLessons.insert(id)
        if ok { lifetime.lessonsRead += 1 }
        // Finished decks don't ask to be continued.
        deckProgress[id] = nil
        return ok ? reward : 0
    }

    // MARK: - Learn

    /// Remembers how far in you got. Only ever moves forward within a session's
    /// reading, so paging back doesn't make Continue offer you an earlier card.
    mutating func setDeckProgress(_ lessonID: String, card index: Int) {
        guard index > 0 else { deckProgress[lessonID] = nil; return }
        deckProgress[lessonID] = max(deckProgress[lessonID] ?? 0, index)
    }

    func deckProgress(_ lessonID: String) -> Int { deckProgress[lessonID] ?? 0 }

    func isSaved(lessonID: String, index: Int) -> Bool {
        savedCards.contains { $0.lessonID == lessonID && $0.index == index }
    }

    /// Hearts or un-hearts a card. Returns the state it ended in, so the view can
    /// bounce the heart only when something was actually saved.
    @discardableResult
    mutating func toggleSaved(lessonID: String, index: Int, now: Date = Date()) -> Bool {
        if let i = savedCards.firstIndex(where: { $0.lessonID == lessonID && $0.index == index }) {
            savedCards.remove(at: i)
            return false
        }
        savedCards.insert(SavedCard(lessonID: lessonID, index: index, savedAt: now), at: 0)
        return true
    }

    /// Files a report against a card. Duplicates are kept — flagging the same card
    /// twice is the student saying it again, not a mistake to swallow.
    mutating func reportCard(lessonID: String, index: Int, reason: CardReportReason,
                             now: Date = Date()) {
        cardReports.insert(CardReport(lessonID: lessonID, cardIndex: index,
                                      reason: reason, date: now), at: 0)
    }

    /// The only counter Learn shows. Counts up within a month and never resets to a
    /// target you have to hit — there is no streak to break here.
    func lessonsThisMonth(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let month = calendar.dateInterval(of: .month, for: now) else { return 0 }
        return ledger.entries.filter { $0.reason == .lesson && month.contains($0.at) }.count
    }

    /// Puzzles finished this month, by the same rule. Every finish posts a ledger
    /// line — the first of the day for coins, the rest at zero (`postPlay`) — so the
    /// lines are the count, and a lost Sort, which posts nothing, is not one.
    func puzzlesThisMonth(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let month = calendar.dateInterval(of: .month, for: now) else { return 0 }
        return ledger.entries.filter { Self.playReasons.contains($0.reason) && month.contains($0.at) }.count
    }

    // MARK: - Spending

    @discardableResult
    mutating func upgradeActiveChibi(now: Date = Date()) -> Bool {
        guard let cost = activeChibi.nextUpgradeCost,
              let i = owned.firstIndex(where: { $0.speciesID == activeChibiID }) else { return false }
        let level = owned[i].level
        guard ledger.post(CoinEntry(key: "upgrade:\(activeChibiID):\(level)", amount: -cost,
                                    reason: .upgrade, day: effectiveDay, at: now)) else { return false }
        owned[i].level += 1
        if owned[i].level >= 3 { firsts.mark(Firsts.threeStars(activeChibiID), at: now) }
        return true
    }

    @discardableResult
    mutating func buy(_ species: ChibiSpecies, now: Date = Date()) -> Bool {
        guard !owned.contains(where: { $0.speciesID == species.id }) else { return false }
        guard ledger.post(CoinEntry(key: "species:\(species.id)", amount: -species.price,
                                    reason: .species, day: effectiveDay, at: now)) else { return false }
        owned.append(OwnedChibi(speciesID: species.id, level: 1))
        activeChibiID = species.id
        return true
    }

    @discardableResult
    mutating func buyScene(_ scene: Scene0, now: Date = Date()) -> Bool {
        guard !ownedScenes.contains(scene.id) else { return false }
        // Today's price, not the Collection price. A scene drawn into the picks row
        // is shown at 20% off, and charging the full price after showing the discount
        // is the one thing the shop's honesty panel promises never happens.
        guard ledger.post(CoinEntry(key: "scene:\(scene.id)", amount: -currentPrice("scene:\(scene.id)"),
                                    reason: .scene, day: effectiveDay, at: now)) else { return false }
        ownedScenes.insert(scene.id)
        sceneID = scene.id
        firsts.mark(Firsts.scene, at: now)
        // Same as adopting a kin: release the slot it was held in and backfill the row,
        // so a bought scene does not sit in today's picks pretending to still be for sale.
        lockedPicks.remove("scene:\(scene.id)")
        refreshPicksIfNeeded(now: now)
        return true
    }

    mutating func equipScene(_ id: String, now: Date = Date()) {
        guard ownedScenes.contains(id) else { return }
        sceneID = id
        // The free tank is where every kin starts, so putting it back is not a first.
        if id != Scene0.all[0].id { firsts.mark(Firsts.scene, at: now) }
    }

    mutating func setActive(_ speciesID: String) {
        guard owned.contains(where: { $0.speciesID == speciesID }) else { return }
        activeChibiID = speciesID
    }

    // MARK: - Canvas

    /// Takes a push from the extension. Work Canvas confirms you handed in pays
    /// on the spot: submitting *is* completing, and the ledger key means a student
    /// who also ticked it by hand is never paid twice.
    mutating func applyCanvas(_ snapshot: CanvasSnapshot, now: Date = Date()) {
        canvasItems = snapshot.tasks
        canvasCourses = snapshot.courses
        canvasEvents = snapshot.events
        lastCanvasSyncAt = now
        for item in snapshot.tasks where item.isSubmitted {
            complete(taskID: item.id, reward: TaskKind.canvas.reward, now: now)
        }
    }

    /// Un-checking is for things you told the app about. Canvas already knows.
    /// Undoing a check-off takes its line out of the lifetime totals as well. That is
    /// the one way a "together since" number can fall, and it is the honest one: the
    /// student is saying the thing did not happen.
    mutating func uncomplete(taskID: String) {
        if let item = canvasItems.first(where: { $0.id == taskID }) {
            guard !item.isSubmitted else { return }
            if ledger.revoke(canvasKey(taskID)) {
                lifetime.tasksFinished = max(0, lifetime.tasksFinished - 1)
                lifetime.canvasFinished = max(0, lifetime.canvasFinished - 1)
            }
        } else if datedTasks.contains(where: { $0.id == taskID }) {
            if ledger.revoke(datedKey(taskID)) {
                lifetime.tasksFinished = max(0, lifetime.tasksFinished - 1)
            }
        } else if ledger.revoke(taskKey(taskID, on: effectiveDay)) {
            lifetime.tasksFinished = max(0, lifetime.tasksFinished - 1)
        }
    }

    /// Makes a code the first time it is needed, then keeps it. Regenerating would
    /// silently orphan a laptop that is already pushing to the old one.
    @discardableResult
    mutating func ensurePairingCode() -> String {
        if let existing = pairingCode { return existing }
        let code = PairingCode.generate()
        pairingCode = code
        return code
    }

    // MARK: - Friends

    /// Takes the list the bridge just sent, keeping what only this phone knows.
    ///
    /// Anybody the bridge no longer returns drops out — that is what Remove and
    /// Block look like from the other side, and there is no tombstone for either.
    mutating func applyFriends(_ rows: [Friend], now: Date = Date()) {
        friends = FriendList.merge(fetched: rows, cached: friends)
        if !friends.isEmpty { firsts.mark(Firsts.friend, at: now) }
    }

    /// Puts somebody you just added by code straight into the list, already seen.
    ///
    /// Already seen because you did the adding: the "added you" card is for the
    /// other direction, and a card telling you about a person you typed a code for
    /// ten seconds ago would be noise.
    mutating func addFriend(_ friend: Friend, now: Date = Date()) {
        var row = friend
        row.seenAt = now
        if let i = friends.firstIndex(where: { $0.id == row.id }) {
            row.nickname = friends[i].nickname
            friends[i] = row
        } else {
            friends.append(row)
        }
        firsts.mark(Firsts.friend, at: now)
    }

    /// What you call them, on this phone. Empty clears it and the word-list name
    /// comes back.
    mutating func setNickname(_ raw: String, for id: String) {
        guard let i = friends.firstIndex(where: { $0.id == id }) else { return }
        friends[i].nickname = Friend.cleanNickname(raw)
    }

    /// The tab has shown them to you, so the card is done.
    mutating func markFriendSeen(_ id: String, at now: Date = Date()) {
        guard let i = friends.firstIndex(where: { $0.id == id }) else { return }
        friends[i].seenAt = now
    }

    /// Drops the row here. The caller tells the bridge; this is what makes the row
    /// leave the screen at the moment of the tap rather than a fetch later.
    mutating func dropFriend(_ id: String) {
        friends.removeAll { $0.id == id }
        wavesSent.remove(id)
        wavesSeen.remove(id)
        wavesIn.remove(id)
    }

    // MARK: - Waves

    /// Everything about waves is one day long, so all three sets are emptied the
    /// moment the day they belong to is not today any more. Keeping a day beside
    /// them rather than clearing on a timer means a phone that was asleep across
    /// midnight is right the moment it wakes.
    private mutating func rollWaves(to day: DayKey) {
        guard wavesDay != day else { return }
        wavesDay = day
        wavesSent = []
        wavesSeen = []
        wavesIn = []
    }

    /// You have waved at them today. Nothing about it is undoable, and nothing says
    /// so out loud — the button simply shows its settled state.
    mutating func markWaved(at id: String, on day: DayKey = .today()) {
        rollWaves(to: day)
        wavesSent.insert(id)
    }

    func hasWaved(at id: String, on day: DayKey = .today()) -> Bool {
        wavesDay == day && wavesSent.contains(id)
    }

    /// What `fetch_sent` says. The bridge is the truth after a reinstall, when this
    /// phone has no memory of today at all.
    mutating func applyWavesSent(_ ids: [String], on day: DayKey = .today()) {
        rollWaves(to: day)
        wavesSent.formUnion(ids)
    }

    /// What `fetch_visits` says: who waved at you.
    mutating func applyWavesReceived(_ ids: [String], on day: DayKey = .today()) {
        rollWaves(to: day)
        wavesIn.formUnion(ids)
    }

    /// Waves you have not looked at yet. The same shape as the "added you" card and
    /// for the same reason: there is no unread count anywhere in this app.
    func unseenWaves(on day: DayKey = .today()) -> [String] {
        guard wavesDay == day else { return [] }
        return friends.map(\.id).filter { wavesIn.contains($0) && !wavesSeen.contains($0) }
    }

    mutating func markWaveSeen(_ id: String, on day: DayKey = .today()) {
        rollWaves(to: day)
        wavesSeen.insert(id)
    }

    /// Forgets the pairing. The caller deletes the bridge row first — leaving it
    /// to expire meant a student who disconnected because something felt wrong
    /// left their coursework readable for another month.
    mutating func unpair() {
        pairingCode = nil
        pairingToken = nil
        requestsAppliedAt = nil
        canvasItems = []
        canvasCourses = []
        canvasEvents = []
        lastCanvasSyncAt = nil
    }
}

// MARK: - Play records

/// One Play game's record. `solved` is kept here rather than derived from the
/// ledger because the ledger compacts lines older than 90 days and it should
/// never go down. `progress` is today's board in whatever shape the game
/// keeps — rungs, misses, a grid — and is only good for `progressDay`.
struct PlayRecord<Progress: Codable & Equatable>: Codable, Equatable {
    var solved = 0
    var lastDay: DayKey?
    var progress: Progress?
    var progressDay: DayKey?
    /// When today's board was first touched, so the stopwatch survives leaving
    /// and coming back. Nil for the games that don't keep time.
    var startedAt: Date?
    /// What `progressDay`'s board was worth. Kept here rather than looked up again
    /// at settle time so a board that has since scrolled out of the deal — a
    /// re-generated content file, a clock rolled forward a week — still settles at
    /// the rating it was actually played at. Nil for a board with no rating.
    var puzzleRating: Int?
}
