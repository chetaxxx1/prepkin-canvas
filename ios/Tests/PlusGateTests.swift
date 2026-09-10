import Foundation
import XCTest
@testable import PrepkinCanvas

/// The house rule, as a test: **nothing that has ever shipped free may move behind
/// Plus, in any release, for any reason.**
///
/// The expected free numbers are written out again here on purpose. `PlusGate.free`
/// is not consulted for them, so a diff that lowers one fails this file and has to
/// be changed by hand, in the open, with a reviewer looking at it. That is the whole
/// mechanism.
final class PlusGateTests: XCTestCase {

    /// What a student with no entitlement gets. Lowering a number in this table is
    /// the moment a promise breaks — see `design/PLUS-SPEC.md` section 10.
    private static let freeToday: [PlusGate: Int] = [
        .scanPhoto:      0,   // never was free
        .calendarExport: 0,   // does not exist yet
        .shopSlots:      5,   // KinState.pickSlots today
        .shopHolds:      1,   // GameState.lockedPicks, one slot
        .shopDiscount:   20,  // "Every pick is 20% off its Collection price"
        .shopRerolls:    3,   // KinState.rerollsPerDay
        .focusLengths:   3,   // 15, 25, 45
        .focusHistory:   0,   // does not exist yet
        .gpaProjection:  0,   // does not exist yet
        .courseGoal:     0,   // does not exist yet
        .vibeCards:      3,   // ships at three with Friends phase 2, or never can
        .savedLooks:     3,   // free cap, and the feature ships free first
        .plusLooks:      0,   // new art, money-only
        .plusScenes:     0,   // new art, money-only
    ]

    // MARK: - One assertion per gate

    /// Every gate, with the entitlement off, hands back the free number the app
    /// ships today. A gate missing from the table above fails too, so a new case
    /// cannot be added without deciding what free gets.
    func testFreePathWorksWithTheEntitlementOff() {
        for gate in PlusGate.allCases {
            guard let expected = Self.freeToday[gate] else {
                XCTFail("\(gate.rawValue) has no free value in this test. Decide what a student without Plus gets, then add it.")
                continue
            }
            XCTAssertEqual(
                PlusGate.value(gate, isPlus: false), expected,
                "\(gate.rawValue): free path returned \(PlusGate.value(gate, isPlus: false)), expected \(expected)"
            )
        }
    }

    /// The same read, per gate, so a failure names one gate rather than the set.
    func testEveryGateIsInTheTable() {
        XCTAssertEqual(Set(PlusGate.allCases), Set(Self.freeToday.keys))
    }

    // MARK: - The shape of a gate

    /// Plus is more of a thing, never a different thing. A gate where Plus is worth
    /// less than free is a gate pointing the wrong way.
    func testPlusIsNeverSmallerThanFree() {
        for gate in PlusGate.allCases {
            XCTAssertGreaterThanOrEqual(gate.plus, gate.free, gate.rawValue)
        }
    }

    /// A gate that changes nothing is a row on the sheet promising nothing.
    func testEveryGateActuallyGivesSomething() {
        for gate in PlusGate.allCases {
            XCTAssertGreaterThan(gate.plus, gate.free, "\(gate.rawValue) gives Plus nothing over free")
        }
    }

    /// `isOn` is `value > 0`, and it has to agree with the table on both sides.
    func testIsOnAgreesWithTheTable() {
        for gate in PlusGate.allCases {
            XCTAssertEqual(PlusGate.isOn(gate, isPlus: false), gate.free > 0, gate.rawValue)
            XCTAssertTrue(PlusGate.isOn(gate, isPlus: true), gate.rawValue)
        }
    }

    // MARK: - The grandfather rule

    /// Nothing in `PLUS-SPEC.md` takes anything away, so nothing carries a
    /// restriction today. This test is what makes adding one deliberate: it fails
    /// the moment a release lowers a free number, and the person doing it has to
    /// come here and say so.
    func testNoGateTakesAnythingAwayToday() {
        for gate in PlusGate.allCases {
            XCTAssertNil(
                gate.restriction,
                "\(gate.rawValue) lowers a free number. That needs a signed line in design/PLUS-SPEC.md section 10 and a grandfather date."
            )
        }
    }

    /// The machinery itself, proved against a made-up gate rather than a real one,
    /// so the proof survives a day when every real gate is still unrestricted.
    func testAnOldInstallKeepsTheOldNumber() {
        let cutoff = Date(timeIntervalSince1970: 1_800_000_000)
        let before = cutoff.addingTimeInterval(-86_400)
        let after = cutoff.addingTimeInterval(86_400)
        let r = PlusGate.Restriction(since: cutoff, was: 57)

        // The rule, stated directly: installed before the cutoff keeps `was`,
        // installed after gets the new number, and Plus is unaffected either way.
        XCTAssertEqual(resolve(free: 1, plus: 99, restriction: r, installedAt: before, isPlus: false), 57)
        XCTAssertEqual(resolve(free: 1, plus: 99, restriction: r, installedAt: after, isPlus: false), 1)
        XCTAssertEqual(resolve(free: 1, plus: 99, restriction: r, installedAt: nil, isPlus: false), 1)
        XCTAssertEqual(resolve(free: 1, plus: 99, restriction: r, installedAt: before, isPlus: true), 99)
    }

    /// The same branch `PlusGate.value` runs, against values a test can supply.
    private func resolve(free: Int, plus: Int, restriction: PlusGate.Restriction?,
                         installedAt: Date?, isPlus: Bool) -> Int {
        if isPlus { return plus }
        guard let r = restriction, let installed = installedAt, installed < r.since else { return free }
        return r.was
    }

    // MARK: - The save file

    /// A phone that has never run Prepkin gets its date stamped on first load, and
    /// an older save gets one filled in by the v6 migration. Without either, a
    /// student who was here first cannot be told apart from one who arrived today.
    func testFirstLoadStampsAnInstallDate() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("plusgate-\(UUID().uuidString)", isDirectory: true)
        let store = Store(directory: dir, defaults: UserDefaults(suiteName: dir.path)!)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fresh = store.load()
        let stamped = try XCTUnwrap(fresh.installedAt, "a fresh install has no date to grandfather from")
        XCTAssertLessThanOrEqual(abs(stamped.timeIntervalSinceNow), 5)

        // Within a second, not exactly equal: the save file writes ISO-8601 without
        // fractional seconds, so a round trip legitimately drops the fraction.
        store.save(fresh, immediately: true)
        let reloaded = try XCTUnwrap(store.load().installedAt, "the date did not survive a relaunch")
        XCTAssertLessThan(abs(reloaded.timeIntervalSince(stamped)), 1,
                          "the date moved on the next launch")
    }
}
