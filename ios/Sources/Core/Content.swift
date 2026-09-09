import Foundation

// MARK: - Cards

/// The five shapes a card in a deck can take. The variety is what keeps an
/// eight-card deck from reading as one long scroll.
enum CardKind: String, Decodable {
    /// Body copy under the lesson's figure, at some reveal step.
    case figure
    /// Body copy with no figure — for lessons that don't have one drawn yet.
    case text
    /// The one sentence worth screenshotting. No figure, set in caps.
    case key
    /// A worked case, with a small drawn spot rather than the full figure.
    case example
    /// One recall question. Getting it right pays nothing; finishing the deck does.
    case check
}

/// One card in a lesson deck.
///
/// `id` is synthesized from the lesson and the card's position, so a saved card is
/// a pointer into the catalogue rather than a copy of its text. Editing a lesson
/// updates what the student saved, and the save file never carries prose.
struct LessonCard: Identifiable, Equatable {
    let id: String
    let index: Int
    let kind: CardKind
    let body: String
    /// Which reveal step of the lesson's figure this card shows. `nil` on the cards
    /// that carry no figure at all.
    let step: Int?
    let question: String
    let choices: [String]
    let answer: Int
    let why: String

    var isFigure: Bool { kind == .figure && step != nil }
}

/// The JSON shape of a card. Every field is optional so one card kind's keys are
/// simply absent on the others.
private struct RawCard: Decodable {
    var kind: CardKind = .text
    var body = ""
    var step: Int?
    var question = ""
    var choices: [String] = []
    var answer = 0
    var why = ""

    private enum CodingKeys: String, CodingKey {
        case kind, body, step, question, choices, answer, why
    }

    init(kind: CardKind = .text, body: String = "", step: Int? = nil) {
        self.kind = kind
        self.body = body
        self.step = step
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(CardKind.self, forKey: .kind) ?? .text
        body = try c.decodeIfPresent(String.self, forKey: .body) ?? ""
        step = try c.decodeIfPresent(Int.self, forKey: .step)
        question = try c.decodeIfPresent(String.self, forKey: .question) ?? ""
        choices = try c.decodeIfPresent([String].self, forKey: .choices) ?? []
        answer = try c.decodeIfPresent(Int.self, forKey: .answer) ?? 0
        why = try c.decodeIfPresent(String.self, forKey: .why) ?? ""
    }
}

// MARK: - Lessons

struct Lesson: Identifiable, Decodable, Equatable {
    let id: String
    let title: String
    /// A `Track.id`, not a display name.
    let trackID: String
    /// The three lines under "What you'll learn" on the preview sheet.
    let blurb: String
    /// The one line the complete screen says back to you. Falls back to the key idea
    /// when a lesson doesn't state one, so no deck can reach that screen with nothing
    /// to show.
    let takeaway: String
    /// Which drawn figure the deck accretes. `nil` until one is authored, and the
    /// deck falls back to text cards rather than showing an empty half-screen.
    let figure: String?
    let minutes: Int
    let reward: Int
    /// Task categories that make this lesson worth surfacing on Learn. A Canvas quiz
    /// due Friday pulls up the lesson about studying for one.
    let triggers: [TaskCategory]
    let cards: [LessonCard]

    private enum CodingKeys: String, CodingKey {
        case id, title, track, blurb, takeaway, figure, minutes, reward, triggers, cards, pages
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        trackID = try c.decode(String.self, forKey: .track)
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        minutes = try c.decodeIfPresent(Int.self, forKey: .minutes) ?? 2
        reward = try c.decodeIfPresent(Int.self, forKey: .reward) ?? 20
        triggers = (try c.decodeIfPresent([String].self, forKey: .triggers) ?? [])
            .compactMap(TaskCategory.init(rawValue:))

        // A lesson written before typed cards existed is a list of strings. It still
        // reads, as a deck of plain text cards with no figure.
        let raw: [RawCard]
        if let typed = try c.decodeIfPresent([RawCard].self, forKey: .cards) {
            raw = typed
        } else {
            raw = (try c.decodeIfPresent([String].self, forKey: .pages) ?? [])
                .map { RawCard(kind: .text, body: $0) }
        }

        let named = try c.decodeIfPresent(String.self, forKey: .figure)
        // A figure only exists if some card actually reveals a step of it.
        figure = raw.contains { $0.kind == .figure && $0.step != nil } ? named : nil
        let lessonID = id
        cards = raw.enumerated().map { i, r in
            LessonCard(id: "\(lessonID)#\(i)", index: i,
                       // Without a figure to reveal, a figure card is a text card.
                       kind: r.kind == .figure && r.step == nil ? .text : r.kind,
                       body: r.body, step: r.step,
                       question: r.question, choices: r.choices,
                       answer: r.answer, why: r.why)
        }
        takeaway = try c.decodeIfPresent(String.self, forKey: .takeaway)
            ?? cards.first { $0.kind == .key }?.body
            ?? title
    }
}

// MARK: - Tracks

/// A run of lessons. Three exist; each has a hand-drawn icon in `LearnIcons`, which
/// is why the display name and order live in code rather than in the JSON.
struct Track: Identifiable, Equatable {
    let id: String
    let name: String
}

// MARK: - Catalog

/// Text content lives in JSON in the bundle, not in Swift arrays, so writing a
/// lesson or adding a word is an edit to a data file instead of a code change.
///
/// A missing or malformed file never crashes the app — it falls back to a small
/// built-in set and logs, because bad content should degrade, not take the app down.
enum Catalog {
    static let lessons: [Lesson] = load("lessons", fallback: fallbackLessons)
    static let wordleAnswers: [String] = load("words", fallback: fallbackWords)
        .map { $0.uppercased() }
        .filter { $0.count == 5 }

    /// Every word the board will accept as a guess. Much wider than the answers —
    /// a student should be able to burn a try on any real word, not only on the 901
    /// we're willing to make a puzzle out of. The answers are folded in, so a
    /// degraded guesses.json can never make the day's word unguessable.
    static let wordleGuesses: Set<String> = {
        let loaded = load("guesses", fallback: fallbackGuesses)
            .map { $0.uppercased() }
            .filter { $0.count == 5 }
        return Set(loaded).union(wordleAnswers)
    }()

    private static let trackNames = [
        "finance": "Personal finance",
        "philosophy": "Philosophy",
        "study": "Study skills",
        "psychology": "Psychology",
        "people": "People skills",
    ]

    /// Every track the catalogue actually uses, in the order it first appears. A
    /// lesson whose track has no name here still shows up rather than vanishing.
    static let tracks: [Track] = {
        var seen = Set<String>()
        return lessons.compactMap { lesson in
            guard seen.insert(lesson.trackID).inserted else { return nil }
            return Track(id: lesson.trackID,
                         name: trackNames[lesson.trackID] ?? lesson.trackID.capitalized)
        }
    }()

    static func track(_ id: String) -> Track {
        tracks.first { $0.id == id } ?? Track(id: id, name: trackNames[id] ?? id.capitalized)
    }

    static func lessons(in trackID: String) -> [Lesson] {
        lessons.filter { $0.trackID == trackID }
    }

    static func lesson(_ id: String) -> Lesson? {
        lessons.first { $0.id == id }
    }

    /// The card a saved reference points at, or nil if the lesson has since been
    /// rewritten shorter. Callers drop those rather than showing a blank row.
    static func card(_ ref: SavedCard) -> (Lesson, LessonCard)? {
        guard let lesson = lesson(ref.lessonID),
              ref.index < lesson.cards.count else { return nil }
        return (lesson, lesson.cards[ref.index])
    }

    private static func load<T: Decodable>(_ name: String, fallback: T, bundle: Bundle = .main) -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            NSLog("Prepkin: \(name).json missing, using the built-in fallback")
            return fallback
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            NSLog("Prepkin: \(name).json is malformed (\(error)), using the built-in fallback")
            return fallback
        }
    }

    private static let fallbackWords = ["SLIME", "STUDY", "FOCUS", "LEARN", "BRAVE"]

    private static let fallbackGuesses = fallbackWords

    private static let fallbackLessons: [Lesson] = []
}

// MARK: - Because of your week

extension Catalog {
    /// A lesson worth reading because of something actually on the student's plate,
    /// paired with the assignment that earned it a place on the screen.
    struct Suggestion: Identifiable, Equatable {
        let lesson: Lesson
        let task: DailyTask
        var id: String { lesson.id }
    }

    /// Picks lessons off the real Canvas feed by matching the assignment's category
    /// against each lesson's `triggers`. Soonest due first, one lesson per slot, and
    /// nothing already finished.
    ///
    /// Returns empty when Canvas has sent nothing — Learn then simply doesn't draw
    /// the section, rather than showing an empty state for a feature the student
    /// may not have connected.
    static func suggestions(for tasks: [DailyTask],
                            completed: Set<String>,
                            limit: Int = 2) -> [Suggestion] {
        let open = tasks
            .filter { $0.kind == .canvas && !$0.done }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }

        var picked: [Suggestion] = []
        var used = Set<String>()
        for task in open {
            let category = task.category
            guard let lesson = lessons.first(where: {
                $0.triggers.contains(category) && !completed.contains($0.id) && !used.contains($0.id)
            }) else { continue }
            used.insert(lesson.id)
            picked.append(Suggestion(lesson: lesson, task: task))
            if picked.count == limit { break }
        }
        return picked
    }
}

// MARK: - Play puzzles

/// A Crossclimb-type ladder: seven words in order, each one letter off the next,
/// with a clue each. `deal` is the scrambled order the middle five (indices 1...5)
/// are shown in. Words 0 and 6 are the locked top and bottom rungs.
struct LadderPuzzle: Codable, Equatable, RatedPuzzle {
    let words: [String]
    let clues: [String]
    let deal: [Int]
    var rating: Int = Rating.unrated

    init(words: [String], clues: [String], deal: [Int], rating: Int = Rating.unrated) {
        self.words = words; self.clues = clues; self.deal = deal; self.rating = rating
    }

    private enum CodingKeys: String, CodingKey { case words, clues, deal, rating }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        words = try c.decode([String].self, forKey: .words)
        clues = try c.decode([String].self, forKey: .clues)
        deal = try c.decode([Int].self, forKey: .deal)
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? Rating.unrated
    }
}

/// Five clues, hardest first, that share one link. `accept` is the list of words a
/// guess has to contain to count; `name` is what the end card shows.
struct ThreadPuzzle: Codable, Equatable, Identifiable, RatedPuzzle {
    let id: String
    let name: String
    let accept: [String]
    let clues: [String]
    var rating: Int = Rating.unrated

    init(id: String, name: String, accept: [String], clues: [String], rating: Int = Rating.unrated) {
        self.id = id; self.name = name; self.accept = accept; self.clues = clues; self.rating = rating
    }

    private enum CodingKeys: String, CodingKey { case id, name, accept, clues, rating }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        accept = try c.decode([String].self, forKey: .accept)
        clues = try c.decode([String].self, forKey: .clues)
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? Rating.unrated
    }
}

/// A sign between two neighbouring cells: `same` means they match, otherwise
/// they differ. `a` and `b` are [row, column].
struct BalanceSign: Codable, Equatable {
    let a: [Int]
    let b: [Int]
    let same: Bool
}

/// Tango-type Takuzu. `givens` is n×n; -1 blank, 0 sun, 1 moon.
struct BalancePuzzle: Codable, Equatable, RatedPuzzle {
    let n: Int
    let givens: [[Int]]
    var signs: [BalanceSign] = []
    var rating: Int = Rating.unrated

    init(n: Int, givens: [[Int]], signs: [BalanceSign] = [], rating: Int = Rating.unrated) {
        self.n = n; self.givens = givens; self.signs = signs; self.rating = rating
    }

    private enum CodingKeys: String, CodingKey { case n, givens, signs, rating }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        n = try c.decode(Int.self, forKey: .n)
        givens = try c.decode([[Int]].self, forKey: .givens)
        signs = try c.decodeIfPresent([BalanceSign].self, forKey: .signs) ?? []
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? Rating.unrated
    }
}

/// Zip-type path puzzle. `numbers` is n×n, 0 for no number; `walls` are pairs of
/// cell indices (r*n+c) the line may not cross between.
struct TracePuzzle: Codable, Equatable, RatedPuzzle {
    let n: Int
    let numbers: [[Int]]
    let walls: [[Int]]
    var rating: Int = Rating.unrated

    init(n: Int, numbers: [[Int]], walls: [[Int]], rating: Int = Rating.unrated) {
        self.n = n; self.numbers = numbers; self.walls = walls; self.rating = rating
    }

    private enum CodingKeys: String, CodingKey { case n, numbers, walls, rating }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        n = try c.decode(Int.self, forKey: .n)
        numbers = try c.decode([[Int]].self, forKey: .numbers)
        walls = try c.decode([[Int]].self, forKey: .walls)
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? Rating.unrated
    }
}

/// Star Battle, one star. `regions` is n×n of region ids 0..<n.
struct PearlsPuzzle: Codable, Equatable, RatedPuzzle {
    let n: Int
    let regions: [[Int]]
    var rating: Int = Rating.unrated

    init(n: Int, regions: [[Int]], rating: Int = Rating.unrated) {
        self.n = n; self.regions = regions; self.rating = rating
    }

    private enum CodingKeys: String, CodingKey { case n, regions, rating }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        n = try c.decode(Int.self, forKey: .n)
        regions = try c.decode([[Int]].self, forKey: .regions)
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? Rating.unrated
    }
}

extension Catalog {
    /// Dealt by design/games/gen.py, which checks every puzzle has one answer that
    /// a rule-only solver can reach. The app never runs a solver; it only counts.
    static let ladders: [LadderPuzzle] = load("ladders", fallback: fallbackLadders)
    static let threads: [ThreadPuzzle] = load("threads", fallback: fallbackThreads)
    static let balance: [BalancePuzzle] = load("balance", fallback: fallbackBalance)
    static let pearls: [PearlsPuzzle] = load("pearls", fallback: fallbackPearls)
    static let trace: [TracePuzzle] = load("trace", fallback: fallbackTrace)

    /// One of each, so a missing file still deals a playable puzzle.
    static let fallbackLadders = [LadderPuzzle(
        words: ["BLAND", "BLEND", "BLIND", "BLINK", "BRINK", "BRISK", "BRICK"],
        clues: ["Lacking flavor", "Mix in a smoothie", "Window shade", "Quick eye shut",
                "Edge of a cliff", "Quick and energetic", "Wall building block"],
        deal: [3, 1, 5, 2, 4])]
    static let fallbackTrace = [TracePuzzle(n: 4, numbers: [
        [1, 0, 0, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [4, 0, 0, 3]], walls: [])]
    private static let fallbackThreads = [ThreadPuzzle(
        id: "card", name: "___ card", accept: ["card"],
        clues: ["Wild", "Green", "Report", "Business", "Credit"])]
    private static let fallbackBalance = [BalancePuzzle(n: 6, givens: [
        [ 1,  0, -1, -1, -1, -1],
        [-1,  0,  0, -1, -1, -1],
        [-1, -1,  1, -1, -1,  1],
        [-1, -1, -1, -1, -1, -1],
        [-1, -1,  0,  0, -1,  0],
        [-1, -1,  1, -1, -1,  1]])]
    private static let fallbackPearls = [PearlsPuzzle(n: 7, regions: [
        [1, 1, 0, 0, 0, 0, 6],
        [1, 3, 4, 2, 0, 6, 6],
        [3, 3, 4, 2, 2, 6, 6],
        [4, 3, 4, 6, 6, 6, 6],
        [4, 4, 4, 4, 4, 6, 6],
        [4, 5, 5, 5, 4, 6, 6],
        [4, 4, 4, 5, 6, 6, 6]])]
}
