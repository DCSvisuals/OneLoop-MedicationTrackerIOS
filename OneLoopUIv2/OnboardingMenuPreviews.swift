//
//  OnboardingMenuPreviews.swift
//  OneLoop
//
//  Decorative menu previews for the onboarding carousel ONLY.
//
//  Isolation rules:
//  • Uses private `PreviewMenuTab` — never `AppTab`.
//  • Local `@State` only — never ContentView’s `selectedTab`.
//  • Never opens sheets, never navigates, never mutates app shell.
//  • Pill preview: fully non-interactive (display only).
//  • Liquid Glass preview: local bubble animation only.
//  • Real menu is created later in ContentView after onboarding ends.
//

import SwiftUI

/// Local demo tab for onboarding previews. Intentionally separate from `AppTab`
/// so taps here can never change the real app shell.
private enum PreviewMenuTab: String, CaseIterable, Identifiable {
    case today
    case schedule
    case add
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .schedule: return "Schedule"
        case .add: return "Add"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .schedule: return "calendar"
        case .add: return "plus.circle.fill"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }

    /// Pill menu uses a slightly different history glyph (matches real shell).
    var pillIcon: String {
        self == .history ? "chart.bar.fill" : icon
    }
}

// MARK: - Pill (floating capsule) preview — display only

/// Visual mock of the floating capsule menu. Not clickable.
struct OnboardingPillMenuPreview: View {
    /// Static highlight only — never driven by user input.
    private let highlightedTab: PreviewMenuTab = .today

    var body: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .bottom) {
                HStack(spacing: 6) {
                    ForEach(PreviewMenuTab.allCases.filter { $0 != .add }) { tab in
                        demoPillItem(tab)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.14), radius: 12, y: 6)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                // Center + — decorative only (not the real Add action)
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.actionText)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.blue, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.34), lineWidth: 1)
                    }
                    .shadow(color: AppTheme.blue.opacity(0.35), radius: 10, y: 5)
                    .offset(y: -18)
                    .accessibilityHidden(true)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        // Entire pill mock is non-interactive — style is chosen via the rows below.
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of the pill style bottom menu")
    }

    private func demoPillItem(_ tab: PreviewMenuTab) -> some View {
        VStack(spacing: 3) {
            Image(systemName: tab.pillIcon)
                .font(.system(size: 16, weight: .semibold))
                .frame(height: 18)

            Text(tab.title)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(
            highlightedTab == tab ? AppTheme.blue : AppTheme.mutedText
        )
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            highlightedTab == tab
                ? AppTheme.blue.opacity(0.14)
                : Color.clear,
            in: Capsule()
        )
    }
}

// MARK: - Liquid Glass style preview (bubble demo only)

/// Glass tab bar mock. Taps only move a local selection bubble — they do not
/// change `AppTab`, open sheets, or affect the real menu after onboarding.
struct OnboardingLiquidGlassMenuPreview: View {
    /// Demo-only. Lives only while this preview is on screen.
    @State private var demoTab: PreviewMenuTab = .today
    @Namespace private var bubbleNamespace

    var body: some View {
        VStack(spacing: 10) {
            Text("Tap icons to move the selection bubble")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(PreviewMenuTab.allCases) { tab in
                    Button {
                        // Local demo state only — never touches ContentView.selectedTab.
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                            demoTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                if demoTab == tab {
                                    Capsule()
                                        .fill(AppTheme.blue.opacity(0.18))
                                        .matchedGeometryEffect(
                                            id: "onboardingLiquidBubble",
                                            in: bubbleNamespace
                                        )
                                        .frame(width: 52, height: 36)
                                }

                                Image(systemName: tab.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(
                                        demoTab == tab
                                            ? AppTheme.blue
                                            : AppTheme.mutedText
                                    )
                                    .frame(width: 52, height: 36)
                            }

                            Text(tab.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(
                                    demoTab == tab
                                        ? AppTheme.blue
                                        : AppTheme.mutedText
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(tab.title) preview")
                    .accessibilityHint("Moves the demo selection bubble only")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background {
                if #available(iOS 26.0, *) {
                    Capsule()
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Preview of the Liquid Glass bottom menu")
    }
}

// MARK: - Combined chooser with live preview

/// Style picker used on the onboarding Appearance page.
/// Preference is stored via `useLiquidGlassNavigation`; the live mock above
/// never drives the real tab shell (that only mounts after onboarding ends).
struct OnboardingMenuStyleChooser: View {
    @Binding var useLiquidGlassNavigation: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Live preview — destroyed when leaving this page / finishing onboarding.
            Group {
                if useLiquidGlassNavigation {
                    OnboardingLiquidGlassMenuPreview()
                        .id("onboarding-preview-liquid-glass")
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    OnboardingPillMenuPreview()
                        .id("onboarding-preview-pill")
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .frame(minHeight: 110)
            .padding(12)
            .background(
                AppTheme.elevatedCard.opacity(0.65),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            }
            .animation(.snappy, value: useLiquidGlassNavigation)

            VStack(spacing: 12) {
                choiceRow(
                    title: "Pill menu",
                    detail: "Floating capsule with a center + button.",
                    systemImage: "capsule.fill",
                    selected: !useLiquidGlassNavigation
                ) {
                    useLiquidGlassNavigation = false
                }

                choiceRow(
                    title: "Liquid Glass",
                    detail: "System-style glass tab bar (iOS 26+).",
                    systemImage: "square.stack.3d.forward.dottedline.fill",
                    selected: useLiquidGlassNavigation
                ) {
                    useLiquidGlassNavigation = true
                }
            }
        }
    }

    private func choiceRow(
        title: String,
        detail: String,
        systemImage: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(selected ? AppTheme.blue : AppTheme.mutedText)
                    .frame(width: 40, height: 40)
                    .background(
                        (selected ? AppTheme.blue : AppTheme.mutedText)
                            .opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.navy)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppTheme.blue : AppTheme.mutedText)
            }
            .padding(14)
            .background(
                AppTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selected ? AppTheme.blue.opacity(0.45) : AppTheme.cardBorder,
                        lineWidth: selected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Pill") {
    OnboardingPillMenuPreview()
        .padding()
        .background(AppTheme.softBackground)
}

#Preview("Liquid Glass") {
    OnboardingLiquidGlassMenuPreview()
        .padding()
        .background(AppTheme.softBackground)
}
