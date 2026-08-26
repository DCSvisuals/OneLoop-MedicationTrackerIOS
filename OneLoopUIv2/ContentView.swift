//
//  ContentView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

struct ContentView: View {
    @Environment(MedicationStore.self) private var store
    @Bindable private var cloud = SupabaseManager.shared
    @State private var selectedTab: AppTab = .today
    /// Last real tab, used so the center + action never stays selected.
    @State private var lastContentTab: AppTab = .today
    @State private var tabIncomingEdge: Edge = .trailing
    @State private var showingAddMedication = false

    @AppStorage("useDarkMode")
    private var useDarkMode = false

    @AppStorage("useSystemAppearance")
    private var useSystemAppearance = true

    @AppStorage("useLiquidGlassNavigation")
    private var useLiquidGlassNavigation = false

    @AppStorage("hasAcceptedMedicalDisclaimer")
    private var hasAcceptedMedicalDisclaimer = false

    /// First-launch carousel (About → Policy → Sign in).
    @AppStorage("hasCompletedOnboarding_v4")
    private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    hasAcceptedDisclaimer: $hasAcceptedMedicalDisclaimer
                )
            } else {
                mainNavigation
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView(store: store)
        }
        .background(AppTheme.softBackground)
        .preferredColorScheme(
            useSystemAppearance
                ? nil
                : (useDarkMode ? .dark : .light)
        )
        .onAppear {
            store.resetDosesIfNeeded()
            // Recover if UserDefaults already marked complete while UI lagged.
            syncOnboardingWithAuthState()
            // Liquid Glass menu is iOS 26+ only.
            if #unavailable(iOS 26.0) {
                useLiquidGlassNavigation = false
            }
        }
        .onChange(of: cloud.isSignedIn) { _, signedIn in
            if signedIn {
                completeOnboardingFromAuth()
            }
        }
        .task(id: cloud.isSignedIn) {
            guard cloud.isSignedIn else { return }
            await cloud.syncMedications(with: store)
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: SupabaseManager.didAuthenticateNotification
            )
        ) { _ in
            completeOnboardingFromAuth()
        }
        .onChange(of: selectedTab) { _, newTab in
            handleTabSelection(newTab)
        }
    }

    private func completeOnboardingFromAuth() {
        hasAcceptedMedicalDisclaimer = true
        hasCompletedOnboarding = true
    }

    private func syncOnboardingWithAuthState() {
        if cloud.isSignedIn {
            completeOnboardingFromAuth()
        }
        // Pick up values written directly to UserDefaults by SupabaseManager.
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding_v4") {
            hasCompletedOnboarding = true
            hasAcceptedMedicalDisclaimer = true
        }
    }

    @ViewBuilder
    private var mainNavigation: some View {
        if useLiquidGlassNavigation {
            // Real system Liquid Glass tab bar (iOS 26+)
            systemLiquidGlassTabView
        } else {
            // Floating capsule menu
            floatingCapsuleTabShell
        }
    }

    private var visibleTab: AppTab {
        selectedTab == .add ? lastContentTab : selectedTab
    }

    /// Center + is an action tab: open the sheet, then restore the previous page.
    private func handleTabSelection(_ newTab: AppTab) {
        if newTab == .add {
            showingAddMedication = true
            selectedTab = lastContentTab
            return
        }

        if newTab != lastContentTab {
            tabIncomingEdge = newTab.siblingIndex > lastContentTab.siblingIndex
                ? .trailing
                : .leading
        }
        lastContentTab = newTab
    }

    private func selectContentTab(_ tab: AppTab) {
        guard tab != selectedTab else { return }
        tabIncomingEdge = tab.siblingIndex > lastContentTab.siblingIndex
            ? .trailing
            : .leading
        withAnimation(OLMotion.sibling) {
            selectedTab = tab
            lastContentTab = tab
        }
    }

    // MARK: - System Liquid Glass (true iOS 26 material)

    private var systemLiquidGlassTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "house.fill", value: .today) {
                TodayDashboardView(
                    store: store,
                    showingAddMedication: $showingAddMedication
                )
            }

            Tab("Schedule", systemImage: "calendar", value: .schedule) {
                ScheduleView(store: store)
            }

            // Middle action: opens Add Medication (not a real page)
            Tab("Add", systemImage: "plus.circle.fill", value: .add) {
                // Content is never shown; selection is immediately restored.
                Color.clear
            }

            Tab(
                "History",
                systemImage: "clock.arrow.circlepath",
                value: .history
            ) {
                MedicationHistoryView(store: store)
            }

            Tab(
                "Settings",
                systemImage: "gearshape.fill",
                value: .settings
            ) {
                SettingsView(store: store)
            }
        }
        .tint(AppTheme.blue)
        .animation(OLMotion.sibling, value: selectedTab)
        .modifier(LiquidGlassTabBarMinimizer())
    }

    // MARK: - Floating capsule menu (non–Liquid Glass option)

    private var floatingCapsuleTabShell: some View {
        // Menu is an overlay. Scroll clearance is explicit on each page
        // (Form/List often ignore parent safeAreaInset).
        ZStack(alignment: .bottom) {
            OLSiblingPageHost(
                id: visibleTab,
                incomingFrom: tabIncomingEdge
            ) {
                tabContent
                    .environment(
                        \.floatingMenuClearance,
                        FloatingMenuMetrics.contentClearance
                    )
            }

            floatingCapsuleNavigation
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .today, .add:
            // `.add` only applies to Liquid Glass; fall back to Today here.
            TodayDashboardView(
                store: store,
                showingAddMedication: $showingAddMedication
            )

        case .schedule:
            ScheduleView(store: store)

        case .history:
            MedicationHistoryView(store: store)

        case .settings:
            SettingsView(store: store)
        }
    }

    private var floatingCapsuleNavigation: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 8) {
                floatingTabButton(
                    .today,
                    title: "Today",
                    icon: "house.fill"
                )

                floatingTabButton(
                    .schedule,
                    title: "Schedule",
                    icon: "calendar"
                )

                Color.clear
                    .frame(width: 64, height: 54)

                floatingTabButton(
                    .history,
                    title: "History",
                    icon: "chart.bar.fill"
                )

                floatingTabButton(
                    .settings,
                    title: "Settings",
                    icon: "gearshape.fill"
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                .ultraThinMaterial,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        Color.white.opacity(0.40),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: AppTheme.navy.opacity(0.12),
                radius: 18,
                y: 8
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Button {
                showingAddMedication = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(AppTheme.actionText)
                    .frame(width: 60, height: 60)
                    .background(
                        AppTheme.blue,
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                Color.white.opacity(0.34),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: AppTheme.blue.opacity(0.35),
                        radius: 14,
                        y: 7
                    )
            }
            .accessibilityLabel("Add medication")
            .offset(y: -28)
            .padding(.bottom, 10)
        }
        // Keep touches on transparent areas above the bar from eating scrolls.
        .padding(.top, 28)
    }

    private func floatingTabButton(
        _ tab: AppTab,
        title: String,
        icon: String
    ) -> some View {
        Button {
            selectContentTab(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )
                    .frame(height: 22)

                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(
                selectedTab == tab
                    ? AppTheme.blue
                    : AppTheme.mutedText
            )
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                selectedTab == tab
                    ? AppTheme.blue.opacity(0.14)
                    : Color.clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}

enum AppTab: Hashable {
    case today
    case schedule
    case add
    case history
    case settings

    /// Left-to-right order of sibling pages in the floating menu.
    var siblingIndex: Int {
        switch self {
        case .today: return 0
        case .schedule: return 1
        case .add: return 1
        case .history: return 2
        case .settings: return 3
        }
    }
}

/// Applies iOS 26+ tab bar minimize only when available.
private struct LiquidGlassTabBarMinimizer: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environment(MedicationStore())
}
