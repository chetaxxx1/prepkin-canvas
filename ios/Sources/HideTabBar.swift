import SwiftUI

/// Attach to any pushed sub-screen that owns the whole screen (Daily Word's
/// keyboard, a lesson, the grade calculator). The floating bar slides away
/// while it is on screen and comes back on the way out.
struct HidesTabBar: ViewModifier {
    @EnvironmentObject var state: AppState

    func body(content: Content) -> some View {
        content
            .onAppear { state.hideTabBar = true }
            .onDisappear { state.hideTabBar = false }
    }
}

extension View {
    func hidesTabBar() -> some View { modifier(HidesTabBar()) }
}
