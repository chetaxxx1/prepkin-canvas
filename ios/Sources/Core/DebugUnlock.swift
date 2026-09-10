import Foundation

/// True only in a DEBUG build launched with `-unlockAll`. Views that gate on
/// Plus read this too, so the scanner can be tried on a simulator.
///
/// Sticky, on purpose. A phone trial is installed from Xcode once — which passes the
/// argument — and then opened from the home screen, where no launch argument survives.
/// So the first launch that sees the argument writes it down, and every tap after that
/// still finds the whole catalogue open. It is still `#if DEBUG`, so a shipped build
/// never compiles the reading at all and the remembered bit can never be consulted.
enum DebugUnlock {
    /// Where an earlier launch's argument is remembered. Read by the costume rail too.
    static let stickyKey = "debug.unlockAll"

    static let isOn: Bool = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-unlockAll") {
            UserDefaults.standard.set(true, forKey: stickyKey)
            return true
        }
        return UserDefaults.standard.bool(forKey: stickyKey)
        #else
        return false
        #endif
    }()

    /// Plus on, and **nothing else**. `-plusOn`.
    ///
    /// Separate from `-unlockAll` because the two want opposite things. `-unlockAll`
    /// grants the whole catalogue, which empties the shop's draw pool — so the one
    /// screen that most needs checking at seven slots is the one screen `-unlockAll`
    /// cannot show. This turns the entitlement on and leaves the collection alone,
    /// which is what a walkthrough of the paid surfaces actually needs.
    ///
    /// Not sticky: an entitlement that outlives its launch is the bug this whole
    /// file is one prompt-injection away from. It is `#if DEBUG`, so a shipped build
    /// never compiles the read.
    static let plusOn: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-plusOn")
        #else
        return false
        #endif
    }()
}

#if DEBUG
extension DebugUnlock {
    /// The whole rack the web build ships (`costumes.ts`), plus the plain coat. Owning
    /// all of it is what makes the costume rail read as bought rather than window
    /// shopping, and it is what the extension's shop is told after a sync.
    static let everyCostume: Set<String> = Costume.ids.union(["classic"])
}

extension GameState {
    /// Testing switch: grant the whole catalogue.
    ///
    /// Every kin at stage III (which is where the costume rack lives), every tank, every
    /// costume, and a balance big enough that nothing in the shop is out of reach. For
    /// playing with the art without grinding for it.
    ///
    /// Two guards, on purpose. It is `#if DEBUG`, so it is not compiled into a shipped build at
    /// all; and it only runs behind the `-unlockAll` launch argument, so an ordinary debug run —
    /// including a normal Xcode Run — still starts from the real save. Nothing here can happen by
    /// accident, and a tester's unlocked state can never be mistaken for a real one.
    mutating func unlockEverythingForTesting(now: Date = Date()) {
        for species in ChibiSpecies.catalog where !owned.contains(where: { $0.speciesID == species.id }) {
            owned.append(OwnedChibi(speciesID: species.id, level: 3))
        }
        // Stage III is the one that wears costumes, so put every kin there.
        for i in owned.indices { owned[i].level = 3 }
        ownedScenes = Set(Scene0.all.map(\.id))
        // A tester lands on a fresh device with nothing saved, and first run gates the whole app
        // behind naming a kin. Skip it — this switch exists to get straight to the art.
        firstRunDone = true
        firstRunOffersDone = true
        ownedLooks.formUnion(DebugUnlock.everyCostume)
        // Idempotent by the ledger's own key rule, so relaunching does not stack up balances.
        _ = ledger.post(CoinEntry(key: "debug:unlock-all", amount: 99_000,
                                  reason: .legacy, units: 1, day: DayKey(now), at: now))
    }
}
#endif
