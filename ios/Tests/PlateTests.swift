import XCTest
import SwiftUI
@testable import PrepkinCanvas

/// The disc behind a kin is the complement of the kin's own colour, pastel.
final class PlateTests: XCTestCase {
    private func hsb(_ c: Color) -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b)
    }

    func testPlateSitsOppositeTheKinOnTheWheel() {
        for id in ["slime", "ember", "droplet", "wisp", "sprout", "comet"] {
            let kin = hsb(Theme.species(id)), plate = hsb(Theme.plate(for: id))
            var gap = abs(kin.h - plate.h)
            if gap > 0.5 { gap = 1 - gap }
            XCTAssertEqual(gap, 0.5, accuracy: 0.02, "\(id) plate is not the complement")
            XCTAssertEqual(plate.s, 0.32, accuracy: 0.02, id)
            XCTAssertEqual(plate.b, 0.97, accuracy: 0.02, id)
        }
    }
}

/// Every three-star still has a face position, and it is inside the image.
final class PortraitTests: XCTestCase {
    func testEveryStillHasItsFaceOnRecord() {
        XCTAssertGreaterThanOrEqual(Catalog.portraits.count, 12, "portraits.json did not load")
        for (name, xy) in Catalog.portraits {
            XCTAssertEqual(xy.count, 3, name)
            XCTAssertTrue((1.2...2.6).contains(xy[2]), "\(name) scale \(xy[2]) is out of range")
            XCTAssertTrue((0.25...0.75).contains(xy[0]), "\(name) face x \(xy[0]) is off the image")
            XCTAssertTrue((0.3...0.8).contains(xy[1]), "\(name) face y \(xy[1]) is off the image")
        }
        for id in ["slime", "ember", "droplet", "wisp", "sprout", "comet"] {
            XCTAssertNotNil(Catalog.portraits[SproutImage.asset(speciesID: id, level: 3, skin: "classic")], id)
        }
    }
}

/// Sprout only at launch (2026-09-10): the catalogue has no other rig, and a save
/// that owned one comes back on a Sprout coat rather than a blank.
final class SproutOnlyTests: XCTestCase {
    func testTheCatalogueIsAllSproutCoats() {
        XCTAssertEqual(ChibiSpecies.catalog.count, 6)
        for s in ChibiSpecies.catalog {
            XCTAssertEqual(SproutView.type(s.id), "sprout", s.id)
            XCTAssertNotNil(Catalog.portraits[SproutImage.asset(speciesID: s.id, level: 3, skin: "classic")], s.id)
        }
    }

    func testASaveWithARetiredKinDropsItAndKeepsAnOwnedOne() throws {
        var s = GameState()
        s.owned.append(OwnedChibi(speciesID: "orca", level: 2))
        s.owned.append(OwnedChibi(speciesID: "ember", level: 1))
        s.activeChibiID = "orca"
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(back.owned.map(\.speciesID), ["slime", "ember"])
        XCTAssertEqual(back.activeChibiID, "slime", "the orca is gone, so the starter fronts the tank")
    }
}
