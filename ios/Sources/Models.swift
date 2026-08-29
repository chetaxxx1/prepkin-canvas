import Foundation

// MARK: - Chibi

/// The 5 preset animations (TFT-style fixed loops). Placeholder art still
/// drives off these states, so real art swaps in without logic changes.
enum ChibiAnimation: String {
    case idle, bounce, celebrate, wave, sleep, dance

    /// How long a one-shot of this animation runs before falling back to idle.
    var duration: Double {
        self == .dance ? 2.98 : 1.6
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

    var reward: Int { kind.reward }
}
