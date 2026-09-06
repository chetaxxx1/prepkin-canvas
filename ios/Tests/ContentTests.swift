import XCTest
@testable import PrepkinCanvas

/// These read the real files out of the built app bundle, so a JSON typo or a
/// resource that quietly stopped being copied fails here instead of on a phone.
final class ContentTests: XCTestCase {
    func testLessonsLoadFromTheBundle() {
        XCTAssertFalse(Catalog.lessons.isEmpty, "lessons.json did not load")
        for lesson in Catalog.lessons {
            XCTAssertFalse(lesson.cards.isEmpty, "\(lesson.id) has no cards")
            XCTAssertFalse(lesson.title.isEmpty)
            XCTAssertFalse(lesson.blurb.isEmpty, "\(lesson.id) has no preview blurb")
            XCTAssertFalse(lesson.takeaway.isEmpty, "\(lesson.id) has no takeaway")
            XCTAssertGreaterThan(lesson.reward, 0)
            XCTAssertFalse(Catalog.track(lesson.trackID).name.isEmpty)
        }
    }

    func testLessonIDsAreUnique() {
        let ids = Catalog.lessons.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// A deck ends in a recall question, and the question has to be answerable.
    func testEveryDeckHasAWellFormedCheck() {
        for lesson in Catalog.lessons {
            guard let check = lesson.cards.last(where: { $0.kind == .check }) else {
                return XCTFail("\(lesson.id) has no check card")
            }
            XCTAssertFalse(check.question.isEmpty, "\(lesson.id) check has no question")
            XCTAssertFalse(check.why.isEmpty, "\(lesson.id) check has no explanation")
            XCTAssertGreaterThanOrEqual(check.choices.count, 2, "\(lesson.id)")
            XCTAssertTrue(check.choices.indices.contains(check.answer),
                          "\(lesson.id) check answer \(check.answer) is out of range")
        }
    }

    /// Copy that isn't a check card has to have something on it, or the reader shows
    /// a blank screen the student can't get anything from.
    func testEveryOtherCardHasCopy() {
        for lesson in Catalog.lessons {
            for card in lesson.cards where card.kind != .check {
                XCTAssertFalse(card.body.isEmpty, "\(lesson.id) card \(card.index) is blank")
            }
        }
    }

    /// The accretion rule: a figure deck's reveal steps only ever go up. A step that
    /// went backwards would make the drawing lose a layer mid-lesson.
    func testFigureStepsOnlyGoForward() {
        for lesson in Catalog.lessons where lesson.figure != nil {
            let steps = lesson.cards.compactMap(\.step)
            XCTAssertEqual(steps, steps.sorted(), "\(lesson.id) reveals a figure out of order")
            XCTAssertEqual(steps.first, 1, "\(lesson.id) does not start from a bare figure")
        }
    }

    /// A lesson naming a figure nothing can draw would leave half the card empty.
    func testNamedFiguresAreDrawable() {
        for lesson in Catalog.lessons where lesson.figure != nil {
            XCTAssertTrue(LessonFigure.exists(lesson.figure),
                          "\(lesson.id) names figure '\(lesson.figure!)' with no drawing")
        }
    }

    func testTracksComeOutInCatalogueOrder() {
        XCTAssertEqual(Catalog.tracks.map(\.id), ["finance", "philosophy", "study", "psychology", "people"])
        for track in Catalog.tracks {
            XCTAssertFalse(Catalog.lessons(in: track.id).isEmpty)
        }
    }

    /// The legacy `pages: [String]` shape still reads, so an old content file — or a
    /// half-migrated one — degrades to plain text cards instead of failing to decode.
    func testLegacyPagesStillDecode() throws {
        let json = """
        [{"id": "old-1", "title": "Old", "track": "study", "emoji": "🧠",
          "pages": ["one", "two"]}]
        """.data(using: .utf8)!
        let lessons = try JSONDecoder().decode([Lesson].self, from: json)
        XCTAssertEqual(lessons.first?.cards.count, 2)
        XCTAssertEqual(lessons.first?.cards.first?.kind, .text)
        XCTAssertNil(lessons.first?.figure)
        XCTAssertEqual(lessons.first?.takeaway, "Old")
    }

    /// A card marked `figure` with no step has nothing to reveal, so it reads as text
    /// rather than sitting under an empty white box.
    func testFigureCardWithoutAStepBecomesText() throws {
        let json = """
        [{"id": "x", "title": "X", "track": "study", "figure": "compound",
          "cards": [{"kind": "figure", "body": "hello"}]}]
        """.data(using: .utf8)!
        let lesson = try JSONDecoder().decode([Lesson].self, from: json)[0]
        XCTAssertEqual(lesson.cards[0].kind, .text)
        XCTAssertNil(lesson.figure)
    }

    func testEveryWordIsFiveLetters() {
        XCTAssertFalse(Catalog.wordleAnswers.isEmpty, "words.json did not load")
        XCTAssertTrue(Catalog.wordleAnswers.allSatisfy { $0.count == 5 })
        XCTAssertEqual(Set(Catalog.wordleAnswers).count, Catalog.wordleAnswers.count)
    }

    /// A year of words, so the daily puzzle doesn't come back around.
    func testThereAreEnoughWordsForAYear() {
        XCTAssertGreaterThanOrEqual(Catalog.wordleAnswers.count, 365)
    }

    /// The one that would ruin someone's game: an answer the board refuses to accept
    /// as a guess is a puzzle that cannot be solved.
    func testEveryAnswerIsAlsoALegalGuess() {
        XCTAssertGreaterThanOrEqual(Catalog.wordleGuesses.count, 5_000,
                                    "guesses.json did not load")
        for word in Catalog.wordleAnswers {
            XCTAssertTrue(Catalog.wordleGuesses.contains(word),
                          "\(word) is an answer but not in the guess list")
        }
    }

    func testEveryGuessIsFiveUppercaseLetters() {
        for word in Catalog.wordleGuesses {
            XCTAssertEqual(word.count, 5, "\(word) is not five letters")
            XCTAssertTrue(word.allSatisfy { $0.isLetter && $0.isUppercase }, word)
        }
    }
}

// MARK: - Because of your week

final class SuggestionTests: XCTestCase {
    private func canvas(_ title: String, due: Date? = Date()) -> DailyTask {
        DailyTask(id: title, title: title, kind: .canvas, detail: "Bio 101", dueAt: due)
    }

    func testAQuizPullsUpTheQuizLesson() {
        let picks = Catalog.suggestions(for: [canvas("Unit 4 quiz")], completed: [])
        XCTAssertEqual(picks.first?.lesson.id, "study-2")
    }

    func testSoonestDueComesFirst() {
        let far = canvas("Chapter 7 reading", due: Date().addingTimeInterval(86_400 * 5))
        let near = canvas("Unit 4 quiz", due: Date().addingTimeInterval(3_600))
        let picks = Catalog.suggestions(for: [far, near], completed: [])
        XCTAssertEqual(picks.first?.lesson.id, "study-2")
    }

    func testFinishedLessonsAreNotSuggestedAgain() {
        let picks = Catalog.suggestions(for: [canvas("Unit 4 quiz")], completed: ["study-2"])
        XCTAssertNotEqual(picks.first?.lesson.id, "study-2")
    }

    func testTheSameLessonIsNeverSuggestedTwice() {
        let picks = Catalog.suggestions(for: [canvas("Quiz one"), canvas("Quiz two")],
                                        completed: [])
        XCTAssertEqual(Set(picks.map(\.lesson.id)).count, picks.count)
    }

    /// Nothing synced means the section isn't drawn at all — Learn is never asked to
    /// show an empty state for a feature the student may not have connected.
    func testNoCanvasWorkMeansNoSuggestions() {
        let mine = DailyTask(id: "t", title: "Drink water", kind: .life)
        XCTAssertTrue(Catalog.suggestions(for: [mine], completed: []).isEmpty)
    }

    func testDoneWorkIsNotAReason() {
        var task = canvas("Unit 4 quiz")
        task.done = true
        XCTAssertTrue(Catalog.suggestions(for: [task], completed: []).isEmpty)
    }
}
