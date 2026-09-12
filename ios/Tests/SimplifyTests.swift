import XCTest
@testable import PrepkinCanvas

/// The 2026-09-12 subtraction pass, as rules: one place for each fact. Each test
/// names the screen the rule was copied from (`design/screenshots/app-simplify-
/// 2026-09-12/README.md` has the table).
final class SimplifyTests: XCTestCase {

    // MARK: - Focus (Forest's timer: one control, one button)

    /// The chip row is the three free lengths, for everybody. It used to carry 60
    /// and 90 as well, in coral, with a typed-length link under it.
    func testFocusChipRowIsExactlyTheThreeFreeLengths() {
        XCTAssertEqual(FocusView.chipLengths, [15, 25, 45])
        XCTAssertEqual(FocusView.chipLengths, FocusView.freeLengths,
                       "the chip row and the free set are one list")
    }

    /// Behind More: sixty, ninety and a typed length, in that order, all Plus.
    func testFocusMoreSheetHoldsSixtyNinetyAndTyped() {
        XCTAssertEqual(FocusView.moreItems, [.minutes(60), .minutes(90), .typed])
    }

    /// Nothing on the More sheet repeats a chip.
    func testFocusMoreSheetNeverRepeatsAChip() {
        for item in FocusView.moreItems {
            if case .minutes(let m) = item {
                XCTAssertFalse(FocusView.chipLengths.contains(m), "\(m) is already a chip")
            }
        }
    }
}
