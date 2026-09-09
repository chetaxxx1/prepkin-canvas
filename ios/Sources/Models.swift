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
    /// 1...5. Drives `Theme.tier` — the name plate, the cost badge and a 2pt card
    /// border, and nothing else. A tier is a price band made visible, never a gate:
    /// every kin is buyable the moment the coins are there.
    let tier: Int
}

extension ChibiSpecies {
    /// The whole ladder. It never gets longer and nothing on it ever leaves.
    static let catalog: [ChibiSpecies] = [
        ChibiSpecies(id: "slime",   name: "Moss",    price: 0,    tier: 1),
        ChibiSpecies(id: "ember",   name: "Ember",   price: 300,  tier: 2),
        ChibiSpecies(id: "droplet", name: "Droplet", price: 400,  tier: 3),
        ChibiSpecies(id: "sprout",  name: "Sprout",  price: 500,  tier: 3),
        ChibiSpecies(id: "wisp",    name: "Wisp",    price: 800,  tier: 4),
        ChibiSpecies(id: "comet",   name: "Comet",   price: 1200, tier: 5),
        // Lane 3, "edge" (2026-09-04): two new Sprout-repo types on the same pear rig.
        // Names are placeholders until George picks. `axolotl-coral` is the same
        // rig in the coral coat.
        ChibiSpecies(id: "orca",          name: "Orca",  price: 900,  tier: 4),
        ChibiSpecies(id: "axolotl",       name: "Axel",  price: 700,  tier: 4),
        ChibiSpecies(id: "axolotl-coral", name: "Rosa",  price: 700,  tier: 4),
    ]

    static func find(_ id: String) -> ChibiSpecies {
        catalog.first { $0.id == id } ?? catalog[0]
    }
}

struct OwnedChibi: Codable, Equatable {
    let speciesID: String
    var level: Int  // 1...3, rendered as star pips — never as "Lv N"
    /// What the student called it. `nil` for a kin adopted before naming existed, and
    /// for the starter slime until they name it; display falls back to the species.
    var name: String?
    /// When it arrived. `nil` only on saves written before this field existed; the
    /// v4 migration fills those from the oldest ledger line.
    var adoptedAt: Date?
    /// The app-wide totals the moment this kin arrived. Its own card counts up
    /// from here, so a kin adopted this morning does not claim last month's work.
    /// `nil` on older saves, which read as "since the beginning".
    var statsAtAdoption: LifetimeStats?
    /// The Sprout look this kin wears — `classic` or `ninja`. Per kin, not per
    /// account, so one kin in the suit does not put every kin in it.
    var skinID: String = "classic"

    init(speciesID: String, level: Int, name: String? = nil, adoptedAt: Date? = nil,
         statsAtAdoption: LifetimeStats? = nil, skinID: String = "classic") {
        self.speciesID = speciesID
        self.level = level
        self.name = name
        self.adoptedAt = adoptedAt
        self.statsAtAdoption = statsAtAdoption
        self.skinID = skinID
    }

    var species: ChibiSpecies { ChibiSpecies.find(speciesID) }

    /// The name to print. Never empty, never a placeholder.
    var displayName: String { name?.isEmpty == false ? name! : species.name }
    var isNamed: Bool { name?.isEmpty == false }

    static let upgradeCost: [Int: Int] = [1: 100, 2: 250]  // cost to leave this level
    var nextUpgradeCost: Int? { level < 3 ? Self.upgradeCost[level] : nil }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey { case speciesID, level, name, adoptedAt, skinID }

    /// Tolerant, for the same reason `GameState`'s decoder is: a save written before
    /// `name` and `adoptedAt` existed must still load. The synthesized decoder would
    /// throw on the first missing key, and a throw here fails the whole file — which
    /// reads to the student as every coin gone.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        speciesID = try c.decodeIfPresent(String.self, forKey: .speciesID) ?? "slime"
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
        name = try c.decodeIfPresent(String.self, forKey: .name)
        adoptedAt = try c.decodeIfPresent(Date.self, forKey: .adoptedAt)
        skinID = try c.decodeIfPresent(String.self, forKey: .skinID) ?? "classic"
    }
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
    /// Life care, by object. `lifeCare` (the water glass) is the fallback.
    case walk, sleep, meal
    /// Five life presets used to collapse onto two glyphs — every unmapped one fell
    /// through to the water glass, so "Text someone you like" and "Tidy your desk"
    /// both poured a drink. One object each, and the fallback means what it says.
    case stretch, outdoors, connect, tidy

    /// Checked in this order — "Ch. 5 Problem Set" has to land on the ruler, not the
    /// book, and "20 min study session" on flashcards, not the ruler.
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

    /// Life presets get their own object each; "Drink a glass of water" keeps the
    /// glass and anything unrecognised falls back to it.
    /// First match wins, so the narrow words come before the broad ones: "stretch"
    /// and "outside" used to sit in `.walk` and swallowed two presets that are not
    /// walks.
    private static let lifeKeywords: [(TaskCategory, [String])] = [
        (.walk,     ["walk", "run", "steps", "gym", "workout"]),
        (.stretch,  ["stretch", "yoga", "mobility", "foam roll"]),
        (.outdoors, ["outside", "outdoors", "fresh air", "sunlight", "sunshine"]),
        (.sleep,    ["bed", "sleep", "phone down", "lights", "wind down"]),
        (.connect,  ["text", "call", "message", "someone", "friend", "family"]),
        (.tidy,     ["tidy", "desk", "clean", "clear", "make your bed", "laundry"]),
        (.meal,     ["breakfast", "lunch", "dinner", "eat", "meal", "snack", "fruit"]),
    ]

    static func of(_ task: DailyTask) -> TaskCategory {
        let title = task.title.lowercased()
        if task.kind == .life {
            for (category, words) in lifeKeywords where words.contains(where: title.contains) {
                return category
            }
            return .lifeCare
        }
        for (category, words) in keywords where words.contains(where: title.contains) {
            return category
        }
        return task.kind == .study ? .study : .reading
    }
}

extension DailyTask {
    var category: TaskCategory { TaskCategory.of(self) }
}

// MARK: - Saved cards

/// A card the student hearted. Holds a pointer into the catalogue, never the prose,
/// so the save file stays small and editing a lesson updates what was kept.
struct SavedCard: Codable, Equatable, Identifiable {
    let lessonID: String
    let index: Int
    let savedAt: Date

    var id: String { "\(lessonID)#\(index)" }
}

// MARK: - Card reports

/// Why a student flagged a card. Raw values are written to the save file, so they
/// are stable strings rather than the display copy.
enum CardReportReason: String, Codable, CaseIterable, Identifiable {
    case typo
    case wrong
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .typo: return "Typo"
        case .wrong: return "Wrong or misleading"
        case .other: return "Other"
        }
    }
}

/// A card the student flagged as broken. Kept on the device — there is nowhere to
/// send it yet — and points at the catalogue the same way `SavedCard` does.
struct CardReport: Codable, Equatable, Identifiable {
    let lessonID: String
    let cardIndex: Int
    let reason: CardReportReason
    let date: Date

    var id: String { "\(lessonID)#\(cardIndex)@\(date.timeIntervalSince1970)" }
}
