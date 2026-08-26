//
//  DesignSystem.swift
//  OneLoop
//
//  Shared chrome used across onboarding and the main app.
//

import SwiftUI

struct OLPrimaryButton: View {
    var title: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.actionText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.blue, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .accessibilityAddTraits(.isButton)
    }
}

struct OLSecondaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.navy)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.cardBackground, in: Capsule())
                .overlay {
                    Capsule().stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct OLGlassCircleButton: View {
    var systemImage: String
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.navy)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct OLCard<Content: View>: View {
    var cornerRadius: CGFloat = 22
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background(
                AppTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.04), radius: 16, y: 8)
    }
}

struct OLPageDots: View {
    var count: Int
    var current: Int
    var onDark: Bool = false

    @Namespace private var indicator

    private var activeFill: Color {
        onDark ? AppTheme.splashWordmark : AppTheme.blue
    }

    private var inactiveFill: Color {
        onDark ? Color.white.opacity(0.32) : AppTheme.mutedText.opacity(0.22)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                ZStack {
                    Capsule()
                        .fill(inactiveFill)
                        .frame(width: 8, height: 8)

                    if index == current {
                        Capsule()
                            .fill(activeFill)
                            .frame(width: 22, height: 8)
                            .matchedGeometryEffect(
                                id: "page-indicator",
                                in: indicator
                            )
                            .shadow(
                                color: activeFill.opacity(onDark ? 0.45 : 0.22),
                                radius: onDark ? 8 : 4,
                                y: 0
                            )
                    }
                }
                .frame(width: index == current ? 22 : 8, height: 8)
            }
        }
        .animation(OLMotion.indicator, value: current)
        .animation(OLMotion.indicator, value: onDark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

struct OLChip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? AppTheme.actionText : AppTheme.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    selected ? AppTheme.blue : AppTheme.cardBackground.opacity(0.55),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            selected ? Color.clear : Color.white.opacity(0.35),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
