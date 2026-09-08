import XCTest
import Foundation

/// Student-facing copy may not use exclamation marks or engineering words
/// (sync, bridge, API, …). Scans every string literal under `ios/Sources`.
final class CopySweepTests: XCTestCase {

    /// Exact source literals that never reach a screen. Fix copy instead of
    /// growing this list.
    private let allowlist: Set<String> = [
        // Ledger idempotency keys — stored, never rendered.
        #"bridge:focus:\(taskId ?? "-"):\(stamp)"#,
        #"bridge:look:\(lookId ?? "-"):\(stamp)"#,
        #"bridge:\(kind):\(stamp)"#,
        // Bundled Supabase config resource name — not UI copy.
        "bridge-config",
        // NSLog when that file is missing — console only.
        "Prepkin: no bridge-config.json in the bundle — running on mock Canvas data",
        // Demo league fixture — never shown as this string.
        "mock-token",
    ]

    private let banned = try! NSRegularExpression(
        pattern: #"\b(sync|syncing|bridge|endpoint|selector|api|token|schema|payload)\b"#,
        options: [.caseInsensitive]
    )

    func testNoBannedStudentCopyInSources() throws {
        let sources = sourcesDirectory()
        let files = try swiftFiles(under: sources)
        XCTAssertFalse(files.isEmpty, "no .swift files under \(sources.path)")

        var failures: [String] = []
        for url in files {
            let text = try String(contentsOf: url, encoding: .utf8)
            let stripped = stripComments(text)
            for literal in stringLiterals(in: stripped) {
                if allowlist.contains(literal) { continue }
                if literal.contains("!") {
                    failures.append("\(url.lastPathComponent): \"\(short(literal))\" has !")
                }
                let range = NSRange(literal.startIndex..., in: literal)
                if banned.firstMatch(in: literal, options: [], range: range) != nil {
                    failures.append("\(url.lastPathComponent): \"\(short(literal))\" has a banned word")
                }
            }
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    // MARK: - Paths

    private func sourcesDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources", isDirectory: true)
    }

    private func swiftFiles(under root: URL) throws -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        var out: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension == "swift" { out.append(url) }
        }
        return out.sorted { $0.path < $1.path }
    }

    // MARK: - Parse

    private func stripComments(_ text: String) -> String {
        var out = ""
        var i = text.startIndex
        while i < text.endIndex {
            if text[i] == "\"" {
                let end = endOfStringLiteral(text, from: i)
                out += text[i..<end]
                i = end
                continue
            }
            if text[i...].hasPrefix("//") {
                while i < text.endIndex, text[i] != "\n" { i = text.index(after: i) }
                continue
            }
            if text[i...].hasPrefix("/*") {
                i = text.index(i, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
                while i < text.endIndex, !text[i...].hasPrefix("*/") {
                    i = text.index(after: i)
                }
                if i < text.endIndex {
                    i = text.index(i, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
                }
                continue
            }
            out.append(text[i])
            i = text.index(after: i)
        }
        return out
    }

    /// Index just past the closing quote of the `"..."` that starts at `start`.
    private func endOfStringLiteral(_ text: String, from start: String.Index) -> String.Index {
        var i = text.index(after: start)
        while i < text.endIndex {
            let c = text[i]
            if c == "\\" {
                let next = text.index(after: i)
                if next < text.endIndex, text[next] == "(" {
                    i = text.index(after: next)
                    var depth = 1
                    while i < text.endIndex, depth > 0 {
                        if text[i] == "\"" {
                            i = endOfStringLiteral(text, from: i)
                            continue
                        }
                        if text[i] == "(" { depth += 1 }
                        if text[i] == ")" { depth -= 1 }
                        i = text.index(after: i)
                    }
                    continue
                }
                i = next < text.endIndex ? text.index(after: next) : next
                continue
            }
            if c == "\"" { return text.index(after: i) }
            i = text.index(after: i)
        }
        return i
    }

    /// Contents of every `"..."` literal, including Swift `\(...)` interpolations.
    private func stringLiterals(in text: String) -> [String] {
        var out: [String] = []
        var i = text.startIndex
        while i < text.endIndex {
            if text[i] == "\"" {
                let end = endOfStringLiteral(text, from: i)
                let inner = text[text.index(after: i)..<text.index(before: end)]
                out.append(String(inner))
                i = end
                continue
            }
            i = text.index(after: i)
        }
        return out
    }

    private func short(_ s: String) -> String {
        s.count <= 80 ? s : String(s.prefix(77)) + "..."
    }
}
