import Foundation

#if DEBUG
extension GameState {
    /// Testing switch: grant the whole catalogue.
    ///
    /// Every kin at stage III (which is where the costume rack lives), every tank, every look,
    /// and a balance big enough that nothing in the shop is out of reach. For playing with the
    /// art without grinding for it.
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
        ownedLooks.formUnion(["classic", "ninja"])
        // Idempotent by the ledger's own key rule, so relaunching does not stack up balances.
        _ = ledger.post(CoinEntry(key: "debug:unlock-all", amount: 99_000,
                                  reason: .legacy, units: 1, day: DayKey(now), at: now))
    }
}
#endif
