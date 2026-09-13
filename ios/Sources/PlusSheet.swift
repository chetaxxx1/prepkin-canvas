import SwiftUI
import StoreKit

/// The one screen in Prepkin that asks for money.
///
/// The shape, and why each part is where it is (`design_handoff_plus_sheet`):
///
/// 1. **A 150pt art band holding a real fragment of the app**, tinted per reason.
///    It is the only part that changes with where the student came from.
/// 2. **The headline, then what stays free**, left aligned on the gutter every
///    other screen uses.
/// 3. **Three goods bands**, each a piece of the app's own UI at the size it
///    appears in the app — not an icon in a circle, which is a settings screen.
///    The other perks are numbers in the compare table one tap down.
/// 4. **The price and the button in a floating card pinned to the bottom**, so the
///    four things App Review looks for can never be scrolled away from. It is the
///    only shadow on the sheet, because it is the one thing that floats.
/// 5. Restore, the hardship row and the mission line under the fold.
///
/// And the things it may never do, from `PLUS-SPEC.md` section 9: no countdown, no
/// crossed-out price, no "most popular", no padlock, no greyed-out anything, and
/// not once the word "unlock". A student who is already Plus never sees a price.
struct PlusSheet: View {

    /// Where the student came from. Only the band and the headline change;
    /// everything below is the same sheet every time, which is the point of a swap.
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

        /// The band's tint. One flat colour, no radius of its own.
        var tint: Color {
            switch self {
            case .scan, .calendarExport: return Theme.coralSoft
            case .shop:                  return Theme.coinSoft
            case .focus:                 return Theme.mintSoft
            case .look, .vibe, .general: return Theme.checkFill
            case .grades:                return Theme.unowned
            }
        }
    }

    let reason: Reason

    @EnvironmentObject var plus: PlusStore
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pick: PlusProduct = .yearly
    @State private var busy = false
    @State private var failed = false
    @State private var showingCompare = false
    /// Measured, so the scroll content clears the card at any text size.
    @State private var cardHeight: CGFloat = 190

    private enum D {
        static let gutter: CGFloat = 22
        static let privacy = URL(string: "https://prepkin.com/privacy")!
        /// Apple's standard EULA. 3.1.2 wants a tappable Terms of Use and this is
        /// the one App Review accepts when an app has not written its own.
        static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
        static let ask = URL(string: "mailto:support@prepkin.com?subject=Prepkin%20Plus")!
    }

    private var swap: Animation? { reduceMotion ? nil : .snappy(duration: 0.24) }

    var body: some View {
        Group {
            // The entitlement is read before the body renders, so a paying student
            // never sees a price frame even for one tick.
            if state.isPlus {
                ScrollView { alreadyPlus }
                    .scrollIndicators(.hidden)
                    .overlay(alignment: .top) { grabber(Theme.hairline) }
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        Group {
                            if showingCompare { compare } else { offer }
                        }
                        .padding(.bottom, cardHeight)
                    }
                    .scrollIndicators(.hidden)
                    footerCard
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardHeight = $0 }
                }
                // The card is 190 from the screen's bottom edge, home indicator
                // included, which is where the drawing puts it. Pinned above the
                // indicator it is 224 and the compare link's words go under it.
                .ignoresSafeArea(edges: .bottom)
            }
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

    /// 38 × 5 at y = 9. White at 85% on the art band, `hairline` on paper.
    private func grabber(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 38, height: 5)
            .padding(.top, 9)
            .accessibilityHidden(true)
    }

    // MARK: - The offer

    private var offer: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReasonBand(reason: reason)
                .overlay(alignment: .top) { grabber(.white.opacity(0.85)) }

            VStack(alignment: .leading, spacing: 0) {
                Text(reason.headline)
                    .font(Theme.font(23, .black))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                Text(Self.freeLine)
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                goods.padding(.top, 14)

                Button {
                    withAnimation(swap) { showingCompare = true }
                } label: {
                    // Top of its 44pt row, not the middle: the row's bottom edge
                    // slips under the price card at rest (the scroll signal) and
                    // the words must stay clear of it.
                    Text("All eight, free and Plus side by side")
                        .font(Theme.font(13, .heavy))
                        .foregroundStyle(Theme.caption)
                        .underline()
                        .padding(.top, 8)
                        .frame(minHeight: 44, alignment: .top)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                belowTheFold
            }
            .padding(.horizontal, D.gutter)
            .padding(.bottom, 8)
        }
    }

    /// First on the sheet, not last. The sentence that makes the ask honest.
    static let freeLine = "Canvas, the Receipt, coins, every kin and costume coins buy, the timer, all 57 lessons, Friends, leagues and Games are free, and stay free."

    // MARK: Goods

    static let goods: [(title: String, detail: String)] = [
        ("Seven picks, three holds, 30% off",
         "Six free rerolls. Every item is still on the shelf at full coin price."),
        ("Sixty and ninety minute shifts",
         "Or any length you type, and a week of your own hours."),
        ("Read in, and sent back out",
         "Photos into your calendar, and every dated task out to Apple Calendar."),
    ]

    /// Three bands, art on the left at the size the thing is in the app, one line
    /// of plain fact on the right. Perk 4's two halves share the third band: page,
    /// arrow, calendar says more than two rows would.
    private var goods: some View {
        VStack(spacing: 8) {
            goodsBand(Theme.coinSoft, Self.goods[0]) {
                PickRowFragment(picks: state.picks, held: heldIDs, tile: 24, wrapped: true)
            }
            goodsBand(Theme.mintSoft, Self.goods[1]) {
                VStack(spacing: 6) {
                    Image("icon-classTime").resizable().scaledToFit().frame(width: 22, height: 22)
                    ChipRowFragment(compact: true)
                }
            }
            goodsBand(Theme.skySoft, Self.goods[2]) {
                CalendarFragment()
            }
        }
    }

    private var heldIDs: Set<String> { Set(state.picks.map(\.id).filter(state.isHeld)) }

    private func goodsBand<A: View>(_ tint: Color, _ good: (title: String, detail: String),
                                    @ViewBuilder art: () -> A) -> some View {
        HStack(spacing: 0) {
            art()
                .frame(width: 138, height: 96)
                .background(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(good.title)
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(good.detail)
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 96)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.card))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .strokeBorder(Theme.cardEdge, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(good.title). \(good.detail)")
    }

    // MARK: Under the fold

    /// Restore, the hardship row, and the mission line, in that order, under the
    /// card until the sheet scrolls. All three keep their 44pt rows.
    private var belowTheFold: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Task {
                    await plus.restore()
                    state.syncPlus(paid: plus.entitlement.isActive)
                }
            } label: {
                Text("Restore a purchase")
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Theme.caption)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Perk 8. A plain text row, never a tile and never a padlock.
            Button { openURL(D.ask) } label: {
                Text("Can't swing it? Ask.")
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Theme.caption)
                    .underline()
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Last on the sheet. Finch and Duolingo both say a version of this.
            Text("Plus keeps Canvas, coins and every lesson free for everyone else.")
                .font(Theme.font(12, .heavy))
                .foregroundStyle(Theme.bagInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44)
        }
    }

    // MARK: - The floating card

    /// The plan row, the button and the 3.1.2 line, pinned over the scroll. The
    /// title, length, price, price per period and both links are all in here.
    private var footerCard: some View {
        PlusFooterCard(
            pick: $pick,
            busy: busy,
            failed: failed,
            price: displayPrice,
            perMonth: perMonth(),
            buy: { Task { await buy() } },
            privacy: { openURL(D.privacy) },
            terms: { openURL(D.terms) }
        )
    }

    private func displayPrice(_ p: PlusProduct) -> String {
        plus.products.first { $0.id == p.rawValue }?.displayPrice
            ?? (p == .yearly ? "$69.99" : "$9.99")
    }

    /// "$5.83 a month" on the yearly card. Derived from the real product price
    /// where StoreKit gave us one, so a storefront in another currency is not told
    /// a dollar figure.
    private func perMonth() -> String {
        guard let product = plus.products.first(where: { $0.id == PlusProduct.yearly.rawValue }) else {
            return "$5.83 a month"
        }
        let monthly = product.price / 12
        return monthly.formatted(product.priceFormatStyle) + " a month"
    }

    // MARK: - Already Plus

    /// The shortest screen here, and the one most apps get wrong. No price, no plan
    /// row, no Restore, no compare link, nothing to buy.
    private var alreadyPlus: some View {
        VStack(spacing: 0) {
            PlusArt.kin(state.activeChibi)
                .frame(width: 92, height: 118)
                .padding(.top, 30)

            Text(state.plusAccess.isGift()
                 ? "Plus is on. Nothing to cancel, because nothing was started."
                 : "Plus is on. Thank you.")
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)

            if state.plusAccess.isGift() {
                giftTimeline.padding(.top, 18)
            }

            Text("On now")
                .font(Theme.font(13, .black))
                .foregroundStyle(Theme.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)

            VStack(spacing: 10) {
                OnNowRow(icon: "shopBag", title: Self.goods[0].title, place: "In the Shop, now.")
                OnNowRow(icon: "classTime", title: Self.goods[1].title, place: "On Focus, now.")
                OnNowRow(icon: "camera", title: "Photos read into your calendar", place: "On the Calendar tab.")
            }
            .padding(.top, 8)

            Text("Everything you wear, make or save stays yours, whatever happens to this.")
                .font(Theme.font(12.5, .heavy))
                .foregroundStyle(Theme.caption)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            Button("Done") { dismiss() }
                .font(Theme.font(17, .heavy))
                .foregroundStyle(Theme.onDarkWarm)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.coral))
                .buttonStyle(PressStyle())
                .padding(.top, 22)
        }
        .padding(.horizontal, D.gutter)
        .padding(.bottom, 32)
    }

    /// Headspace's and Quizlet's shape: three dated rows, one line each, and not one
    /// number that goes down.
    @ViewBuilder
    private var giftTimeline: some View {
        if let start = state.game.plus.giftStartedAt {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(PlusGift.timeline(start: start).enumerated()), id: \.offset) { i, row in
                    if i > 0 { Divider().overlay(Theme.hairline).padding(.leading, 74) }
                    HStack(alignment: .top, spacing: 12) {
                        Text(row.when)
                            .font(Theme.font(12.5, .black))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 62, alignment: .leading)
                        Text(row.what)
                            .font(Theme.font(12.5, .heavy))
                            .foregroundStyle(Theme.caption)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                }
            }
            .card(padding: 0)
        }
    }

    // MARK: - The compare table

    /// Structured's and Forest's shape. It is the second screen, not the first,
    /// because a table is what you read when you have already decided to look
    /// closely. The floating card stays under it.
    private var compare: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation(swap) { showingCompare = false }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .black))
                        Text("Back").font(Theme.font(14, .heavy))
                    }
                    .foregroundStyle(Theme.caption)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 20)

            Text("Free and Plus, side by side")
                .font(Theme.font(20, .black))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 0) {
                compareHead
                ForEach(Array(PlusCompare.rows.enumerated()), id: \.offset) { i, row in
                    if i > 0 { Divider().overlay(Theme.hairline) }
                    compareRow(row)
                }
            }
            .card(padding: 0)

            Text("Nothing in the left column ever moves to the right one.")
                .font(Theme.font(12, .heavy))
                .foregroundStyle(Theme.bagInk)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.horizontal, D.gutter)
        .padding(.bottom, 24)
    }

    private var compareHead: some View {
        HStack(spacing: 0) {
            Text("").frame(maxWidth: .infinity, alignment: .leading)
            Text("Free")
                .font(Theme.fixedFont(11, .black))
                .foregroundStyle(Theme.caption)
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
            cell(row.free, tint: Theme.caption)
            cell(row.plus, tint: Theme.coralShade)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.name): free \(spoken(row.free)), Plus \(spoken(row.plus))")
    }

    private func spoken(_ mark: PlusCompare.Mark) -> String {
        switch mark {
        case .yes: return "yes"
        case .text(let s): return s
        }
    }

    @ViewBuilder
    private func cell(_ mark: PlusCompare.Mark, tint: Color) -> some View {
        Group {
            switch mark {
            case .yes:
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Theme.mintDark)
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

// MARK: - The reason band

/// One 150pt band, full bleed, tinted per reason, holding a real fragment of the
/// screen the student was just on. Nothing else on the sheet changes with it.
struct ReasonBand: View {
    let reason: PlusSheet.Reason

    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            reason.tint
            fragment
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var fragment: some View {
        switch reason {
        case .scan, .calendarExport: scan
        case .shop:                  shop
        case .focus:                 focus
        case .look, .vibe, .general: look
        case .grades:                grades
        }
    }

    /// The photographed page, two corner marks, an arrow, and the two rows the
    /// reader made from it. The dates are a few days out from today, so the
    /// picture is never a page from last term.
    private var scan: some View {
        let course = state.courses.first.map { $0.code.isEmpty ? $0.name : $0.code } ?? "Physics 13"
        let soon = PlusGift.stamp(Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date())
        let later = PlusGift.stamp(Calendar.current.date(byAdding: .day, value: 19, to: Date()) ?? Date())
        return HStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                PlusArt.syllabusPage([soon, later])
                    .padding(.leading, 18).padding(.top, 14)
                PlusArt.cornerMark()
            }
            PlusArt.arrow(Theme.coralIcon, size: 18)
            VStack(spacing: 8) {
                ReadTaskRow(title: "Ch. 5 Problem Set", caption: "\(course) · \(soon)")
                ReadTaskRow(title: "Midterm", caption: "\(course) · \(later)")
            }
            .frame(width: 210)
        }
        .padding(.horizontal, 14)
    }

    /// The Shop's own row: today's real picks, their real prices, and the two
    /// slots Plus adds. The caption is the Shop's own sentence about the hold.
    private var shop: some View {
        VStack(spacing: 14) {
            PickRowFragment(picks: state.picks, held: Set(state.picks.map(\.id).filter(state.isHeld)))
            Text("today's picks · the pin holds one through a reroll")
                .font(Theme.fixedFont(11, .black))
                .foregroundStyle(Theme.coinInk)
        }
    }

    private var focus: some View {
        ChipRowFragment()
    }

    /// The three scene paintings are not drawn yet, so until they land this is the
    /// kin, doing what it does on Home.
    private var look: some View {
        PlusArt.kin(state.activeChibi, size: 112)
            .frame(height: 118)
    }

    private var grades: some View {
        TermCardFragment(courses: state.courses)
    }
}

// MARK: - The floating price card

/// The plan row, `Get Plus`, and the 3.1.2 line, in one card pinned to the bottom
/// of the sheet. It is the only shadow on the sheet. Purchasing and failed both
/// live inside it: never a dialog, never an alert.
struct PlusFooterCard: View {
    @Binding var pick: PlusProduct
    let busy: Bool
    let failed: Bool
    let price: (PlusProduct) -> String
    let perMonth: String
    let buy: () -> Void
    let privacy: () -> Void
    let terms: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Between `Radius.card` and `Radius.sheet`: at 20 it reads as a big band, at
    /// 28 as a second sheet.
    static let radius: CGFloat = 24

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                plan(.yearly)
                plan(.monthly)
            }
            .opacity(busy ? 0.5 : 1)
            .disabled(busy)
            .padding(.bottom, 2)

            Button(action: buy) {
                HStack(spacing: 8) {
                    if busy {
                        ProgressView().tint(Theme.onDarkWarm).controlSize(.small)
                    }
                    Text(busy ? "One moment" : "Get Plus")
                        .font(Theme.font(17, .heavy))
                }
                .foregroundStyle(Theme.onDarkWarm)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .disabled(busy)
            .accessibilityLabel(busy ? "One moment" : "Get Plus")

            if failed {
                Text("That didn't go through. Nothing was charged.")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.coralDeep)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            legal.padding(.top, -2)
        }
        .padding(.top, 12).padding(.horizontal, 12).padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: Self.radius, topTrailingRadius: Self.radius, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.ink.opacity(0.10), radius: 26, y: -8)
        )
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: Self.radius, topTrailingRadius: Self.radius, style: .continuous)
                .strokeBorder(Theme.cardEdge, lineWidth: 1)
        )
        .padding(.horizontal, 12)
    }

    /// Yearly is the default because it saves 42%, and that number is arithmetic
    /// off the two prices. There is no "most popular" badge.
    private func plan(_ p: PlusProduct) -> some View {
        let on = pick == p
        let yearly = p == .yearly
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) { pick = p }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(yearly ? "Plus, yearly" : "Plus, monthly")
                    .font(Theme.font(12, .black))
                    .foregroundStyle(on ? Theme.coralShade : Theme.ink)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(price(p))
                        .font(Theme.fixedFont(19, .black))
                        .foregroundStyle(Theme.ink)
                    if yearly {
                        Text("saves 42%")
                            .font(Theme.fixedFont(9.5, .black))
                            .foregroundStyle(Theme.mintDark)
                    }
                }
                Text(yearly ? "\(perMonth), once a year" : "Billed every month")
                    .font(Theme.font(9.5, .heavy))
                    .foregroundStyle(Theme.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(on ? Theme.coralSoft : Theme.paper))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(on ? Theme.coral : Theme.cardEdge, lineWidth: on ? 2 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityLabel(yearly ? "Plus, yearly, \(price(p)), \(perMonth), saves 42%"
                                   : "Plus, monthly, \(price(p)), billed every month")
    }

    /// Apple 3.1.2 wants the title, the length, the price, the price per period and
    /// two tappable links on this screen. Missing one is the commonest first
    /// rejection there is.
    private var legal: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("Prepkin Plus renews until you turn it off. Cancel any time in Settings.")
                .font(Theme.font(10, .bold))
                .foregroundStyle(Theme.caption)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button(action: privacy) {
                    Text("Privacy").underline().frame(minHeight: 32).contentShape(Rectangle())
                }
                Button(action: terms) {
                    Text("Terms of Use").underline().frame(minHeight: 32).contentShape(Rectangle())
                }
            }
            .font(Theme.font(10, .heavy))
            .foregroundStyle(Theme.caption)
            .buttonStyle(.plain)
            .padding(.vertical, -8)
            .fixedSize()
        }
    }
}

// MARK: - On now

/// One perk that is on, and where it is. A 44pt tile with the object, the title,
/// and the place — the anatomy of a task row, because that is what a student
/// already knows how to read.
struct OnNowRow: View {
    let icon: String
    let title: String
    let place: String

    var body: some View {
        HStack(spacing: 12) {
            IconTile(icon: icon, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.font(14.5, .black))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(place)
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.caption)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 62)
        .card(padding: 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(place)")
    }
}
