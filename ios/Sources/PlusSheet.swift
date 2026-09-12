import SwiftUI
import StoreKit

/// The one screen in Prepkin that asks for money.
///
/// The shape, and why each part is where it is:
///
/// 1. **The kin, doing what it does on Home.** Never sad, never pleading, never
///    holding a sign. Duolingo's paywall was checked to decide what to avoid.
/// 2. **What stays free, first.** Finch puts this on line one of its benefits page,
///    and it is the reason its own reviewers forgive it for being cosmetic. Copy the
///    placement, not the wording.
/// 3. **The perks as pictures of the goods.** Imprint fans its cards out rather than
///    listing them; eight rows of an icon in a circle is a settings screen.
/// 4. **Two plain price cards**, yearly first because it saves 42%, which is
///    arithmetic and not a badge.
/// 5. **"Support our mission"**, last, in Finch's and Duolingo's words but ours.
///
/// And the things it may never do, from `PLUS-SPEC.md` section 9: no countdown, no
/// crossed-out price, no "most popular" that is not true, no padlock, no greyed-out
/// anything, and not once the word "unlock". A student who is already Plus never
/// sees a price at all.
struct PlusSheet: View {

    /// Where the student came from. Only the top third changes; everything below it
    /// is the same sheet every time, which is the whole point of a swap.
    enum Reason: String, CaseIterable, Identifiable {
        var id: String { rawValue }

        case scan, calendarExport, shop, focus, look, vibe, grades, general

        /// One line. It names the thing the student was just reaching for, in the
        /// words that screen used.
        var headline: String {
            switch self {
            case .scan:           return "Photograph a syllabus. The dates land in your calendar."
            case .calendarExport: return "Send your dated work out to the calendar you already use."
            case .shop:           return "Seven picks a day, three slots you can hold, 30% off."
            case .focus:          return "Sixty and ninety minute shifts, or any length you type."
            case .look:           return "A look and three scenes coins cannot buy."
            case .vibe:           return "All six cards to send a friend."
            case .grades:         return "Your GPA for the term, and a target you set per course."
            case .general:        return "More of your fish, a longer shift, and your own calendar."
            }
        }

        /// The picture over the headline. One drawing per reason, at the size the
        /// student will see the real thing.
        var art: Art {
            switch self {
            case .scan, .calendarExport: return .page
            case .shop:                  return .slots
            case .focus:                 return .chips
            case .look, .vibe:           return .kin
            case .grades:                return .grades
            case .general:               return .kin
            }
        }

        enum Art { case kin, slots, chips, page, grades }
    }

    let reason: Reason

    @EnvironmentObject var plus: PlusStore
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var pick: PlusProduct = .yearly
    @State private var busy = false
    @State private var failed = false
    @State private var showingCompare = false

    private enum D {
        static let shadow = Theme.hex(0x2E2622).opacity(0.05)
        static let privacy = URL(string: "https://prepkin.com/privacy")!
        /// Apple's standard EULA. 3.1.2 wants a tappable Terms of Use and this is
        /// the one App Review accepts when an app has not written its own.
        static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
        static let ask = URL(string: "mailto:support@prepkin.com?subject=Prepkin%20Plus")!
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Theme.hairline)
                .frame(width: 38, height: 5)
                .frame(height: 24)
            ScrollView {
                if state.isPlus {
                    alreadyPlus
                } else if showingCompare {
                    compare
                } else {
                    offer
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.paper)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.paper)
        .task { if plus.products.isEmpty { await plus.load() } }
        .onChange(of: plus.entitlement.isActive) { _, active in
            state.syncPlus(paid: active)
            if active { dismiss() }
        }
    }

    // MARK: - The offer

    private var offer: some View {
        VStack(spacing: 20) {
            hero
            freeLine
            perks
            seeEverything
            prices
            cta
            Button {
                Task {
                    await plus.restore()
                    state.syncPlus(paid: plus.entitlement.isActive)
                }
            } label: {
                Text("Restore a purchase")
                    .font(Theme.font(13.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -12)

            hardship
            mission
            legal
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 32)
    }

    /// The top third, and the only part that changes with the reason.
    private var hero: some View {
        VStack(spacing: 14) {
            reasonArt.frame(height: 118)
            Text(reason.headline)
                .font(Theme.font(23, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var reasonArt: some View {
        switch reason.art {
        case .kin:    PlusArt.kin(state.activeChibi)
        case .slots:  PlusArt.slots
        case .chips:  PlusArt.chips
        case .page:   PlusArt.page
        case .grades: PlusArt.grades
        }
    }

    /// First on the sheet, not last. The sentence that makes the ask honest. It
    /// was a 27-word list of everything free; the compare table one tap down
    /// already lists it, so this says the one thing that matters.
    static let freeLine = "Everything else stays free."

    private var freeLine: some View {
        Text(Self.freeLine)
            .font(Theme.font(13, .heavy))
            .foregroundStyle(Theme.muted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    /// Five pictures of the goods, one line each: Imprint's "your subscription
    /// includes" is a label and a picture of the thing, stacked (Mobbin
    /// 9036a4f7-80dd-4781-b9c3-695383698d5a); Finch's Plus sheet is the bird
    /// first and four perks with one line each (Mobbin
    /// 0525a643-772d-4665-b5fc-b0d7d10a3a3a). The tiles this replaced carried a
    /// second sentence each; the compare table still has every word.
    static let perkTitles = [
        "A look and three scenes",
        "Seven picks, three holds, 30% off",
        "Sixty and ninety minute shifts",
        "Photos read into your calendar",
        "Your work in your own calendar",
    ]

    private var perks: some View {
        VStack(spacing: 18) {
            perkPicture(PlusArt.coatRow, Self.perkTitles[0])
            perkPicture(PlusArt.slots, Self.perkTitles[1])
            perkPicture(PlusArt.chips, Self.perkTitles[2])
            perkPicture(PlusArt.page, Self.perkTitles[3])
            perkPicture(PlusArt.calendar, Self.perkTitles[4])
        }
    }

    /// One line, then the goods at the size the student will see them.
    private func perkPicture<A: View>(_ art: A, _ title: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(Theme.font(14.5, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            art.frame(height: 72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card)
            .shadow(color: D.shadow, radius: 10, y: 6))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    private func perkTile<A: View>(_ art: A, _ title: String, _ body: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            art.frame(width: 78, height: 62)
                .clipped()
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.font(14.5, .black))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(body)
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card)
            .shadow(color: D.shadow, radius: 10, y: 6))
    }

    private var seeEverything: some View {
        Button {
            withAnimation(.snappy(duration: 0.24)) { showingCompare = true }
        } label: {
            Text("See everything, side by side")
                .font(Theme.font(13.5, .heavy))
                .foregroundStyle(Theme.muted)
                .underline()
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -12)
    }

    // MARK: - Price

    private var prices: some View {
        VStack(spacing: 10) {
            priceCard(.yearly)
            priceCard(.monthly)
        }
    }

    private func displayPrice(_ p: PlusProduct) -> String {
        plus.products.first { $0.id == p.rawValue }?.displayPrice
            ?? (p == .yearly ? "$69.99" : "$9.99")
    }

    /// "$5.83 a month" under the yearly card. Derived from the real product price
    /// where StoreKit gave us one, so a storefront in another currency is not told
    /// a dollar figure.
    private func perMonth() -> String? {
        guard let product = plus.products.first(where: { $0.id == PlusProduct.yearly.rawValue }) else {
            return "$5.83 a month"
        }
        let monthly = product.price / 12
        return monthly.formatted(product.priceFormatStyle) + " a month"
    }

    private func priceCard(_ p: PlusProduct) -> some View {
        let on = pick == p
        let yearly = p == .yearly
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.snappy(duration: 0.22)) { pick = p }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(yearly ? "Plus, yearly" : "Plus, monthly")
                        .font(Theme.font(14, .black))
                        .foregroundStyle(on ? Theme.coralShade : Theme.ink)
                    Text(yearly
                         ? (perMonth().map { "\($0), billed once a year" } ?? "Billed once a year")
                         : "Billed every month")
                        .font(Theme.font(12, .heavy))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(displayPrice(p))
                        .font(Theme.font(19, .black))
                        .foregroundStyle(Theme.ink)
                    if yearly {
                        Text("saves 42%")
                            .font(Theme.fixedFont(10.5, .black))
                            .foregroundStyle(Theme.mintDark)
                    }
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(on ? Theme.coralSoft : Theme.card)
                .shadow(color: D.shadow, radius: 10, y: 6))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(on ? Theme.coral : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var cta: some View {
        VStack(spacing: 9) {
            Button { Task { await buy() } } label: {
                HStack(spacing: 8) {
                    if busy { ProgressView().tint(Theme.onDarkWarm) }
                    Text(busy ? "One moment" : "Get Plus")
                        .font(Theme.font(17, .heavy))
                }
                .foregroundStyle(Theme.onDarkWarm)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .disabled(busy)
            if failed {
                Text("That didn't go through. Nothing was charged.")
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Theme.coralDeep)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// Perk 8. A plain text row, never a tile and never a padlock.
    private var hardship: some View {
        Button { openURL(D.ask) } label: {
            Text("Can't swing it? Ask.")
                .font(Theme.font(13.5, .heavy))
                .foregroundStyle(Theme.muted)
                .underline()
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -12)
    }

    /// Last on the sheet. Finch and Duolingo both say a version of this, and it is
    /// why their own reviewers forgive them for selling cosmetics.
    private var mission: some View {
        Text("Plus keeps Canvas, coins and every lesson free for everyone else.")
            .font(Theme.font(12.5, .heavy))
            .foregroundStyle(Theme.bagInk)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }

    /// Apple 3.1.2 wants the title, the length, the price, the price per period and
    /// two tappable links on this screen. Missing one is the commonest first
    /// rejection there is.
    private var legal: some View {
        VStack(spacing: 8) {
            Text("Prepkin Plus renews until you turn it off. Cancel any time in Settings.")
                .font(Theme.font(11.5, .bold))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                Button { openURL(D.privacy) } label: {
                    Text("Privacy").frame(minHeight: 44).contentShape(Rectangle())
                }
                Button { openURL(D.terms) } label: {
                    Text("Terms of Use").frame(minHeight: 44).contentShape(Rectangle())
                }
            }
            .font(Theme.font(11.5, .heavy))
            .foregroundStyle(Theme.muted)
            .buttonStyle(.plain)
            .padding(.vertical, -14)
        }
    }

    // MARK: - Already Plus

    /// The shortest screen here, and the one most apps get wrong. A student who has
    /// paid, or who is inside the gift week, must never be shown a price again.
    private var alreadyPlus: some View {
        VStack(spacing: 18) {
            PlusArt.kin(state.activeChibi).frame(height: 118)
            Text(state.plusAccess.isGift()
                 ? "Plus is on. Nothing to cancel, because nothing was started."
                 : "Plus is on. Thank you.")
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if state.plusAccess.isGift() {
                giftTimeline
            }

            VStack(spacing: 12) {
                perkTile(PlusArt.slotsCompact, "Seven picks, three holds, 30% off", "In the Shop, now.")
                perkTile(PlusArt.chipsCompact, "Sixty and ninety minute shifts", "On Focus, now.")
                perkTile(PlusArt.page, "Photos read into your calendar", "On the Calendar tab.")
            }

            Text("Everything you wear, make or save stays yours, whatever happens to this.")
                .font(Theme.font(12.5, .heavy))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Done") { dismiss() }
                .font(Theme.font(17, .heavy))
                .foregroundStyle(Theme.onDarkWarm)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.coral))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 32)
    }

    /// Headspace's and Quizlet's shape: three dated rows, one line each, and not one
    /// number that goes down.
    @ViewBuilder
    private var giftTimeline: some View {
        if let start = state.game.plus.giftStartedAt {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(PlusGift.timeline(start: start).enumerated()), id: \.offset) { i, row in
                    if i > 0 { Divider().padding(.leading, 74) }
                    HStack(alignment: .top, spacing: 12) {
                        Text(row.when)
                            .font(Theme.font(12.5, .black))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 62, alignment: .leading)
                        Text(row.what)
                            .font(Theme.font(12.5, .heavy))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                }
            }
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card)
                .shadow(color: D.shadow, radius: 10, y: 6))
        }
    }

    // MARK: - The compare table

    /// Structured's and Forest's shape. It is the second screen, not the first,
    /// because a table is what you read when you have already decided to look
    /// closely.
    private var compare: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation(.snappy(duration: 0.24)) { showingCompare = false }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .black))
                        Text("Back").font(Theme.font(14, .heavy))
                    }
                    .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
                Spacer()
            }

            Text("Free and Plus, side by side")
                .font(Theme.font(20, .black))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 0) {
                compareHead
                ForEach(Array(PlusCompare.rows.enumerated()), id: \.offset) { i, row in
                    if i > 0 { Divider() }
                    compareRow(row)
                }
            }
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card)
                .shadow(color: D.shadow, radius: 10, y: 6))

            Text("Nothing in the left column ever moves to the right one.")
                .font(Theme.font(12, .heavy))
                .foregroundStyle(Theme.bagInk)
                .multilineTextAlignment(.center)

            prices
            cta
            legal
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 32)
    }

    private var compareHead: some View {
        HStack(spacing: 0) {
            Text("").frame(maxWidth: .infinity, alignment: .leading)
            Text("Free")
                .font(Theme.fixedFont(11, .black))
                .foregroundStyle(Theme.muted)
                .frame(width: 62)
            Text("Plus")
                .font(Theme.fixedFont(11, .black))
                .foregroundStyle(Theme.coralShade)
                .frame(width: 62)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14).padding(.bottom, 8)
    }

    private func compareRow(_ row: PlusCompare.Row) -> some View {
        HStack(spacing: 0) {
            Text(row.name)
                .font(Theme.font(13, .heavy))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            cell(row.free, tint: Theme.muted)
            cell(row.plus, tint: Theme.coralShade)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private func cell(_ mark: PlusCompare.Mark, tint: Color) -> some View {
        Group {
            switch mark {
            case .yes:
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Theme.mintDark)
            case .no:
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.dim)
            case .text(let s):
                Text(s)
                    .font(Theme.fixedFont(11.5, .black))
                    .foregroundStyle(tint)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 62)
    }

    // MARK: - Buying

    private func buy() async {
        busy = true
        failed = false
        defer { busy = false }
        do {
            let ok = try await plus.purchase(pick)
            if ok { state.syncPlus(paid: true) }
        } catch {
            failed = true
        }
    }
}
