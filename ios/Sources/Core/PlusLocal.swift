import Foundation

/// One combination of kin, costume and scene, kept so it can be put back on.
///
/// Free saves three. Plus saves as many as you like, and — this is the promise, not
/// a nicety — **every combination already saved stays applicable forever, including
/// the ones above three.** A lapsed subscription stops new saves. It never deletes
/// one, and it never greys one out.
struct SavedLook: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var speciesID: String
    var costumeID: String
    var sceneID: String
    var savedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        speciesID: String,
        costumeID: String,
        sceneID: String,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.speciesID = speciesID
        self.costumeID = costumeID
        self.sceneID = sceneID
        self.savedAt = savedAt
    }
}

/// Everything Plus stores on the phone, in one property.
///
/// It is one blob rather than six fields on `GameState` for a boring reason: this
/// file is edited by more than one person at a time, and one new stored property is
/// one line to merge instead of six.
///
/// None of this is an entitlement. The entitlement lives in StoreKit and is read
/// through `PlusAccess`. What is here is the gift week's dates, what the season has
/// paid out, and the looks a student saved — all of which have to survive a lapse
/// untouched, which is exactly why they are in the save file and not in a receipt.
struct PlusLocal: Codable, Equatable {

    /// When the gift week ends. Set once, on the third finished Canvas task, and
    /// never extended or re-armed.
    var giftEndsAt: Date?
    /// When it started, so the timeline screen can draw real dates.
    var giftStartedAt: Date?
    /// The sheet that appears the once, the day the gift stops. Set the moment it
    /// is shown, so it can never appear twice.
    var giftSheetShown = false
    /// Combinations, newest first.
    var savedLooks: [SavedLook] = []
    /// Season id to the days claimed in it.
    var seasons: [String: SeasonProgress] = [:]

    // MARK: - The gift week

    /// Turns the gift on if this is the third finished Canvas task and it has never
    /// been given. Returns true only on the one call that actually starts it, so a
    /// caller can show the quiet line exactly once.
    ///
    /// `giftStartedAt` is the guard rather than `giftEndsAt`, because after the week
    /// runs out `giftEndsAt` is a date in the past and would otherwise read as
    /// "never given" and arm a second week.
    @discardableResult
    mutating func startGiftIfEarned(canvasFinished: Int, now: Date = Date()) -> Bool {
        guard giftStartedAt == nil, PlusGift.earned(canvasFinished: canvasFinished) else {
            return false
        }
        giftStartedAt = now
        giftEndsAt = PlusGift.endDate(from: now)
        return true
    }

    func giftIsOn(at now: Date = Date()) -> Bool { giftEndsAt.map { $0 > now } ?? false }

    /// The one moment the sheet is owed: the week was given, it has run out, and
    /// nobody has been shown it yet.
    func giftJustEnded(at now: Date = Date()) -> Bool {
        guard let end = giftEndsAt, !giftSheetShown else { return false }
        return end <= now
    }

    // MARK: - Saved looks

    func canSave(_ limit: Int) -> Bool { savedLooks.count < limit }

    /// Saves a combination if there is room. Returns false when the free three are
    /// full, which is the only thing the cap ever does — it never removes one.
    @discardableResult
    mutating func save(_ look: SavedLook, limit: Int) -> Bool {
        guard canSave(limit) else { return false }
        savedLooks.insert(look, at: 0)
        return true
    }

    /// Deleting is always allowed, at any number, paid or not. A student can always
    /// get out of a full shelf without paying to do it.
    mutating func removeLook(_ id: String) { savedLooks.removeAll { $0.id == id } }

    // MARK: - Seasons

    func progress(_ season: Season) -> SeasonProgress { seasons[season.id] ?? SeasonProgress() }

    /// Claims today's rung. Returns the rung's two rewards, or nil when the day is
    /// not claimable — the caller does not re-derive the rule.
    @discardableResult
    mutating func claim(
        _ season: Season,
        day: DayKey,
        finishedToday: Int,
        isPlus: Bool
    ) -> (rung: Int, free: Season.Reward, plus: Season.Reward?)? {
        let verdict = SeasonClaim.check(
            season: season, progress: progress(season), day: day, finishedToday: finishedToday
        )
        guard case .ready(let rung) = verdict else { return nil }
        var p = progress(season)
        p.claimedDays.insert(day.raw)
        seasons[season.id] = p
        let step = season.rungs[rung]
        return (rung, step.free, isPlus ? step.plus : nil)
    }
}
