import Foundation

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
    static let currentVersion = 2

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
    private let defaults: UserDefaults
    private let io = DispatchQueue(label: "com.prepkin.canvas.store", qos: .utility)
    private let lock = NSLock()
    private var pending: GameState?
    /// How long to wait for the taps to stop before writing.
    private let debounce: TimeInterval

    init(directory: URL? = nil, defaults: UserDefaults = .standard, debounce: TimeInterval = 0.6) {
        let base = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrepkinCanvas", isDirectory: true)
        self.directory = base
        fileURL = base.appendingPathComponent("state.json")
        backupURL = base.appendingPathComponent("state.backup.json")
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
        return GameState()
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
        // v2 is the first file-based schema. Later versions chain from here, e.g.
        // if envelope.version < 3 { state = Self.v2ToV3(state) }
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
              let old = try? Self.decoder.decode(LegacySnapshot.self, from: data) else { return nil }
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
        state.sceneID = old.sceneID ?? "dorm"
        state.ownedScenes = old.ownedScenes ?? ["dorm"]
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

        let doneToday = carriedToday ? old.tasks.filter(\.done) : []
        let spentOnDone = doneToday.reduce(0) { $0 + $1.reward }
        state.ledger = Ledger(openingBalance: max(0, old.coins - spentOnDone))
        for task in doneToday {
            state.complete(taskID: task.id, reward: task.reward, now: old.savedOn)
        }
        return state
    }

    // MARK: - Coders

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
