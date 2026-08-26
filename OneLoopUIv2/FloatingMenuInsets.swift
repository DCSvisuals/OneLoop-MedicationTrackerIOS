//
//  FloatingMenuInsets.swift
//  OneLoop
//
//  Bottom clearance for the custom floating capsule menu.
//

import SwiftUI

enum FloatingMenuMetrics {
    /// Space reserved under the last content so it can scroll fully above
    /// the floating capsule + raised add button.
    static let contentClearance: CGFloat = 160
}

private struct FloatingMenuClearanceKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// Extra bottom space pages must add when the floating menu is visible.
    var floatingMenuClearance: CGFloat {
        get { self[FloatingMenuClearanceKey.self] }
        set { self[FloatingMenuClearanceKey.self] = newValue }
    }
}

/// Place at the end of `ScrollView` / `Form` content so the last items
/// can scroll above the floating menu. Forms often ignore parent insets.
struct FloatingMenuScrollSpacer: View {
    @Environment(\.floatingMenuClearance) private var clearance

    var body: some View {
        if clearance > 0 {
            Color.clear
                .frame(height: clearance)
                .accessibilityHidden(true)
        }
    }
}

extension View {
    /// Pads scroll content so it clears the floating menu.
    func floatingMenuBottomPadding() -> some View {
        modifier(FloatingMenuBottomPaddingModifier())
    }
}

private struct FloatingMenuBottomPaddingModifier: ViewModifier {
    @Environment(\.floatingMenuClearance) private var clearance

    func body(content: Content) -> some View {
        content.padding(.bottom, clearance)
    }
}
