import Foundation

import SwiftUI
import WebKit

/// Sprout, the mint pear companion, hosted in a WKWebView.
///
/// The character is web art and web motion — `ios/SproutWeb/` is a copy of the
/// Sprout repo's `npm run build` output, running in embed mode so the page draws
/// only the character: no tank plate, no HUD, transparent background. Prepkin
/// keeps drawing its own scene behind it.
///
/// The view is not interactive. Touches pass straight through to the SwiftUI
/// gestures the caller puts on top, which is how Home keeps tap-to-wave.
///
/// To refresh the art after a change in the Sprout repo:
/// ```
/// cd ~/Downloads/Sprout-handoff && npm run build
/// rm -rf ios/SproutWeb && mkdir -p ios/SproutWeb/assets ios/SproutWeb/tanks/ios
/// cp dist/index.html dist/favicon.svg ios/SproutWeb/
/// cp dist/assets/* ios/SproutWeb/assets/
/// cp dist/tanks/ios/* ios/SproutWeb/tanks/ios/
/// cp -R dist/badges ios/SproutWeb/badges
/// cp -R dist/costumes ios/SproutWeb/costumes
/// ```
/// `costumes/` holds the stage III costume layers (cut from renders of the rig);
/// without it three-star kin stand there undressed. `badges/` is the retired
/// belly-emblem art, kept so the dormant code still resolves.
/// Copy `tanks/ios/` with the bundle — Home asks the page to paint the tank
/// (`?tank=lagoon`) because a see-through WKWebView composites nothing at all.
/// Skip the full-screen playground plates; they are not used in embed.
struct SproutView: UIViewRepresentable {
    /// Which chibi the student has active. Picks Sprout's coat.
    var speciesID: String
    /// 1–3, mapped onto Sprout's three evolutions.
    var level: Int
    /// Which Sprout look the kin is wearing: `classic` or `ninja`.
    var skin: String = "classic"
    var animation: ChibiAnimation
    /// Stage-3 body radius in points. The page sizes the drawing from this
    /// rather than filling the view, because the view is deliberately larger
    /// than the character to give the jumping emotes room.
    var radius: CGFloat
    /// Tank plate to draw behind him. The page then paints the whole scene, so
    /// the web view can stay opaque — a see-through WKWebView composites
    /// nothing at all, which leaves the character invisible.
    var tank: String
    /// Painted under the page until it draws, so a cold launch is never a white
    /// block where the tank will be.
    var placeholder: UIColor = .white
    /// A see-through instance of its own, for a host that paints its own scene around
    /// him — the Focus reef. Not the shared Home view: Home's stays opaque and paints its
    /// tank, and the two are never on screen together but both keep their view alive.
    /// The page already has no background in embed mode; only the web view had one.
    ///
    /// The old note on Home said a non-opaque WKWebView composites nothing at all.
    /// Checked on 2026-09-11: this instance draws fine, under a `clipShape` ancestor too.
    var transparent: Bool = false
    /// Asleep on the sand — a paused shift. A toggle on the page, not a one-shot emote,
    /// so it is its own switch rather than an `animation` value that would time out.
    var sleeping: Bool = false
    /// Reduce Motion, pushed to the page on ready and on change. The page also
    /// reads the system setting itself; this is the belt to that brace.
    var reduceMotion: Bool = false
    /// True while the host has this off screen — another tab, or the app in the
    /// background. The web view outlives its host, so nothing else tells the page to
    /// stop: without this it keeps running its animation loop, writing attributes and
    /// re-running the rim filter, behind whatever the student is actually looking at.
    var paused: Bool = false
    /// Fires with `true` once the page has drawn, `false` when a look change
    /// forces a reload. Lets the host cover the view until then.
    var onReady: ((Bool) -> Void)? = nil
    /// Fires with the band the page will actually let him into, whenever the page
    /// reports its layout. Read it rather than assume: it is where the page parks
    /// him, so a host that lays something out above him and does not trim the same
    /// way draws above a fish who is not that high.
    var onLayout: ((Band) -> Void)? = nil

    /// The strip of the view his steering point is allowed into, top and bottom as
    /// fractions of the view's height. Fractions, not the CSS pixels the message
    /// carries, because the fraction is the one number that means the same thing on
    /// both sides of the bridge.
    struct Band: Equatable {
        var top: CGFloat
        var bottom: CGFloat
    }

    /// Drawn width, fins included, as a multiple of drawn height. From the
    /// Sprout build's `reach` for the three-star drawing (long fins, belly badge):
    /// 640 + 680 wide by 470 + 380 tall, in art units.
    static let aspect: CGFloat = 1.5529
    /// Stage-3 body radius as a fraction of the drawn width: 849 / (1320 × 2.52).
    static let radiusRatio: CGFloat = 0.2552
    /// Drawn height as a multiple of the stage-3 radius: 850 × 2.52 / 849. This is
    /// the whole drawing; `riseRatio` says how much of it stands above the point the
    /// page steers by.
    static let heightPerRadius: CGFloat = 2.523
    /// How much of the drawn height sits above the steering point: 470 of the 850 art
    /// units in `aspect`. The other 380 hang below it.
    static let riseRatio: CGFloat = 0.5529

    /// Home is the only opaque host, and the page takes about a second to boot, so one
    /// web view and one coordinator live for the whole run. Leaving the tab
    /// detaches the view; coming back re-attaches the same one, already drawn,
    /// instead of loading the page again and flashing the placeholder. A
    /// `transparent` host (the Focus reef) gets its own view and coordinator and
    /// lets them go with the screen.
    private enum Shared {
        static var webView: WKWebView?
        static let coordinator = Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        if !transparent, let view = Shared.webView {
            view.removeFromSuperview()
            // The page is deaf to touches: the app drives it entirely through JS, and the
            // tank's own drag gesture sits on top. Set on the reused view too, because
            // Shared.webView outlives any one host.
            view.isUserInteractionEnabled = false
            context.coordinator.onReady = onReady
            context.coordinator.onLayout = onLayout
            // The page is already up, but this host starts covered and has to be
            // told so, and handed the band it reported the first time round — the
            // coordinator outlives the host, so a new host would otherwise have no
            // band at all until the page happened to lay out again.
            // Deferred: SwiftUI is mid-update while it builds the view.
            if context.coordinator.ready {
                let ready = onReady
                let layout = onLayout
                let band = context.coordinator.band
                DispatchQueue.main.async {
                    ready?(true)
                    if let band { layout?(band) }
                }
            }
            return view
        }

        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "riverSprite")

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.setURLSchemeHandler(SproutSchemeHandler(), forURLScheme: SproutSchemeHandler.scheme)

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.scrollView.isScrollEnabled = false
        // The view sits under the status bar. Left automatic, the scroll view
        // hands the page a safe-area inset and the tank stops short of the
        // bottom edge, leaving a band of bare page colour.
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isUserInteractionEnabled = false
        view.backgroundColor = placeholder
        view.scrollView.backgroundColor = placeholder
        // Both of the above are invisible while the view is opaque, and it has to
        // stay opaque. This is the base WebKit actually paints before the document
        // has a background of its own, so a reload or a killed web content process
        // shows the tank floor rather than white.
        view.underPageBackgroundColor = placeholder
        if transparent {
            view.isOpaque = false
            view.backgroundColor = .clear
            view.scrollView.backgroundColor = .clear
            view.underPageBackgroundColor = .clear
        }

        let look = currentLook
        context.coordinator.look = look
        context.coordinator.onReady = onReady
        context.coordinator.onLayout = onLayout
        context.coordinator.reduceMotion = reduceMotion
        view.load(URLRequest(url: look.url))
        if !transparent { Shared.webView = view }
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onReady = onReady
        coordinator.onLayout = onLayout
        // Coat, evolution and size are read once at boot, so a change to any of
        // them is a reload rather than something pushed in like an emote.
        let look = currentLook
        if coordinator.look != look {
            coordinator.look = look
            coordinator.ready = false
            coordinator.pending = nil
            onReady?(false)
            webView.load(URLRequest(url: look.url))
            return
        }

        if coordinator.sleeping != sleeping {
            coordinator.sleeping = sleeping
            coordinator.send(sleeping ? "window.RiverSprite.play('sleep')"
                                      : "if (window.RiverSprite.isSleeping()) window.RiverSprite.wake()",
                             to: webView)
        }

        if coordinator.paused != paused {
            coordinator.paused = paused
            // Straight to the web view, not through `send`: a pause has to land even
            // when the page has not reported ready, and a queued pause is pointless.
            if coordinator.ready {
                webView.evaluateJavaScript("window.RiverSprite.setPaused(\(paused))")
            }
        }

        if coordinator.reduceMotion != reduceMotion {
            coordinator.reduceMotion = reduceMotion
            if coordinator.ready {
                webView.evaluateJavaScript("window.RiverSprite.setReduceMotion(\(reduceMotion))")
            }
        }


        guard animation != coordinator.lastAnimation else { return }
        coordinator.lastAnimation = animation
        coordinator.send(Self.script(for: animation), to: webView)
    }

    // The coordinator is the page's message handler and remembers what the page
    // has been told, so it has to outlive the host along with the web view.
    func makeCoordinator() -> Coordinator { transparent ? Coordinator() : Shared.coordinator }

    private var currentLook: Look {
        Look(type: Self.type(speciesID), coat: Self.coat(speciesID), evo: Self.evo(level),
             skin: skin, costume: Self.costume(skin, level: level), radius: radius, tank: tank)
    }

    /// The costume the page should put on, or empty for the coat's default. Only
    /// stage III wears one, so a younger kin always asks for the default.
    static func costume(_ skin: String, level: Int) -> String {
        guard level >= 3, Costume.ids.contains(skin) else { return "" }
        return skin
    }

    struct Look: Equatable {
        var type: String
        var coat: String
        var evo: String
        var skin: String
        var costume: String
        var radius: CGFloat
        var tank: String

        var url: URL {
            var components = URLComponents()
            components.scheme = SproutSchemeHandler.scheme
            components.host = SproutSchemeHandler.host
            components.path = "/index.html"
            components.queryItems = [
                URLQueryItem(name: "embed", value: "1"),
                URLQueryItem(name: "type", value: type),
                URLQueryItem(name: "coat", value: coat),
                URLQueryItem(name: "evo", value: evo),
                URLQueryItem(name: "skin", value: skin),
                URLQueryItem(name: "radius", value: String(format: "%.2f", radius)),
            ]
            // No tank means no plate: the page leaves its background clear, which is
            // what a transparent host wants.
            if !tank.isEmpty {
                components.queryItems?.append(URLQueryItem(name: "tank", value: tank))
            }
            // Empty means the kin has never been dressed, and the page puts it in its
            // coat's default. Sending "classic" instead would be an unknown costume id,
            // which the page would ignore — the same picture, by accident rather than on
            // purpose.
            if !costume.isEmpty {
                components.queryItems?.append(URLQueryItem(name: "costume", value: costume))
            }
            return components.url!
        }
    }

    /// Buffers the first emote until the page reports `ready`, so an animation
    /// played during launch is not swallowed.
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var lastAnimation: ChibiAnimation?
        var look: Look?
        var ready = false
        var pending: String?
        var onReady: ((Bool) -> Void)?
        var reduceMotion = false
        var paused = false
        var sleeping = false
        var band: Band?
        var onLayout: ((Band) -> Void)?

        func send(_ script: String, to webView: WKWebView) {
            guard ready else {
                pending = script
                return
            }
            webView.evaluateJavaScript(script)
        }

        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            // `ready` and `layout` both carry the page's own measurements — `w`/`h`
            // and the rectangle he may occupy, all in CSS pixels. They are passed on
            // as fractions of `h`: a host laying something out around him must never
            // be handed pixels it would have to assume match the view's points.
            guard let body = message.body as? [String: Any],
                  let event = body["event"] as? String else { return }
            if let h = body["h"] as? Double, h > 0,
               let top = body["top"] as? Double,
               let bottom = body["bottom"] as? Double {
                let reported = Band(top: CGFloat(top / h), bottom: CGFloat(bottom / h))
                if reported != band {
                    band = reported
                    onLayout?(reported)
                }
            }
            guard event == "ready" else { return }
            ready = true
            message.webView?.evaluateJavaScript("window.RiverSprite.setReduceMotion(\(reduceMotion))")
            if let script = pending, let webView = message.webView {
                pending = nil
                webView.evaluateJavaScript(script)
            }
            revealOncePainted(message.webView, tries: 0)
        }

        /// `ready` means the script is up, not that the tank plate has decoded: for
        /// a beat the canvas is a flat wash, which showed through the cover as a
        /// green flash. Hold the cover until the plate has arrived, or 1.2 seconds,
        /// whichever comes first.
        private func revealOncePainted(_ webView: WKWebView?, tries: Int) {
            guard let webView, tries < 12 else { onReady?(true); return }
            let probe = "performance.getEntriesByType('resource').some(function(r){return r.name.indexOf('/tanks/')>-1})"
            webView.evaluateJavaScript(probe) { [weak self] result, _ in
                guard let self, self.ready else { return }
                if result as? Bool == true {
                    self.onReady?(true)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.revealOncePainted(webView, tries: tries + 1)
                    }
                }
            }
        }

        /// Under memory pressure iOS kills the web content process and the view
        /// goes blank, or keeps a stale corner of the tank. Load the page again
        /// and cover it until it reports ready, as on a look change.
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            ready = false
            onReady?(false)
            guard let look else { return }
            webView.load(URLRequest(url: look.url))
        }
    }

    // MARK: - Mapping

    /// Prepkin's species palette onto Sprout's six coats. `slime` and anything
    /// unrecognised stay mint, which is Sprout's default.
    static func coat(_ speciesID: String) -> String {
        switch speciesID {
        case "ember", "mochi": return "coral"
        case "droplet", "puff": return "sky"
        case "wisp": return "lilac"
        case "comet": return "butter"
        case "sprout": return "peach"
        default: return "mint"
        }
    }

    /// Which Sprout-repo type draws the kin. Sprout only since 2026-09-10; the
    /// orca and axolotl rigs still exist in the web bundle but nothing asks for them.
    static func type(_ speciesID: String) -> String { "sprout" }

    /// Chibi level onto the three-star line: 1 the pear, 2 long fins, 3 belly badge.
    static func evo(_ level: Int) -> String { String(min(max(level, 1), 3)) }

    /// Prepkin's animation set onto Sprout's 15 emotes.
    ///
    /// `idle` is not an emote — Sprout idles on his own — so it only has to undo
    /// a sleep, which is a toggle on the web side rather than a one-shot.
    static func script(for animation: ChibiAnimation) -> String {
        guard let emote = emote(for: animation) else {
            return "if (window.RiverSprite.isSleeping()) window.RiverSprite.wake()"
        }
        return "window.RiverSprite.play('\(emote)')"
    }

    static func emote(for animation: ChibiAnimation) -> String? {
        switch animation {
        case .idle: return nil
        case .bounce: return "bounce"
        case .celebrate: return "cheer"
        case .wave: return "wave"
        case .sleep: return "sleep"
        case .dance: return "dance"
        case .peek: return "curious"
        case .startle: return "surprise"
        case .slump: return "pout"
        }
    }
}

/// Serves `SproutWeb/` from the app bundle over a real origin.
///
/// `file://` will not do: it is an opaque origin, so the CORS check on the
/// `crossorigin` module script and stylesheet Vite emits fails, the bundle never
/// executes, and the page renders blank with nothing logged.
final class SproutSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "sprout-app"
    static let host = "bundle"

    private let root = Bundle.main.url(forResource: "SproutWeb", withExtension: nil)

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let root, let url = task.request.url else {
            task.didFailWithError(URLError(.badURL))
            return
        }

        let path = url.path.isEmpty || url.path == "/" ? "/index.html" : url.path
        let file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL
        // A `..` in the path must not escape the bundled folder.
        guard file.path.hasPrefix(root.standardizedFileURL.path),
              let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        // `no-store`, and an `HTTPURLResponse` to carry it. A plain `URLResponse`
        // has no headers, so WKWebView cached the page — and because the URL never
        // changes, a rebuilt bundle kept being answered from that cache. The app
        // shipped new art and new script and the web view ran neither.
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": Self.mimeType(file.pathExtension),
                           "Content-Length": String(data.count),
                           "Cache-Control": "no-store"])
        task.didReceive(response ?? URLResponse(url: url,
                                                mimeType: Self.mimeType(file.pathExtension),
                                                expectedContentLength: data.count,
                                                textEncodingName: "utf-8"))
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    static func mimeType(_ pathExtension: String) -> String {
        switch pathExtension {
        case "html": return "text/html"
        case "js": return "text/javascript"
        case "css": return "text/css"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "json": return "application/json"
        default: return "application/octet-stream"
        }
    }
}
