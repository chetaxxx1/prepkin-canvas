import Foundation
import StoreKit
import UIKit

/// One row the scanner read off a page. Dates come back as `yyyy-MM-dd` so a
/// task typed for the 12th lands on the 12th in every time zone.
struct ScanRow: Decodable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var date: String
    var time: String?
    var course: String?
    var confidence: Double = 1

    private enum CodingKeys: String, CodingKey { case title, date, time, course, confidence }

    init(title: String, date: String, time: String? = nil, course: String? = nil, confidence: Double = 1) {
        self.title = title
        self.date = date
        self.time = time
        self.course = course
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decode(String.self, forKey: .title)
        date = try c.decode(String.self, forKey: .date)
        time = try c.decodeIfPresent(String.self, forKey: .time)
        course = try c.decodeIfPresent(String.self, forKey: .course)
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 1
    }

    var day: DayKey? {
        let parts = date.split(separator: "-")
        guard parts.count == 3, parts.allSatisfy({ Int($0) != nil }) else { return nil }
        return DayKey(raw: date)
    }

    /// "14:30" → minutes past midnight.
    var minute: Int? {
        guard let time else { return nil }
        let p = time.split(separator: ":").compactMap { Int($0) }
        guard p.count >= 2, (0..<24).contains(p[0]), (0..<60).contains(p[1]) else { return nil }
        return p[0] * 60 + p[1]
    }

    /// Below this the review sheet draws the row dashed, so it is read first.
    var isShaky: Bool { confidence < 0.5 }

    func task(source note: String) -> DatedTask? {
        guard let day else { return nil }
        return DatedTask(title: title, kind: .study, source: .photo,
                         detail: course ?? note, day: day, minute: minute)
    }
}

struct ScanResult: Decodable {
    var rows: [ScanRow]
    /// Scans left this month, after this one.
    var remaining: Int
    var limit: Int
    /// A one-line note from the reader, e.g. "This looks like a grading policy,
    /// not a schedule." Shown when there are no rows.
    var note: String?
}

enum ScanError: LocalizedError, Equatable {
    case notPlus
    case limitReached(resetsOn: String)
    case badImage
    case offline
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notPlus: return "Scanning is a Plus feature."
        case .limitReached(let on): return "That's 50 this month. Resets \(on)."
        case .badImage: return "Couldn't read that photo. Try one with more light."
        case .offline: return "No connection. Try again in a minute."
        case .server(let s): return s
        }
    }
}

/// Sends a photo to the bridge's `parse_schedule` function and gets dated rows
/// back. The photo is the only thing sent besides today's date, the time zone,
/// and the signed App Store transaction that proves Plus. Nothing is stored.
///
/// design/CALENDAR-PLAN.md, "Plus only, 50 photos a month".
struct ScanClient {
    static let monthlyLimit = 50

    /// The reader is a Supabase function that has not been deployed yet
    /// (design/CALENDAR-PLAN.md, "Deploying the scanner"). Until it is, the
    /// Calendar tab shows no camera and says nothing about syllabuses, because
    /// a tab may not promise a feature that is not live. One line to flip.
    static let isDeployed = false

    private let url: URL
    private let key: String
    private let session: URLSession

    init?(session: URLSession = .shared) {
        guard let cfg = Bundle.main.url(forResource: "bridge-config", withExtension: "json"),
              let data = try? Data(contentsOf: cfg),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = obj["url"] as? String, let key = obj["publishableKey"] as? String,
              let url = URL(string: base + "/functions/v1/parse_schedule") else { return nil }
        self.url = url
        self.key = key
        self.session = session
    }

    /// Shrinks to 1568px on the long side (about 1,600 image tokens) and JPEG 0.82.
    static func encode(_ image: UIImage) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, 1568 / max(longest, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let out = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return out.jpegData(compressionQuality: 0.82)
    }

    /// The signed transaction for the live Plus subscription, as the server
    /// checks it. Nil when the student is not Plus.
    static func plusTransactionJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result,
                  PlusProduct(rawValue: t.productID) != nil,
                  t.revocationDate == nil,
                  (t.expirationDate ?? .distantFuture) > Date() else { continue }
            return result.jwsRepresentation
        }
        return nil
    }

    func scan(_ image: UIImage, calendar: Calendar = .current) async throws -> ScanResult {
        guard let jpeg = Self.encode(image) else { throw ScanError.badImage }
        var jws = await Self.plusTransactionJWS()
        var devToken: String?
        if jws == nil, DebugUnlock.isOn {
            // A simulator has no App Store. The function accepts a dev token
            // instead when it has one configured; otherwise this fails as not Plus.
            devToken = ProcessInfo.processInfo.environment["PREPKIN_SCAN_DEV_TOKEN"]
            jws = devToken == nil ? nil : ""
        }
        guard jws != nil else { throw ScanError.notPlus }

        let body: [String: Any] = [
            "image": jpeg.base64EncodedString(),
            "mediaType": "image/jpeg",
            "today": DayKey.today(calendar).raw,
            "timeZone": calendar.timeZone.identifier,
            "jws": jws ?? "",
            "devToken": devToken ?? "",
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 60
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw ScanError.offline
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        struct Failure: Decodable { var error: String; var code: String?; var resetsOn: String? }
        if status == 200 {
            do { return try JSONDecoder().decode(ScanResult.self, from: data) }
            catch { throw ScanError.server("The reader sent back something odd. Try again.") }
        }
        let failure = try? JSONDecoder().decode(Failure.self, from: data)
        switch failure?.code {
        case "not_plus": throw ScanError.notPlus
        case "limit": throw ScanError.limitReached(resetsOn: failure?.resetsOn ?? "next month")
        case "bad_image": throw ScanError.badImage
        default: throw ScanError.server(failure?.error ?? "The reader is down. Try again in a bit.")
        }
    }
}
