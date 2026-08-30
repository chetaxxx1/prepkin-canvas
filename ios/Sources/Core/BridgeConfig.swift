import Foundation

/// Where the Supabase bridge lives, read at launch from a bundled file that
/// `bridge/apply-config.sh` writes. The file is gitignored, so keys never reach
/// a commit, and a build without it simply has no bridge rather than failing.
struct BridgeConfig: Decodable, Equatable {
    let url: String
    let publishableKey: String

    /// True once both halves are filled in. Everything bridge-related checks this
    /// first, so an unconfigured checkout still runs on mock data.
    var isConfigured: Bool { !url.isEmpty && !publishableKey.isEmpty }

    static let shared: BridgeConfig = load()

    private static func load(bundle: Bundle = .main) -> BridgeConfig {
        guard let url = bundle.url(forResource: "bridge-config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(BridgeConfig.self, from: data) else {
            NSLog("Prepkin: no bridge-config.json in the bundle — running on mock Canvas data")
            return BridgeConfig(url: "", publishableKey: "")
        }
        return config
    }

    func endpoint(_ function: String) -> URL? {
        URL(string: "\(url.hasSuffix("/") ? String(url.dropLast()) : url)/rest/v1/rpc/\(function)")
    }
}
