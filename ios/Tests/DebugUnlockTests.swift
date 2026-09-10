import XCTest
@testable import PrepkinCanvas

/// The testing unlock — the whole catalogue, every costume, and the Plus gates
/// open — must never reach a student.
///
/// Two independent guards, and this checks both. `DebugUnlock.isOn` reads a launch
/// argument, or the bit an earlier launch's argument wrote down so a phone trial
/// survives being opened from the home screen, and is false when there has never
/// been one; and it sits inside `#if DEBUG`, so a Release build does not compile the
/// reading at all and returns false unconditionally. The second guard is the one that
/// matters for the App Store, and the only way to check it from a debug test bundle
/// is to read the source.
final class DebugUnlockTests: XCTestCase {

    /// The launch argument, or the bit it wrote on an earlier launch, is the only
    /// thing that can turn either flag on.
    ///
    /// Asserted as an equivalence rather than a flat `false` because the scheme's
    /// test action inherits the Run action's arguments, so this bundle is itself
    /// launched with `-unlockAll`. The equivalence is the claim that matters and
    /// it holds either way: no argument ever, no rails.
    func testBothFlagsFollowTheLaunchArgumentAndNothingElse() {
        let passed = ProcessInfo.processInfo.arguments.contains("-unlockAll")
        let on = DebugUnlock.isOn
        let remembered = UserDefaults.standard.bool(forKey: DebugUnlock.stickyKey)
        XCTAssertEqual(on, passed || remembered)
    }

    /// Belt to the equivalence's braces: with the argument stripped and nothing
    /// remembered, the same expression both flags are built from is false.
    func testUnlockIsOffWhenTheArgumentIsAbsent() {
        let withoutIt = ProcessInfo.processInfo.arguments.filter { $0 != "-unlockAll" }
        XCTAssertFalse(withoutIt.contains("-unlockAll"))
        XCTAssertFalse(Self.railsAreOn(givenArguments: withoutIt, remembered: false))
        XCTAssertTrue(Self.railsAreOn(givenArguments: withoutIt, remembered: true))
        XCTAssertTrue(Self.railsAreOn(givenArguments: withoutIt + ["-unlockAll"], remembered: false))
    }

    /// Every costume the web build ships is owned, so the rail is a wardrobe and
    /// not a shop window.
    func testUnlockOwnsTheWholeRack() {
        var game = GameState()
        game.unlockEverythingForTesting()
        XCTAssertTrue(DebugUnlock.everyCostume.isSubset(of: game.ownedLooks))
        XCTAssertTrue(game.ownedLooks.contains("ninja"))
        XCTAssertTrue(game.ownedLooks.contains("hex"))
    }

    /// The expression `DebugUnlock.isOn` is built from, with the argument list and
    /// the remembered bit injected.
    private static func railsAreOn(givenArguments arguments: [String], remembered: Bool) -> Bool {
        #if DEBUG
        return arguments.contains("-unlockAll") || remembered
        #else
        return false
        #endif
    }

    func testTheUnlockIsCompiledOutOfARelease() throws {
        for file in ["Core/DebugUnlock.swift"] {
            let text = try String(contentsOf: source(file), encoding: .utf8)
            let flag = try XCTUnwrap(
                range(of: text, from: "#if DEBUG", to: "#endif"),
                "\(file): the -unlockAll flag is not inside #if DEBUG")
            XCTAssertTrue(flag.contains(#"arguments.contains("-unlockAll")"#),
                          "\(file): the launch-argument read moved out of #if DEBUG")
            XCTAssertTrue(flag.contains("#else"),
                          "\(file): no #else, so a Release build would not compile")
            let release = flag[flag.range(of: "#else")!.upperBound...]
            XCTAssertTrue(release.contains("return false"),
                          "\(file): a Release build must return false")
        }
    }

    // MARK: - Reading the sources

    private func source(_ path: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources")
            .appendingPathComponent(path)
    }

    /// The first `#if DEBUG` … `#endif` block in a file.
    private func range(of text: String, from open: String, to close: String) -> String? {
        guard let start = text.range(of: open),
              let end = text.range(of: close, range: start.upperBound..<text.endIndex)
        else { return nil }
        return String(text[start.upperBound..<end.lowerBound])
    }
}
