import SwiftUI
import StoreKit

/// The Prepkin Plus sheet. One pitch line for the thing that opened it, two
/// prices with yearly pre-answered, one coral button. Restore is a text link.
struct PlusSheet: View {
    enum Reason {
        case scan
        case general

        var headline: String {
            switch self {
            case .scan: return "Scan a syllabus and Sprout fills your calendar."
            case .general: return "Everything Prepkin can do, in one plan."
            }
        }
    }

    let reason: Reason

    @EnvironmentObject var plus: PlusStore
    @Environment(\.dismiss) private var dismiss
    @State private var pick: PlusProduct = .yearly
    @State private var busy = false
    @State private var failed = false

    private enum D {
        static let grabber = Theme.hex(0xE2D8C6)
        static let shadow = Theme.hex(0x2E2622).opacity(0.05)
        static let plum = Theme.hex(0x5B3E8C)
        static let plumSoft = Theme.hex(0xEFE8FA)
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(D.grabber)
                .frame(width: 38, height: 5)
                .frame(height: 24)
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    perks
                    prices
                    cta
                    Button("Restore a purchase") {
                        Task { await plus.restore() }
                    }
                    .font(Theme.font(13.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    Text("Cancel any time in Settings. Renews unless you turn it off.")
                        .font(Theme.font(11.5, .bold))
                        .foregroundStyle(Theme.dim)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.paper)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.paper)
        .task { if plus.products.isEmpty { await plus.load() } }
        .onChange(of: plus.entitlement.isActive) { _, active in
            if active { dismiss() }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .black))
                Text("PREPKIN PLUS")
                    .font(Theme.fixedFont(12, .black))
                    .kerning(1.2)
            }
            .foregroundStyle(D.plum)
            .padding(.horizontal, 12).frame(height: 30)
            .background(Capsule().fill(D.plumSoft))

            Text(reason.headline)
                .font(Theme.font(24, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private var perks: some View {
        VStack(spacing: 0) {
            // Only what Plus actually gates today. Canvas, the calendar, and
            // the kin stay free; promising them here would be a lie.
            perk("camera.fill", "Photo to calendar",
                 "Snap a syllabus, a whiteboard, a planner page. Printed or handwritten. Sprout reads the dates and fills your calendar. 50 a month.")
            Divider().padding(.leading, 56)
            perk("sparkles", "And the rest of Plus",
                 "Scanning is one part. The other Plus perks show up here as they ship.")
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Theme.card)
            .shadow(color: D.shadow, radius: 11, y: 8))
    }

    private func perk(_ glyph: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: glyph)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(D.plum)
                .frame(width: 32, height: 32)
                .background(Circle().fill(D.plumSoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.font(13, .bold))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var prices: some View {
        HStack(spacing: 10) {
            priceCard(.yearly, label: "Yearly", note: "Save 42%")
            priceCard(.monthly, label: "Monthly", note: nil)
        }
    }

    private func priceCard(_ p: PlusProduct, label: String, note: String?) -> some View {
        let on = pick == p
        let product = plus.products.first { $0.id == p.rawValue }
        let price = product?.displayPrice ?? (p == .yearly ? "$69.99" : "$9.99")
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.snappy(duration: 0.22)) { pick = p }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(label)
                        .font(Theme.font(14, .black))
                        .foregroundStyle(on ? Theme.coralShade : Theme.ink)
                    Spacer()
                    if let note {
                        Text(note)
                            .font(Theme.fixedFont(10, .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Theme.coral))
                    }
                }
                Text(price)
                    .font(Theme.font(22, .black))
                    .foregroundStyle(Theme.ink)
                Text(p == .yearly ? "per year" : "per month")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(on ? Theme.coralSoft : Theme.card)
                .shadow(color: D.shadow, radius: 11, y: 8))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(on ? Theme.coral : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var cta: some View {
        VStack(spacing: 8) {
            Button {
                Task { await buy() }
            } label: {
                HStack(spacing: 8) {
                    if busy { ProgressView().tint(.white) }
                    Text(busy ? "One moment" : "Get Plus")
                        .font(Theme.font(17, .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.coral))
                .shadow(color: Theme.coral.opacity(0.3), radius: 10, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(busy)
            if failed {
                Text("That didn't go through. Nothing was charged.")
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Theme.coralDeep)
            }
        }
    }

    private func buy() async {
        busy = true
        failed = false
        defer { busy = false }
        do {
            let ok = try await plus.purchase(pick)
            if !ok { return }
        } catch {
            failed = true
        }
    }
}
