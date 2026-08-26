//
//  ScrollFrost.swift
//  OneLoopUIv2
//
//  Instagram-style top chrome: as the feed starts scrolling, a
//  gradient-masked frosted glass fades in over the status bar so
//  content passes underneath without colliding with the time/battery.
//

import SwiftUI
import UIKit

struct OLInstagramTopFrost: View {
    var progress: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.42),
                            .init(color: .white.opacity(0.45), location: 0.72),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            LinearGradient(
                stops: [
                    .init(
                        color: AppTheme.softBackground.opacity(0.88),
                        location: 0
                    ),
                    .init(
                        color: AppTheme.softBackground.opacity(0.42),
                        location: 0.55
                    ),
                    .init(color: AppTheme.softBackground.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 96)
        .frame(maxWidth: .infinity)
        .opacity(progress)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Attach to a ScrollView / List / Form.
struct OLScrollTopFrostModifier: ViewModifier {
    @State private var progress: CGFloat = 0
    @State private var topInset: CGFloat = 59

    func body(content: Content) -> some View {
        content
            .contentMargins(.top, topInset, for: .scrollContent)
            .ignoresSafeArea(edges: .top)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                let next = min(1, max(0, offset / 20))
                if abs(next - progress) > 0.02 {
                    progress = next
                }
            }
            .overlay(alignment: .top) {
                OLInstagramTopFrost(progress: progress)
                    .ignoresSafeArea(edges: .top)
            }
            .onAppear {
                topInset = Self.windowTopInset
            }
    }

    private static var windowTopInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap {
            $0 as? UIWindowScene
        }
        let inset = scenes.first?.windows.first(where: \.isKeyWindow)?
            .safeAreaInsets.top
            ?? scenes.first?.windows.first?.safeAreaInsets.top
        return max(inset ?? 59, 54)
    }
}

extension View {
    /// Frosted gradient at the top that appears when scrolling starts.
    func olScrollTopFrost() -> some View {
        modifier(OLScrollTopFrostModifier())
    }
}
