import Foundation

/// What Plus does to the save file.
///
/// `PlusGate` says what a gate is worth. `PlusAccess` says whether a student is
/// Plus. This is the third and last piece: the handful of places the game state
/// actually changes because of it — the gift week arming itself, a season rung
/// paying out, a look being saved.
///
/// It is an extension in its own file rather than more methods on `GameState`
/// because `GameState.swift` is edited by several people at once, and this is the
/// part of Plus most likely to change.
extension GameState {

    // MARK: - Reading a gate

    /// Everything the app knows about whether this student is Plus right now.
    /// `paid` comes from StoreKit and `debug` from `-unlockAll`; the gift week is
    /// the only part that lives in the save file.
    func plusAccess(paid: Bool, debug: Bool = DebugUnlock.isOn || DebugUnlock.plusOn) -> PlusAccess {
        PlusAccess(paid: paid, giftEndsAt: plus.giftEndsAt, debug: debug)
    }

    func plusValue(_ gate: PlusGate, access: PlusAccess, at now: Date = Date()) -> Int {
        access.value(gate, installedAt: installedAt, at: now)
    }

    // MARK: - The gift week

    /// Arms the gift the first time three Canvas tasks are finished. Returns true
    /// on the single call that starts it, so the caller can show the quiet line the
    /// once and never again.
    ///
    /// Called from the task-posting path rather than from a view, because the gift
    /// has to arrive on the third finished task even if the student never opens the
    /// screen that would have noticed.
    @discardableResult
    mutating func armGiftWeekIfEarned(now: Date = Date()) -> Bool {
        plus.startGiftIfEarned(canvasFinished: lifetime.canvasFinished, now: now)
    }

    // MARK: - The season

    /// Real work finished today: tasks checked off, shifts finished, lessons read.
    ///
    /// Read off the ledger rather than counted separately, so it cannot drift from
    /// what the student was actually paid for. Games are deliberately not in it —
    /// a round of Sort is play, and the season is for work.
    func finishedToday(_ day: DayKey = DayKey.today()) -> Int {
        ledger.entries.filter { $0.day == day && Self.realWork.contains($0.reason) }.count
    }

    private static let realWork: Set<CoinReason> = [.task, .focus, .lesson]

    /// Today's rung, claimed. Pays the free coins, hands over the Plus costume, and
    /// writes the day down so it cannot be claimed twice.
    ///
    /// Returns what was handed over, or nil when today is not claimable — the view
    /// asks `SeasonClaim.check` for the reason rather than getting one from here.
    @discardableResult
    mutating func claimSeasonRung(
        _ season: Season,
        isPlus: Bool,
        day: DayKey = DayKey.today(),
        now: Date = Date()
    ) -> SeasonPayout? {
        guard let claim = plus.claim(
            season, day: day, finishedToday: finishedToday(day), isPlus: isPlus
        ) else { return nil }

        var coins = 0
        var costume: Costume?

        if case .coins(let n) = claim.free {
            // Keyed by season and rung, so a retry after a crash cannot pay twice.
            let posted = ledger.post(CoinEntry(
                key: "season:\(season.id):\(claim.rung)",
                amount: n, reason: .season, units: 1, day: day, at: now
            ))
            if posted { coins = n }
        }

        if let id = claim.plus?.costumeID {
            // Already on the rack? Then the rung pays what it is worth in coins
            // instead, so a Plus student is never handed a duplicate.
            if ownedLooks.contains(id) {
                let price = Costume.find(id)?.price ?? 0
                let posted = ledger.post(CoinEntry(
                    key: "season:\(season.id):\(claim.rung):owned",
                    amount: price, reason: .season, units: 1, day: day, at: now
                ))
                if posted { coins += price }
            } else {
                ownedLooks.insert(id)
                costume = Costume.find(id)
            }
        }

        return SeasonPayout(rung: claim.rung, coins: coins, costume: costume)
    }

    struct SeasonPayout: Equatable {
        var rung: Int
        var coins: Int
        var costume: Costume?
    }

    // MARK: - Saved looks

    /// How many combinations can be saved. Plus is unlimited; free is three, and
    /// anything already above three stays saved forever.
    func savedLookLimit(_ access: PlusAccess, at now: Date = Date()) -> Int {
        access.value(.savedLooks, installedAt: installedAt, at: now)
    }

    @discardableResult
    mutating func saveCurrentLook(name: String, access: PlusAccess, now: Date = Date()) -> Bool {
        let look = SavedLook(
            name: name,
            speciesID: activeChibi.speciesID,
            costumeID: activeChibi.skinID,
            sceneID: sceneID,
            savedAt: now
        )
        return plus.save(look, limit: savedLookLimit(access, at: now))
    }

    /// Puts a saved combination back on. Every part of it is re-checked against
    /// what is owned, so a look saved on a kin that was let go cannot resurrect it.
    mutating func wearSavedLook(_ id: String) {
        guard let look = plus.savedLooks.first(where: { $0.id == id }) else { return }
        if owned.contains(where: { $0.speciesID == look.speciesID }) {
            activeChibiID = look.speciesID
        }
        wear(look.costumeID)
        if ownedScenes.contains(look.sceneID) { sceneID = look.sceneID }
    }
}
