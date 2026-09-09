import Foundation
import SwiftUI

/// The bridge between SwiftUI and `GameState`.
///
/// All the rules live in `GameState`, which is a plain value type with no I/O — this
/// class only publishes it, saves it, and plays the mascot's reaction. Anything you
/// would want to write a test for belongs on the other side of this line.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var game: GameState {
        didSet { store.save(game) }
    }

    @Published var animation: ChibiAnimation = .wave
    /// Raised by pushed sub-screens (Daily Word, a lesson, the grade calculator)
    /// and by a running focus session, so the floating bar gets out of the way.
    @Published var hideTabBar = false

    /// What the last sync did, for the connect screen. Not persisted — it is only
    /// ever about this run.
    @Published private(set) var canvasStatus: String?
    /// The Canvas card reads this and nothing else for its dot and title. The free
    /// text above is kept as a mirror (a test pins that it is set), never as the
    /// source of a colour: a mint "Connected" over "could not reach" was the bug.
    enum CanvasLink: Equatable {
        case notSetUp          // no client: unpaired, or a build with no Canvas
        case waitingForLaptop  // paired, nothing received yet
        case connected         // the last check reached the laptop's list
        case offline           // the last check failed; the last list stays
        case expired           // a previous list arrived, but this pairing ran out
    }
    @Published private(set) var canvasLink: CanvasLink = .notSetUp
    /// Why the pairing code on screen is not usable yet — the bridge was
    /// unreachable when the app tried to claim it. Nil when the code is good.
    @Published private(set) var pairingStatus: String?
    /// Friends who are working right now. Not persisted: a presence is only ever
    /// true for the next few minutes, and a cached one would seat somebody at a desk
    /// they left yesterday.
    @Published private(set) var friendsFocusing: [FocusPresence] = []

    /// What the last pod sync did, for the league board. Not persisted — the board
    /// itself is, so a failure leaves the standings up and only this line changes.
    @Published private(set) var leagueStatus: String?

    /// One line of dark glass saying what just happened. A new value replaces the
    /// current one in place; there is never a second toast on screen.
    @Published var toast: String?
    /// The four steps of adopting a kin, as one path. `nil` when nothing is in flight.
    @Published var adoption: Adoption?
    /// Set while the picks row is changing over, so the row can stagger.
    @Published var rerolling = false
    /// "Meet <kin>" was tapped on the adoption card. Root switches to the Kin tab,
    /// and whatever shop or sheet is open gets out of the way. Cleared by Root.
    @Published var meetKinRequest: String?
    /// "Add a friend" was tapped on a locked game's sheet. Root switches to the
    /// Friends tab. Cleared by Root once the switch is made; never persisted.
    @Published var openFriendsRequest = false

    private var toastTask: Task<Void, Never>?

    private let store: Store
    private let makeClient: (GameState) -> CanvasSyncClient?
    private let makeLeagueClient: (GameState) -> LeagueClient?
    private let makeStudyClient: (GameState) -> StudyClient?

    /// Real bridge once there is a pairing code. Sample data only in a checkout
    /// with no bridge configured at all, so a demo is never an empty page — but a
    /// real install that unpairs gets nothing, not fake homework that pays coins.
    nonisolated static func defaultClient(for state: GameState, config: BridgeConfig = .shared) -> CanvasSyncClient? {
        guard config.isConfigured else { return MockCanvasClient() }
        guard let code = state.pairingCode, let token = state.pairingToken else { return nil }
        return SupabaseCanvasClient(code: code, token: token)
    }

    /// The real bridge on any configured install. Sample data only in a checkout with
    /// no bridge at all — and even then the mock pod holds exactly one member, you.
    ///
    /// The league does not ride on the Canvas pairing: a student with no laptop still
    /// has a pod. So there is nothing else to check, and a configured install always
    /// gets the real client rather than invented company.
    nonisolated static func defaultLeagueClient(for state: GameState,
                                                config: BridgeConfig = .shared) -> LeagueClient? {
        guard config.isConfigured else { return MockLeagueClient() }
        return SupabaseLeagueClient()
    }

    /// Same rule as the league client, and the mock deliberately reports that nobody
    /// is focusing. See `MockStudyClient`.
    nonisolated static func defaultStudyClient(for state: GameState,
                                               config: BridgeConfig = .shared) -> StudyClient? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(MockStudyClient.fakeTableArgument) {
            return MockStudyClient.seatedForTesting()
        }
        #endif
        guard config.isConfigured else { return MockStudyClient() }
        return SupabaseStudyClient()
    }

    init(store: Store = .shared,
         makeClient: @escaping (GameState) -> CanvasSyncClient? = { AppState.defaultClient(for: $0) },
         makeLeagueClient: @escaping (GameState) -> LeagueClient? = { AppState.defaultLeagueClient(for: $0) },
         makeStudyClient: @escaping (GameState) -> StudyClient? = { AppState.defaultStudyClient(for: $0) }) {
        self.store = store
        self.makeClient = makeClient
        self.makeLeagueClient = makeLeagueClient
        self.makeStudyClient = makeStudyClient
        var loaded = store.load()
        loaded.advance()
        loaded.lastOpenedAt = Date()
        game = loaded
        #if DEBUG
        // Launch with `-unlockAll` to open the whole catalogue. See DebugUnlock.swift.
        if ProcessInfo.processInfo.arguments.contains("-unlockAll") {
            game.unlockEverythingForTesting()
        }
        #endif
        game.refreshPicksIfNeeded()
        store.save(game)
    }

    // MARK: - Read-through for the views

    var coins: Int { game.ledger.balance }
    var owned: [OwnedChibi] { game.owned }
    var activeChibiID: String { game.activeChibiID }
    var activeChibi: OwnedChibi { game.activeChibi }
    var tasks: [DailyTask] { game.tasks }
    var allDone: Bool { game.allDone }
    var week: WeekStats { game.week }
    var completedLessons: Set<String> { game.completedLessons }
    var savedCards: [SavedCard] { game.savedCards }
    var cardReports: [CardReport] { game.cardReports }
    var hasSeenTapCoach: Bool { game.hasSeenTapCoach }
    var firstRunDone: Bool { game.firstRunDone }
    var firstRunOffersDone: Bool { game.firstRunOffersDone }
    var lessonsThisMonth: Int { game.lessonsThisMonth() }
    var sceneID: String { game.sceneID }
    var ownedScenes: Set<String> { game.ownedScenes }
    var templates: [TaskTemplate] { game.templates }
    var settings: AppSettings { game.settings }
    var wordleClaimedToday: Bool { game.wordleClaimedToday }
    var coinHistory: [CoinEntry] { game.ledger.entries.reversed() }
    var courses: [CanvasCourse] { game.canvasCourses }
    var bestShift: Int { game.bestShift }
    var lifetime: LifetimeStats { game.lifetime }
    var picks: [ShopPick] { game.picks }
    var league: LeagueState { game.league }
    var leaguePoints: Int { game.leaguePoints }
    var leaguePointsToNextTier: Int? { game.leaguePointsToNextTier }
    var lockedPick: String? { game.lockedPick }
    func currentPrice(_ id: String) -> Int { game.currentPrice(id) }
    func workToAfford(_ id: String) -> String? { game.workToAfford(id) }
    func ownedKin(_ speciesID: String) -> OwnedChibi? {
        game.owned.first { $0.speciesID == speciesID }
    }
    func daysTogether(_ kin: OwnedChibi) -> Int { game.daysTogether(kin) }
    var canvasFinished: Int? { game.canvasFinishedOrNil }

    // MARK: - Day

    /// Rebuilds today's list. Called on launch, on foreground, at midnight, and on a
    /// time-zone change — the four moments the old `isDateInToday` check missed.
    func refreshDay() {
        game.advance()
        game.lastOpenedAt = Date()
        rescheduleReminders()
    }

    func flush() { store.flush() }

    // MARK: - Canvas

    func syncCanvas() async {
        guard let client = makeClient(game) else {
            canvasStatus = "Pair with Prepkin for Canvas in Chrome to see Canvas here."
            canvasLink = .notSetUp
            return
        }
        // If the user disconnects (or re-pairs) while this fetch is in the air, the
        // response belongs to a pairing that no longer exists. Drop it.
        let codeAtStart = game.pairingCode
        do {
            let snapshot = try await client.fetchTodo()
            guard game.pairingCode == codeAtStart else { return }
            let before = Set(game.tasks.map(\.id))
            game.applyCanvas(snapshot)
            ReviewPrompt.askIfEarned(finishedCanvasItems: game.canvasItems.filter(\.isSubmitted).count)
            // Pay what the laptop asked for — finished focus sessions, looks
            // bought in its shop — then tell it the balance and what it can stop
            // re-sending. Without this half the extension's coins never arrive.
            game.applyBridgeRequests(snapshot.requests)
            let state = game.bridgeState
            Task { try? await client.pushState(state) }
            if let version = snapshot.extensionVersion,
               CanvasSnapshot.isOlder(version, than: CanvasSnapshot.minimumExtensionVersion) {
                canvasStatus = "Update Prepkin for Canvas in Chrome to keep getting your work."
            } else {
                canvasStatus = nil
            }
            canvasLink = .connected
            rescheduleReminders()
            // New homework just dropped in — a startled "whoa!", but never
            // interrupting an animation that is already playing.
            if animation == .idle, game.tasks.contains(where: { !before.contains($0.id) }) {
                play(.startle)
            }
        } catch BridgeError.notPairedYet {
            guard game.pairingCode == codeAtStart else { return }
            if game.lastCanvasSyncAt != nil {
                canvasStatus = "Your laptop's link ran out. Make a new code and paste it into Chrome."
                canvasLink = .expired
            } else {
                canvasStatus = "Waiting for your laptop to send its first list."
                canvasLink = .waitingForLaptop
            }
        } catch {
            guard game.pairingCode == codeAtStart else { return }
            // Keep whatever is already on the list. A dropped connection is not a
            // reason to empty somebody's day.
            canvasStatus = "Could not reach your laptop just now. Showing your last list."
            canvasLink = .offline
        }
    }

    // MARK: - Study Together

    /// Whether anybody is at the table. Drives one line on the Focus screen and
    /// nothing else; when it is false the feature is invisible rather than empty.
    var anyoneFocusing: Bool { !liveFocusPresences.isEmpty }

    /// Presences that are still running as of now. The list is refreshed on a screen
    /// appearing rather than on a timer, so it is filtered again on read.
    var liveFocusPresences: [FocusPresence] { friendsFocusing.filter { $0.isLive() } }

    /// Asks the bridge who is working. Silent on every failure: a friend who cannot
    /// be seen right now is the same as a friend who is not working, and neither is
    /// worth an error on a screen whose whole job is to be calm.
    ///
    /// Does nothing without an identity. Today the only thing that mints one is
    /// joining a league pod; when the friends flow lands it will mint one too, and
    /// this reads whatever is there.
    func refreshFriendsFocusing() async {
        var identity = game.league.identity
        #if DEBUG
        // `-fakeTable` seats friends before anything has minted a real identity.
        if identity == nil, ProcessInfo.processInfo.arguments.contains(MockStudyClient.fakeTableArgument) {
            identity = LeagueIdentity(id: "debug", token: "debug", adjective: 0, noun: 0)
        }
        #endif
        guard let identity, let client = makeStudyClient(game) else {
            friendsFocusing = []
            return
        }
        // Whose answer this is. Compared again after the call so a student who erased
        // their player mid-flight does not get a table back. Nil under `-fakeTable`,
        // where nothing was ever minted and there is nothing to invalidate.
        let asked = game.league.identity
        do {
            let rows = try await client.friendsFocusing(identity: identity)
            guard game.league.identity == asked else { return }
            friendsFocusing = rows
        } catch {
            friendsFocusing = []
        }
    }

    /// Says a session has started, so friends can see the row and join. Fire and
    /// forget: the timer on this phone never waits on the bridge, and a session that
    /// nobody else could see still counts for everything it counts for.
    func announceFocus(minutes: Int) {
        guard let identity = game.league.identity, let client = makeStudyClient(game) else { return }
        Task { _ = try? await client.startFocus(identity: identity, minutes: minutes) }
    }

    /// Says it is over, early or otherwise. Also fire and forget — the row expires on
    /// its own, so the worst a dropped call costs is a friend seeing a clock run out.
    func endFocusAnnouncement() {
        guard let identity = game.league.identity, let client = makeStudyClient(game) else { return }
        Task { try? await client.endFocus(identity: identity) }
    }

    // MARK: - The league pod

    /// The board as it was last seen, kept across launches so opening the tab with no
    /// signal shows standings rather than a blank card. `nil` before the first sync.
    var pod: PodSnapshot? { game.league.lastPod }
    /// This phone's own two-word name, or `nil` before there is one.
    var podName: String? { game.league.identity?.displayName }
    var podOptIn: Bool { game.league.podOptIn }

    /// Turns the pod on and fetches a board.
    ///
    /// This is the only thing in the app that creates a row on the pod bridge, so a
    /// student who never taps it is not out there at all.
    func joinLeaguePod() async {
        guard !game.league.podOptIn else { return }
        game.league.podOptIn = true
        await syncLeague()
    }

    /// Leaves this week's pod and turns the pod back off.
    ///
    /// Off, not "off until the next sync": leaving while still opted in would simply
    /// re-join on the next pass, which is a Leave button that does nothing.
    ///
    /// The identity survives. It is this phone, not this pod, and keeping it is what
    /// stops a second row being minted the next time somebody comes back.
    func leaveLeaguePod() async {
        let identity = game.league.identity
        game.league.podOptIn = false
        game.league.podID = nil
        game.league.podWeek = nil
        game.league.lastPod = nil
        leagueStatus = nil
        guard let identity, let client = makeLeagueClient(game) else { return }
        try? await client.leavePod(identity: identity)
    }

    /// The erase button: drop the identity here and tell the bridge to forget the row.
    /// One call, not leave-then-forget — deleting the row takes the pod membership
    /// with it.
    ///
    /// Nothing on the ladder moves. The tier and the pennants are this phone's own
    /// record of its own weeks; the pod never earned them and cannot take them.
    func forgetLeaguePlayer() async {
        let identity = game.league.identity
        game.league.podOptIn = false
        game.league.podID = nil
        game.league.podWeek = nil
        game.league.lastPod = nil
        game.league.identity = nil
        leagueStatus = nil
        guard let identity, let client = makeLeagueClient(game) else { return }
        try? await client.forgetPlayer(identity: identity)
    }

    /// Publishes this week's coins and brings the ranked pod back.
    ///
    /// A no-op unless the student opted in, and nothing here mints a player on its
    /// own. Safe to call on every foreground and every pull-to-refresh.
    ///
    /// The number it publishes is one only this phone has ever seen — every coin is an
    /// honour-system check-off made offline. The bridge cannot verify it and does not
    /// pretend to; see `SupabaseLeagueClient.pushPoints` for what it can do instead,
    /// and why the ladder stays climb-only because of it.
    func syncLeague() async {
        guard game.league.podOptIn else { return }
        guard let client = makeLeagueClient(game) else {
            leagueStatus = "The pod needs a connection."
            return
        }
        do {
            // The identity is settled once, up front. If the student leaves or erases
            // while a call is in the air, the answer belongs to a league this phone is
            // no longer in, and every guard below drops it on the floor.
            guard let identity = try await leagueIdentity(client) else { return }
            let kin = game.activeChibi
            let week = WeekKey(game.effectiveDay)

            if !game.league.isPodCurrent(for: week) {
                let placement = try await client.joinPod(identity: identity, species: kin.speciesID,
                                                         look: kin.skinID, level: kin.level)
                guard game.league.identity == identity else { return }
                game.league.podID = placement.podID
                // A bridge that does not name the week is taken to mean this one,
                // rather than leaving a blank that makes every sync re-join.
                game.league.podWeek = placement.week.raw.isEmpty ? week : placement.week
            }

            let board = try await client.pushPoints(identity: identity, points: game.leaguePoints,
                                                    species: kin.speciesID, look: kin.skinID,
                                                    level: kin.level)
            guard game.league.identity == identity else { return }
            game.league.podID = board.podID
            game.league.podWeek = board.week.raw.isEmpty ? week : board.week
            game.league.lastPod = board
            leagueStatus = nil
        } catch LeagueError.notInPod {
            guard game.league.podOptIn else { return }
            // The bridge says this pod is gone — its week rolled over on that side, or
            // the row was purged. Forget which pod it was and the next pass joins a
            // new one. The student is not told off for it.
            game.league.podID = nil
            game.league.podWeek = nil
            leagueStatus = "Finding you a pod."
        } catch {
            guard game.league.podOptIn else { return }
            // Keep the board that is on screen. A dropped connection is not a reason
            // to empty somebody's standings.
            leagueStatus = "Could not reach the pod. Showing the last board."
        }
    }

    /// The identity to work with, minting one on the bridge the first time.
    ///
    /// Returns `nil` when the student opted out while `create_player` was in the air.
    /// The row exists but this phone no longer wants it, so it is dropped rather than
    /// saved — an unused row is the bridge's to purge, and keeping it here would mean
    /// a student who changed their mind is still out there.
    private func leagueIdentity(_ client: LeagueClient) async throws -> LeagueIdentity? {
        if let existing = game.league.identity { return existing }
        let made = try await client.createPlayer()
        guard game.league.podOptIn, game.league.identity == nil else { return nil }
        game.league.identity = made
        return made
    }

    // MARK: - Pairing

    var pairingCode: String? { game.pairingCode }
    var lastCanvasSyncAt: Date? { game.lastCanvasSyncAt }
    var isBridgeConfigured: Bool { BridgeConfig.shared.isConfigured }

    /// The code shown on screen. Claiming it on the bridge is what actually
    /// creates the row the laptop later binds to, so this kicks that off and the
    /// UI watches `pairingStatus` rather than blocking on the network.
    @discardableResult
    func ensurePairingCode() -> String {
        let code = game.ensurePairingCode()
        if game.pairingToken == nil { Task { await claimPairingCode() } }
        return code
    }

    /// Trades the code for this phone's own token. A code somebody else already
    /// holds is refused by the bridge, and the app quietly rolls a new one rather
    /// than joining a stranger's row.
    func claimPairingCode() async {
        guard BridgeConfig.shared.isConfigured else { return }
        for attempt in 0..<3 {
            let code = game.pairingCode ?? game.ensurePairingCode()
            do {
                if let token = try await SupabaseCanvasClient.claimCode(code) {
                    game.pairingToken = token
                    pairingStatus = nil
                    return
                }
                // Taken. Roll a fresh code and try again.
                game.pairingCode = PairingCode.generate()
                _ = attempt
            } catch {
                pairingStatus = "Could not get a code just now. Pull down to try again."
                return
            }
        }
        pairingStatus = "Could not make a pairing code. Try again in a moment."
    }

    // MARK: - Friends

    var friendCode: String? { game.friendCode }
    var friends: [Friend] { game.friends }
    var pendingFriendCodes: [String] { game.pendingFriendCodes }

    @discardableResult
    func ensureFriendCode() -> String { game.ensureFriendCode() }

    func addPendingFriendCode(_ code: String) { game.addPendingFriendCode(code) }
    func removePendingFriendCode(_ code: String) { game.removePendingFriendCode(code) }

    func unpair() {
        // Delete the row first — the token that proves it is ours is about to be
        // thrown away, and a row left to expire keeps a student's coursework
        // readable for another month.
        if let code = game.pairingCode, let token = game.pairingToken,
           BridgeConfig.shared.isConfigured {
            Task { try? await SupabaseCanvasClient(code: code, token: token).deletePairing() }
        }
        game.unpair()
        canvasStatus = nil
        canvasLink = .notSetUp
        pairingStatus = nil
    }

    // MARK: - Tasks

    func complete(_ task: DailyTask) {
        let paid = game.complete(taskID: task.id, reward: task.reward)
        guard paid > 0 else { return }
        play(game.allDone ? .celebrate : .bounce)
        rescheduleReminders()
    }

    /// Undo a check-off. Takes the coins back, plays nothing. Never a penalty.
    func uncomplete(_ task: DailyTask) {
        game.uncomplete(taskID: task.id)
        rescheduleReminders()
    }

    func addTask(title: String, kind: TaskKind, recurrence: Recurrence) {
        game.addTask(title: title, kind: kind, recurrence: recurrence)
        rescheduleReminders()
    }

    func setTemplate(_ id: String, active: Bool) {
        game.setTemplate(id, active: active)
        rescheduleReminders()
    }

    func deleteTask(_ id: String) {
        game.deleteTask(id)
        rescheduleReminders()
    }

    // MARK: - Other earnings

    func recordFocus(minutes: Int) {
        let paid = game.recordFocus(minutes: minutes)
        if paid > 0 { play(minutes >= 25 ? .celebrate : .bounce) }
    }

    /// Miles from a finished shift. Called for a clock-out too — the miles were
    /// still driven.
    func recordShift(miles: Int) {
        game.recordShift(miles: miles)
    }

    /// `dealtDay` is the day the puzzle was dealt, so a solve finished just past
    /// midnight settles the word it actually was.
    func recordWordleWin(guesses: Int, dealtDay: DayKey) {
        if game.recordWordleWin(guesses: guesses, day: dealtDay) > 0 { play(.celebrate) }
    }

    /// The guesses made on the word dealt on `day`. Empty for any other day.
    func wordleGuesses(for day: DayKey) -> [String] {
        game.wordleGuessDay == day ? game.wordleGuesses : []
    }

    func saveWordleGuesses(_ guesses: [String], for day: DayKey) {
        game.wordleGuesses = guesses
        game.wordleGuessDay = day
    }

    var numberLineClaimedToday: Bool { game.numberLineClaimedToday }

    /// True once any game has banked today's Play coins.
    var playClaimedToday: Bool { game.playClaimedToday }
    /// The game that banked them, for the "Today's 30 banked by Ladder" line.
    var playBankedBy: CoinReason? { game.playBanked(on: game.effectiveDay) }

    /// Returns what was paid: 30 for the first game finished today, 0 after.
    @discardableResult
    func recordPlaySolve<P>(_ path: WritableKeyPath<GameState, PlayRecord<P>>, reason: CoinReason,
                            dealtDay: DayKey) -> Int {
        let paid = game.recordPlaySolve(path, reason: reason, day: dealtDay)
        if paid > 0 { play(.celebrate) }
        return paid
    }

    func playProgress<P>(_ path: KeyPath<GameState, PlayRecord<P>>, for day: DayKey) -> P? {
        game.playProgress(path, for: day)
    }

    func savePlayProgress<P>(_ path: WritableKeyPath<GameState, PlayRecord<P>>, _ progress: P,
                             startedAt: Date? = nil, day: DayKey,
                             puzzleRating: Int = Rating.unrated) {
        game.savePlayProgress(path, progress, startedAt: startedAt, day: day,
                              puzzleRating: puzzleRating)
    }

    /// The puzzle rating, for the end card and the Play rail.
    var rating: PlayerRating { game.rating }

    /// The stopwatch start for today's board, if it was touched today.
    func playStartedAt<P>(_ path: KeyPath<GameState, PlayRecord<P>>, for day: DayKey) -> Date? {
        game[keyPath: path].progressDay == day ? game[keyPath: path].startedAt : nil
    }

    /// Returns what was paid: 30 if this is the first game finished today, 0 after.
    @discardableResult
    func finishNumberLineRound(accuracy: Int) -> Int {
        let paid = game.recordNumberLineRound(accuracy: accuracy)
        if paid > 0 { play(.celebrate) }
        return paid
    }

    /// Pays for a finished deck and returns what it paid, so the finish card can show
    /// the coins flying only when coins actually moved. A re-read pays 0 and is silent.
    @discardableResult
    func completeLesson(id: String, reward: Int) -> Int {
        let paid = game.completeLesson(id: id, reward: reward)
        if paid > 0 { play(.celebrate) }
        return paid
    }

    // MARK: - Learn

    func deckProgress(_ lessonID: String) -> Int { game.deckProgress(lessonID) }

    func setDeckProgress(_ lessonID: String, card index: Int) {
        game.setDeckProgress(lessonID, card: index)
    }

    func isSaved(lessonID: String, index: Int) -> Bool {
        game.isSaved(lessonID: lessonID, index: index)
    }

    @discardableResult
    func toggleSaved(lessonID: String, index: Int) -> Bool {
        game.toggleSaved(lessonID: lessonID, index: index)
    }

    func markTapCoachSeen() { game.hasSeenTapCoach = true }

    func reportCard(lessonID: String, index: Int, reason: CardReportReason) {
        game.reportCard(lessonID: lessonID, index: index, reason: reason)
    }

    // MARK: - First run

    /// The end of the two-screen first run: every preset is switched to match the
    /// three picks, and Root moves on to Home.
    func finishFirstRun(picked: Set<String>) {
        for t in game.templates where t.isPreset {
            game.setTemplate(t.id, active: picked.contains(t.id))
        }
        game.firstRunDone = true
        rescheduleReminders()
    }

    func markFirstRunOffersDone() { game.firstRunOffersDone = true }

    /// The deck offered under Continue: the one you are furthest into. Finished decks
    /// clear their progress, so this only ever offers something genuinely unfinished.
    var continueLesson: (lesson: Lesson, card: Int)? {
        game.deckProgress
            .compactMap { id, index -> (Lesson, Int)? in
                guard let lesson = Catalog.lesson(id), index < lesson.cards.count else { return nil }
                return (lesson, index)
            }
            .max { $0.1 < $1.1 }
            .map { (lesson: $0.0, card: $0.1) }
    }

    var lessonSuggestions: [Catalog.Suggestion] {
        // A deck already on offer under Continue must not be offered twice on the
        // same screen, so it counts as spoken for here.
        var spokenFor = completedLessons
        if let cont = continueLesson { spokenFor.insert(cont.lesson.id) }
        return Catalog.suggestions(for: tasks, completed: spokenFor)
    }

    // MARK: - Spending

    func upgradeActiveChibi() {
        if game.upgradeActiveChibi() { play(.celebrate) }
    }

    func buy(_ species: ChibiSpecies) {
        if game.buy(species) { play(.celebrate) }
    }

    func buyScene(_ scene: Scene0) {
        let price = game.currentPrice("scene:\(scene.id)")
        guard coins >= price else {
            // The picks row already prints "N to go" on the slot; a tap that does
            // nothing at all was the only place the shop went quiet.
            show("\(price - coins) to go. Nothing here expires.")
            return
        }
        if game.buyScene(scene) {
            play(.celebrate)
            game.equipScene(scene.id)
            show("\(scene.name) is your scene")
        }
    }

    func equipScene(_ id: String) {
        game.equipScene(id)
        show("\(Scene0.find(id).name) is your scene")
    }

    func setActive(_ speciesID: String) {
        game.setActive(speciesID)
        play(.wave)
        if let kin = ownedKin(speciesID) { show("\(kin.displayName) is your active kin") }
    }

    // MARK: - Kin

    /// The purchase ceremony, as one path: confirm, arrival, naming, certificate.
    /// Every step after the first can be left, and leaving keeps the kin.
    struct Adoption: Equatable {
        enum Step { case confirm, arrival, naming, certificate }
        var species: ChibiSpecies
        var step: Step = .confirm
        var draftName: String = ""
    }

    func beginAdoption(_ species: ChibiSpecies) {
        adoption = Adoption(species: species, draftName: Self.shuffleName())
    }

    /// Takes the coins and hands back the kin. Returns false only when the balance
    /// moved underneath us; the sheet never opens without the coins being there.
    @discardableResult
    func confirmAdoption() -> Bool {
        guard var flow = adoption, game.adopt(flow.species) else { return false }
        play(.celebrate)
        flow.step = .arrival
        adoption = flow
        return true
    }

    func advanceAdoption(to step: Adoption.Step) {
        guard var flow = adoption else { return }
        flow.step = step
        adoption = flow
    }

    func shuffleDraftName() {
        guard var flow = adoption else { return }
        var next = Self.shuffleName()
        while next == flow.draftName { next = Self.shuffleName() }
        flow.draftName = next
        adoption = flow
    }

    func commitName() {
        guard let flow = adoption else { return }
        game.rename(flow.species.id, to: flow.draftName)
        advanceAdoption(to: .certificate)
    }

    func rename(_ speciesID: String, to name: String) {
        game.rename(speciesID, to: name)
    }

    func endAdoption() { adoption = nil }

    /// One tap from the kin's sheet: pay and go straight to the arrival screen.
    /// The sheet already showed the price and the wallet after, so a second
    /// confirm sheet was the same question asked twice.
    func adoptNow(_ species: ChibiSpecies) {
        beginAdoption(species)
        confirmAdoption()
    }

    /// "Meet <kin>" on the certificate. Ends the flow and asks Root for the Kin tab.
    func meetKin(_ species: ChibiSpecies) {
        if activeChibiID != species.id { setActive(species.id) }
        endAdoption()
        meetKinRequest = species.id
    }

    private static func shuffleName() -> String {
        GameState.shuffleNames.randomElement() ?? "Moss"
    }

    // MARK: - Shop picks

    var rerollsLeft: Int { game.rerollsLeft }
    var rerollCanChange: Bool { game.rerollCanChange }

    /// Free, three a day, never confirmed. The 420ms flag is only so the row can
    /// stagger; nothing is disabled while it runs, because there is no cost to
    /// protect against a double tap.
    func rerollPicks() {
        let held = game.lockedPick.flatMap { game.resolvePick($0)?.name }
        // Late on there is less left to own than the row has slots, so every draw is
        // the same draw. Spending a free reroll to watch nothing move is worse than
        // not offering one.
        guard game.rerollCanChange else {
            show("This is everything you don't own yet.")
            return
        }
        guard game.rerollPicks() else {
            show("No rerolls left today. New picks tomorrow.")
            return
        }
        rerolling = true
        // Counted, never the hard-coded five: the row shrinks as the collection fills.
        let changed = max(0, game.picks.count - (held == nil ? 0 : 1))
        let noun = changed == 1 ? "1 new pick" : "\(changed) new picks"
        show(held.map { "\(noun) · \($0) kept" } ?? noun)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            rerolling = false
        }
    }

    /// Rolls the row over if the day changed, or backfills a slot that was bought.
    func refreshPicks() { game.refreshPicksIfNeeded() }

    func toggleLock(_ id: String) {
        let wasLocked = game.lockedPick == id
        game.toggleLock(id)
        guard !wasLocked, let pick = game.resolvePick(id) else { return }
        show("\(pick.name) held at \(pick.price) · long-press again to release")
    }

    // MARK: - Care

    /// Free, unlimited, no cooldown, no counter, no coins either way. The kin has no
    /// meter to fill and nothing it needs from the student.
    func care(_ kind: CareKind) {
        play(kind.animation)
    }

    enum CareKind: CaseIterable {
        case pet, highFive, snack

        var animation: ChibiAnimation {
            switch self {
            case .pet: return .bounce
            case .highFive: return .wave
            case .snack: return .celebrate
            }
        }
        var label: String {
            switch self {
            case .pet: return "Pet"
            case .highFive: return "High five"
            case .snack: return "Snack"
            }
        }
        var glyph: KinGlyph {
            switch self {
            case .pet: return .pet
            case .highFive: return .highFive
            case .snack: return .snack
            }
        }
        func bubble(_ name: String) -> String {
            switch self {
            case .pet: return "\(name) leans into it."
            case .highFive: return "Nailed it."
            case .snack: return "Crunch."
            }
        }
    }

    // MARK: - Toast

    func show(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2400))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    // MARK: - Reminders

    /// Turning reminders on is the only thing that asks iOS for permission. If the
    /// user says no at the system prompt, the switch goes back off rather than
    /// pretending it worked.
    func setRemindersEnabled(_ on: Bool) async {
        if on {
            let granted = await NotificationScheduler.shared.requestAuthorization()
            game.settings.remindersEnabled = granted
        } else {
            game.settings.remindersEnabled = false
        }
        await NotificationScheduler.shared.reschedule(for: game)
    }

    func setNudgeHour(_ hour: Int) {
        game.settings.nudgeHour = min(max(hour, 6), 23)
        rescheduleReminders()
    }

    func setDueReminders(_ on: Bool) {
        game.settings.dueRemindersEnabled = on
        rescheduleReminders()
    }

    func setComeBackReminders(_ on: Bool) {
        game.settings.comeBackRemindersEnabled = on
        rescheduleReminders()
    }

    private func rescheduleReminders() {
        guard game.settings.remindersEnabled else { return }
        let snapshot = game
        Task { await NotificationScheduler.shared.reschedule(for: snapshot) }
    }

    // MARK: - Mascot

    /// Play a one-shot animation, then fall back to idle.
    private var animationToken = UUID()
    func play(_ anim: ChibiAnimation) {
        animation = anim
        let token = UUID()
        animationToken = token
        Task {
            try? await Task.sleep(for: .seconds(anim.duration))
            if animationToken == token { animation = .idle }
        }
    }
}
