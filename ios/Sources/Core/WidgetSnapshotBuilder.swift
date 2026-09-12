import Foundation

/// Turns the save into the widget's snapshot. The one place the two shapes meet.
extension WidgetSnapshot {
    static func make(from state: GameState, shift: SavedShift?, now: Date = Date()) -> WidgetSnapshot {
        let kin = state.activeChibi
        let tasks = state.tasks.map { t in
            Task(id: t.id, title: t.title, dueAt: t.dueAt, done: t.done,
                 isDaily: t.kind != .canvas && !t.isDated)
        }
        let seed = Int((state.installedAt ?? kin.adoptedAt ?? now).timeIntervalSince1970) % 1_000_003
        return WidgetSnapshot(
            speciesID: kin.speciesID,
            stage: kin.level,
            costumeID: state.activeCostumeID,
            name: kin.displayName,
            kinAsset: SproutImage.asset(speciesID: kin.speciesID, level: kin.level, skin: kin.skinID),
            plainAsset: SproutImage.asset(speciesID: kin.speciesID, level: kin.level, skin: "classic"),
            coins: state.ledger.balance,
            tasks: tasks,
            allDone: state.allDone,
            lastOpenedAt: state.lastOpenedAt,
            shiftEndsAt: shift?.shift().endsAt(at: now),
            checkInHour: state.settings.nudgeHour,
            dayBankSeed: abs(seed),
            day: state.effectiveDay.raw,
            writtenAt: now)
    }
}
