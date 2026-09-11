import SwiftUI

/// Switches for Kin work that is built but waiting on something outside the code.
enum KinFlags {
    /// The Decorate door. Off until the Kin handoff is back and the prop cut-outs
    /// are in the asset catalogue (`TankProp.catalog` is empty until then). With it
    /// off the tab shows three doors; a door that opens on an empty tray would be
    /// the "?" tile in another shape.
    static let decorate = false
}

/// The Decorate door: two slots on the tank floor, a ring on the open one, a tray
/// of props under it. Tolan's planet for the slot and ring, Replika's room for the
/// tray. The kin stands behind the props in paint order and never moves for this.
///
/// The preview here is the still plate rather than the live page, because the
/// rings are placed in plate fractions and the still is the one surface whose
/// plate rectangle is known exactly.
struct DecorateEditor: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var open: PropSlot?
    @State private var ringShown = false

    private var kin: OwnedChibi { state.activeChibi }
    private var scene: Scene0 { Scene0.find(state.sceneID) }
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    /// The plate is 4:3, fitted to the width.
    private var plateHeight: CGFloat { screenWidth * 0.75 }

    var body: some View {
        VStack(spacing: 0) {
            plate
            tray
        }
        .background(scene.floor.ignoresSafeArea())
        .kinToast(state.toast, bottom: 24)
    }

    // MARK: - Plate

    private var plate: some View {
        ZStack(alignment: .topLeading) {
            Image(scene.asset)
                .resizable()
                .scaledToFit()
                .frame(width: screenWidth, height: plateHeight)

            ForEach(PropSlot.allCases) { slot in
                slotView(slot)
            }

            SproutImage(speciesID: kin.speciesID, level: kin.level, skin: kin.skinID, size: 150)
                .position(x: screenWidth / 2, y: plateHeight * PropSlot.base - 150 * SproutImage.heightRatio / 2)
                .allowsHitTesting(false)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(scene.isDark ? .white : Theme.ink)
                        .frame(width: 44, height: 44)
                        .background(GlassPill(onDark: scene.isDark, strong: false))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                Spacer()
                Button { dismiss() } label: {
                    Text("Done")
                        .font(Theme.fixedFont(15, .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(Theme.coral))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 60)
        }
        .frame(width: screenWidth, height: plateHeight + 60)
        .background(scene.floor)
        .ignoresSafeArea(edges: .top)
    }

    /// A slot is a tap target on the floor. Open, it wears the ring: a 2pt white
    /// ellipse with a soft ink shadow so it reads on Lagoon and on Deep alike.
    private func slotView(_ slot: PropSlot) -> some View {
        let w = screenWidth * PropSlot.maxWidth * 1.25
        let h = w * 0.42
        let isOpen = open == slot
        let placed = state.game.decor.prop(in: slot, tank: scene.id).flatMap(TankProp.find)
        return Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                open = isOpen ? nil : slot
                ringShown = open != nil
            }
        } label: {
            ZStack(alignment: .bottom) {
                if let placed {
                    Image(placed.asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: w, height: plateHeight * PropSlot.maxHeight, alignment: .bottom)
                }
                Ellipse()
                    .strokeBorder(.white, lineWidth: 2)
                    .shadow(color: Theme.ink.opacity(0.35), radius: 4, y: 1)
                    .frame(width: w, height: h)
                    .scaleEffect(isOpen && ringShown ? 1 : 0.9)
                    .opacity(isOpen ? 1 : 0)
            }
            .frame(width: max(w, 44), height: max(h, 44) + plateHeight * PropSlot.maxHeight, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .position(x: screenWidth * slot.x,
                  y: plateHeight * PropSlot.base - (max(h, 44) + plateHeight * PropSlot.maxHeight) / 2 + h / 2)
        .accessibilityLabel(placed.map { "\(slot.name), \($0.name)" } ?? "\(slot.name), empty")
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }

    // MARK: - Tray

    /// None first, then the props for this tank. With no slot open the tray says
    /// which slot to tap, in one line.
    private var tray: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(open.map { "\($0.name)" } ?? "Tap a spot on the floor.")
                .font(Theme.font(13, .black))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, Theme.gutter)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    trayTile(nil)
                    ForEach(TankProp.catalog) { prop in trayTile(prop) }
                }
                .padding(.horizontal, Theme.gutter)
            }
            .scrollIndicators(.hidden)
            Spacer(minLength: 0)
        }
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.sheet,
                                   topTrailingRadius: Theme.Radius.sheet, style: .continuous)
                .fill(Theme.paper)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func trayTile(_ prop: TankProp?) -> some View {
        let chosen = open.flatMap { state.game.decor.prop(in: $0, tank: scene.id) } == prop?.id
        return Button {
            guard let slot = open else { return }
            state.place(prop?.id, in: slot)
        } label: {
            VStack(spacing: 5) {
                Group {
                    if let prop {
                        Image(prop.asset).resizable().scaledToFit().padding(8)
                    } else {
                        Text("None").font(Theme.font(13, .black)).foregroundStyle(Theme.muted)
                    }
                }
                .frame(width: 96, height: 78)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(chosen ? Theme.mint : Theme.cardEdge, lineWidth: chosen ? 2 : 1))
                Text(prop?.name ?? " ")
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.ink).lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(open == nil)
        .accessibilityLabel(prop?.name ?? "None")
    }
}
