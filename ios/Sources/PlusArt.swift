import SwiftUI

/// The perks, drawn as the things they are.
///
/// Eight rows of an SF Symbol in a circle is a settings screen, which is what the
/// old sheet looked like. Imprint fans its cards out instead and shows the goods at
/// the size you will see them; these are the Prepkin version of that — a real chip
/// row, a real slot row, a real page. Nothing here is an icon standing in for a
/// feature.
///
/// Everything is `Theme`. No colour was invented for this file.
enum PlusArt {

    private static let shadow = Theme.hex(0x2E2622).opacity(0.06)

    // MARK: The kin

    /// The student's own kin, doing what it does on Home. Not sad, not locked, not
    /// holding a sign, and not a crowd of mascots.
    static func kin(_ chibi: OwnedChibi) -> some View {
        KinArtView(speciesID: chibi.speciesID, level: chibi.level, skin: chibi.skinID, size: 108)
    }

    /// An **example** fish wearing a Plus coat, never the student's own. Previewing
    /// a coat on their kin would be showing them a thing they do not have on the
    /// animal they love, which is the padlock feeling wearing a costume.
    static var coatRow: some View {
        HStack(spacing: -14) {
            KinArtView(speciesID: "slime", level: 3, skin: "scholar", size: 46)
                .opacity(0.55)
            KinArtView(speciesID: "slime", level: 3, skin: "grad", size: 58)
        }
    }

    // MARK: Seven slots

    /// The shop row, at seven. Five in ink and two in coral, so the picture says
    /// "two more" without a caption saying it.
    static var slots: some View {
        HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { i in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(i < 5 ? Theme.card : Theme.coralSoft)
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(i < 5 ? Theme.hairline : Theme.coral, lineWidth: 1.5))
                    .frame(width: 15, height: 22)
            }
        }
        .shadow(color: shadow, radius: 5, y: 3)
    }

    // MARK: The chips

    /// The Focus chip row, with 60 and 90 on it in full colour. This is the picture
    /// most likely to be a padlock in another app; here 15, 25 and 45 are drawn
    /// exactly as they are on Focus and the two new ones simply sit beside them.
    static var chips: some View {
        HStack(spacing: 5) {
            chip("15", plus: false)
            chip("25", plus: false)
            chip("45", plus: false)
            chip("60", plus: true)
            chip("90", plus: true)
        }
    }

    /// The two new chips alone, sized for a perk tile.
    ///
    /// The full row is 170pt wide and a tile is 78. Scaling the row down would make
    /// five unreadable pills; showing the two the perk is actually about is both
    /// narrower and truer.
    static var chipsCompact: some View {
        HStack(spacing: 5) {
            chip("60", plus: true)
            chip("90", plus: true)
        }
    }

    /// Seven slots at tile width. Narrower cells, not a scaled-down row.
    static var slotsCompact: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(i < 5 ? Theme.card : Theme.coralSoft)
                    .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(i < 5 ? Theme.hairline : Theme.coral, lineWidth: 1.2))
                    .frame(width: 8, height: 18)
            }
        }
        .shadow(color: shadow, radius: 4, y: 2)
    }

    private static func chip(_ label: String, plus: Bool) -> some View {
        Text(label)
            .font(Theme.fixedFont(11, .black))
            .foregroundStyle(plus ? Theme.coralShade : Theme.ink)
            .frame(width: 30, height: 26)
            .background(Capsule().fill(plus ? Theme.coralSoft : Theme.card))
            .overlay(Capsule().strokeBorder(plus ? Theme.coral : Theme.hairline, lineWidth: 1.5))
    }

    // MARK: A syllabus page

    /// A page with dates down it. The lines are ruled and two of them carry a date
    /// pill, which is the whole thing the reader does.
    static var page: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1.5))
                .shadow(color: shadow, radius: 6, y: 4)
                .frame(width: 62, height: 78)
                .rotationEffect(.degrees(-4))
            VStack(alignment: .leading, spacing: 6) {
                ruled(width: 34)
                dated(width: 26)
                ruled(width: 38)
                dated(width: 22)
                ruled(width: 30)
            }
            .rotationEffect(.degrees(-4))
        }
    }

    private static func ruled(width: CGFloat) -> some View {
        Capsule().fill(Theme.hairline).frame(width: width, height: 3.5)
    }

    private static func dated(width: CGFloat) -> some View {
        HStack(spacing: 4) {
            Capsule().fill(Theme.coral).frame(width: 13, height: 6)
            Capsule().fill(Theme.hairline).frame(width: width, height: 3.5)
        }
    }

    // MARK: A calendar

    /// A month, with three days marked. Dots rather than numbers, because at this
    /// size numbers are noise and the shape is the message.
    static var calendar: some View {
        VStack(spacing: 4) {
            Capsule().fill(Theme.coral).frame(width: 44, height: 5)
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { col in
                            Circle()
                                .fill(Self.marked.contains(row * 5 + col) ? Theme.coral : Theme.hairline)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .padding(7)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1.5))
            .shadow(color: shadow, radius: 6, y: 4))
    }

    private static let marked: Set<Int> = [2, 7, 11]

    // MARK: Grades

    /// A rising bar pair with a target line above it. The one place a line is drawn
    /// on purpose, because a grade goal *is* a target the student set.
    static var grades: some View {
        HStack(alignment: .bottom, spacing: 6) {
            bar(26, Theme.hairline)
            bar(38, Theme.hairline)
            bar(50, Theme.coral)
        }
        .overlay(alignment: .top) {
            Capsule()
                .fill(Theme.mintDark)
                .frame(height: 2.5)
                .padding(.top, 4)
        }
        .padding(9)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1.5))
            .shadow(color: shadow, radius: 6, y: 4))
    }

    private static func bar(_ h: CGFloat, _ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 12, height: h)
    }
}
