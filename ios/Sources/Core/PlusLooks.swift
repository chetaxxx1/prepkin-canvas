import Foundation

/// Looks and scenes coins cannot buy.
///
/// The one place Prepkin differs from Finch, which has no member-only items at all.
/// Two rules make the difference survivable, and both are in `PLUS-SPEC.md`:
///
/// - **They stay yours after you cancel** (signature 4). One paid month buys them
///   forever. That is a real revenue leak, kept on purpose, because the alternative
///   is taking a coat off a student's fish because a card expired.
/// - **Accessibility is never in here** (R3). Dark is a coin item — the `deep` scene
///   is `isDark: true` at 280 coins — so nothing in this file is the only way to get
///   a readable screen.
///
/// **This catalogue is art-bound and ships with whatever is drawn and signed off.**
/// The rail slot, the entitlement check and the example-fish preview are built and
/// tested; an empty catalogue draws nothing at all rather than an empty shelf, which
/// is why `PlusLooks.hasAnything` exists.
enum PlusLooks {

    struct Look: Identifiable, Equatable {
        let id: String
        let name: String
        /// The `skinID` the web build draws, exactly like a costume id.
        let skinID: String
    }

    /// Money-only coats. Empty until art is drawn and signed off — the animation
    /// and face rule is that George signs a GIF before anything ships.
    static let looks: [Look] = []

    /// Money-only scenes: Observatory, Lantern Street, Snow Cabin, per section 2
    /// row 1. Ids are reserved here so nothing else claims them, and each one goes
    /// live the day its plate lands in the asset catalogue.
    static let sceneIDs = ["observatory", "lantern", "cabin"]

    /// Scenes that are both in the reserved list and actually drawn. A scene with no
    /// plate would render the fish over a blank rectangle.
    static var scenes: [Scene0] {
        sceneIDs.compactMap { id in Scene0.all.first { $0.id == id } }
    }

    /// Whether the rail has anything to show. An empty Plus shelf is worse than no
    /// shelf: it reads as a thing taken away.
    static var hasAnything: Bool { !looks.isEmpty || !scenes.isEmpty }

    static func isPlusOnly(scene id: String) -> Bool { sceneIDs.contains(id) }
    static func isPlusOnly(look id: String) -> Bool { looks.contains { $0.skinID == id } }

    /// The fish a Plus coat is previewed on. **Never the student's own.**
    ///
    /// Showing a coat they do not have on the animal they love is the padlock
    /// feeling wearing a costume, and it is the one thing section 4 says not to do
    /// on the Kin tab.
    static let exampleSpeciesID = "slime"
}
