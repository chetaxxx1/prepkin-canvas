import Foundation
import WidgetKit

/// Reads and writes the save file.
///
/// Three things this fixes over the old single `UserDefaults` blob:
/// 1. **A version number.** The file says which schema wrote it, so the next model
///    change runs a migration instead of failing to decode and silently starting
///    everyone from zero coins.
/// 2. **A backup.** The previous good file is kept. A half-written or corrupt file
///    falls back to it, and the bad one is set aside rather than overwritten.
/// 3. **Coalesced writes.** Checking off a task no longer encodes the whole world
///    on the main thread mid-animation.
final class Store {
    /// Bump when `GameState`'s shape changes, and add a step to `migrate`.
    static let currentVersion = 6

    /// The v1 shape: the `snapshot2` blob in UserDefaults, from before there was a file.
    static let legacyDefaultsKey = "snapshot2"

    static let shared = Store()

    private struct Envelope: Codable {
        var version: Int
        var state: GameState
    }

    private let directory: URL
    private let fileURL: URL
    private let backupURL: URL
    /// Where `widget.json` goes: the app group, so the widget can read it.
    private let widgetDirectory: URL
    private let defaults: UserDefaults
    private let io = DispatchQueue(label: "com.prepkin.canvas.store", qos: .utility)
    private let lock = NSLock()
    private var pending: GameState?
    /// How long to wait for the taps to stop before writing.
    private let debounce: TimeInterval

    init(directory: URL? = nil, defaults: UserDefaults = .standard, debounce: TimeInterval = 0.6,
         widgetDirectory: URL? = nil) {
        let base = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrepkinCanvas", isDirectory: true)
        self.directory = base
        fileURL = base.appendingPathComponent("state.json")
        backupURL = base.appendingPathComponent("state.backup.json")
        // A store given its own folder (the tests) keeps the widget file there too,
        // so a test run never rewrites the phone's real widget.
        self.widgetDirectory = widgetDirectory ?? (directory == nil ? AppGroup.container : base)
        self.defaults = defaults
        self.debounce = debounce
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }

    // MARK: - Loading

    func load() -> GameState {
        if let state = read(fileURL) { return state }
        if let state = read(backupURL) {
            NSLog("Prepkin: main save unreadable, recovered from backup")
            return state
        }
        if let legacy = loadLegacyDefaults() {
            NSLog("Prepkin: migrated the old UserDefaults save into the state file")
            save(legacy, immediately: true)
            return legacy
        }
        // A phone with no save has just installed. Stamp it now: this is the only
        // moment the date is knowable, and every later release depends on it.
        var fresh = GameState()
        fresh.installedAt = Date()
        return fresh
    }

    private func read(_ url: URL) -> GameState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let envelope = try? Self.decoder.decode(Envelope.self, from: data) else {
            quarantine(url)
            return nil
        }
        return migrate(envelope)
    }

    /// A file we could not decode is moved aside, never deleted — if a migration is
    /// ever wrong, the user's real data is still on disk to recover from.
    private func quarantine(_ url: URL) {
        let dead = directory.appendingPathComponent("state.unreadable-\(Int(Date().timeIntervalSince1970)).json")
        try? FileManager.default.moveItem(at: url, to: dead)
        NSLog("Prepkin: could not read \(url.lastPathComponent), set aside as \(dead.lastPathComponent)")
    }

    /// Runs a decoded file forward to the current schema. Each future version adds
    /// one step here; nothing else in the app needs to know the file is old.
    private func migrate(_ envelope: Envelope) -> GameState {
        var state = envelope.state
        // v2 was the first file-based schema. v3 added Canvas courses, grades and
        // submission state; no step is needed for it, because `GameState` now
        // reads every field with a fallback, so a missing key is not an error.
        //
        // v4 added the Kin tab: a kin now knows when it arrived, and lifetime totals
        // are counted as work happens instead of read back out of the ledger. Both
        // need seeding, because a missing key here is not a zero — it is a fact the
        // old file never wrote down.
        if envelope.version < 4 {
            let firstLine = state.ledger.entries.map(\.at).min() ?? Date()
            for i in state.owned.indices where state.owned[i].adoptedAt == nil {
                state.owned[i].adoptedAt = firstLine
            }
            // Only what the ledger still holds can be counted. Lines already folded
            // into the opening balance are gone, so an old save starts its totals a
            // little low rather than claiming a number it cannot show its work for.
            if state.lifetime == LifetimeStats() {
                for e in state.ledger.entries {
                    switch e.reason {
                    case .task: state.lifetime.tasksFinished += e.units
                    case .focus: state.lifetime.focusMinutes += e.units
                    case .lesson: state.lifetime.lessonsRead += e.units
                    default: break
                    }
                }
            }
        }
        // v5 made friends real. Everything a v4 file holds about them is now untrue:
        // its `friends` are the four invented rows the tab used to draw, its
        // `pendingFriendCodes` were never sent anywhere (that key is simply gone,
        // so it drops on decode), and its `friendCode` was generated on this phone,
        // which means nobody could ever have looked it up. All three go, and the
        // real ones arrive from `my_code` and `fetch_friends` on the next open.
        if envelope.version < 5 {
            state.friends = []
            state.friendCode = nil
        }
        // v6 wrote down when a phone first ran Prepkin, so a release that ever
        // lowers a free number can leave the people who were already here on the
        // old one (`PlusGate.restriction`). An old file has no such date, so it is
        // read off the oldest ledger line — the same trick v4 used for `adoptedAt`.
        // An empty ledger means a save that has never earned a coin, and the
        // earliest honest answer for that one is now.
        if envelope.version < 6, state.installedAt == nil {
            state.installedAt = state.ledger.entries.map(\.at).min() ?? Date()
        }
        state.advance()
        return state
    }

    // MARK: - Saving

    func save(_ state: GameState, immediately: Bool = false) {
        lock.lock()
        pending = state
        lock.unlock()
        if immediately {
            io.sync { self.writePending() }
        } else {
            io.asyncAfter(deadline: .now() + debounce) { [weak self] in self?.writePending() }
        }
    }

    /// Writes any waiting change right now. Call when the app goes to the background.
    func flush() {
        io.sync { self.writePending() }
    }

    /// Takes whatever is waiting and writes it. A no-op when an earlier write already
    /// took it, so the debounce can fire as often as it likes.
    private func writePending() {
        lock.lock()
        let state = pending
        pending = nil
        lock.unlock()
        guard let state else { return }
        guard let data = try? Self.encoder.encode(Envelope(version: Self.currentVersion, state: state))
        else { return }
        // Keep the last good file before replacing it.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        }
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Prepkin: save failed — \(error.localizedDescription)")
        }
        writeWidgetSnapshot(state)
    }

    // MARK: - The widget's copy

    /// Writes `widget.json` beside the save and asks WidgetKit to redraw. Also
    /// called on its own when a shift starts or pauses, which changes nothing in
    /// the save but does change the widget's line.
    func writeWidgetSnapshot(_ state: GameState, now: Date = Date()) {
        let snapshot = WidgetSnapshot.make(from: state, shift: ShiftStore.load(defaults), now: now)
        snapshot.write(to: widgetDirectory)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - v1: the old UserDefaults blob

    struct LegacyWeek: Codable { var key: String? }

    struct LegacySnapshot: Codable {
        var coins: Int
        var owned: [OwnedChibi]
        var activeChibiID: String
        var tasks: [DailyTask]
        var completedLessons: Set<String>
        var week: LegacyWeek?
        var savedOn: Date
        var sceneID: String?
        var ownedScenes: Set<String>?
    }

    private func loadLegacyDefaults(now: Date = Date()) -> GameState? {
        guard let data = defaults.data(forKey: Self.legacyDefaultsKey),
              let old = try? Self.legacyDecoder.decode(LegacySnapshot.self, from: data) else { return nil }
        return Self.fromLegacy(old, now: now)
    }

    /// Carries a v1 blob forward. The balance is preserved exactly: today's finished
    /// tasks become real ledger lines, and the opening balance is the rest, so the
    /// coin count on screen after the upgrade is the same number as before it.
    ///
    /// One known loss, accepted once: weekly counters from before the upgrade are not
    /// reconstructed, because the old blob never recorded when anything happened.
    static func fromLegacy(_ old: LegacySnapshot, now: Date = Date()) -> GameState {
        var state = GameState()
        let today = DayKey(now)

        state.owned = old.owned.isEmpty ? [OwnedChibi(speciesID: "slime", level: 1)] : old.owned
        state.activeChibiID = old.activeChibiID
        state.completedLessons = old.completedLessons
        // Land scenes became tanks; `Scene0.find` maps a retired id onto its tank.
        state.sceneID = Scene0.find(old.sceneID ?? "").id
        state.ownedScenes = Set((old.ownedScenes ?? []).map { Scene0.find($0).id })
        state.ownedScenes.insert(Scene0.all[0].id)
        state.currentDay = today
        state.maxDayReached = today

        // Old saves held task instances. Turn the ones the user chose back into rules.
        let carriedToday = Calendar.current.isDate(old.savedOn, inSameDayAs: now)
        var templates = TaskTemplate.presets.map { p -> TaskTemplate in
            var t = p; t.isActive = false; return t
        }
        for task in old.tasks where task.kind != .canvas {
            if let i = templates.firstIndex(where: { $0.id == task.id }) {
                templates[i].isActive = true
            } else {
                templates.append(TaskTemplate(id: task.id, title: task.title, kind: task.kind))
            }
        }
        state.templates = templates
        state.canvasItems = old.tasks.filter { $0.kind == .canvas }.map {
            CanvasItem(id: $0.id, title: $0.title, courseName: $0.detail ?? "", dueAt: $0.dueAt)
        }

        // Today's finished tasks become real ledger lines, and the opening balance
        // is whatever makes the total come out to the old number exactly. It can be
        // negative — a user who earned 30 today and spent 25 of it had 5 on screen,
        // and 5 is what they keep.
        let doneToday = carriedToday ? old.tasks.filter(\.done) : []
        let canvasIDs = Set(state.canvasItems.map(\.id))
        let entries = doneToday.map { task in
            CoinEntry(key: canvasIDs.contains(task.id) ? state.canvasKey(task.id)
                                                       : state.taskKey(task.id, on: today),
                      amount: task.reward, reason: .task, day: today, at: old.savedOn)
        }
        let replayed = entries.reduce(0) { $0 + $1.amount }
        state.ledger = Ledger(openingBalance: old.coins - replayed, entries: entries)
        // A v1 blob predates every gate, so this phone was here first and keeps
        // whatever a later release ever lowers. The blob never wrote down when it
        // arrived; the day it was last saved is the earliest date it can prove.
        state.installedAt = old.savedOn
        return state
    }

    // MARK: - Coders

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    /// The old save was written by a bare `JSONEncoder()`, so its dates are raw
    /// numbers rather than ISO-8601 strings. Reading it with the current decoder
    /// throws, and the user silently starts over at zero coins.
    static let legacyDecoder = JSONDecoder()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
