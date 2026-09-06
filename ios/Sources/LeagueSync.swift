import Foundation

// The pod half of the league: the bridge that puts other real students on the board.
//
// Built on the same shape as `CanvasSync.swift` — a protocol, a Supabase client that
// POSTs to one database function per call, a mock, and a rule in `AppState` that a
// configured install never falls back to sample data. Read that file first; this one
// only says what is different.
//
// What is different is that there is no account, and there is not going to be one. A
// player is a random id and a random token the bridge minted, and a name is two
// integers into word lists this app ships. Nothing a student typed is stored anywhere,
// so there is nothing here to spell someone's real name with, and no free-text field
// for a fifteen-year-old to write something cruel in.

// MARK: - Who you are in a pod

/// This phone's place in the league, as the bridge knows it.
///
/// `id` and `token` are random strings the bridge handed out; the name is two indices.
/// Like the Canvas pairing token, they live in the save file rather than the Keychain
/// — the same trade the bridge already makes, written down rather than hidden.
struct LeagueIdentity: Codable, Equatable {
    let id: String
    /// Proves this phone owns `id`. Every call except `create_player` needs it, and
    /// the bridge should treat a wrong one exactly as it treats a guess: nothing back.
    let token: String
    /// Index into `Catalog.podNames.adjectives`.
    let adjective: Int
    /// Index into `Catalog.podNames.nouns`.
    let noun: Int

    var displayName: String { PodName.name(adjective: adjective, noun: noun) }
}

// MARK: - The board

/// One student on the board, including you.
///
/// There is deliberately no id here. Two members of a pod are told apart by their rank
/// and nothing else, because anything stable enough to follow a person between weeks
/// is the beginning of an account.
struct PodMember: Codable, Equatable, Identifiable {
    /// 1-based, and numbered from the position the bridge sent, never read off the
    /// wire. The bridge already decided the order; a second number that could disagree
    /// with it is a bug waiting to happen.
    let rank: Int
    let isYou: Bool
    let adjective: Int
    let noun: Int
    /// A `ChibiSpecies.id`, a `OwnedChibi.skinID`, and a level of 1...3 — everything
    /// the board needs to draw somebody else's kin, and nothing else about them.
    let speciesID: String
    let lookID: String
    let level: Int
    /// Coins that student earned this week. See `pushPoints` for why this cannot be
    /// verified and what is done about that.
    let points: Int

    var id: Int { rank }
    var displayName: String { PodName.name(adjective: adjective, noun: noun) }

    init(rank: Int, isYou: Bool, adjective: Int, noun: Int,
         speciesID: String, lookID: String, level: Int, points: Int) {
        self.rank = rank
        self.isYou = isYou
        self.adjective = adjective
        self.noun = noun
        self.speciesID = speciesID
        self.lookID = lookID
        self.level = min(max(level, 1), 3)
        self.points = max(0, points)
    }

    /// The wire keys are short because they are sent once per member per sync.
    private enum CodingKeys: String, CodingKey {
        case rank, you, adj, noun, species, look, level, points
    }

    /// Tolerant for the reason `GameState`'s decoder is: this shape is also what a
    /// cached board decodes from, and one missing key must never cost the save file.
    /// A level outside 1...3 or a negative score is clamped rather than trusted —
    /// the art only has three evolutions and a board is not the place to find out.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(rank: try c.decodeIfPresent(Int.self, forKey: .rank) ?? 0,
                  isYou: try c.decodeIfPresent(Bool.self, forKey: .you) ?? false,
                  adjective: try c.decodeIfPresent(Int.self, forKey: .adj) ?? 0,
                  noun: try c.decodeIfPresent(Int.self, forKey: .noun) ?? 0,
                  speciesID: try c.decodeIfPresent(String.self, forKey: .species) ?? "slime",
                  lookID: try c.decodeIfPresent(String.self, forKey: .look) ?? "classic",
                  level: try c.decodeIfPresent(Int.self, forKey: .level) ?? 1,
                  points: try c.decodeIfPresent(Int.self, forKey: .points) ?? 0)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rank, forKey: .rank)
        try c.encode(isYou, forKey: .you)
        try c.encode(adjective, forKey: .adj)
        try c.encode(noun, forKey: .noun)
        try c.encode(speciesID, forKey: .species)
        try c.encode(lookID, forKey: .look)
        try c.encode(level, forKey: .level)
        try c.encode(points, forKey: .points)
    }

    func at(rank: Int) -> PodMember {
        PodMember(rank: rank, isYou: isYou, adjective: adjective, noun: noun,
                  speciesID: speciesID, lookID: lookID, level: level, points: points)
    }
}

/// One pod, ranked, for one week.
///
/// A pod that holds only you is a real answer and the board says so in words. It is
/// also the state most students meet first, because a pod fills up as people join.
/// Padding the list to look busy would be the same lie as the four hard-coded friends
/// that were cut from this app.
struct PodSnapshot: Codable, Equatable {
    let podID: String
    let week: WeekKey
    /// The water this pod is swimming in. Every member of a pod is in the same tier,
    /// which is the only reason comparing their coins means anything.
    let tier: LeagueTier
    /// Best first. The bridge sorts; the phone never re-sorts, so two phones cannot
    /// disagree about who is second.
    let members: [PodMember]

    var you: PodMember? { members.first { $0.isYou } }
    var others: [PodMember] { members.filter { !$0.isYou } }
    /// Nobody else has joined yet. Say it plainly on screen; never fill the gap.
    var isAlone: Bool { others.isEmpty }

    private enum CodingKeys: String, CodingKey { case pod, week, tier, members }

    init(podID: String, week: WeekKey, tier: LeagueTier, members: [PodMember]) {
        self.podID = podID
        self.week = week
        self.tier = tier
        self.members = Self.ranked(members)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(podID: try c.decodeIfPresent(String.self, forKey: .pod) ?? "",
                  week: WeekKey(raw: try c.decodeIfPresent(String.self, forKey: .week) ?? ""),
                  tier: WireTier.tier(try c.decodeIfPresent(WireTier.self, forKey: .tier)),
                  members: try c.decodeIfPresent([PodMember].self, forKey: .members) ?? [])
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(podID, forKey: .pod)
        try c.encode(week.raw, forKey: .week)
        try c.encode(tier.rawValue, forKey: .tier)
        try c.encode(members, forKey: .members)
    }

    private static func ranked(_ members: [PodMember]) -> [PodMember] {
        members.enumerated().map { $1.at(rank: $0 + 1) }
    }
}

/// What `join_pod` answers: which pod, which week, which water. No members yet — the
/// phone follows straight away with `push_points`, which returns the board.
struct PodPlacement: Codable, Equatable {
    let podID: String
    let week: WeekKey
    let tier: LeagueTier

    private enum CodingKeys: String, CodingKey { case pod, week, tier }

    init(podID: String, week: WeekKey, tier: LeagueTier) {
        self.podID = podID
        self.week = week
        self.tier = tier
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(podID: try c.decodeIfPresent(String.self, forKey: .pod) ?? "",
                  week: WeekKey(raw: try c.decodeIfPresent(String.self, forKey: .week) ?? ""),
                  tier: WireTier.tier(try c.decodeIfPresent(WireTier.self, forKey: .tier)))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(podID, forKey: .pod)
        try c.encode(week.raw, forKey: .week)
        try c.encode(tier.rawValue, forKey: .tier)
    }
}

/// A tier as the bridge writes it. The number is the contract, but a name is accepted
/// too: the SQL side names its tiers, and a silent mismatch here would put every
/// student in Tidepool without anything looking broken.
private enum WireTier: Decodable {
    case number(Int)
    case name(String)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let n = try? c.decode(Int.self) { self = .number(n) } else { self = .name((try? c.decode(String.self)) ?? "") }
    }

    static func tier(_ wire: WireTier?) -> LeagueTier {
        switch wire {
        case .number(let n):
            return LeagueTier(rawValue: n) ?? .tidepool
        case .name(let text):
            let want = squashed(text)
            return LeagueTier.allCases.first { squashed($0.name) == want } ?? .tidepool
        case .none:
            return .tidepool
        }
    }

    private static func squashed(_ s: String) -> String {
        s.lowercased().filter { !$0.isWhitespace && $0 != "_" && $0 != "-" }
    }
}

// MARK: - Display names

/// The two word lists a display name is drawn from.
struct PodNames: Decodable, Equatable {
    let adjectives: [String]
    let nouns: [String]
}

extension Catalog {
    /// Loaded the same way the lessons and the word lists are. It lives here rather
    /// than in `Content.swift` only because that file's loader is file-private.
    static let podNames: PodNames = loadPodNames()

    private static func loadPodNames(bundle: Bundle = .main) -> PodNames {
        guard let url = bundle.url(forResource: "podnames", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            NSLog("Prepkin: podnames.json missing, using the built-in fallback")
            return PodNames.fallback
        }
        do {
            return try JSONDecoder().decode(PodNames.self, from: data)
        } catch {
            NSLog("Prepkin: podnames.json is malformed (\(error)), using the built-in fallback")
            return PodNames.fallback
        }
    }
}

extension PodNames {
    /// Eight and eight, lifted from the shipped file. Small on purpose: it only runs
    /// when the JSON is missing, and a repeated name is better than a blank one.
    static let fallback = PodNames(
        adjectives: ["Quiet", "Calm", "Steady", "Patient", "Gentle", "Bright", "Swift", "Kind"],
        nouns: ["Otter", "Heron", "Turtle", "Dolphin", "Harbor", "Beacon", "Anchor", "Tide"])
}

/// Two integers in, one name out.
///
/// Pure and separate from everything else so the safety claim — that no pair of these
/// 4096 can read as an insult, a slur, a comment about a body, or anything sexual —
/// is something a test can walk in full.
enum PodName {
    static func name(adjective: Int, noun: Int,
                     adjectives: [String] = Catalog.podNames.adjectives,
                     nouns: [String] = Catalog.podNames.nouns) -> String {
        guard !adjectives.isEmpty, !nouns.isEmpty else { return "Someone" }
        return "\(adjectives[wrap(adjective, adjectives.count)]) \(nouns[wrap(noun, nouns.count)])"
    }

    /// Indices wrap instead of trapping. The bridge picks them, and a bridge whose
    /// lists grew past the ones in this build must not be able to hand a student a
    /// blank name or take the board down. Negative lands inside the list too.
    static func wrap(_ index: Int, _ count: Int) -> Int {
        guard count > 0 else { return 0 }
        let m = index % count
        return m < 0 ? m + count : m
    }
}

// MARK: - The client

enum LeagueError: Error, Equatable {
    case notConfigured
    case server(status: Int)
    /// The bridge answered with something this build cannot read.
    case badResponse
    /// The bridge says this player is in no pod. Recoverable, and not an error the
    /// student ever sees: the phone joins again on the next pass.
    case notInPod
}

/// The bridge to the pod.
protocol LeagueClient {
    /// Mints a player. The only call with no token, and the only one that creates
    /// anything — a student who never opts in has no row on the bridge at all.
    func createPlayer() async throws -> LeagueIdentity
    func joinPod(identity: LeagueIdentity, species: String, look: String, level: Int) async throws -> PodPlacement
    func pushPoints(identity: LeagueIdentity, points: Int, species: String, look: String, level: Int) async throws -> PodSnapshot
    /// `nil` means this player is in no pod yet, which is different from a pod that
    /// happens to be empty.
    func fetchPod(identity: LeagueIdentity) async throws -> PodSnapshot?
    func leavePod(identity: LeagueIdentity) async throws
    /// Deletes the row. After this the id and token open nothing, which is the point.
    func forgetPlayer(identity: LeagueIdentity) async throws
}

/// Talks to the pod through database functions, one per call.
///
/// The publishable key ships in every build, so anyone can reach these functions. The
/// token is what makes that safe: with no token a call gets nothing back, exactly as
/// in `bridge/schema.sql`.
struct SupabaseLeagueClient: LeagueClient {
    var config: BridgeConfig = .shared
    var session: URLSession = .shared

    /// The same POST `SupabaseCanvasClient` makes, written out again because that
    /// one is private to its own file. If a third caller ever needs it, lift it out
    /// then rather than now.
    private func call(_ function: String, _ body: [String: Any]) async throws -> Data {
        guard config.isConfigured, let endpoint = config.endpoint(function) else {
            throw LeagueError.notConfigured
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw LeagueError.server(status: status) }
        return data
    }

    func createPlayer() async throws -> LeagueIdentity {
        let data = try await call("create_player", [:])
        guard !Self.isNull(data),
              let wire = try? Self.decoder.decode(WirePlayer.self, from: data) else {
            throw LeagueError.badResponse
        }
        return LeagueIdentity(id: wire.id, token: wire.token, adjective: wire.adj, noun: wire.noun)
    }

    func joinPod(identity: LeagueIdentity, species: String, look: String, level: Int) async throws -> PodPlacement {
        let data = try await call("join_pod", [
            "p_player": identity.id, "p_token": identity.token,
            "p_species": species, "p_look": look, "p_level": level,
        ])
        guard !Self.isNull(data),
              let placement = try? Self.decoder.decode(PodPlacement.self, from: data),
              !placement.podID.isEmpty else {
            throw LeagueError.badResponse
        }
        return placement
    }

    /// Publishes this week's coins and gets the ranked pod back.
    ///
    /// **The phone is the only witness to this number.** Every coin is an
    /// honour-system check-off made offline, so the bridge cannot verify a score and
    /// nothing here pretends otherwise. The most it can do is ask whether this is a
    /// number a person could have earned in a week and refuse the ones that are not.
    /// That is a smell test, not proof.
    ///
    /// Which is exactly why the ladder is climb-only. Under a fixed bar a forged
    /// score only fast-forwards the liar. Under demotion the same lie would push a
    /// real student down, and no amount of server-side checking would make that safe.
    func pushPoints(identity: LeagueIdentity, points: Int, species: String, look: String, level: Int) async throws -> PodSnapshot {
        let data = try await call("push_points", [
            "p_player": identity.id, "p_token": identity.token, "p_points": max(0, points),
            "p_species": species, "p_look": look, "p_level": level,
        ])
        guard !Self.isNull(data) else { throw LeagueError.notInPod }
        guard let board = try? Self.decoder.decode(PodSnapshot.self, from: data) else {
            throw LeagueError.badResponse
        }
        guard !board.podID.isEmpty else { throw LeagueError.notInPod }
        return board
    }

    func fetchPod(identity: LeagueIdentity) async throws -> PodSnapshot? {
        let data = try await call("fetch_pod", ["p_player": identity.id, "p_token": identity.token])
        // `null` is a real answer: no pod. It is not the same as a pod with one
        // member in it, and the board says two different things about them.
        guard !Self.isNull(data) else { return nil }
        guard let board = try? Self.decoder.decode(PodSnapshot.self, from: data) else {
            throw LeagueError.badResponse
        }
        return board.podID.isEmpty ? nil : board
    }

    func leavePod(identity: LeagueIdentity) async throws {
        _ = try await call("leave_pod", ["p_player": identity.id, "p_token": identity.token])
    }

    func forgetPlayer(identity: LeagueIdentity) async throws {
        _ = try await call("forget_player", ["p_player": identity.id, "p_token": identity.token])
    }

    private struct WirePlayer: Decodable {
        let id: String
        let token: String
        let adj: Int
        let noun: Int
    }

    private static let decoder = JSONDecoder()

    private static func isNull(_ data: Data) -> Bool {
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty || text == "null"
    }
}

/// Sample data for a checkout with no bridge configured, so a demo is never a blank
/// page — and never a populated lie either.
///
/// The mock pod holds exactly one member: you. Inventing pod-mates here would put
/// people who do not exist in front of a student, which is the single worst thing
/// this feature could do and the reason four hard-coded friends were cut from this
/// app already. A pod of one is also what most students meet on their first Monday,
/// so this is the state most worth building against.
struct MockLeagueClient: LeagueClient {
    var identity = LeagueIdentity(id: "mock-player", token: "mock-token", adjective: 0, noun: 0)
    var tier: LeagueTier = .tidepool

    private var week: WeekKey { WeekKey(.today()) }

    func createPlayer() async throws -> LeagueIdentity { identity }

    func joinPod(identity: LeagueIdentity, species: String, look: String, level: Int) async throws -> PodPlacement {
        PodPlacement(podID: "mock-pod", week: week, tier: tier)
    }

    func pushPoints(identity: LeagueIdentity, points: Int, species: String, look: String, level: Int) async throws -> PodSnapshot {
        PodSnapshot(podID: "mock-pod", week: week, tier: tier, members: [
            PodMember(rank: 1, isYou: true, adjective: identity.adjective, noun: identity.noun,
                      speciesID: species, lookID: look, level: level, points: points),
        ])
    }

    func fetchPod(identity: LeagueIdentity) async throws -> PodSnapshot? { nil }
    func leavePod(identity: LeagueIdentity) async throws {}
    func forgetPlayer(identity: LeagueIdentity) async throws {}
}
