import Foundation

/// Lifetime totals behind the Kin tab's "together since" strip.
///
/// These are counted as the work happens rather than read back out of the ledger,
/// because `Ledger` folds lines older than its window into the opening balance. A
/// derived count would quietly shrink, and the whole promise of this strip is that
/// nothing on it ever goes down on its own.
struct LifetimeStats: Codable, Equatable {
    var tasksFinished = 0
    var canvasFinished = 0
    var focusMinutes = 0
    var lessonsRead = 0
}

/// One offer in the shop's picks row. A pick is a **discount**, never an item you can
/// miss — everything here is also in the Collection at full price, forever.
struct ShopPick: Identifiable, Equatable {
    enum Kind: Equatable { case kin(ChibiSpecies), scene(Scene0) }

    let id: String          // "kin:ember" / "scene:meadow"
    let kind: Kind

    /// Every pick in a row is off by the same amount. There is no rare discount to
    /// chase, and there never is one: the number is 20 for everyone and 30 for
    /// Plus (`PlusGate.shopDiscount`), set once when the row is resolved.
    ///
    /// It is a field rather than a constant because it is the one number on a pick
    /// that money moves. Every item is still in the Collection at `fullPrice`
    /// forever, which is the sentence that keeps this off the wrong side of "coins
    /// are never sold".
    var discountPercent: Int = PlusGate.shopDiscount.free

    var fullPrice: Int {
        switch kind {
        case .kin(let s): return s.price
        case .scene(let s): return s.price
        }
    }
    var price: Int {
        Int((Double(fullPrice) * (1 - Double(discountPercent) / 100)).rounded())
    }

    var name: String {
        switch kind {
        case .kin(let s): return s.name
        case .scene(let s): return s.name
        }
    }

    /// Scenes borrow the tier ramp so one row can hold both kinds without a second
    /// colour language: they band by price, exactly as kin do.
    var tier: Int {
        switch kind {
        case .kin(let s): return s.tier
        case .scene(let s):
            switch s.price {
            case 0..<200: return 1
            case 200..<400: return 2
            case 400..<700: return 3
            case 700..<1100: return 4
            default: return 5
            }
        }
    }
}

// MARK: - Picks, locking and adoption

extension GameState {

    // MARK: Picks

    /// Slots in today's row, rerolls a day, holds, and the percent off — all four
    /// read from the one gate table so a reviewer can see what money changes by
    /// reading `PlusGate`, not by reading the shop.
    ///
    /// `plusIsOn` is a plain stored flag rather than a lookup because these are read
    /// inside SwiftUI bodies dozens of times a frame. `AppState` keeps it current;
    /// it is deliberately not in `CodingKeys`, because an entitlement that survives
    /// in a save file is an entitlement that outlives the subscription.
    /// The free slot count, as a constant the views can compare against without
    /// reading an entitlement of their own.
    static let pickSlotsFree = PlusGate.shopSlots.free
    var pickSlots: Int { PlusGate.value(.shopSlots, isPlus: plusIsOn, installedAt: installedAt) }
    var holdLimit: Int { PlusGate.value(.shopHolds, isPlus: plusIsOn, installedAt: installedAt) }
    var discountPercent: Int { PlusGate.value(.shopDiscount, isPlus: plusIsOn, installedAt: installedAt) }

    /// Everything the student does not own yet, kin first, then scenes. This is the
    /// pool the row draws from, and it is also exactly the Collection minus what they
    /// already have — so a reroll can never take away a thing they wanted.
    var pickPool: [String] {
        ChibiSpecies.catalog
            .filter { s in !owned.contains { $0.speciesID == s.id } }
            .map { "kin:\($0.id)" }
        + Scene0.all
            .filter { !ownedScenes.contains($0.id) }
            .map { "scene:\($0.id)" }
    }

    func resolvePick(_ id: String) -> ShopPick? {
        let parts = id.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "kin":
            guard let s = ChibiSpecies.catalog.first(where: { $0.id == parts[1] }) else { return nil }
            return ShopPick(id: id, kind: .kin(s), discountPercent: discountPercent)
        case "scene":
            guard let s = Scene0.all.first(where: { $0.id == parts[1] }) else { return nil }
            return ShopPick(id: id, kind: .scene(s), discountPercent: discountPercent)
        default: return nil
        }
    }

    var picks: [ShopPick] { shopPicks.compactMap(resolvePick) }

    /// Rolls the row over at the day boundary, and keeps it stable inside a day —
    /// the same row comes back after a relaunch, so nothing feels snatched away.
    mutating func refreshPicksIfNeeded(now: Date = Date()) {
        let day = effectiveDay
        if shopPickDay != day {
            shopPickDay = day
            rerollCount = 0
            drawPicks()
        } else if shopPicks.isEmpty || shopPicks.contains(where: { !isStillAvailable($0) }) {
            // Something in the row was bought. Backfill rather than leave a hole.
            drawPicks()
        } else if shopPicks.count != min(pickSlots, pickPool.count + shopPicks.count) {
            // Plus turned on or off mid-day and the row is the wrong length now.
            // Redrawing keeps the two extra slots from waiting until tomorrow, and
            // held slots survive it because `drawPicks` keeps them first.
            drawPicks()
        }
    }

    /// Free, but three a day. Unlimited rerolls made "today's picks" mean nothing —
    /// the row was whatever you shuffled to. Three keeps the discount honest and
    /// still costs no coins.
    static let rerollsPerDay = PlusGate.shopRerolls.free
    var rerollsPerDay: Int { PlusGate.value(.shopRerolls, isPlus: plusIsOn, installedAt: installedAt) }
    var rerollsLeft: Int { max(0, rerollsPerDay - rerollCount) }

    /// Whether a reroll could actually change the row.
    ///
    /// Late on, when there is less left to own than the row has slots, every draw
    /// is the same draw. Spending one of three free rerolls to watch nothing move
    /// is worse than not offering it, so the Shop asks this first.
    var rerollCanChange: Bool { pickPool.count > pickSlots }

    @discardableResult
    mutating func rerollPicks() -> Bool {
        guard rerollsLeft > 0 else { return false }
        rerollCount += 1
        drawPicks()
        return true
    }

    /// Holding a slot keeps its discount through every reroll and overnight into
    /// tomorrow's row. The only shop control kept from TFT, because it is the only
    /// one that can only help.
    mutating func toggleLock(_ id: String) {
        if lockedPicks.contains(id) {
            lockedPicks.remove(id)
        } else if lockedPicks.count < holdLimit {
            lockedPicks.insert(id)
        }
    }

    /// Whether one more slot can be held. The Shop asks before it offers, so a
    /// long-press that cannot do anything is never offered in the first place.
    func canHoldMore(_ id: String) -> Bool {
        lockedPicks.contains(id) || lockedPicks.count < holdLimit
    }

    private func isStillAvailable(_ id: String) -> Bool { pickPool.contains(id) }

    /// Drawn evenly over everything unowned — a Legendary has exactly the same chance
    /// as a Common. There are no weights and no hidden odds table, which is what the
    /// honesty panel says out loud.
    private mutating func drawPicks() {
        var pool = pickPool
        // Held slots come back first, in the row's own order so they do not shuffle
        // around underneath a student who is holding them on purpose.
        let held = shopPicks.filter { lockedPicks.contains($0) }
        let extra = lockedPicks.subtracting(held).sorted()
        var kept: [String] = []
        for id in held + extra where pool.contains(id) {
            kept.append(id)
            pool.removeAll { $0 == id }
        }
        // Anything held that was bought stops holding a slot.
        lockedPicks = lockedPicks.intersection(pool).union(kept)

        var rng = SplitMix64(seed: Self.seed(day: shopPickDay, nonce: rerollCount))
        var drawn: [String] = []
        while !pool.isEmpty && drawn.count < pickSlots - kept.count {
            drawn.append(pool.remove(at: Int(rng.next() % UInt64(pool.count))))
        }
        shopPicks = kept + drawn
    }

    private static func seed(day: DayKey, nonce: Int) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in day.raw.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h &+ UInt64(bitPattern: Int64(nonce)) &* 0x9E3779B97F4A7C15
    }

    // MARK: Buying a pick

    /// What this id costs right now: the pick price if it is in today's row, the
    /// Collection price otherwise. Never more than the Collection price.
    func currentPrice(_ id: String) -> Int {
        guard let pick = resolvePick(id) else { return 0 }
        return shopPicks.contains(id) ? pick.price : pick.fullPrice
    }

    /// The gap to a purchase, stated as work rather than as a shortfall. Prefers
    /// Canvas assignments because they are the biggest single line and the most
    /// likely thing already waiting on the student's list.
    func workToAfford(_ id: String) -> String? {
        let gap = currentPrice(id) - ledger.balance
        guard gap > 0 else { return nil }
        let canvas = TaskKind.canvas.reward
        let assignments = gap / canvas
        if assignments >= 1 {
            let rest = gap - assignments * canvas
            let plural = assignments == 1 ? "assignment" : "assignments"
            if rest <= 0 { return "That's \(assignments) more \(plural) finished." }
            return "That's \(assignments) more \(plural) finished, and a lesson."
        }
        return "That's one lesson, or a 25-minute focus session."
    }

    // MARK: Adoption

    /// Buys a kin at today's price and stamps the date it arrived. Naming happens
    /// after, on its own screen, and can be skipped.
    @discardableResult
    mutating func adopt(_ species: ChibiSpecies, now: Date = Date()) -> Bool {
        guard !owned.contains(where: { $0.speciesID == species.id }) else { return false }
        let price = currentPrice("kin:\(species.id)")
        guard ledger.post(CoinEntry(key: "species:\(species.id)", amount: -price,
                                    reason: .species, day: effectiveDay, at: now)) else { return false }
        owned.append(OwnedChibi(speciesID: species.id, level: 1, adoptedAt: now,
                                statsAtAdoption: lifetime))
        activeChibiID = species.id
        lockedPicks.remove("kin:\(species.id)")
        refreshPicksIfNeeded(now: now)
        return true
    }

    mutating func rename(_ speciesID: String, to name: String) {
        guard let i = owned.firstIndex(where: { $0.speciesID == speciesID }) else { return }
        let clean = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(14))
        owned[i].name = clean.isEmpty ? nil : clean
    }

    /// Names offered by the Shuffle die. Short, soft, and none of them a person's
    /// name, so a student never has to un-pick something that landed oddly.
    static let shuffleNames = ["Moss", "Pip", "Bramble", "Tuck", "Sprig", "Bean",
                              "Juniper", "Clover", "Pebble", "Wren", "Fig", "Marlow",
                              "Nimbus", "Cricket", "Olive", "Bodhi"]

    // MARK: Together since

    /// Days including today, so a kin adopted this morning reads "Day 1", never 0.
    func daysTogether(_ kin: OwnedChibi, now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let from = kin.adoptedAt else { return 1 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: from),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        return max(1, days + 1)
    }

    /// What has happened since this kin arrived. The starter, and any kin from a
    /// save older than the snapshot, get the whole history.
    func stats(since kin: OwnedChibi) -> LifetimeStats {
        guard let base = kin.statsAtAdoption else { return lifetime }
        return LifetimeStats(tasksFinished: max(0, lifetime.tasksFinished - base.tasksFinished),
                             canvasFinished: max(0, lifetime.canvasFinished - base.canvasFinished),
                             focusMinutes: max(0, lifetime.focusMinutes - base.focusMinutes),
                             lessonsRead: max(0, lifetime.lessonsRead - base.lessonsRead))
    }

    func canvasFinished(since kin: OwnedChibi) -> Int? {
        canvasFinishedOrNil == nil ? nil : stats(since: kin).canvasFinished
    }

    var canvasFinishedOrNil: Int? {
        // A code on its own is only an invitation — the app mints one the moment the
        // connect screen opens, so keying off `pairingCode` counted a student as
        // connected before any laptop had ever answered, and printed a hard 0 they
        // had no way to earn. A received list is the real test.
        (lastCanvasSyncAt == nil && canvasItems.isEmpty && lifetime.canvasFinished == 0)
            ? nil : lifetime.canvasFinished
    }
}

/// A small deterministic generator, so today's row is the same row after a relaunch.
/// `SystemRandomNumberGenerator` would reshuffle the shop every time the view loaded.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
