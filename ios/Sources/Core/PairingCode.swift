import Foundation

/// The one string that ties a laptop to a phone.
///
/// Read aloud and typed by hand, so the alphabet drops every character people
/// confuse: no O or 0, no I or 1. What is left is 32 characters over 8 slots,
/// about a trillion combinations — far past guessing a stranger's homework list.
enum PairingCode {
    static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    static let length = 8

    static func generate() -> String {
        let raw = (0..<length).map { _ in alphabet.randomElement()! }
        return String(raw[0..<4]) + "-" + String(raw[4..<8])
    }

    /// Accepts what a person actually types: lower case, missing dash, stray spaces.
    static func normalize(_ input: String) -> String? {
        let cleaned = input.uppercased().filter { alphabet.contains($0) }
        guard cleaned.count == length else { return nil }
        return String(cleaned.prefix(4)) + "-" + String(cleaned.suffix(4))
    }

    static func isValid(_ code: String) -> Bool { normalize(code) == code }
}
