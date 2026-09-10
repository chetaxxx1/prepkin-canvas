import Foundation

enum Recurrence: String, Codable, CaseIterable {
    case daily      // comes back every morning
    case once       // disappears after the day it is finished
}

/// The *rule* for a task, not today's copy of it.
///
/// Storing templates instead of task instances is what makes rollover safe: a new
/// day regenerates the list from these, so nothing can be left checked overnight and
/// no instance can be orphaned in a stale array. Canvas tasks are never templates —
/// they come from the sync and own their own due dates.
struct TaskTemplate: Codable, Equatable, Identifiable {
    let id: String
    var title: String
    var kind: TaskKind          // .study or .life
    var recurrence: Recurrence
    /// Life presets the user hasn't picked are kept but switched off, so turning one
    /// back on doesn't lose its history.
    var isActive: Bool
    /// Built-in suggestion vs. something the user typed. Presets can't be deleted.
    var isPreset: Bool
    /// Set when a `once` task is finished, so rollover knows to retire it.
    var retiredOn: DayKey?

    init(id: String, title: String, kind: TaskKind, recurrence: Recurrence = .daily,
         isActive: Bool = true, isPreset: Bool = false, retiredOn: DayKey? = nil) {
        self.id = id
        self.title = title
        self.kind = kind
        self.recurrence = recurrence
        self.isActive = isActive
        self.isPreset = isPreset
        self.retiredOn = retiredOn
    }
}

extension TaskTemplate {
    /// The built-in menu. Everything here is offered in the day editor; the ones
    /// marked active below are what a brand-new user starts with.
    /// Order is the menu. Both screens that show this list — first run's pick-three
    /// and the day editor — read it top down, and the day editor only shows the
    /// first three of each kind before "more". So the ones a 19-year-old actually
    /// has on their plate lead, and the wellness habits follow. They are all still
    /// here; a student who wants the water reminder is two taps away from it.
    static let presets: [TaskTemplate] = [
        // Study
        TaskTemplate(id: "s-5", title: "Read for one class", kind: .study, isActive: true, isPreset: true),
        TaskTemplate(id: "s-6", title: "Start the thing due Friday", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-7", title: "Email a professor", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-8", title: "Go to office hours", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-1", title: "20 min study session", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-2", title: "Review today's notes", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-3", title: "Read 10 pages", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-4", title: "Redo one question you got wrong", kind: .study, isActive: false, isPreset: true),
        // Life
        TaskTemplate(id: "l-9", title: "Laundry", kind: .life, isActive: false, isPreset: true),
        TaskTemplate(id: "l-1", title: "Drink a glass of water", kind: .life, isActive: true, isPreset: true),
        TaskTemplate(id: "l-2", title: "10 minute walk", kind: .life, isActive: true, isPreset: true),
        TaskTemplate(id: "l-3", title: "In bed by 11", kind: .life, isActive: true, isPreset: true),
        TaskTemplate(id: "l-4", title: "Eat breakfast", kind: .life, isActive: false, isPreset: true),
        TaskTemplate(id: "l-5", title: "5 minute stretch", kind: .life, isActive: false, isPreset: true),
        TaskTemplate(id: "l-6", title: "Step outside", kind: .life, isActive: false, isPreset: true),
        TaskTemplate(id: "l-7", title: "Text someone you like", kind: .life, isActive: false, isPreset: true),
        TaskTemplate(id: "l-8", title: "Tidy your desk", kind: .life, isActive: false, isPreset: true),
    ]

    static func starterSet() -> [TaskTemplate] { presets }

    /// Saved templates plus any preset the catalogue has gained since that save was
    /// written, switched off.
    ///
    /// Without this a student who installed in August never sees a preset added in
    /// September: `templates` is stored whole, and nothing merged the menu back in.
    /// Presets come back in catalogue order so a new lead item actually leads;
    /// anything the student typed themselves keeps its place at the end.
    static func addingMissingPresets(to saved: [TaskTemplate]) -> [TaskTemplate] {
        let have = Set(saved.map(\.id))
        let missing = presets.filter { !have.contains($0.id) }.map { p -> TaskTemplate in
            var t = p; t.isActive = false; return t
        }
        guard !missing.isEmpty else { return saved }
        let rank = Dictionary(uniqueKeysWithValues: presets.enumerated().map { ($1.id, $0) })
        let ordered = (saved.filter(\.isPreset) + missing)
            .sorted { (rank[$0.id] ?? 0) < (rank[$1.id] ?? 0) }
        return ordered + saved.filter { !$0.isPreset }
    }
}
