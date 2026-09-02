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
/// ```
/// Copy `tanks/ios/` with the bundle — Home asks the page to paint the tank
/// (`?tank=lagoon`) because a see-through WKWebView composites nothing at all.
/// Skip the full-screen playground plates; they are not used in embed.
struct SproutView: UIViewRepresentable {
    /// Which chibi the student has active. Picks Sprout's coat.
    var speciesID: String
    /// 1–3, mapped onto Sprout's three evolutions.
    var level: Int
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
    /// Fires with `true` once the page has drawn, `false` when a look change
    /// forces a reload. Lets the host cover the view until then.
    var onReady: ((Bool) -> Void)? = nil

    /// Drawn width, fins included, as a multiple of drawn height.
    static let aspect: CGFloat = 1.4162
    /// Stage-3 body radius as a fraction of the drawn width.
    static let radiusRatio: CGFloat = 0.2846
    /// Drawn height as a multiple of the stage-3 radius. He is anchored by his
    /// feet, so this is how far up from the floor the top of his tuft lands.
    static let heightPerRadius: CGFloat = 2.48

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "riverSprite")

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.setURLSchemeHandler(SproutSchemeHandler(), forURLScheme: SproutSchemeHandler.scheme)

        let view = WKWebView(frame: .zero, configuration: config)
        view.scrollView.isScrollEnabled = false
        // The view sits under the status bar. Left automatic, the scroll view
        // hands the page a safe-area inset and the tank stops short of the
        // bottom edge, leaving a band of bare page colour.
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isUserInteractionEnabled = false
        view.backgroundColor = placeholder
        view.scrollView.backgroundColor = placeholder

        let look = currentLook
        context.coordinator.look = look
        context.coordinator.onReady = onReady
        view.load(URLRequest(url: look.url))
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onReady = onReady
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

        guard animation != coordinator.lastAnimation else { return }
        coordinator.lastAnimation = animation
        coordinator.send(Self.script(for: animation), to: webView)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private var currentLook: Look {
        Look(coat: Self.coat(speciesID), evo: Self.evo(level), radius: radius, tank: tank)
    }

    struct Look: Equatable {
        var coat: String
        var evo: String
        var radius: CGFloat
        var tank: String

        var url: URL {
            var components = URLComponents()
            components.scheme = SproutSchemeHandler.scheme
            components.host = SproutSchemeHandler.host
            components.path = "/index.html"
            components.queryItems = [
                URLQueryItem(name: "embed", value: "1"),
                URLQueryItem(name: "coat", value: coat),
                URLQueryItem(name: "evo", value: evo),
                URLQueryItem(name: "radius", value: String(format: "%.2f", radius)),
                URLQueryItem(name: "tank", value: tank),
            ]
            return components.url!
        }
    }

    /// Buffers the first emote until the page reports `ready`, so an animation
    /// played during launch is not swallowed.
    final class Coordinator: NSObject, WKScriptMessageHandler {
        var lastAnimation: ChibiAnimation?
        var look: Look?
        var ready = false
        var pending: String?
        var onReady: ((Bool) -> Void)?

        func send(_ script: String, to webView: WKWebView) {
            guard ready else {
                pending = script
                return
            }
            webView.evaluateJavaScript(script)
        }

        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  body["event"] as? String == "ready" else { return }
            ready = true
            onReady?(true)
            if let script = pending, let webView = message.webView {
                pending = nil
                webView.evaluateJavaScript(script)
            }
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

    /// Chibi level onto the three-star line. Stage 3 is the full Sprout.
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

        task.didReceive(URLResponse(url: url,
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
