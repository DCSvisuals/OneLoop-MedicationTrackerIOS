//
//  PageMotion.swift
//  OneLoopUIv2
//
//  Sibling page motion (Material 3 spatial): peers slide in unison
//  from opposite edges. Chrome stays put. No nested page scrolling.
//

import SwiftUI

enum OLMotion {
    /// M3 emphasized-decelerate, duration medium-2 (~500ms) for large spatial moves.
    static let sibling = Animation.timingCurve(0.05, 0.7, 0.1, 1.0, duration: 0.5)

    /// M3 emphasized for small indicators.
    static let indicator = Animation.timingCurve(0.2, 0.0, 0.0, 1.0, duration: 0.35)

    static func siblingTransition(incomingFrom edge: Edge) -> AnyTransition {
        let outgoing: Edge = (edge == .trailing) ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: outgoing).combined(with: .opacity)
        )
    }
}

enum OnboardingChrome {
    /// Extra space under the status island for onboarding titles.
    static let titleTopPadding: CGFloat = 86

    /// Space pages reserve so Continue, dots, and the home indicator
    /// never cover the toggle or disclaimer card.
    static let bottomReserve: CGFloat = 200

    static let toggleBlockHeight: CGFloat = 120
}

/// Horizontal sibling pager driven by selection, not a ScrollView —
/// so the page itself cannot rubber-band or vertically scroll.
struct OLSiblingPager<Page: View>: View {
    @Binding var selection: Int
    var pageCount: Int
    var swipeEnabled: Bool = false
    /// Pages with index < lockedBelow are omitted (e.g. consumed splash).
    var lockedBelow: Int = 0
    @ViewBuilder var page: (Int) -> Page

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                ForEach(lockedBelow..<pageCount, id: \.self) { index in
                    page(index)
                        .frame(width: width, height: geo.size.height)
                        .offset(x: CGFloat(index - selection) * width)
                        .opacity(opacity(for: index))
                        .allowsHitTesting(index == selection)
                }
            }
            .frame(width: width, height: geo.size.height)
            .clipped()
            .contentShape(Rectangle())
            .modifier(OptionalSwipe(enabled: swipeEnabled, width: width) { delta in
                selection = min(
                    pageCount - 1,
                    max(lockedBelow, selection + delta)
                )
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(OLMotion.sibling, value: selection)
    }

    private func opacity(for index: Int) -> Double {
        abs(index - selection) <= 1 ? 1 : 0
    }

}

private struct OptionalSwipe: ViewModifier {
    var enabled: Bool
    var width: CGFloat
    var onPageDelta: (Int) -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.highPriorityGesture(
                DragGesture(minimumDistance: 28)
                    .onEnded { value in
                        let threshold = width * 0.18
                        if value.translation.width < -threshold {
                            onPageDelta(1)
                        } else if value.translation.width > threshold {
                            onPageDelta(-1)
                        }
                    }
            )
        } else {
            content
        }
    }
}

/// Sibling container for tab-style pages that are not a swipe pager.
struct OLSiblingPageHost<Content: View>: View {
    var id: AnyHashable
    var incomingFrom: Edge
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()
                .id(id)
                .transition(OLMotion.siblingTransition(incomingFrom: incomingFrom))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
