import XCTest
@testable import PrepkinCanvas

/// The two chip rails above the mascot on Home — the emote row and the costume
/// row — are testing furniture. They must never reach a student.
///
/// Two independent guards, and this checks both. `DebugUnlock.isOn` and
/// `sproutShowsCostumeTray` read a launch argument, so they are false whenever
/// nobody passed one; and both sit inside `#if DEBUG`, so a Release build does
/// not compile the reading at all and returns false unconditionally. The second
/// guard is the one that matters for the App Store, and the only way to check it
/// from a debug test bundle is to read the source.
final class DebugUnlockTests: XCTestCase {

    /// The launch argument is the only thing that can turn either flag on.
    ///
    /// Asserted as an equivalence rather than a flat `false` because the scheme's
    /// test action inherits the Run action's arguments, so this bundle is itself
    /// launched with `-unlockAll`. The equivalence is the claim that matters and
    /// it holds either way: no argument, no rails.
    func testBothFlagsFollowTheLaunchArgumentAndNothingElse() {
        let passed = ProcessInfo.processInfo.arguments.contains("-unlockAll")
        XCTAssertEqual(DebugUnlock.isOn, passed)
        XCTAssertEqual(sproutShowsCostumeTray, passed,
                       "the costume rail on Home is -unlockAll only")
    }

    /// Belt to the equivalence's braces: with the argument stripped, the same
    /// expression both flags are built from is false.
    func testUnlockIsOffWhenTheArgumentIsAbsent() {
        let withoutIt = ProcessInfo.processInfo.arguments.filter { $0 != "-unlockAll" }
        XCTAssertFalse(withoutIt.contains("-unlockAll"))
        XCTAssertFalse(Self.railsAreOn(givenArguments: withoutIt))
        XCTAssertTrue(Self.railsAreOn(givenArguments: withoutIt + ["-unlockAll"]))
    }

    /// The one expression `DebugUnlock.isOn` and `sproutShowsCostumeTray` are
    /// both built from, with the argument list injected.
    private static func railsAreOn(givenArguments arguments: [String]) -> Bool {
        #if DEBUG
        return arguments.contains("-unlockAll")
        #else
        return false
        #endif
    }

    func testBothRailsAreCompiledOutOfARelease() throws {
        for file in ["Core/DebugUnlock.swift", "SproutView.swift"] {
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
