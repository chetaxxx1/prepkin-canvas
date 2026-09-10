import Foundation

/// A shift that is still running, written down.
///
/// The clock used to live only in `FocusView`'s `@State`, which is fine while the app
/// is on screen and wrong the moment it is not. iOS kills a backgrounded app under
/// memory pressure, and a 45-minute shift spends all of it backgrounded — that is the
/// point of the tab. Without this, the lock screen would say "Shift over. 45 coins
/// paid." over a save file where nothing was paid, which is the one thing this tab
/// may never do.
///
/// So: one small record, written on every change of state, read on the way in. It
/// carries `id` because that is the ledger's idempotency key — a shift restored twice
/// still pays once.
struct SavedShift: Codable, Equatable {
    let id: String
    let minutes: Int
    /// Time from legs already finished.
    let banked: TimeInterval
    /// When the current leg began. `nil` while paused.
    let legStart: Date?
    let workingOnID: String?
    /// A shift the student explicitly said was about nothing in particular, which is
    /// not the same as one they never chose for.
    let workingOnCleared: Bool

    var isPaused: Bool { legStart == nil }

    /// The clock this record describes.
    func shift() -> FocusShift {
        var s = FocusShift()
        s.restore(minutes: minutes, banked: banked, legStart: legStart)
        return s
    }

    var workingOn: WorkingOn {
        if let workingOnID { return .task(workingOnID) }
        return workingOnCleared ? .nothing : .auto
    }
}

/// Where the running shift is kept. `UserDefaults`, not `GameState`: this is a fact
/// about the next few minutes, not part of the save, and it must never end up inside
/// something a sync could overwrite.
enum ShiftStore {
    static let key = "focus.runningShift"

    static func load(_ defaults: UserDefaults = .standard) -> SavedShift? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedShift.self, from: data)
    }

    static func save(_ shift: SavedShift, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(shift) else { return }
        defaults.set(data, forKey: key)
    }

    static func clear(_ defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
