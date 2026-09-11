import Foundation

/// The stage III wardrobe.
///
/// Ids, names and prices match the web build's `costumes.ts` exactly — the page is
/// what actually draws the clothes, so a name invented here would be a second truth.
/// Order is the rail's order: cheapest first, and inside a price the order the rack
/// was drawn in.
///
/// A costume is worn by writing its id into `OwnedChibi.skinID`. `classic` is not in
/// this list because it is not a costume: it means "whatever this coat's default is",
/// which is what a kin wears before anyone has chosen for it.
struct Costume: Identifiable, Equatable {
    let id: String
    let name: String
    let price: Int

    static let catalog: [Costume] = [
        Costume(id: "hoodie", name: "Hoodie", price: 150),
        Costume(id: "flannel", name: "Flannel", price: 150),
        Costume(id: "barista", name: "Barista", price: 150),
        Costume(id: "scholar", name: "Blazer", price: 300),
        Costume(id: "varsity", name: "Varsity", price: 300),
        Costume(id: "pajamas", name: "Pajamas", price: 300),
        Costume(id: "keynote", name: "Keynote", price: 300),
        Costume(id: "happi", name: "Happi", price: 500),
        Costume(id: "idol", name: "Idol", price: 500),
        Costume(id: "racer", name: "Racer", price: 500),
        Costume(id: "ballet", name: "Ballet", price: 500),
        Costume(id: "hanbok", name: "Hanbok", price: 500),
        Costume(id: "biker", name: "Biker", price: 800),
        Costume(id: "astronaut", name: "Astronaut", price: 800),
        Costume(id: "monster", name: "Monster", price: 800),
        Costume(id: "ninja", name: "Ninja", price: 1200),
        Costume(id: "sorcerer", name: "Sorcerer", price: 1200),
        Costume(id: "grad", name: "Grad", price: 1200),
        Costume(id: "hex", name: "Hex", price: 1200),
    ]

    static let ids: Set<String> = Set(catalog.map(\.id))

    /// The None tile. Not in the catalogue and not a costume: wearing it writes
    /// `classic`, which asks the page for nothing and leaves the kin in its coat's
    /// default. Finch's closet puts NONE first for the same reason.
    static let none = Costume(id: "classic", name: "None", price: 0)

    static func find(_ id: String) -> Costume? { catalog.first { $0.id == id } }

    /// What the page dresses a stage III kin in when nobody has chosen. Mirrors the
    /// `COAT_DEFAULT` map in the web build, and the stills are captured from it.
    static let coatDefault: [String: String] = [
        "mint": "scholar", "coral": "ninja", "sky": "hoodie",
        "peach": "flannel", "lilac": "astronaut", "butter": "racer",
    ]
}
