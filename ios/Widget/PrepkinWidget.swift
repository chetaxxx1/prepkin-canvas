import SwiftUI
import WidgetKit

/// The home-screen widget and the two lock-screen ones.
///
/// Finch's shape: the kin, one line, tap opens the app. Apple's size grammar:
/// small is one thing, medium is a list. Everything drawn here comes from
/// `widget.json` in the app group; nothing is fetched and nothing runs in the
/// background. The line is `WidgetLine`, the same table the tests cover.
@main
struct PrepkinWidgetBundle: WidgetBundle {
    var body: some Widget { PrepkinWidget() }
}

struct PrepkinWidget: Widget {
    static let kind = "PrepkinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            WidgetRoot(entry: entry)
                .containerBackground(Theme.paper, for: .widget)
                .widgetURL(PrepkinLinks.home)
        }
        .configurationDisplayName("Prepkin")
        .description("Your kin, and one true line about today.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

/// Where a tap goes. The app registers the scheme; Home is the only stop today.
enum PrepkinLinks {
    static let home = URL(string: "prepkin://home")!
}

// MARK: - Timeline

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

/// Entries at now, at each due time minus three hours, at noon, at the check-in
/// hour, at the shift's end and at midnight. The line is picked fresh at each.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: context.isPreview ? .sample : WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshot.load()
        let entries = WidgetLine.timelineDates(for: snapshot, now: now)
            .map { SnapshotEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

extension WidgetSnapshot {
    /// What the gallery shows before the app has written anything.
    static let sample = WidgetSnapshot(
        speciesID: "slime", stage: 2, costumeID: "none", name: "Moss",
        kinAsset: "sprout-mint-2", plainAsset: "sprout-mint-2", coins: 240,
        tasks: [
            Task(id: "a", title: "Bio quiz", dueAt: nil, done: false, isDaily: false),
            Task(id: "b", title: "Essay outline", dueAt: nil, done: false, isDaily: true),
            Task(id: "c", title: "10 minute walk", dueAt: nil, done: false, isDaily: true),
        ],
        allDone: false, lastOpenedAt: Date(), shiftEndsAt: nil, checkInHour: 19,
        dayBankSeed: 0, day: WidgetLine.day(Date(), calendar: .current), writtenAt: Date())
}

// MARK: - Views

struct WidgetRoot: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        switch family {
        case .accessoryCircular: CircularFace(entry: entry)
        case .accessoryRectangular: RectangularLine(entry: entry)
        case .systemMedium: MediumWidget(entry: entry)
        default: SmallWidget(entry: entry)
        }
    }
}

/// Four icon spots: the line top left, the kin bottom right, "Moss · Wed" bottom left.
struct SmallWidget: View {
    let entry: SnapshotEntry

    var body: some View {
        let snap = entry.snapshot ?? .sample
        let line = entry.snapshot.map { WidgetLine.line(for: $0, now: entry.date) } ?? "Open Prepkin once."
        // The line takes the whole width: the kin sits in the bottom right, under
        // it, so only the stamp has to make room.
        ZStack(alignment: .bottomTrailing) {
            TankBand()
            KinStill(snapshot: snap, size: 84)
                .padding(.trailing, 4)
                .padding(.bottom, 2)
            VStack(alignment: .leading, spacing: 0) {
                Text(line)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Text(WidgetLine.stamp(snap.name, entry.date))
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .padding(.trailing, 70)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(line) \(snap.name).")
    }
}

/// The lagoon plate, faded into the paper: the same world as Home, at a whisper.
struct TankBand: View {
    var body: some View {
        GeometryReader { geo in
            Image("scene-lagoon")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height * 0.62)
                .clipped()
                .opacity(0.42)
                .mask(LinearGradient(colors: [.clear, .black, .black],
                                     startPoint: .top, endPoint: .bottom))
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// The kin from this target's own catalogue, or the plain coat when the costume
/// has no still here. Never a blank frame.
struct KinStill: View {
    let snapshot: WidgetSnapshot
    let size: CGFloat

    var body: some View {
        Image(Self.asset(for: snapshot))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    static func asset(for snapshot: WidgetSnapshot) -> String {
        UIImage(named: snapshot.kinAsset) != nil ? snapshot.kinAsset : snapshot.plainAsset
    }
}

// MARK: - Lock screen

/// The kin's face in the circle. The lock screen draws accessories in one tint,
/// so the still reads as a silhouette with its own shading — still the fish.
struct CircularFace: View {
    let entry: SnapshotEntry

    var body: some View {
        let snap = entry.snapshot ?? .sample
        ZStack {
            AccessoryWidgetBackground()
            KinStill(snapshot: snap, size: 44)
                .offset(y: 3)
        }
        .accessibilityLabel("\(snap.name)")
    }
}

/// "2 left today" over the next due title. No countdown, no seconds: the lock
/// screen redraws about once a minute and a stale clock reads as broken.
struct RectangularLine: View {
    let entry: SnapshotEntry

    var body: some View {
        if let snap = entry.snapshot {
            let count = WidgetLine.count(for: snap, now: entry.date)
            VStack(alignment: .leading, spacing: 1) {
                Text(count)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .widgetAccentable()
                Text(second(snap))
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            Text("Open Prepkin once.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
    }

    private func second(_ snap: WidgetSnapshot) -> String {
        if let next = WidgetLine.nextDue(for: snap, now: entry.date), let due = next.dueAt {
            let time = due.formatted(.dateTime.hour().minute())
            return "\(WidgetLine.fit(next.title, leaving: time.count + 3)) · \(time)"
        }
        return WidgetLine.line(for: snap, now: entry.date)
    }
}

// MARK: - Medium

/// Eight spots. Built in the last step; until then the medium is the small,
/// wider, so a student who picks it is never shown a blank.
struct MediumWidget: View {
    let entry: SnapshotEntry

    var body: some View {
        SmallWidget(entry: entry)
    }
}
