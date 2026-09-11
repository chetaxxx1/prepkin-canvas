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
        didSet {
            store.save(game)
            // The gift week arms itself inside `GameState`, on the third finished
            // Canvas task, because it has to land whether or not anyone is looking
            // at the screen that would have noticed. This is the only place that can
            // say so: one line, once, and never announced before it arrives.
            if oldValue.plus.giftStartedAt == nil, game.plus.giftStartedAt != nil {
                syncPlus(paid: plusAccess.paid)
                show("Plus is on for a week. Nothing to cancel.")
            }
            // Both are cheap: a handful of values compared, and each leaves
            // immediately unless the thing it publishes actually changed.
            pushTankIfNeeded()
            pushTodayIfNeeded()
        }
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

    /// Friends' day rows for the last week, newest per friend. Not persisted: it is
    /// a fact about today that goes stale by tomorrow, and a cached one would draw
    /// yesterday's work under somebody's name.
    @Published private(set) var friendDays: [DayRow] = []

    /// One quiet line for the Add a friend screen when a call could not be made.
    /// Never an error about a code: a code that opens nothing is answered on the
    /// screen itself, in the same words every time.
    @Published var friendStatus: String?

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
    /// Sitting down beside a friend: how many minutes to start. Root switches to
    /// Focus and Focus starts the shift and clears it. Never persisted — it is only
    /// ever about the next few seconds.
    @Published var joinShiftRequest: Int?
    /// The Tomorrow line on Home was tapped. Root switches to the Calendar tab and
    /// Calendar opens on this day. Cleared by Calendar once it lands; never persisted.
    @Published var openCalendarOn: DayKey?

    private var toastTask: Task<Void, Never>?
    /// The last (costume, scene) the bridge was told about, and the call waiting to
    /// tell it about the next one. See `pushTankIfNeeded`.
    private var lastTankPushed: TankPush?
    private var tankPush: Task<Void, Never>?
    /// The last day counts the bridge was told about, and the call waiting to tell
    /// it about the next ones. See `pushTodayIfNeeded`.
    private var lastTodayPushed: TodayPush?
    private var todayPush: Task<Void, Never>?

    private let store: Store
    private let makeClient: (GameState) -> CanvasSyncClient?
    private let makeLeagueClient: (GameState) -> LeagueClient?
    private let makeStudyClient: (GameState) -> StudyClient?
    private let makeFriendClient: (GameState) -> FriendClient?

    /// Real bridge once there is a pairing code. Sample data only in a checkout
    /// with no bridge configured at all, so a demo is never an empty page — but a
    /// real install that unpairs gets nothing, not fake homework that pays coins.
    nonisolated static func defaultClient(for state: GameState, config: BridgeConfig = .shared) -> CanvasSyncClient? {
        guard config.isConfigured else { return MockCanvasClient() }
        #if DEBUG
        // `-sampleCanvas` shows the sample feed on a simulator that has no
        // laptop to pair with. DEBUG only, and a separate switch from
        // `-unlockAll` so the pairing tests keep seeing the real client.
        if ProcessInfo.processInfo.arguments.contains("-sampleCanvas") { return MockCanvasClient() }
        #endif
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

    /// Same rule again, and the mock deliberately has nobody in it. Friends do not
    /// ride on the Canvas pairing or on the pod: a student with neither still has
    /// the tab, so there is nothing else to check.
    nonisolated static func defaultFriendClient(for state: GameState,
                                                config: BridgeConfig = .shared) -> FriendClient? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(MockFriendClient.fakeFriendArgument) {
            return MockFriendClient.seededForTesting()
        }
        #endif
        guard config.isConfigured else { return MockFriendClient() }
        return SupabaseFriendClient()
    }

    init(store: Store = .shared,
         makeClient: @escaping (GameState) -> CanvasSyncClient? = { AppState.defaultClient(for: $0) },
         makeLeagueClient: @escaping (GameState) -> LeagueClient? = { AppState.defaultLeagueClient(for: $0) },
         makeStudyClient: @escaping (GameState) -> StudyClient? = { AppState.defaultStudyClient(for: $0) },
         makeFriendClient: @escaping (GameState) -> FriendClient? = { AppState.defaultFriendClient(for: $0) }) {
        self.store = store
        self.makeClient = makeClient
        self.makeLeagueClient = makeLeagueClient
        self.makeStudyClient = makeStudyClient
        self.makeFriendClient = makeFriendClient
        var loaded = store.load()
        loaded.advance()
        loaded.lastOpenedAt = Date()
        game = loaded
        #if DEBUG
        // Launch with `-unlockAll` to open the whole catalogue, and it stays open on the
        // launches after that one. See DebugUnlock.swift.
        if DebugUnlock.isOn {
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
    var puzzlesThisMonth: Int { game.puzzlesThisMonth() }
    var lessonDoneToday: Bool { game.lessonDoneToday }
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
    var lockedPicks: Set<String> { game.lockedPicks }
    func isHeld(_ id: String) -> Bool { game.lockedPicks.contains(id) }
    func canHoldMore(_ id: String) -> Bool { game.canHoldMore(id) }
    var holdLimit: Int { game.holdLimit }
    var pickSlots: Int { game.pickSlots }
    var pickDiscountPercent: Int { game.discountPercent }

    // MARK: - Plus

    /// Everything that can make this student Plus: a live subscription, the gift
    /// week, or `-unlockAll`. Set by `syncPlus` and read by every gate.
    @Published private(set) var plusAccess = PlusAccess.none
    var isPlus: Bool { plusAccess.isOn() }

    /// Takes StoreKit's answer and folds in the gift week and the debug flag.
    ///
    /// Called on launch, whenever the entitlement changes, and after the gift is
    /// armed. `game.plusIsOn` is the shop's cached copy; nothing else caches it.
    func syncPlus(paid: Bool, now: Date = Date()) {
        plusAccess = game.plusAccess(paid: paid)
        let on = plusAccess.isOn(at: now)
        guard game.plusIsOn != on else { return }
        game.plusIsOn = on
        // The row is five slots long or seven; changing the entitlement changes it
        // today, not tomorrow.
        game.refreshPicksIfNeeded(now: now)
    }

    /// Today's season rung, claimed. Returns what was handed over, or nil when
    /// today is not claimable — the card asks `SeasonClaim.check` for the reason.
    @discardableResult
    func claimSeasonRung(_ season: Season, now: Date = Date()) -> GameState.SeasonPayout? {
        guard let payout = game.claimSeasonRung(season, isPlus: isPlus, now: now) else { return nil }
        play(.celebrate)
        return payout
    }

    /// The season running today, if there is one. Nothing is drawn between seasons.
    var currentSeason: Season? { Season.current(on: DayKey.today()) }

    // MARK: - Saved looks

    var savedLooks: [SavedLook] { game.plus.savedLooks }
    var savedLookLimit: Int { game.savedLookLimit(plusAccess) }
    var canSaveLook: Bool { game.plus.canSave(savedLookLimit) }

    @discardableResult
    func saveLook(named name: String) -> Bool {
        let ok = game.saveCurrentLook(name: name, access: plusAccess)
        show(ok ? "\(name) saved." : "Three saved looks on free. Plus saves as many as you like.")
        return ok
    }

    func wearSavedLook(_ id: String) {
        game.wearSavedLook(id)
        play(.bounce)
    }

    /// Always allowed, at any number, paid or not. Nobody has to pay to get out of
    /// a full shelf.
    func removeSavedLook(_ id: String) { game.plus.removeLook(id) }

    /// The one moment the sheet is owed: the week was given, it has run out, and
    /// nobody has been shown it yet.
    var giftJustEnded: Bool { game.plus.giftJustEnded() }

    /// Marks it shown, so it can never appear a second time.
    func markGiftSheetShown() { game.plus.giftSheetShown = true }

    /// The gift week, armed the first time three Canvas tasks are finished.
    /// Returns true on the single call that starts it, which is the only time the
    /// quiet line is shown.
    @discardableResult
    func armGiftWeekIfEarned(now: Date = Date()) -> Bool {
        guard game.armGiftWeekIfEarned(now: now) else { return false }
        plusAccess = game.plusAccess(paid: plusAccess.paid)
        game.plusIsOn = plusAccess.isOn(at: now)
        game.refreshPicksIfNeeded(now: now)
        return true
    }

    func currentPrice(_ id: String) -> Int { game.currentPrice(id) }
    func workToAfford(_ id: String) -> String? { game.workToAfford(id) }
    func workToAfford(price: Int) -> String? { game.workToAfford(price: price) }
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
        // The row is about to be deleted, and every friendship goes with it. Leaving
        // the list on screen would draw people this phone can no longer reach.
        game.friends = []
        game.friendCode = nil
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
    /// One line of what is on tomorrow, or `nil` when tomorrow is empty.
    var tomorrowLine: String? { game.tomorrowLine() }
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
    /// The people to put a card at the top of the tab for. See `FriendList.added`.
    var friendsWhoAddedYou: [Friend] { FriendList.added(in: game.friends) }

    /// What `addFriend` did, in the three words the screen needs.
    enum AddFriendOutcome: Equatable {
        case added(Friend)
        /// The code opens nothing. Never says whether it exists — a typo, a
        /// replaced code and somebody who blocked you all land here.
        case nothing
        case couldNotReach
    }

    /// Who this phone is on the bridge, minting one the first time somebody asks.
    ///
    /// One identity serves the pod, Study Together and friends; it already served
    /// two of those. Called when the Add a friend screen opens, which is the first
    /// moment a student has asked for anything social — a student who never opens
    /// it has no row out there at all.
    @discardableResult
    func ensureIdentity() async -> LeagueIdentity? {
        if let existing = game.league.identity { return existing }
        guard let client = makeLeagueClient(game) else { return nil }
        guard let made = try? await client.createPlayer() else { return nil }
        // Two screens can ask at once. Whoever landed first owns it, and the other
        // row is the bridge's to purge.
        guard game.league.identity == nil else { return game.league.identity }
        game.league.identity = made
        return made
    }

    /// Fills `friendCode` from the bridge. Idempotent, and safe on every open.
    func loadMyCode() async {
        guard let identity = await ensureIdentity(), let client = makeFriendClient(game) else { return }
        guard let code = try? await client.myCode(identity: identity) else { return }
        guard game.league.identity == identity else { return }
        game.friendCode = code
    }

    /// Hands out a new code. The old one stops opening anything, which is how a
    /// student takes back a code they have already sent to somebody.
    func rotateMyCode() async {
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        guard let code = try? await client.rotateCode(identity: identity) else {
            friendStatus = "Could not get a new code just now. Try again in a moment."
            return
        }
        guard game.league.identity == identity else { return }
        game.friendCode = code
        friendStatus = nil
    }

    /// Adds by code, and puts them on the tab.
    func addFriend(code: String) async -> AddFriendOutcome {
        guard let identity = await ensureIdentity(), let client = makeFriendClient(game) else {
            return .couldNotReach
        }
        do {
            guard let friend = try await client.addFriend(identity: identity, code: code) else {
                return .nothing
            }
            guard game.league.identity == identity else { return .couldNotReach }
            game.addFriend(friend)
            return .added(friend)
        } catch {
            return .couldNotReach
        }
    }

    /// Draws the whole tab in one call. Silent on every failure: the list already on
    /// screen stays, because a dropped connection is not a reason to empty somebody's
    /// friends.
    func refreshFriends() async {
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        guard let rows = try? await client.fetchFriends(identity: identity) else { return }
        guard game.league.identity == identity else { return }
        game.applyFriends(rows)
    }

    func setNickname(_ raw: String, for id: String) { game.setNickname(raw, for: id) }

    func markFriendSeen(_ id: String) { game.markFriendSeen(id) }

    /// Instant and silent, both of them. The row goes now; the bridge is told after,
    /// and a failed call leaves a row that the next fetch puts back rather than a
    /// student stuck looking at somebody they just removed.
    func removeFriend(_ id: String) {
        game.dropFriend(id)
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        Task { try? await client.removeFriend(identity: identity, friendID: id) }
    }

    func blockFriend(_ id: String) {
        game.dropFriend(id)
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        Task { try? await client.blockPlayer(identity: identity, playerID: id) }
    }

    /// Sends two ids and a time. The friendship is left alone — reporting somebody
    /// and wanting them gone are two different taps, and the menu offers both.
    func reportFriend(_ id: String) {
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        Task { try? await client.reportPlayer(identity: identity, playerID: id) }
    }

    // MARK: - Today

    /// This phone's own four counts for today, read off the ledger.
    var todayCounts: TodayCounts { TodayCounts(ledger: game.ledger, day: game.effectiveDay) }

    /// One friend's today, or nothing at all.
    ///
    /// Nothing is the common answer and it draws nothing: a friend with sharing off
    /// and a friend who has not started yet look identical on screen, which is the
    /// point of `share_today` being a flag rather than a status.
    func today(for friend: Friend) -> TodayCounts? {
        guard let counts = TodayLines.newest(friendDays, for: friend.id), !counts.isEmpty
        else { return nil }
        return counts
    }

    /// The sentence under the whole tab, or nothing.
    var weeklyTogether: String? {
        // Only friends who actually put a row in the week are counted, so the
        // headcount is never a claim about people who are not in the number.
        let contributors = game.friends.compactMap { f -> TodayCounts? in
            let mine = friendDays.filter { $0.playerID == f.id }.map(\.counts)
            guard !mine.isEmpty else { return nil }
            let week = mine.reduce(TodayCounts(), +)
            return week.isEmpty ? nil : week
        }
        return TodayLines.weekly(mine: weekOfMine, friends: contributors)
    }

    /// My own week, folded the same way a friend's is, in one pass.
    private var weekOfMine: TodayCounts {
        let now = Date()
        let days = Set((0...6).map { DayKey(now.addingTimeInterval(TimeInterval(-$0 * 86_400))) })
        return TodayCounts.week(ledger: game.ledger, days: days)
    }

    /// Asks for a week of rows, one day either side of it.
    ///
    /// **A day either side because `day` is each sender's own local day.** A friend
    /// twelve hours ahead is already writing tomorrow's date; asking only for days
    /// up to mine would leave their lines empty all day and then show them late.
    /// `fetch_today` clamps the span to a fortnight, so the extra day is free.
    func refreshToday() async {
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        let now = Date()
        let from = DayKey(now.addingTimeInterval(-7 * 86_400))
        let to = DayKey(now.addingTimeInterval(86_400))
        guard let rows = try? await client.fetchToday(identity: identity, from: from, to: to) else { return }
        guard game.league.identity == identity else { return }
        friendDays = rows
    }

    /// Publishes today's counts when they change.
    ///
    /// **Nothing leaves the phone while the switch is off.** The bridge would hide
    /// the rows from friends either way, but "we store it and promise not to show
    /// anybody" is not what the privacy sheet says, and it is not what a student
    /// reading "your fish, and nothing else" would picture. Not writing the row is
    /// also what stops turning the switch on from revealing a fortnight the student
    /// spent with it off.
    ///
    /// **Nothing is sent for an empty day.** A phone that saves at one minute past
    /// midnight would otherwise write a row of four zeros, and the bridge's promise
    /// that a friend with no row simply has no line would stop holding. And nothing
    /// is sent at all with no friends: a student who has never added anybody has
    /// nobody who could read it.
    private func pushTodayIfNeeded() {
        let want = TodayPush(day: game.effectiveDay, counts: todayCounts)
        guard game.shareToday, !want.counts.isEmpty, !game.friends.isEmpty,
              want != lastTodayPushed else { return }
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        todayPush?.cancel()
        todayPush = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.todaySettle * 1_000_000_000))
            guard !Task.isCancelled else { return }
            try? await client.pushToday(identity: identity, day: want.day, counts: want.counts)
            guard !Task.isCancelled else { return }
            self?.lastTodayPushed = want
        }
    }

    private struct TodayPush: Equatable {
        let day: DayKey
        let counts: TodayCounts
    }

    /// A minute. Checking off six things in a lesson deck is one push, not six.
    private static let todaySettle: TimeInterval = 60

    // MARK: - Waves

    /// Friends who waved at you and have not been shown yet.
    var unseenWaves: [Friend] {
        let ids = Set(game.unseenWaves(on: game.effectiveDay))
        return game.friends.filter { ids.contains($0.id) }
    }

    func hasWaved(at friend: Friend) -> Bool {
        game.hasWaved(at: friend.id, on: game.effectiveDay)
    }

    /// Waves. Settles on the phone straight away, because the button showing its
    /// settled state is the whole feedback — there is no toast and nothing to undo.
    func wave(at friend: Friend) {
        let day = game.effectiveDay
        guard !game.hasWaved(at: friend.id, on: day) else { return }
        game.markWaved(at: friend.id, on: day)
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        Task {
            _ = try? await client.sendVibe(identity: identity, friendID: friend.id,
                                           kind: Vibes.wave.kind, day: day)
        }
    }

    func markWaveSeen(_ id: String) { game.markWaveSeen(id, on: game.effectiveDay) }

    /// Who waved at you, and who you have already waved at. Silent on failure: a
    /// hello that cannot be fetched right now is the same as no hello.
    func refreshWaves() async {
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        let day = game.effectiveDay
        if let visits = try? await client.fetchVisits(identity: identity, day: day) {
            guard game.league.identity == identity else { return }
            game.applyWavesReceived(visits.map(\.sender.id), on: day)
        }
        if let sent = try? await client.fetchSent(identity: identity, day: day) {
            guard game.league.identity == identity else { return }
            game.applyWavesSent(sent, on: day)
        }
    }

    // MARK: - What friends can see

    func setSharing(today: Bool, board: Bool) {
        let wasOff = !game.shareToday
        game.shareToday = today
        game.shareBoard = board
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        Task { try? await client.setSharing(identity: identity, today: today, board: board) }
        // Turning it on starts from today, not from a fortnight ago: nothing was
        // written while it was off, so this is the first row there is.
        if today, wasOff { pushTodayIfNeeded() }
    }

    /// Publishes the two cosmetic ids a friend's screen needs, when they change.
    ///
    /// Debounced rather than sent on the tap: changing a tank is a browsing action —
    /// a student flicks through five of them — and only the one they stop on is
    /// worth a call. Nothing waits on it and nothing is told when it fails; the next
    /// change sends the current state anyway.
    private func pushTankIfNeeded() {
        let want = TankPush(costume: game.activeCostumeID, scene: game.sceneID)
        guard want != lastTankPushed else { return }
        guard let identity = game.league.identity, let client = makeFriendClient(game) else { return }
        tankPush?.cancel()
        tankPush = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.tankSettle * 1_000_000_000))
            guard !Task.isCancelled else { return }
            try? await client.setTank(identity: identity, costume: want.costume, scene: want.scene)
            guard !Task.isCancelled else { return }
            self?.lastTankPushed = want
        }
    }

    private struct TankPush: Equatable {
        let costume: String
        let scene: String
    }

    /// How long a burst of taps has to stop for before the last one is published.
    private static let tankSettle: TimeInterval = 2

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

    // MARK: - Dated tasks (the calendar)

    func tasks(on day: DayKey) -> [DailyTask] { game.tasks(on: day) }
    func events(on day: DayKey) -> [CanvasEvent] { game.events(on: day) }
    func datedTask(_ id: String) -> DatedTask? { game.datedTasks.first { $0.id == id } }

    func addDated(_ task: DatedTask) {
        game.addDated(task)
        rescheduleReminders()
    }

    func addDated(_ tasks: [DatedTask]) {
        for t in tasks { game.addDated(t) }
        if !tasks.isEmpty { play(.bounce) }
        rescheduleReminders()
    }

    func updateDated(_ task: DatedTask) {
        game.updateDated(task)
        rescheduleReminders()
    }

    func deleteDated(_ id: String) {
        game.deleteDated(id)
        rescheduleReminders()
    }

    func setScanConsent() {
        game.settings.scanConsentGiven = true
    }

    // MARK: - Other earnings

    /// `sessionID` is the ledger's idempotency key. Focus passes the id it wrote down
    /// when the shift started, so a shift restored after the app was killed pays once
    /// however many times the app is opened.
    func recordFocus(minutes: Int, sessionID: String = UUID().uuidString) {
        let paid = game.recordFocus(minutes: minutes, sessionID: sessionID)
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
    /// The game that banked them, for the "Today's 30 banked by Pearls" line.
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
            // Since the 10 Sept rebuild the grid cards do not print the gap at all
            // — the shortfall lives on the featured card alone — so this toast is
            // the whole answer to a tap on a scene you cannot afford yet.
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

    /// Wears a costume, and says so. The bounce is the same one care gives: the point
    /// of the rail is watching the kin change, so the change needs a beat of motion.
    /// Puts a Plus look on. Owning it is checked in `GameState.wear`, so a lapsed
    /// subscription keeps every look that was ever worn — signature 4, in code.
    func wear(plusLook id: String) {
        guard game.activeChibi.skinID != id else { return }
        game.ownedLooks.insert(id)
        game.wear(id)
        play(.bounce)
    }

    func wear(_ costume: Costume) {
        guard game.activeChibi.skinID != costume.id else { return }
        game.wear(costume.id)
        play(.bounce)
        show(costume.id == Costume.none.id
             ? "\(activeChibi.displayName) is back to the usual"
             : "\(activeChibi.displayName) is wearing the \(costume.name)")
    }

    /// Puts a prop in one of the tank's two slots, or clears it. Owned props only;
    /// the tray never shows a prop the student cannot place.
    func place(_ propID: String?, in slot: PropSlot) {
        game.decor.place(propID, in: slot, tank: game.sceneID)
    }

    /// Buys a costume off the Wardrobe rack and puts it straight on. Short of coins
    /// it says the gap once, the way a scene does, and nothing is greyed or locked.
    func buyCostume(_ costume: Costume) {
        guard coins >= costume.price else {
            show("\(costume.price - coins) to go. Nothing here expires.")
            return
        }
        if game.buyCostume(costume) {
            game.wear(costume.id)
            play(.celebrate)
            show("\(activeChibi.displayName) is wearing the \(costume.name)")
        }
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
        let heldNames = game.lockedPicks.compactMap { game.resolvePick($0)?.name }.sorted()
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
        // Counted, never the hard-coded five: the row shrinks as the collection fills,
        // and Plus holds up to three slots through the draw.
        let changed = max(0, game.picks.count - heldNames.count)
        let noun = changed == 1 ? "1 new pick" : "\(changed) new picks"
        show(heldNames.isEmpty ? noun : "\(noun) · \(heldNames.joined(separator: ", ")) kept")
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            rerolling = false
        }
    }

    /// Rolls the row over if the day changed, or backfills a slot that was bought.
    func refreshPicks() { game.refreshPicksIfNeeded() }

    func toggleLock(_ id: String) {
        let wasLocked = game.lockedPicks.contains(id)
        guard let pick = game.resolvePick(id) else { return }
        // A hold that cannot be taken says why, and says what the shelf is. It never
        // drops somebody else's hold to make room.
        guard wasLocked || game.canHoldMore(id) else {
            let n = game.holdLimit
            show(n == 1 ? "One slot at a time. Release the one you're holding first."
                        : "\(n) slots at a time. Release one first.")
            return
        }
        game.toggleLock(id)
        guard !wasLocked else { return }
        show("\(pick.name) held at \(pick.price) · long-press again to release")
    }

    // MARK: - Care

    /// Free, unlimited, no cooldown, no counter, no coins either way. The kin has no
    /// meter to fill and nothing it needs from the student. A tap does count toward
    /// the friendship word, which is the one thing care moves.
    func care(_ kind: CareKind) {
        play(kind.animation)
        if let stage = game.recordCare() { announce(stage) }
    }

    /// The word under the name plate: Just met, Tankmates, Buddies, Besties, Old friends.
    var friendshipStage: FriendshipStage { game.friendshipStage(activeChibi) }

    /// A day passing can move the word as well as a tap, so the Kin tab asks on open.
    func settleFriendship() {
        if let stage = game.settleFriendship() { announce(stage) }
    }

    /// The whole ceremony for a stage: one quiet line. No number, no bar, no sheet.
    private func announce(_ stage: FriendshipStage) {
        show("You and \(activeChibi.displayName) are \(stage.name.lowercased()) now.")
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
