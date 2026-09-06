import SwiftUI

// The pieces every Kin surface is assembled from. Defined once here so the tier
// ramp can only ever appear in the three places it is allowed: the name plate, the
// cost badge, and a 2pt card border.

// MARK: - Stars

/// A kin's level, drawn the way a TFT unit reads its star level. Replaces the string
/// "Lv N" everywhere — a level is a thing you can see, not a number to parse.
struct StarPips: View {
    let level: Int
    var size: CGFloat = 13
    var spacing: CGFloat = 4

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...3, id: \.self) { i in
                StarShape()
                    .fill(i <= level ? Theme.coin : .clear)
                    .overlay(
                        StarShape().strokeBorder(
                            i <= level ? Theme.coinBorder : Theme.hex(0xDDD3C4),
                            lineWidth: i <= level ? size * 0.108 : size * 0.138)
                    )
                    .frame(width: size, height: size)
            }
        }
    }
}

/// Five-point star in a 20x20 box, from the handoff's path data.
struct StarShape: InsettableShape {
    var inset: CGFloat = 0

    private static let pts: [(Double, Double)] = [
        (10, 1.4), (12.5, 6.7), (18.3, 7.4), (14, 11.3), (15.2, 17),
        (10, 14.2), (4.8, 17), (6, 11.3), (1.7, 7.4), (7.5, 6.7),
    ]

    func path(in r: CGRect) -> Path {
        let box = r.insetBy(dx: inset, dy: inset)
        let s = min(box.width, box.height) / 20
        var p = Path()
        for (i, pt) in Self.pts.enumerated() {
            let c = CGPoint(x: box.minX + pt.0 * s, y: box.minY + pt.1 * s)
            if i == 0 { p.move(to: c) } else { p.addLine(to: c) }
        }
        p.closeSubpath()
        return p
    }

    func inset(by amount: CGFloat) -> Self { var c = self; c.inset += amount; return c }
}

// MARK: - Tier ramp

/// COMMON / UNCOMMON / RARE / EPIC / LEGENDARY. Text is ink at every tier — all five
/// colours are light enough to carry it, so weight and colour never change across
/// the ramp and only the fill tells you what band you are in.
struct TierPlate: View {
    let tier: Int
    var dense = false

    var body: some View {
        Text(Theme.tierName(tier))
            .font(Theme.font(9.5, .black))
            .tracking(1.33)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, dense ? 7 : 8)
            .padding(.vertical, dense ? 2.5 : 3)
            .background(Capsule().fill(Theme.tier(tier)))
    }
}

/// A price in its tier's colour. `filled` is the shop's on-sale badge; the hollow
/// variant is the Collection's full price.
struct KinCostBadge: View {
    let price: Int
    let tier: Int
    var filled = true
    var compact = false

    /// A #FFC24B coin on a #FFC24B badge disappears, so Legendary — and only
    /// Legendary — inverts the disc. The single conditional in the whole ramp.
    private var invertsDisc: Bool { filled && tier == 5 }

    var body: some View {
        HStack(spacing: compact ? 3 : 4) {
            Group {
                if invertsDisc {
                    Circle().fill(Theme.coinSoft)
                        .overlay(Circle().strokeBorder(Theme.coinDark, lineWidth: (compact ? 9.0 : 11.0) * 0.16))
                } else {
                    CoinDisc(size: compact ? 9 : 11)
                }
            }
            .frame(width: compact ? 9 : 11, height: compact ? 9 : 11)

            Text("\(price)")
                .font(Theme.font(compact ? 11 : 12.5, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, compact ? 7 : 10)
        .padding(.vertical, compact ? 2 : 3)
        .background(
            Capsule()
                .fill(filled ? Theme.tier(tier) : Theme.card)
                .overlay(filled ? nil : Capsule().strokeBorder(Theme.tier(tier), lineWidth: 1.5))
        )
    }
}

// MARK: - Wallet

/// The balance, always reachable, always the same object. On a dark scene the pill
/// flips to glass but the coin keeps its brand colours.
struct WalletChip: View {
    let coins: Int
    var compact = false
    var onDark = false

    var body: some View {
        HStack(spacing: 6) {
            CoinDisc(size: compact ? 16 : 18)
            Text("\(coins)")
                .font(Theme.fixedFont(compact ? 14 : 15, .black))
                .foregroundStyle(onDark ? .white : Theme.ink)
                .contentTransition(.numericText())
                .animation(.snappy, value: coins)
        }
        .padding(.horizontal, compact ? 13 : 14)
        .padding(.vertical, compact ? 7 : 8)
        .background(GlassPill(onDark: onDark, strong: false))
    }
}

/// The one background used by everything that floats over a scene. On light art it
/// is a white pill; on dark art it is dark glass with a hairline, so the pills read
/// without a scrim fighting the illustration.
struct GlassPill: View {
    var onDark: Bool
    var strong: Bool

    var body: some View {
        if onDark {
            Capsule()
                .fill(Theme.hex(0x101820).opacity(strong ? 0.62 : 0.54))
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        } else {
            Capsule()
                .fill(Theme.card)
                .shadow(color: Theme.hex(0x2E2822).opacity(0.12), radius: 8, y: 2)
        }
    }
}

// MARK: - Kin art

/// A kin at a given size, in its species colour. Every surface draws its kin through
/// this so a species is never a colour swap in one place and a silhouette in another.
struct KinArtView: View {
    let speciesID: String
    var level: Int = 1
    /// Which Sprout look the kin is wearing: `classic` or `ninja`.
    var skin: String = "classic"
    var animation: ChibiAnimation = .idle
    var expression: SlimeExpression? = nil
    var size: CGFloat

    var body: some View {
        // Sprout since 2026-09-02. `expression` is kept on the signature so call
        // sites did not have to change; the stills carry one face.
        SproutImage(speciesID: speciesID, level: level, skin: skin, animation: animation, size: size)
    }
}

// MARK: - Cards

/// One kin in a grid. Owned sits on white with its name and stars; unowned sits on
/// cream at full colour with its price. An unowned kin is never greyed, silhouetted,
/// blurred, padlocked or hidden — you can always see what you are saving for.
struct KinCard: View {
    let species: ChibiSpecies
    let owned: OwnedChibi?
    var isActive = false
    var artSize: CGFloat = 86

    var body: some View {
        VStack(spacing: 7) {
            KinArtView(speciesID: species.id, level: owned?.level ?? 1,
                       skin: owned?.skinID ?? "classic", size: artSize)
                .frame(height: artSize * 0.92)

            Text(owned?.displayName ?? species.name)
                .font(Theme.font(14.5, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            if let owned {
                StarPips(level: owned.level, size: 12)
                if isActive {
                    Text("ACTIVE")
                        .font(Theme.font(10, .black))
                        .foregroundStyle(Theme.mintDark)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.mintSoft))
                } else {
                    Color.clear.frame(height: 16)
                }
            } else {
                KinCostBadge(price: species.price, tier: species.tier, filled: false)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(owned == nil ? Theme.unowned : Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.tier(species.tier), lineWidth: 2))
        )
    }
}

/// A tier holding a single kin gets a full-width row instead of a grid cell with an
/// empty half beside it.
struct KinRow: View {
    let species: ChibiSpecies
    let owned: OwnedChibi?
    var isActive = false
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            KinArtView(speciesID: species.id, level: owned?.level ?? 1,
                       skin: owned?.skinID ?? "classic", size: 64)
                .frame(width: 64, height: 57)

            VStack(alignment: .leading, spacing: 2) {
                Text(owned?.displayName ?? species.name)
                    .font(Theme.font(15.5, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.font(12, .heavy))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer(minLength: 8)

            if let owned {
                VStack(alignment: .trailing, spacing: 5) {
                    StarPips(level: owned.level, size: 12)
                    if isActive {
                        Text("ACTIVE")
                            .font(Theme.font(10, .black))
                            .foregroundStyle(Theme.mintDark)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Theme.mintSoft))
                    }
                }
            } else {
                KinCostBadge(price: species.price, tier: species.tier, filled: false)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(owned == nil ? Theme.unowned : Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.tier(species.tier), lineWidth: 2))
        )
    }
}

// MARK: - Toast

/// One line of dark glass that says what just happened. Never more than one on
/// screen, no dismiss control and no undo — every action it reports is reversible
/// by repeating it.
struct KinToast: View {
    let text: String
    var accent: Color = Theme.mint

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(accent).frame(width: 9, height: 9)
            Text(text)
                .font(Theme.font(14, .heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Theme.ink)
            .shadow(color: Theme.hex(0x2E2822).opacity(0.28), radius: 24, y: 8))
        .padding(.horizontal, 20)
    }
}

extension View {
    /// Floats the toast above the tab bar. Rises 12pt as it fades in.
    func kinToast(_ text: String?, accent: Color = Theme.mint, bottom: CGFloat = 34) -> some View {
        overlay(alignment: .bottom) {
            if let text {
                KinToast(text: text, accent: accent)
                    .padding(.bottom, bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: text)
    }
}

// MARK: - Care

/// Pet / High five / Snack. Free, unlimited, no cooldown, no counter. The hit target
/// is the whole 96pt column, not the 60pt circle.
struct CareButton: View {
    let glyph: KinGlyph
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                KinIcon(glyph, size: 24, color: Theme.ink)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Theme.card)
                        .shadow(color: Theme.hex(0x2E2822).opacity(0.09), radius: 10, y: 2))
                Text(label)
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.muted)
            }
            .frame(width: 96)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Icons

/// Drawn vectors in a 24x24 box. No emoji, and no SF Symbol whose metaphor is not
/// literally the thing named.
enum KinGlyph {
    case shopDoor, dock, lock, reroll, die, info, share
    case pet, highFive, snack
}

struct KinIcon: View {
    let glyph: KinGlyph
    var size: CGFloat = 24
    var color: Color = Theme.ink

    init(_ glyph: KinGlyph, size: CGFloat = 24, color: Color = Theme.ink) {
        self.glyph = glyph
        self.size = size
        self.color = color
    }

    var body: some View {
        Canvas { ctx, sz in
            let s = min(sz.width, sz.height) / 24
            func p(_ build: (inout Path) -> Void) -> Path {
                var path = Path()
                build(&path)
                return path.applying(CGAffineTransform(scaleX: s, y: s))
            }
            let stroke = StrokeStyle(lineWidth: 2 / s * s, lineCap: .round, lineJoin: .round)

            switch glyph {
            case .shopDoor:
                // Awning with a scalloped edge, then the shop front with the doorway
                // cut out of it. A plain bar over a box read as a trash can.
                ctx.fill(p { path in
                    path.move(to: CGPoint(x: 2.5, y: 8))
                    path.addLine(to: CGPoint(x: 4.6, y: 3.4))
                    path.addLine(to: CGPoint(x: 19.4, y: 3.4))
                    path.addLine(to: CGPoint(x: 21.5, y: 8))
                    for i in 0..<4 {
                        let x0 = 21.5 - Double(i) * 4.75
                        path.addArc(center: CGPoint(x: x0 - 2.375, y: 8), radius: 2.375,
                                    startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    }
                    path.closeSubpath()
                }, with: .color(color))
                ctx.fill(p { path in
                    path.addRoundedRect(in: CGRect(x: 4.4, y: 10.6, width: 15.2, height: 10.6),
                                        cornerSize: CGSize(width: 1.8, height: 1.8))
                    path.addRoundedRect(in: CGRect(x: 9.2, y: 13.6, width: 5.6, height: 7.6),
                                        cornerSize: CGSize(width: 1.4, height: 1.4))
                }, with: .color(color), style: FillStyle(eoFill: true))

            case .dock:
                for (x, y) in [(3.0, 3.0), (13.0, 3.0), (3.0, 13.0), (13.0, 13.0)] {
                    ctx.fill(p { $0.addRoundedRect(in: CGRect(x: x, y: y, width: 8, height: 8),
                                                   cornerSize: CGSize(width: 2.4, height: 2.4)) },
                             with: .color(color))
                }

            case .lock:
                ctx.stroke(p { path in
                    path.addArc(center: CGPoint(x: 12, y: 10), radius: 4.4,
                                startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                }, with: .color(color), style: stroke)
                ctx.fill(p { $0.addRoundedRect(in: CGRect(x: 5, y: 10, width: 14, height: 10),
                                               cornerSize: CGSize(width: 3, height: 3)) },
                         with: .color(color))

            case .reroll:
                ctx.stroke(p { path in
                    path.addArc(center: CGPoint(x: 12, y: 12), radius: 7.5,
                                startAngle: .degrees(-50), endAngle: .degrees(215), clockwise: false)
                }, with: .color(color), style: stroke)
                ctx.fill(p { path in
                    path.move(to: CGPoint(x: 16.4, y: 2.6))
                    path.addLine(to: CGPoint(x: 20.2, y: 7.4))
                    path.addLine(to: CGPoint(x: 14.4, y: 7.9))
                    path.closeSubpath()
                }, with: .color(color))

            case .die:
                ctx.stroke(p { $0.addRoundedRect(in: CGRect(x: 4, y: 4, width: 16, height: 16),
                                                 cornerSize: CGSize(width: 4, height: 4)) },
                           with: .color(color), style: stroke)
                for (x, y) in [(8.5, 8.5), (15.5, 8.5), (12.0, 12.0), (8.5, 15.5), (15.5, 15.5)] {
                    ctx.fill(p { $0.addEllipse(in: CGRect(x: x - 1.3, y: y - 1.3, width: 2.6, height: 2.6)) },
                             with: .color(color))
                }

            case .info:
                ctx.stroke(p { $0.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18)) },
                           with: .color(color), style: stroke)
                ctx.fill(p { $0.addEllipse(in: CGRect(x: 10.8, y: 7, width: 2.4, height: 2.4)) },
                         with: .color(color))
                ctx.fill(p { $0.addRoundedRect(in: CGRect(x: 10.8, y: 11, width: 2.4, height: 6.4),
                                               cornerSize: CGSize(width: 1.2, height: 1.2)) },
                         with: .color(color))

            case .share:
                ctx.stroke(p { path in
                    path.move(to: CGPoint(x: 12, y: 15))
                    path.addLine(to: CGPoint(x: 12, y: 3.5))
                    path.move(to: CGPoint(x: 7.6, y: 7.6))
                    path.addLine(to: CGPoint(x: 12, y: 3.2))
                    path.addLine(to: CGPoint(x: 16.4, y: 7.6))
                    path.move(to: CGPoint(x: 5.5, y: 12.5))
                    path.addLine(to: CGPoint(x: 5.5, y: 20))
                    path.addLine(to: CGPoint(x: 18.5, y: 20))
                    path.addLine(to: CGPoint(x: 18.5, y: 12.5))
                }, with: .color(color), style: stroke)

            case .pet:
                // A head, and two strokes travelling over it. Concentric arcs alone
                // read as a rainbow.
                ctx.fill(p { path in
                    path.move(to: CGPoint(x: 4.6, y: 21))
                    path.addCurve(to: CGPoint(x: 19.4, y: 21),
                                  control1: CGPoint(x: 4.6, y: 11.6), control2: CGPoint(x: 19.4, y: 11.6))
                    path.closeSubpath()
                }, with: .color(color))
                for (i, y) in [8.4, 5.2].enumerated() {
                    ctx.stroke(p { path in
                        path.move(to: CGPoint(x: 6.4, y: y + 2.2))
                        path.addQuadCurve(to: CGPoint(x: 17.6, y: y + 2.2),
                                          control: CGPoint(x: 12, y: y - 2.2))
                    }, with: .color(color.opacity(i == 0 ? 0.7 : 0.34)), style: stroke)
                }

            case .highFive:
                ctx.fill(p { $0.addRoundedRect(in: CGRect(x: 7, y: 12, width: 10, height: 9),
                                               cornerSize: CGSize(width: 3.4, height: 3.4)) },
                         with: .color(color))
                for x in [7.6, 10.9, 14.2] {
                    ctx.fill(p { $0.addRoundedRect(in: CGRect(x: x, y: 4.5, width: 2.6, height: 9),
                                                   cornerSize: CGSize(width: 1.3, height: 1.3)) },
                             with: .color(color))
                }

            case .snack:
                ctx.fill(p { path in
                    path.move(to: CGPoint(x: 4, y: 13))
                    path.addLine(to: CGPoint(x: 20, y: 13))
                    path.addCurve(to: CGPoint(x: 12, y: 20.5),
                                  control1: CGPoint(x: 20, y: 17.6), control2: CGPoint(x: 16.6, y: 20.5))
                    path.addCurve(to: CGPoint(x: 4, y: 13),
                                  control1: CGPoint(x: 7.4, y: 20.5), control2: CGPoint(x: 4, y: 17.6))
                    path.closeSubpath()
                }, with: .color(color))
                ctx.fill(p { $0.addEllipse(in: CGRect(x: 7.4, y: 6.4, width: 5.2, height: 5.2)) },
                         with: .color(color.opacity(0.42)))
                ctx.fill(p { $0.addEllipse(in: CGRect(x: 12.2, y: 7.8, width: 4.2, height: 4.2)) },
                         with: .color(color.opacity(0.42)))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
