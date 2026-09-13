import SwiftUI

/// The perks, drawn as fragments of the app's own UI at the size they appear in
/// the app.
///
/// Not illustrations and not icons in circles. Flighty's Pro screen is the
/// reference: it does not illustrate a feature, it shows a picture of the real
/// screen at real size and lets it sell itself. So the shop perk is the pick row
/// with today's real picks and their real coin prices, the focus perk is the chip
/// row, and the calendar perk is a task row with an arrow out to a calendar.
///
/// Everything is `Theme`. No colour was invented for this file, and nothing here
/// carries a shadow — the only shadow on the sheet is the floating price card.
enum PlusArt {

    // MARK: The kin

    /// The student's own kin, doing what it does on Home. Not sad, not locked, not
    /// holding a sign, and not a crowd of mascots.
    static func kin(_ chibi: OwnedChibi, size: CGFloat = 108) -> some View {
        KinArtView(speciesID: chibi.speciesID, level: chibi.level, skin: chibi.skinID, size: size)
    }

    // MARK: A syllabus page

    /// The photographed page, 104pt, turned −4° the way a phone never quite holds
    /// a sheet straight. Two dates on it are the whole thing the reader finds.
    static func syllabusPage(_ dates: [String]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Capsule().fill(Theme.ink).frame(width: 44, height: 5)
            Capsule().fill(Theme.hairline).frame(width: 66, height: 4)
            Capsule().fill(Theme.hairline).frame(width: 58, height: 4)
            HStack(spacing: 5) {
                ForEach(dates, id: \.self) { d in
                    Text(d)
                        .font(Theme.fixedFont(8, .black))
                        .foregroundStyle(Theme.coralShade)
                        .padding(.horizontal, 5).padding(.vertical, 2.5)
                        .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Theme.coralSoft))
                }
            }
            Capsule().fill(Theme.hairline).frame(width: 62, height: 4)
            Capsule().fill(Theme.hairline).frame(width: 48, height: 4)
        }
        .padding(.horizontal, 12).padding(.vertical, 13)
        .frame(width: 104, height: 104, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.card))
        .rotationEffect(.degrees(-4))
        .accessibilityHidden(true)
    }

    /// One corner of the camera's frame: an L in `coralIcon`.
    static func cornerMark(flipped: Bool = false) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 18))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 18, y: 0))
        }
        .stroke(Theme.coralIcon, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        .frame(width: 18, height: 18)
        .rotationEffect(.degrees(flipped ? 180 : 0))
        .accessibilityHidden(true)
    }

    /// The arrow between a thing and where it goes.
    static func arrow(_ color: Color, size: CGFloat = 16) -> some View {
        Image(systemName: "arrow.right")
            .font(.system(size: size, weight: .black))
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

// MARK: - The pick row

/// The Shop's picks, at the size they are in the Shop's own row: today's real
/// picks with their real coin prices, then the two slots Plus adds. The hold pin
/// sits on a held pick, or on the first one when nothing is held, because the
/// picture is about holding.
struct PickRowFragment: View {
    let picks: [ShopPick]
    let held: Set<String>
    /// 44 × 52 on the band; 24 × 26 inside a goods band.
    var tile: CGFloat = 44
    /// Two rows (4 + 3) when the fragment has to fit a 138pt art column.
    var wrapped = false

    private var plusSlots: Int { max(0, PlusGate.shopSlots.plus - PlusGate.shopSlots.free) }
    private var pinned: String? { picks.first { held.contains($0.id) }?.id ?? picks.first?.id }

    var body: some View {
        let shown = Array(picks.prefix(PlusGate.shopSlots.free))
        let cells = shown.map(Cell.pick) + Array(repeating: Cell.plus, count: plusSlots)
        Group {
            if wrapped {
                let split = 4
                VStack(alignment: .leading, spacing: 6) {
                    row(Array(cells.prefix(split)))
                    row(Array(cells.dropFirst(split)))
                }
            } else {
                row(cells)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's picks, and two more slots on Plus")
    }

    private enum Cell { case pick(ShopPick), plus }

    private func row(_ cells: [Cell]) -> some View {
        HStack(spacing: tile > 30 ? 8 : 5) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                switch cell {
                case .pick(let p): pickTile(p)
                case .plus: plusTile
                }
            }
        }
    }

    private var radius: CGFloat { tile > 30 ? Theme.Radius.control : 7 }
    private var height: CGFloat { tile > 30 ? tile + 8 : tile + 2 }

    private func pickTile(_ pick: ShopPick) -> some View {
        VStack(spacing: tile > 30 ? 3 : 0) {
            PickObject(pick: pick, size: tile > 30 ? 26 : 15)
            if tile > 30 {
                Text("\(pick.price)")
                    .font(Theme.fixedFont(8, .black))
                    .foregroundStyle(Theme.coinInk)
            }
        }
        .frame(width: tile, height: height)
        .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Theme.cardEdge, lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            if pinned == pick.id { holdPin }
        }
    }

    /// The hold: a `coral` disc with the pin on it, 14pt on the band and 9 in a
    /// goods band. The mark on a control takes the control's colour.
    private var holdPin: some View {
        let d: CGFloat = tile > 30 ? 14 : 9
        return Circle()
            .fill(Theme.coral)
            .frame(width: d, height: d)
            .overlay(Image(systemName: "pin.fill")
                .font(.system(size: d * 0.5, weight: .black))
                .foregroundStyle(Theme.onDarkWarm))
            .offset(x: d * 0.3, y: -d * 0.3)
    }

    private var plusTile: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Theme.coralSoft)
            .frame(width: tile, height: height)
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Theme.coralIcon, style: StrokeStyle(lineWidth: 1.2, dash: [3, 2.5])))
            .overlay {
                if tile > 30 {
                    Text("Plus")
                        .font(Theme.fixedFont(9, .black))
                        .foregroundStyle(Theme.coralShade)
                }
            }
    }
}

/// The thing a pick is: a kin's face on its plate, or a scene cut to a thumb.
struct PickObject: View {
    let pick: ShopPick
    var size: CGFloat = 26

    var body: some View {
        switch pick.kind {
        case .kin(let s):
            SproutFace(speciesID: s.id, size: size, plate: Theme.plate(for: s.id))
        case .scene(let s):
            Image(s.asset)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size * 0.82)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        }
    }
}

// MARK: - The chip row

/// Focus's length chips: 15, 25 and 45 on white, 60 and 90 in `coralSoft` with a
/// `coralIcon` hairline, and a dashed chip showing a typed length. Same shape as
/// `FocusView.lengthChip`, so the picture is the control.
struct ChipRowFragment: View {
    /// The band draws chips at Focus's own 50 × 36; a goods band at 36 × 26.
    var compact = false
    /// A length someone might type. Not a gate number; it stands for "any".
    var typed = 42

    private var free: [Int] { FocusView.freeLengths }
    private var plus: [Int] { FocusView.moreItems.compactMap { if case .minutes(let m) = $0 { m } else { nil } } }

    var body: some View {
        Group {
            if compact {
                VStack(spacing: 5) {
                    HStack(spacing: 5) { ForEach(free, id: \.self) { chip("\($0)", .free) } }
                    HStack(spacing: 5) {
                        ForEach(plus, id: \.self) { chip("\($0)", .plus) }
                        chip("\(typed)", .typed)
                    }
                }
            } else {
                HStack(spacing: 7) {
                    ForEach(free, id: \.self) { chip("\($0)", .free) }
                    ForEach(plus, id: \.self) { chip("\($0)", .plus) }
                    chip("\(typed)", .typed)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fifteen, twenty-five and forty-five minute shifts, then sixty, ninety, or any length you type")
    }

    private enum Kind { case free, plus, typed }

    private func chip(_ label: String, _ kind: Kind) -> some View {
        Text(label)
            .font(compact ? Theme.fixedFont(11, .black) : Theme.font(14.5, .black))
            .foregroundStyle(kind == .free ? Theme.ink : Theme.coralShade)
            .frame(width: compact ? 36 : 50, height: compact ? 26 : 36)
            .background(Capsule().fill(kind == .free ? Theme.card : Theme.coralSoft))
            .overlay {
                switch kind {
                case .free: Capsule().strokeBorder(Theme.cardEdge, lineWidth: 1)
                case .plus: Capsule().strokeBorder(Theme.coralIcon, lineWidth: 1)
                case .typed: Capsule().strokeBorder(Theme.coralIcon, style: StrokeStyle(lineWidth: 1.2, dash: [3, 2.5]))
                }
            }
    }
}

// MARK: - The calendar

/// A task row the reader made, at 46pt: the camera in its tile, the read date
/// in its caption, and the checkbox — Calendar's row anatomy, drawn small.
struct ReadTaskRow: View {
    let title: String
    let caption: String

    var body: some View {
        HStack(spacing: 9) {
            IconTile(icon: "camera", size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.fixedFont(12, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(caption)
                    .font(Theme.fixedFont(9.5, .heavy))
                    .foregroundStyle(Theme.caption)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.checkFill)
                .frame(width: 22, height: 22)
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Theme.checkBorder, lineWidth: 2))
        }
        .padding(.horizontal, 9)
        .frame(height: 46)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .strokeBorder(Theme.cardEdge, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(caption)")
    }
}

/// The read-in and the send-out in one picture: the Calendar tab's own page, an
/// arrow, and the calendar the phone already has.
struct CalendarFragment: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("icon-tabCalendar").resizable().scaledToFit().frame(width: 46, height: 46)
            PlusArt.arrow(Theme.skyDeep, size: 15)
            Image("icon-calendarOut").resizable().scaledToFit().frame(width: 46, height: 46)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Grades

/// The Grade calculator's term card, as it looks with Plus on: the term GPA and
/// a row per graded course. Real courses when the phone has any; otherwise two
/// example rows, so the picture is never a blank card.
struct TermCardFragment: View {
    let courses: [CanvasCourse]

    private var rows: [(String, Double)] {
        let real = courses.compactMap { c -> (String, Double)? in
            guard let s = c.score else { return nil }
            return (c.code.isEmpty ? c.name : c.code, s)
        }
        return real.isEmpty ? [("PHYS 13", 91), ("ENGL 20", 84)] : Array(real.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your term")
                    .font(Theme.fixedFont(12.5, .black))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if let gpa = GradeProjection.termGPA(rows.map(\.1)) {
                    Text(GradeProjection.format(gpa))
                        .font(Theme.fixedFont(19, .black))
                        .foregroundStyle(Theme.ink)
                }
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    Text(row.0)
                        .font(Theme.fixedFont(11, .heavy))
                        .foregroundStyle(Theme.caption)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(GradeProjection.letter(forPercent: row.1))
                        .font(Theme.fixedFont(10, .black))
                        .foregroundStyle(Theme.caption)
                    Text(String(format: "%.1f", GradeProjection.points(forPercent: row.1)))
                        .font(Theme.fixedFont(10, .black))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .frame(width: 236)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .strokeBorder(Theme.cardEdge, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your GPA for the term, and a row per course")
    }
}
