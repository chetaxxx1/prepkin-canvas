import XCTest
@testable import PrepkinCanvas

/// The first run's answers, and what each one changes (`FirstRun.swift`).
final class FirstRunTests: XCTestCase {

    private let presets = TaskTemplate.presets

    // MARK: - School

    /// Every answer has its own preset list, and the lists differ where the
    /// prompt says they must.
    func testSchoolAnswerPicksThePresetList() {
        let hs = TaskTemplate.menu(presets, for: .highSchool).map(\.title)
        let college = TaskTemplate.menu(presets, for: .college).map(\.title)
        let grad = TaskTemplate.menu(presets, for: .gradSchool).map(\.title)

        XCTAssertEqual(Array(hs.prefix(3)), ["Read the chapter", "Study for the quiz", "Ask the teacher"])
        XCTAssertEqual(Array(college.prefix(3)), ["Read for one class", "Go to office hours", "Email a professor"])
        XCTAssertTrue(college.contains("Laundry"))
        XCTAssertEqual(Array(grad.prefix(4)), ["Write for 25 minutes", "Meet my advisor", "Lab notebook", "TA hours"])

        XCTAssertFalse(hs.contains("Go to office hours"), "a high-schooler has no office hours")
        XCTAssertFalse(grad.contains("Ask the teacher"))
        XCTAssertFalse(college.contains("Lab notebook"))
    }

    /// Every id a level lists is a real preset, so no level can show a blank row.
    func testEveryLevelIDIsInTheCatalogue() {
        let ids = Set(presets.map(\.id))
        for level in SchoolLevel.allCases {
            for id in level.presetIDs { XCTAssertTrue(ids.contains(id), "\(level) lists \(id)") }
            XCTAssertEqual(level.presetIDs.count, Set(level.presetIDs).count, "\(level) repeats an id")
        }
    }

    /// A preset the student switched on stays on their menu even after the level
    /// stops listing it; nothing they chose is taken away.
    func testMenuKeepsAnActivePresetTheLevelDoesNotList() {
        var t = presets
        t[t.firstIndex { $0.id == "s-8" }!].isActive = true   // office hours, on
        let hs = TaskTemplate.menu(t, for: .highSchool)
        XCTAssertEqual(hs.last?.id, "s-8")
        XCTAssertFalse(hs.contains { $0.id == "s-7" }, "an inactive unlisted preset stays hidden")
    }

    func testSchoolAnswerSetsFocusDefault() {
        XCTAssertEqual(SchoolLevel.highSchool.focusMinutes, 25)
        XCTAssertEqual(SchoolLevel.college.focusMinutes, 25)
        XCTAssertEqual(SchoolLevel.gradSchool.focusMinutes, 45)
        for level in SchoolLevel.allCases {
            XCTAssertTrue(FocusView.freeLengths.contains(level.focusMinutes), "\(level) opens on a Plus length")
        }
    }

    func testSchoolAnswerSetsCanvasWording() {
        XCTAssertEqual(SchoolLevel.highSchool.canvasOwner, "your school's Canvas")
        XCTAssertEqual(SchoolLevel.college.canvasOwner, "your college's Canvas")
        XCTAssertEqual(SchoolLevel.gradSchool.canvasOwner, "your university's Canvas")
    }

    func testSchoolAnswerSetsTheLearnLead() {
        XCTAssertEqual(FirstRun.trackOrder(school: .highSchool).first?.id, "study")
        XCTAssertEqual(FirstRun.trackOrder(school: .college).first?.id, "finance")
        XCTAssertEqual(FirstRun.trackOrder(school: .gradSchool).first?.id, "work")
        // Every track is still on the shelf, once.
        for level in SchoolLevel.allCases {
            XCTAssertEqual(FirstRun.trackOrder(school: level).map(\.id).sorted(),
                           Catalog.tracks.map(\.id).sorted())
        }
    }

    func testSchoolAnswerSetsTheSampleCourses() async throws {
        let hs = try await MockCanvasClient(school: .highSchool).fetchTodo()
        let grad = try await MockCanvasClient(school: .gradSchool).fetchTodo()
        XCTAssertEqual(hs.courses.map(\.name), ["Biology", "English 11", "US History"])
        XCTAssertEqual(grad.courses.first?.name, "Research seminar")
        XCTAssertNotEqual(hs.tasks.map(\.courseName), grad.tasks.map(\.courseName))
    }

    /// A skipped question runs the app as college, and nothing else is stored.
    func testSkippedSchoolReadsAsCollege() {
        var g = GameState()
        XCTAssertNil(g.schoolLevel)
        XCTAssertEqual(g.school, .college)
        g.schoolLevel = .gradSchool
        XCTAssertEqual(g.presetMenu(.study).first?.id, "gr-1")
    }

    /// Home lists the day's presets in the level's order, so the row the first
    /// run led with is the first row on Home, whatever the catalogue's order.
    func testHomeRowsFollowTheLevelOrder() {
        var g = GameState()
        g.schoolLevel = .highSchool
        for t in g.templates where t.isPreset { g.setTemplate(t.id, active: ["s-4", "hs-2", "l-1"].contains(t.id)) }
        XCTAssertEqual(g.tasks.map(\.id), ["hs-2", "s-4", "l-1"])
        g.addTask(title: "Call home", kind: .life, recurrence: .daily, id: "x")
        XCTAssertEqual(g.tasks.last?.title, "Call home", "the student's own tasks follow the presets")
    }

    // MARK: - Plate

    /// The plate answer reorders the three suggested picks, inside the level's list.
    func testPlateReordersTheSuggestedPicks() {
        let exams = FirstRun.suggestedPicks(school: .highSchool, plate: [.exams], presets: presets)
        XCTAssertEqual(exams.first, "hs-2", "exams lead with the quiz")
        XCTAssertEqual(exams.count, 3)

        let routine = FirstRun.suggestedPicks(school: .college, plate: [.routine], presets: presets)
        XCTAssertEqual(routine.first, "l-3", "a routine leads with bed by 11")

        let none = FirstRun.suggestedPicks(school: .college, plate: [], presets: presets)
        XCTAssertEqual(none, ["s-5", "s-8", "l-9"], "no plate: the level's own top two study picks and first life pick")

        // Never a college row for a high-schooler, whatever the plate says.
        let friends = FirstRun.suggestedPicks(school: .highSchool, plate: [.friends], presets: presets)
        XCTAssertFalse(friends.contains("s-8"))
        XCTAssertEqual(friends.first, "hs-3")
    }

    /// Three every time, at most two of a kind, for every level and every plate.
    func testSuggestedPicksAreAlwaysThreeAndMixed() {
        let byID = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
        for level in SchoolLevel.allCases {
            for item in PlateItem.allCases {
                let picks = FirstRun.suggestedPicks(school: level, plate: [item], presets: presets)
                XCTAssertEqual(picks.count, 3, "\(level) \(item)")
                XCTAssertEqual(Set(picks).count, 3, "\(level) \(item) repeats")
                let study = picks.filter { byID[$0]?.kind == .study }.count
                XCTAssertTrue((1...2).contains(study), "\(level) \(item): \(study) study picks")
            }
            let all = FirstRun.suggestedPicks(school: level, plate: PlateItem.allCases, presets: presets)
            XCTAssertEqual(all.count, 3)
        }
    }

    func testPlateOrdersTheDayOneOffers() {
        XCTAssertEqual(FirstRun.firstOffer(plate: [.exams]), .canvas)
        XCTAssertEqual(FirstRun.firstOffer(plate: [.focus, .exams]), .canvas)
        XCTAssertEqual(FirstRun.firstOffer(plate: [.focus]), .notify)
        XCTAssertEqual(FirstRun.firstOffer(plate: []), .notify)
    }

    func testPlatePicksTheFirstLesson() {
        XCTAssertEqual(FirstRun.firstLessonID(school: .college, plate: [.focus]), "psy-2")
        XCTAssertEqual(FirstRun.firstLessonID(school: .college, plate: [.other, .exams]), "study-1")
        // Nothing named: the lead track's first lesson.
        XCTAssertEqual(FirstRun.firstLessonID(school: .gradSchool, plate: []), "work-1")
        XCTAssertEqual(FirstRun.firstLessonID(school: .highSchool, plate: [.other]), "study-1")
        for item in PlateItem.allCases {
            if let id = item.firstLessonID { XCTAssertNotNil(Catalog.lesson(id), "\(item) names a missing lesson") }
        }
    }

    // MARK: - Resume

    /// The step and every answer survive a save, so a killed app comes back to
    /// the same screen with the same things ticked.
    func testFlowResumesAtTheSavedStep() throws {
        var g = GameState()
        XCTAssertEqual(g.firstRunStep, .welcome)
        g.firstRunStep = .coat
        g.schoolLevel = .highSchool
        g.plate = [.exams, .friends]
        g.starterCoat = "coral"
        let back = try Store.decoder.decode(GameState.self, from: Store.encoder.encode(g))
        XCTAssertEqual(back.firstRunStep, .coat)
        XCTAssertEqual(back.schoolLevel, .highSchool)
        XCTAssertEqual(back.plate, [.exams, .friends])
        XCTAssertEqual(back.pickedCoat, "coral")
        XCTAssertFalse(back.firstRunDone)

        // A save from before these fields existed decodes to the start, done.
        let old = #"{"activeChibiID": "slime", "sceneID": "dorm"}"#.data(using: .utf8)!
        let existing = try Store.decoder.decode(GameState.self, from: old)
        XCTAssertEqual(existing.firstRunStep, .welcome)
        XCTAssertNil(existing.schoolLevel)
        XCTAssertNil(existing.pickedCoat)
        XCTAssertTrue(existing.firstRunDone)
    }

    func testProgressBarRunsOverTheQuestions() {
        XCTAssertNil(FirstRunStep.welcome.progress)
        XCTAssertEqual(FirstRunStep.school.progress!, 1.0 / 6, accuracy: 0.001)
        XCTAssertEqual(FirstRunStep.result.progress, 1)
    }

    // MARK: - Coat

    /// The picked coat draws the starter fish and travels to the laptop as a
    /// coat name, which the extension already reads as a species.
    func testPickedCoatDrawsTheStarterAndReachesTheBridge() {
        var g = GameState()
        XCTAssertNil(g.pickedCoat)
        XCTAssertEqual(g.publicSpecies, "slime")
        g.starterCoat = "lilac"
        XCTAssertEqual(g.pickedCoat, "lilac")
        XCTAssertEqual(g.bridgeState.kin?.species, "lilac")
        g.starterCoat = "plaid"
        XCTAssertNil(g.pickedCoat, "an unknown coat draws the default rather than a blank")

        SproutView.starterCoat = "coral"
        defer { SproutView.starterCoat = nil }
        XCTAssertEqual(SproutImage.asset(speciesID: "slime", level: 1, skin: "classic"), "sprout-coral-1")
        XCTAssertEqual(SproutImage.asset(speciesID: "ember", level: 1, skin: "classic"), "sprout-coral-1",
                       "other kin keep their own coat")
        XCTAssertEqual(SproutImage.asset(speciesID: "lilac", level: 2, skin: "classic"), "sprout-lilac-2",
                       "a friend's starter arrives as its coat name and draws as that")
    }

    func testEveryStarterCoatHasAStill() {
        for coat in StarterCoat.allCases {
            XCTAssertNotNil(UIImage(named: "sprout-\(coat.rawValue)-1"), coat.rawValue)
        }
    }

    /// Every personality fits the coat card and Home's one-line bubble.
    func testEveryStarterCoatHasAShortPersonality() {
        for coat in StarterCoat.allCases {
            guard let personality = KinPersonality.all[coat] else {
                XCTFail("\(coat) has no personality")
                continue
            }
            XCTAssertEqual(coat.personality, personality)
            XCTAssertLessThanOrEqual(personality.title.count, 18, personality.title)
            XCTAssertEqual(personality.traits.count, 3, "\(coat) needs three traits")
            for trait in personality.traits {
                XCTAssertLessThanOrEqual(trait.count, 9, trait)
                XCTAssertEqual(trait, trait.capitalized, trait)
                XCTAssertEqual(trait.split(whereSeparator: { $0.isWhitespace }).count, 1, trait)
            }
            XCTAssertLessThanOrEqual(personality.line.count, 40, personality.line)
            XCTAssertFalse(personality.line.contains("!"), personality.line)
            XCTAssertEqual(personality.greetings.count, 3, "\(coat) needs three greetings")
            for greeting in personality.greetings {
                let named = greeting.replacingOccurrences(of: "%@", with: "Marigold")
                XCTAssertLessThanOrEqual(named.count, 40, named)
                XCTAssertFalse(named.contains("!"), named)
            }
        }
    }

    func testPersonalityGreetingCyclesByDayAndIncludesTheName() {
        let personality = StarterCoat.coral.personality
        let greetings = (0...3).map { personality.greeting(name: "Marigold", day: $0) }
        XCTAssertEqual(Array(greetings.prefix(3)), [
            "Marigold is ready when you are.",
            "Marigold wants the big one first.",
            "Marigold says go. Then go again.",
        ])
        XCTAssertEqual(greetings[3], greetings[0])
        for greeting in greetings { XCTAssertTrue(greeting.contains("Marigold"), greeting) }
    }

    func testSavedCoatPicksThePersonalityAndOldSavesUseMint() {
        var game = GameState()
        game.starterCoat = "sky"
        XCTAssertEqual(game.starterPersonality, StarterCoat.sky.personality)
        XCTAssertEqual(game.starterPersonality.title, "The planner")
        game.starterCoat = nil
        XCTAssertEqual(game.starterPersonality, StarterCoat.mint.personality)
        game.starterCoat = "unknown"
        XCTAssertEqual(game.starterPersonality, StarterCoat.mint.personality)
    }

    func testSixStarterCoatRawValuesRoundTrip() {
        let rawValues = ["mint", "coral", "butter", "lilac", "peach", "sky"]
        XCTAssertEqual(StarterCoat.allCases.count, 6)
        XCTAssertEqual(StarterCoat.allCases.map(\.rawValue), rawValues)
        for rawValue in rawValues {
            XCTAssertEqual(StarterCoat(rawValue: rawValue)?.rawValue, rawValue)
        }
    }

    // MARK: - Day 3

    /// The attribution answer stores one of five and the card shows once.
    func testHeardFromStoresOneOfFiveOnce() throws {
        var g = GameState()
        XCTAssertFalse(g.heardFromDone)
        XCTAssertEqual(HeardFrom.allCases.count, 5)
        g.heardFrom = .reddit
        g.heardFromDone = true
        let back = try Store.decoder.decode(GameState.self, from: Store.encoder.encode(g))
        XCTAssertEqual(back.heardFrom, .reddit)
        XCTAssertTrue(back.heardFromDone)
        XCTAssertThrowsError(try Store.decoder.decode(HeardFrom.self, from: "\"billboard\"".data(using: .utf8)!))
    }

    @MainActor
    func testDayThreeWaitsForDayThree() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("firstrun-\(UUID().uuidString)")
        let store = Store(directory: dir, defaults: UserDefaults(suiteName: "firstrun-\(UUID().uuidString)")!,
                          debounce: 0)
        let state = AppState(store: store, makeClient: { _ in nil })
        // A phone that installed today is on Day 1: neither later card is due.
        XCTAssertFalse(state.isDayOrLater(2))
        XCTAssertFalse(state.isDayOrLater(3))
        XCTAssertFalse(state.heardFromDone)
        state.answerHeardFrom(.tiktok)
        XCTAssertTrue(state.heardFromDone)
        XCTAssertEqual(state.game.heardFrom, .tiktok)
        state.answerHeardFrom(nil)
        XCTAssertNil(state.game.heardFrom, "Not now stores nothing")
    }

    func testDayCountingFromTheInstallDate() {
        let cal = Calendar.current
        let noon = cal.date(from: DateComponents(year: 2026, month: 9, day: 12, hour: 12))!
        func installed(daysAgo: Int) -> Date { cal.date(byAdding: .day, value: -daysAgo, to: noon)! }
        XCTAssertFalse(FirstRunTests.dayOrLater(3, installed: installed(daysAgo: 0), now: noon))
        XCTAssertFalse(FirstRunTests.dayOrLater(3, installed: installed(daysAgo: 1), now: noon))
        XCTAssertTrue(FirstRunTests.dayOrLater(3, installed: installed(daysAgo: 2), now: noon))
        XCTAssertFalse(FirstRunTests.dayOrLater(2, installed: installed(daysAgo: 0), now: noon))
        XCTAssertTrue(FirstRunTests.dayOrLater(2, installed: installed(daysAgo: 1), now: noon))
    }

    /// The same arithmetic as `AppState.isDayOrLater`, on a bare date.
    private static func dayOrLater(_ n: Int, installed: Date, now: Date, calendar: Calendar = .current) -> Bool {
        let start = calendar.startOfDay(for: now)
        let cutoff = calendar.date(byAdding: .day, value: -(n - 2), to: start)!
        return installed < cutoff
    }

    // MARK: - Copy

    /// Every string on the flow's own screens is under 40 characters. The one
    /// line George wrote longer — the welcome pitch — is listed here on purpose.
    func testFirstRunCopyIsShort() {
        let strings = SchoolLevel.allCases.map(\.label)
            + PlateItem.allCases.map(\.label)
            + HeardFrom.allCases.map(\.label)
            + SchoolLevel.allCases.map(\.canvasOwner)
            + ["Meet your fish", "Have a friend code?", "Already use Prepkin on another phone?",
               "Where are you in school?", "What's on your plate?", "Pick your coat", "Meet",
               "What do you want to name your kin?", "You can change this later.",
               "Pick three for today", "Your day is set.", "That's the whole thing.", "Let's go",
               "Your Canvas homework can live here.", "I'm at my laptop", "Send the link to my laptop",
               "Your friend's code goes here.", "They see your fish, never your coins.",
               "How did you hear about Prepkin?",
               "No accounts here.", "Your fish and coins stay on this phone.",
               "Canvas work follows your laptop link.", "Pair Chrome with this phone's code.",
               "Add them after setup. Two minutes.", "By continuing you accept the",
               "A coat is a colour. Each one is Sprout.",
               "Finish one. " + String(repeating: "M", count: 14) + " gets paid."]
        for s in strings {
            XCTAssertLessThan(s.count, 40, "\"\(s)\" is \(s.count) characters")
            XCTAssertFalse(s.contains("!"), s)
        }
    }

    func testShareTextCarriesTheLinkAndTheCode() {
        let text = FirstRun.shareText(code: "ABCD-EFGH")
        XCTAssertTrue(text.contains("https://prepkin.com/chrome"))
        XCTAssertTrue(text.contains("ABCD-EFGH"))
        XCTAssertFalse(text.contains("!"))
    }
}
