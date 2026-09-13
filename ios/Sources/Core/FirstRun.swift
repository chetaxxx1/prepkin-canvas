import Foundation

// The answers the first run asks for, and what each one changes. Every
// question here is asked because a screen after it looks different for a
// different answer (design/ONBOARDING-PROMPT.md). Nothing here is a school
// name, a year, an email or an account.

/// Where the student is in school. One of three, never a school name, never a
/// year. `nil` on the save means the question was skipped, and the app reads
/// that as college — the students it was built for.
enum SchoolLevel: String, Codable, CaseIterable, Identifiable {
    case highSchool, college, gradSchool

    var id: String { rawValue }

    var label: String {
        switch self {
        case .highSchool: return "High school"
        case .college: return "College"
        case .gradSchool: return "Grad school"
        }
    }

    /// Whose Canvas it is, on the Day 1 card and in Your day.
    var canvasOwner: String {
        switch self {
        case .highSchool: return "your school's Canvas"
        case .college: return "your college's Canvas"
        case .gradSchool: return "your university's Canvas"
        }
    }

    /// The shift length Focus opens on.
    var focusMinutes: Int {
        switch self {
        case .highSchool, .college: return 25
        case .gradSchool: return 45
        }
    }

    /// The Learn track that leads the shelf.
    var leadTrackID: String {
        switch self {
        case .highSchool: return "study"
        case .college: return "finance"
        case .gradSchool: return "work"
        }
    }

    /// The preset menu for this kind of school, in the order both the pick-three
    /// screen and Your day show it. Study first, then life. Ids point into
    /// `TaskTemplate.presets`; a preset not listed here is hidden for this level
    /// unless the student has already switched it on.
    var presetIDs: [String] {
        switch self {
        case .highSchool:
            return ["hs-1", "hs-2", "hs-3", "s-1", "s-2", "s-4", "s-3",
                    "l-1", "l-2", "l-3", "l-4", "l-5", "l-6", "l-7", "l-8", "l-9"]
        case .college:
            return ["s-5", "s-8", "s-7", "s-6", "s-1", "s-2", "s-3", "s-4",
                    "l-9", "l-1", "l-2", "l-3", "l-4", "l-5", "l-6", "l-7", "l-8"]
        case .gradSchool:
            return ["gr-1", "gr-2", "gr-3", "gr-4", "s-2", "s-3", "s-1",
                    "l-2", "l-3", "l-9", "l-1", "l-4", "l-5", "l-6", "l-7", "l-8"]
        }
    }

    /// Course names wherever sample data shows (`MockCanvasClient`), so a demo
    /// feed reads like the student's own timetable.
    var sampleCourses: [(name: String, code: String)] {
        switch self {
        case .highSchool: return [("Biology", "BIO"), ("English 11", "ENG 11"), ("US History", "HIST")]
        case .college: return [("Physics 13", "PHYS 13"), ("Writing 5", "WRIT 5"), ("Intro Psych", "PSYC 1")]
        case .gradSchool: return [("Research seminar", "SEM 501"), ("Methods", "METH 510"), ("Thesis", "THS 600")]
        }
    }

    /// What a skipped question reads as.
    static let fallback: SchoolLevel = .college
}

/// What is on the student's plate. Multi-select, at least one; the order they
/// are listed in is the order the screen shows them.
enum PlateItem: String, Codable, CaseIterable, Identifiable {
    case homework, exams, focus, routine, friends, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .homework: return "Homework I keep putting off"
        case .exams: return "Big exams coming"
        case .focus: return "Staying focused"
        case .routine: return "Getting a routine"
        case .friends: return "Studying with friends"
        case .other: return "Something else"
        }
    }

    /// The presets this answer pulls to the front of the suggested three. Ids
    /// that the school level does not list are skipped, so a high-schooler is
    /// never suggested office hours.
    var leadPresetIDs: [String] {
        switch self {
        case .homework: return ["s-6", "hs-2", "gr-1", "s-5", "hs-1", "s-1"]
        case .exams: return ["hs-2", "s-4", "s-2", "s-1", "gr-1"]
        case .focus: return ["s-1", "gr-1", "s-3", "l-2"]
        case .routine: return ["l-3", "l-4", "l-1", "s-2"]
        case .friends: return ["s-8", "hs-3", "gr-4", "l-7"]
        case .other: return []
        }
    }

    /// The lesson Learn opens on because of this answer.
    var firstLessonID: String? {
        switch self {
        case .homework: return "study-6"     // The five-minute start
        case .exams: return "study-1"        // Spaced practice beats cramming
        case .focus: return "psy-2"          // Why you can't stop scrolling
        case .routine: return "psy-6"        // The habit loop
        case .friends: return "ppl-7"        // Group projects that actually get done
        case .other: return nil
        }
    }
}

/// The screens of the first run, in order. Persisted, so a first run that was
/// interrupted at the coat comes back to the coat.
enum FirstRunStep: Int, Codable, CaseIterable, Comparable {
    case welcome, school, plate, coat, name, picks, result

    static func < (a: FirstRunStep, b: FirstRunStep) -> Bool { a.rawValue < b.rawValue }

    /// The thin bar across the top runs over the six question screens; the
    /// welcome has none.
    var progress: Double? {
        guard self != .welcome else { return nil }
        return Double(rawValue) / Double(FirstRunStep.result.rawValue)
    }
}

/// Where the student heard about Prepkin. One of five, stored locally, asked
/// once on the Day 3 card and never again. The marketing plan's one instrument.
enum HeardFrom: String, Codable, CaseIterable, Identifiable {
    case tiktok, friend, appStore, reddit, elsewhere

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tiktok: return "TikTok"
        case .friend: return "A friend"
        case .appStore: return "App Store"
        case .reddit: return "Reddit"
        case .elsewhere: return "Somewhere else"
        }
    }
}

/// The six coats the first run offers. A coat is a colour of the one fish, and
/// each colour has a personality: a title, three traits, one line, and the
/// things it says over the tank on Home.
enum StarterCoat: String, CaseIterable, Identifiable {
    case mint, coral, butter, lilac, peach, sky
    var id: String { rawValue }

    /// Readable colour name for labels: "Mint", "Coral", ...
    var displayName: String { rawValue.capitalized }

    var personality: KinPersonality { KinPersonality.all[self]! }
}

struct KinPersonality: Equatable {
    let title: String
    let traits: [String]
    let line: String
    let greetings: [String]

    /// The Home bubble line for today: `greetings[day % 3]` with the name filled in.
    func greeting(name: String, day: Int) -> String {
        greetings[day % 3].replacingOccurrences(of: "%@", with: name)
    }

    static let all: [StarterCoat: KinPersonality] = [
        .mint: KinPersonality(
            title: "The steady one",
            traits: ["Calm", "Patient", "Early"],
            line: "Gets the reading done before lunch.",
            greetings: ["%@ is here. One thing at a time.",
                        "%@ says the first one is hardest.",
                        "%@ is not counting. Promise."]
        ),
        .coral: KinPersonality(
            title: "The spark",
            traits: ["Bold", "Quick", "Loud"],
            line: "Starts Friday's thing on Monday.",
            greetings: ["%@ is ready when you are.",
                        "%@ wants the big one first.",
                        "%@ says go. Then go again."]
        ),
        .butter: KinPersonality(
            title: "The sunny one",
            traits: ["Warm", "Easy", "Kind"],
            line: "Thinks a walk counts. It does.",
            greetings: ["%@ is glad you opened this.",
                        "%@ says small ones count too.",
                        "%@ is happy either way."]
        ),
        .lilac: KinPersonality(
            title: "The night owl",
            traits: ["Quiet", "Curious", "Late"],
            line: "Does the best work after ten.",
            greetings: ["%@ is up too. No rush.",
                        "%@ likes the quiet hours.",
                        "%@ says start with the odd one."]
        ),
        .peach: KinPersonality(
            title: "The soft one",
            traits: ["Gentle", "Slow", "Sure"],
            line: "Finishes. Just not fast.",
            greetings: ["%@ is here. Take the easy one.",
                        "%@ says slow is still moving.",
                        "%@ is fine with a short list."]
        ),
        .sky: KinPersonality(
            title: "The planner",
            traits: ["Tidy", "Sharp", "Early"],
            line: "Knows what is due before Canvas does.",
            greetings: ["%@ has the list. Top one first.",
                        "%@ says Friday means Thursday.",
                        "%@ checked. You are fine."]
        ),
    ]
}

/// The card that comes first after the first coin.
enum DayOneOffer: Equatable { case notify, canvas }

enum FirstRun {
    /// The three presets ticked on arrival at "Pick three for today": one lead
    /// per plate answer in turn, then the level's own menu top down. Never more
    /// than two of a kind, so Day 1 is never three study tasks or three chores.
    static func suggestedPicks(school: SchoolLevel, plate: [PlateItem],
                               presets: [TaskTemplate]) -> [String] {
        let menu = school.presetIDs
        let byID = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
        var out: [String] = []
        func add(_ id: String) {
            guard out.count < 3, !out.contains(id), menu.contains(id), let t = byID[id] else { return }
            guard out.filter({ byID[$0]?.kind == t.kind }).count < 2 else { return }
            out.append(id)
        }
        let leads = plate.map(\.leadPresetIDs)
        for round in 0..<(leads.map(\.count).max() ?? 0) {
            for list in leads where round < list.count { add(list[round]) }
        }
        menu.forEach(add)
        return out
    }

    /// Exams put the Canvas card first; everything else keeps the check-in first.
    static func firstOffer(plate: [PlateItem]) -> DayOneOffer {
        plate.contains(.exams) ? .canvas : .notify
    }

    /// The lesson Learn leads with on Day 1: the first plate answer that names
    /// one, else the first lesson of the level's lead track.
    static func firstLessonID(school: SchoolLevel, plate: [PlateItem],
                              lessons: [Lesson] = Catalog.lessons) -> String? {
        if let id = plate.compactMap(\.firstLessonID).first, lessons.contains(where: { $0.id == id }) {
            return id
        }
        return lessons.first { $0.trackID == school.leadTrackID }?.id
    }

    /// Tracks with the level's lead first and the rest in catalogue order.
    static func trackOrder(school: SchoolLevel, tracks: [Track] = Catalog.tracks) -> [Track] {
        tracks.filter { $0.id == school.leadTrackID } + tracks.filter { $0.id != school.leadTrackID }
    }

    /// Where the extension lives, for the Day 1 card's share sheet.
    static let extensionURL = URL(string: "https://prepkin.com/chrome")!

    /// What the share sheet carries to the laptop: the link and the code, so
    /// AirDrop, Messages or Mail can hand both over in one go.
    static func shareText(code: String) -> String {
        "Prepkin for Chrome: \(extensionURL.absoluteString)\nYour code: \(code)"
    }
}

// MARK: - On the save

extension GameState {
    /// The level the app runs as: the answer, or college when it was skipped.
    var school: SchoolLevel { schoolLevel ?? .fallback }

    /// The preset menu for this student, per `TaskTemplate.menu`.
    func presetMenu(_ kind: TaskKind? = nil) -> [TaskTemplate] {
        TaskTemplate.menu(templates, for: school).filter { kind == nil || $0.kind == kind }
    }

    /// The coat the starter fish wears, or `nil` for the species default. Only
    /// the starter has a picked coat; every other kin is a coat of its own.
    var pickedCoat: String? {
        guard let picked = starterCoat, StarterCoat(rawValue: picked) != nil else { return nil }
        return picked
    }

    /// The starter's personality: the picked coat's, or mint's when nothing was picked
    /// (old saves from before the pick existed).
    var starterPersonality: KinPersonality {
        StarterCoat(rawValue: starterCoat ?? "")?.personality ?? StarterCoat.mint.personality
    }

    /// What the laptop, the pod and friends are told the kin is. A starter with
    /// a picked coat travels as the coat name: the extension reads one as a
    /// species (`KIN_SPECIES` in content.js) and so does `SproutView.coat`, so
    /// another phone draws the coat that was picked and not its own.
    var publicSpecies: String {
        if activeChibi.speciesID == "slime", let picked = pickedCoat { return picked }
        return activeChibi.speciesID
    }
}
