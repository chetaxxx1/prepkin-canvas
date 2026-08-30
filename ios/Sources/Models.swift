import Foundation

// MARK: - Chibi

/// The 5 preset animations (TFT-style fixed loops). Placeholder art still
/// drives off these states, so real art swaps in without logic changes.
enum ChibiAnimation: String {
    case idle, bounce, celebrate, wave, sleep, dance, peek, startle, slump

    /// How long a one-shot of this animation runs before falling back to idle.
    var duration: Double {
        switch self {
        case .dance: return 2.98
        case .peek: return SlimePeek.duration
        case .celebrate: return SlimeCelebrate.duration
        case .bounce: return SlimeJump.duration
        case .wave: return SlimeWave.duration
        case .startle: return SlimeStartle.duration
        case .slump: return SlimeSlump.duration
        default: return 1.6
        }
    }
}

struct ChibiSpecies: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let price: Int   // coins; 0 = starter
}

extension ChibiSpecies {
    static let catalog: [ChibiSpecies] = [
        ChibiSpecies(id: "slime", name: "Slime", price: 0),
        ChibiSpecies(id: "ember", name: "Ember", price: 300),
        ChibiSpecies(id: "droplet", name: "Droplet", price: 400),
        ChibiSpecies(id: "sprout", name: "Sprout", price: 500),
    ]
}

struct OwnedChibi: Codable, Equatable {
    let speciesID: String
    var level: Int  // 1...3

    var species: ChibiSpecies {
        ChibiSpecies.catalog.first { $0.id == speciesID } ?? ChibiSpecies.catalog[0]
    }

    static let upgradeCost: [Int: Int] = [1: 100, 2: 250]  // cost to leave this level
    var nextUpgradeCost: Int? { level < 3 ? Self.upgradeCost[level] : nil }
}

// MARK: - Tasks

enum TaskKind: String, Codable {
    case canvas, study, life

    var reward: Int {
        switch self {
        case .canvas: return 30
        case .study: return 20
        case .life: return 10
        }
    }

    var label: String {
        switch self {
        case .canvas: return "Canvas"
        case .study: return "Study"
        case .life: return "Life"
        }
    }
}

struct DailyTask: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let kind: TaskKind
    var detail: String?     // e.g. course name
    var dueAt: Date?
    var done: Bool = false
    /// Canvas says this was handed in, so the check-off is not the student's to
    /// undo. Only ever true for synced work.
    var isLocked: Bool = false

    var reward: Int { kind.reward }
}

// MARK: - Task categories

/// What object rides in a task row's tile. Canvas gives us a title and a course but
/// no assignment type, so the category is read off the title, falling back to the
/// task's own kind. Life-care tasks never go through the keyword pass.
enum TaskCategory: String, Codable, CaseIterable {
    case reading, writing, problemSet, labs, study, lifeCare

    /// Checked in this order — "Ch. 5 Problem Set" has to land on the ruler, not the
    /// book, and "20 min SAT practice" on flashcards, not the ruler.
    private static let keywords: [(TaskCategory, [String])] = [
        (.labs,       ["lab", "project", "writeup", "write-up", "report", "presentation",
                       "experiment", "poster"]),
        (.writing,    ["essay", "outline", "draft", "discussion", "write", "paper",
                       "journal", "reflection", "response"]),
        (.study,      ["quiz", "test", "exam", "review", "flashcard", "vocab", "sat",
                       "study", "memoriz", "notes"]),
        (.problemSet, ["problem", "pset", "homework", "hw", "practice", "worksheet",
                       "exercise", "set"]),
        (.reading,    ["read", "chapter", "ch.", "article", "textbook", "pages", "book"]),
    ]

    static func of(_ task: DailyTask) -> TaskCategory {
        if task.kind == .life { return .lifeCare }
        let title = task.title.lowercased()
        for (category, words) in keywords where words.contains(where: title.contains) {
            return category
        }
        return task.kind == .study ? .study : .reading
    }
}

extension DailyTask {
    var category: TaskCategory { TaskCategory.of(self) }
}
