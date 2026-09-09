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
    static let presets: [TaskTemplate] = [
        // Study
        TaskTemplate(id: "s-1", title: "20 min study session", kind: .study, isActive: true, isPreset: true),
        TaskTemplate(id: "s-2", title: "Review today's notes", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-3", title: "Read 10 pages", kind: .study, isActive: false, isPreset: true),
        TaskTemplate(id: "s-4", title: "Redo one question you got wrong", kind: .study, isActive: false, isPreset: true),
        // Life
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
}
