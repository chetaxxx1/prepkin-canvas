import Foundation
import XCTest
@testable import PrepkinCanvas

final class PlusTests: XCTestCase {
    func testEntitlementResolution() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let earlier = now.addingTimeInterval(-1)
        let later = now.addingTimeInterval(1)

        let cases: [(name: String, records: [PlusRecord], expected: PlusEntitlement)] = [
            (
                "nothing",
                [],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "active monthly",
                [PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: later, revokedAt: nil)],
                PlusEntitlement(product: .monthly, expiresAt: later, isActive: true)
            ),
            (
                "expired monthly",
                [PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: earlier, revokedAt: nil)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "revoked yearly",
                [PlusRecord(productID: PlusProduct.yearly.rawValue, expiresAt: later, revokedAt: now)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "both active picks yearly",
                [
                    PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: later, revokedAt: nil),
                    PlusRecord(productID: PlusProduct.yearly.rawValue, expiresAt: later, revokedAt: nil),
                ],
                PlusEntitlement(product: .yearly, expiresAt: later, isActive: true)
            ),
            (
                "unknown product is ignored",
                [PlusRecord(productID: "com.prepkin.canvas.plus.other", expiresAt: later, revokedAt: nil)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "expiry exactly at now",
                [PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: now, revokedAt: nil)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
        ]

        for testCase in cases {
            XCTAssertEqual(
                PlusEntitlement.resolve(testCase.records, now: now),
                testCase.expected,
                testCase.name
            )
        }
    }
}

/// Apple's billing grace period, which `PlusEntitlement.resolve` did not handle
/// before 2026-09-10.
extension PlusTests {

    /// A card that bounced must not cost a student a perk. In grace the expiration
    /// date is already in the past, so the plain date check would drop it.
    func testAGracePeriodRecordStaysActiveAfterItsDatePasses() {
        let now = Date()
        let record = PlusRecord(
            productID: PlusProduct.monthly.rawValue,
            expiresAt: now.addingTimeInterval(-86_400),
            revokedAt: nil,
            inGracePeriod: true
        )
        XCTAssertTrue(PlusEntitlement.resolve([record], now: now).isActive)
    }

    /// The same record, not in grace, is expired. Grace is the only thing that
    /// keeps a past date alive.
    func testAnExpiredRecordWithoutGraceIsInactive() {
        let now = Date()
        let record = PlusRecord(
            productID: PlusProduct.monthly.rawValue,
            expiresAt: now.addingTimeInterval(-86_400),
            revokedAt: nil
        )
        XCTAssertFalse(PlusEntitlement.resolve([record], now: now).isActive)
    }

    /// A refund revokes it, grace or not.
    func testARevokedRecordIsInactiveEvenInGrace() {
        let now = Date()
        let record = PlusRecord(
            productID: PlusProduct.yearly.rawValue,
            expiresAt: now.addingTimeInterval(86_400),
            revokedAt: now,
            inGracePeriod: true
        )
        XCTAssertFalse(PlusEntitlement.resolve([record], now: now).isActive)
    }
}
