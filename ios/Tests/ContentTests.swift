import XCTest
@testable import PrepkinCanvas

/// These read the real files out of the built app bundle, so a JSON typo or a
/// resource that quietly stopped being copied fails here instead of on a phone.
final class ContentTests: XCTestCase {
    func testLessonsLoadFromTheBundle() {
        XCTAssertFalse(Catalog.lessons.isEmpty, "lessons.json did not load")
        for lesson in Catalog.lessons {
            XCTAssertFalse(lesson.pages.isEmpty, "\(lesson.id) has no pages")
            XCTAssertFalse(lesson.title.isEmpty)
            XCTAssertGreaterThan(lesson.reward, 0)
        }
    }

    func testLessonIDsAreUnique() {
        let ids = Catalog.lessons.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEveryWordIsFiveLetters() {
        XCTAssertFalse(Catalog.wordleAnswers.isEmpty, "words.json did not load")
        XCTAssertTrue(Catalog.wordleAnswers.allSatisfy { $0.count == 5 })
        XCTAssertEqual(Set(Catalog.wordleAnswers).count, Catalog.wordleAnswers.count)
    }
}
