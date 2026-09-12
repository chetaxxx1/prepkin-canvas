import SwiftUI

/// Last week, once: Duolingo's Monday screen (Mobbin 99e7f2d1, 790f98ad), copied
/// in shape. The trophy big in the middle with sparks around it, one line saying
/// where you finished, one saying what you moved up to, and Continue.
///
/// Ours is a sheet, not a takeover: the app has no full-screen ceremonies and the
/// tab underneath is the board it is talking about. The trophy is the pennant you
/// keep — gold, silver or bronze from the board, or the water you moved up to when
/// the week cleared the bar alone. No exclamation marks, which Duolingo's has and
/// `PRODUCT.md` bans.
struct MondaySheet: View {
    let last: LeagueWeekResult
    let onContinue: () -> Void

    private var placement: BoardPlacement? { last.placement }
    private var placed: Bool { (placement?.of ?? 0) >= 2 }
    private var upTo: LeagueTier? { last.promoted ? last.tier.next : nil }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                Sparks(color: sparkColor)
                    .frame(width: 220, height: 180)
                trophy
                    .shadow(color: Theme.hex(0x281923).opacity(0.14), radius: 14, y: 8)
            }
            .padding(.top, 8)

            Text(title)
                .font(Theme.font(24, .black))
                .kerning(-0.5)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 22)

            Text(line)
                .font(Theme.font(15, .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            if let upTo {
                HStack(spacing: 6) {
                    TierPennant(tier: upTo, earned: true, height: 16)
                    Text("\(upTo.name) now")
                        .font(Theme.font(12, .black))
                }
                .foregroundStyle(upTo.edge)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(upTo.color.opacity(0.18)))
                .padding(.top, 14)
            }

            Spacer(minLength: 0)

            Button(action: onContinue) {
                Text("Continue")
                    .font(Theme.font(17, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous)
                        .fill(Theme.coral))
                    .shadow(color: Theme.coral.opacity(0.3), radius: 10, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.paper)
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
    }

    // MARK: - The trophy

    @ViewBuilder private var trophy: some View {
        if let medal = placement?.medal {
            MedalPennant(medal: medal, height: 132)
        } else if let upTo {
            TierPennant(tier: upTo, earned: true, height: 132)
        } else {
            TierPennant(tier: last.tier, earned: true, height: 132)
        }
    }

    private var sparkColor: Color {
        if let medal = placement?.medal { return MedalPennant.cloth(medal).1 }
        return (upTo ?? last.tier).edge
    }

    // MARK: - The words

    private var title: String {
        if let p = placement, placed {
            return "You finished \(FriendsWater.ordinal(p.place)) last week"
        }
        return "Last week cleared the bar"
    }

    private var line: String {
        var parts: [String] = []
        if let p = placement, placed {
            switch p.medal {
            case 1: parts.append("First of \(p.of). A gold pennant, kept.")
            case 2: parts.append("Second of \(p.of). Silver, kept.")
            case 3: parts.append("Third of \(p.of). Bronze, kept.")
            default: parts.append("\(FriendsWater.ordinal(p.place)) of \(p.of). Everybody starts over today.")
            }
        } else {
            parts.append("\(last.coinsEarned.formatted()) coins in the week.")
        }
        if let upTo {
            parts.append("You moved up to \(upTo.name).")
        }
        return parts.joined(separator: " ")
    }
}

/// Duolingo's sparks: a few short crossed lines and dots around the trophy, in the
/// trophy's own colour. Fixed positions, so the sheet is still on open.
private struct Sparks: View {
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let marks: [(CGFloat, CGFloat, CGFloat)] = [
                (0.10, 0.28, 9), (0.90, 0.22, 7), (0.18, 0.78, 6), (0.86, 0.70, 9), (0.50, 0.04, 6),
            ]
            for (x, y, r) in marks {
                let c = CGPoint(x: w * x, y: h * y)
                var p = Path()
                p.move(to: CGPoint(x: c.x - r, y: c.y)); p.addLine(to: CGPoint(x: c.x + r, y: c.y))
                p.move(to: CGPoint(x: c.x, y: c.y - r)); p.addLine(to: CGPoint(x: c.x, y: c.y + r))
                ctx.stroke(p, with: .color(color.opacity(0.7)),
                           style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
            for (x, y, r) in [(0.28, 0.12, 3.0), (0.74, 0.88, 3.5), (0.04, 0.55, 2.5), (0.96, 0.46, 2.5)] {
                let c = CGPoint(x: w * x, y: h * y)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                         with: .color(color.opacity(0.55)))
            }
        }
        .accessibilityHidden(true)
    }
}
