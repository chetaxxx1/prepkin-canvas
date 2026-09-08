import XCTest
@testable import PrepkinCanvas

final class ReviewAskTests: XCTestCase {
    private let day: TimeInterval = 24 * 60 * 60
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func ask(
        items: Int,
        lastAskedDaysAgo: TimeInterval? = nil,
        installedDaysAgo: TimeInterval = 10
    ) -> Bool {
        ReviewAsk.shouldAsk(
            finishedCanvasItems: items,
            lastAskedAt: lastAskedDaysAgo.map { now.addingTimeInterval(-$0 * day) },
            installedAt: now.addingTimeInterval(-installedDaysAgo * day),
            now: now
        )
    }

    func testFourFinishedItemsIsNotEnough() {
        XCTAssertFalse(ask(items: 4))
    }

    func testFiveFinishedItemsEarnsTheAsk() {
        XCTAssertTrue(ask(items: 5))
    }

    func testInstalledTwoDaysAgoIsTooSoon() {
        XCTAssertFalse(ask(items: 5, installedDaysAgo: 2))
    }

    func testAskedOneHundredDaysAgoIsTooSoon() {
        XCTAssertFalse(ask(items: 5, lastAskedDaysAgo: 100, installedDaysAgo: 200))
    }

    func testAskedOneHundredTwentyOneDaysAgoCanAskAgain() {
        XCTAssertTrue(ask(items: 5, lastAskedDaysAgo: 121, installedDaysAgo: 200))
    }
}
