import XCTest

/// Brand rule: no streaks. The word must not reach a student in any string the
/// app can show. This reads every Swift source file, drops comments, and fails on
/// the whole word "streak" inside a string literal. The allowlist stays empty.
final class NoStreakTests: XCTestCase {
    private static let allowlist: [String] = [] // must stay empty

    func testNoUserVisibleStringSaysStreak() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources")
        let files = try XCTUnwrap(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThan(files.count, 10, "expected to find the app sources next to the tests")

        var hits: [String] = []
        for file in files {
            var text = try String(contentsOf: file, encoding: .utf8)
            text = text.replacingOccurrences(of: #"/\*[\s\S]*?\*/"#, with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: #"//[^\n]*"#, with: "", options: .regularExpression)
            let literal = try NSRegularExpression(pattern: #""(?:[^"\\\n]|\\.)*""#)
            let word = try NSRegularExpression(pattern: #"\bstreak"#, options: .caseInsensitive)
            let ns = text as NSString
            for m in literal.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                let s = ns.substring(with: m.range)
                guard word.firstMatch(in: s, range: NSRange(location: 0, length: (s as NSString).length)) != nil,
                      !Self.allowlist.contains(s) else { continue }
                hits.append("\(file.lastPathComponent): \(s)")
            }
        }
        XCTAssertEqual(hits, [], "the word streak is in a user-visible string")
    }
}
