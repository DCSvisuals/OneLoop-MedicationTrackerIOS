//
//  OnboardingView.swift
//  OneLoop
//
//  First-launch carousel:
//  About → Tutorial → Appearance → Notifications → Policy → Sign in
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var hasAcceptedDisclaimer: Bool

    @Bindable private var cloud = SupabaseManager.shared

    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("useLiquidGlassNavigation")
    private var useLiquidGlassNavigation = false
    @AppStorage("notificationsEnabled")
    private var notificationsEnabled = false

    @State private var page = 0
    @State private var acceptedPolicy = false
    @State private var isRequestingNotifications = false
    @State private var notificationStatus:
        NotificationManager.AuthorizationStatus = .notDetermined

    /// Page indices (must stay in sync with TabView tags).
    private enum Page: Int, CaseIterable {
        case about = 0
        case tutorial = 1
        case appearance = 2
        case notifications = 3
        case policy = 4
        case auth = 5
    }

    private var lastPageIndex: Int { Page.auth.rawValue }
    private var policyPageIndex: Int { Page.policy.rawValue }

    private var supportsLiquidGlass: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    var body: some View {
        ZStack {
            AppTheme.softBackground
                .ignoresSafeArea()

            OnboardingBackdrop()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $page) {
                    aboutPage.tag(Page.about.rawValue)
                    tutorialPage.tag(Page.tutorial.rawValue)
                    appearancePage.tag(Page.appearance.rawValue)
                    notificationsPage.tag(Page.notifications.rawValue)
                    policyPage.tag(Page.policy.rawValue)
                    authPage.tag(Page.auth.rawValue)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.snappy, value: page)
                .background {
                    OnboardingTabViewScrollLock(
                        isPagingEnabled: page != policyPageIndex || acceptedPolicy
                    )
                }
                .onChange(of: page) { _, newPage in
                    if newPage > policyPageIndex, !acceptedPolicy {
                        withAnimation(.snappy) { page = policyPageIndex }
                    }
                }
                .onChange(of: acceptedPolicy) { _, isAccepted in
                    if !isAccepted, page > policyPageIndex {
                        withAnimation(.snappy) { page = policyPageIndex }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        // Live preview of appearance choices during onboarding.
        .preferredColorScheme(
            useSystemAppearance
                ? nil
                : (useDarkMode ? .dark : .light)
        )
        .onAppear {
            // Liquid Glass is iOS 26+ only.
            if !supportsLiquidGlass {
                useLiquidGlassNavigation = false
            }
        }
        .task {
            await cloud.refreshSession()
            if cloud.isSignedIn {
                finishOnboarding()
            }
        }
        .onChange(of: cloud.isSignedIn) { _, signedIn in
            if signedIn { finishOnboarding() }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: SupabaseManager.didAuthenticateNotification
            )
        ) { _ in
            finishOnboarding()
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            if page > 0 {
                Button {
                    withAnimation(.snappy) { page -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.navy)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.cardBackground, in: Circle())
                        .overlay {
                            Circle().stroke(AppTheme.cardBorder, lineWidth: 1)
                        }
                }
                .accessibilityLabel("Back")
            } else {
                Color.clear.frame(width: 40, height: 40)
            }

            Spacer()
            pageIndicator
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0...lastPageIndex, id: \.self) { index in
                Capsule()
                    .fill(
                        index == page
                            ? AppTheme.blue
                            : AppTheme.mutedText.opacity(0.25)
                    )
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(.snappy, value: page)
            }
        }
    }

    // MARK: - Page 0: About

    private var aboutPage: some View {
        onboardingScaffold(title: "About OneLoop", subtitle: "Your personal medication schedule and reminder companion.") {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppTheme.blue)
                    .frame(width: 76, height: 76)
                    .background(
                        AppTheme.blue.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 22)
                    )

                aboutBullet(
                    icon: "bell.badge.fill",
                    title: "Smart reminders",
                    detail: "Local notifications for every scheduled dose."
                )
                aboutBullet(
                    icon: "calendar",
                    title: "Flexible schedules",
                    detail: "Daily plans, intervals, and staged dose changes."
                )
                aboutBullet(
                    icon: "clock.arrow.circlepath",
                    title: "History that lasts",
                    detail: "Keep records even after removing a medication."
                )
                aboutBullet(
                    icon: "icloud",
                    title: "Optional cloud backup",
                    detail: "Sign in later to sync across devices when you’re ready."
                )
            }
        } footer: {
            primaryButton("Continue") {
                withAnimation(.snappy) { page = Page.tutorial.rawValue }
            }
        }
    }

    // MARK: - Page 1: Tutorial + widgets

    private var tutorialPage: some View {
        onboardingScaffold(
            title: "How to use OneLoop",
            subtitle: "Add medications in a few taps, then pin widgets for a quick glance."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Add a medication")
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)

                tutorialStep(
                    number: "1",
                    title: "Tap the + button",
                    detail: "Use the center + in the bottom menu, or the + in the Today toolbar."
                )
                tutorialStep(
                    number: "2",
                    title: "Enter name, dose, and times",
                    detail: "Choose form (pill, injection, cream), amount, first reminder, and how often."
                )
                tutorialStep(
                    number: "3",
                    title: "Save and follow Today",
                    detail: "Mark doses taken, snooze when needed, and review History anytime."
                )

                Divider().padding(.vertical, 4)

                Text("Home Screen & Lock Screen widgets")
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)

                aboutBullet(
                    icon: "rectangle.on.rectangle",
                    title: "Home Screen",
                    detail: "Add the OneLoop widget to see next medication and today’s progress."
                )
                aboutBullet(
                    icon: "lock.rectangle.on.rectangle",
                    title: "Lock Screen",
                    detail: "Use circular, rectangular, or inline widgets for glanceable reminders."
                )

                Text(
                    "Tip: touch and hold the Home or Lock Screen → Edit → Add Widget → OneLoop."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.mutedText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    AppTheme.elevatedCard,
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
        } footer: {
            primaryButton("Continue") {
                withAnimation(.snappy) { page = Page.appearance.rawValue }
            }
        }
    }

    // MARK: - Page 2: Appearance

    private var appearancePage: some View {
        onboardingScaffold(
            title: "Make it yours",
            subtitle: "Choose how OneLoop looks. You can change this later in Settings."
        ) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Appearance")
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)

                Toggle("Use system appearance", isOn: $useSystemAppearance)
                    .tint(AppTheme.blue)

                Toggle("Dark mode", isOn: $useDarkMode)
                    .tint(AppTheme.blue)
                    .disabled(useSystemAppearance)
                    .opacity(useSystemAppearance ? 0.45 : 1)

                Text(
                    useSystemAppearance
                        ? "OneLoop follows your device light/dark setting."
                        : (
                            useDarkMode
                                ? "Dark mode is selected."
                                : "Light mode is selected."
                        )
                )
                .font(.caption)
                .foregroundStyle(AppTheme.mutedText)

                Divider()

                Text("Bottom menu")
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)

                if supportsLiquidGlass {
                    // Live visual preview + style picker. Previews use local
                    // demo state only and never drive the real app menu.
                    OnboardingMenuStyleChooser(
                        useLiquidGlassNavigation: $useLiquidGlassNavigation
                    )
                } else {
                    // iOS 18: pill preview only (non-interactive).
                    OnboardingPillMenuPreview()

                    HStack(spacing: 12) {
                        Image(systemName: "capsule.fill")
                            .foregroundStyle(AppTheme.blue)
                            .frame(width: 40, height: 40)
                            .background(
                                AppTheme.blue.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pill menu")
                                .font(.headline)
                                .foregroundStyle(AppTheme.navy)
                            Text(
                                "Your iOS version uses the floating capsule menu. " +
                                "Liquid Glass requires iOS 26 or newer."
                            )
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        AppTheme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.blue.opacity(0.35), lineWidth: 1.5)
                    }
                    .onAppear {
                        useLiquidGlassNavigation = false
                    }
                }
            }
        } footer: {
            primaryButton("Continue") {
                if !supportsLiquidGlass {
                    useLiquidGlassNavigation = false
                }
                withAnimation(.snappy) {
                    page = Page.notifications.rawValue
                }
            }
        }
    }

    // MARK: - Page 3: Notifications

    private var notificationsPage: some View {
        onboardingScaffold(
            title: "Stay on track",
            subtitle: "Allow notifications so OneLoop can remind you at every scheduled dose."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppTheme.blue)
                    .frame(width: 76, height: 76)
                    .background(
                        AppTheme.blue.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 22)
                    )

                aboutBullet(
                    icon: "clock.fill",
                    title: "On-time dose reminders",
                    detail: "Get a local alert when each medication is due."
                )
                aboutBullet(
                    icon: "lock.shield.fill",
                    title: "Stays on your device",
                    detail: "Reminders are scheduled on this iPhone — nothing is sent to a third-party messaging service."
                )
                aboutBullet(
                    icon: "slider.horizontal.3",
                    title: "Change anytime",
                    detail: "You can turn reminders on or off later in Settings."
                )

                notificationStatusBanner
            }
        } footer: {
            VStack(spacing: 12) {
                primaryButton(
                    isRequestingNotifications
                        ? "Requesting…"
                        : allowNotificationsButtonTitle
                ) {
                    Task { await handleAllowNotifications() }
                }
                .disabled(isRequestingNotifications)
                .opacity(isRequestingNotifications ? 0.7 : 1)

                Button {
                    withAnimation(.snappy) {
                        page = Page.policy.rawValue
                    }
                } label: {
                    Text(skipNotificationsButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(AppTheme.navy)
                        .background(
                            AppTheme.cardBackground,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isRequestingNotifications)
            }
        }
        .task {
            notificationStatus = await NotificationManager.shared
                .authorizationStatus
            if notificationStatus == .authorized {
                notificationsEnabled = true
            }
        }
    }

    private var allowNotificationsButtonTitle: String {
        switch notificationStatus {
        case .authorized:
            return "Continue"
        case .denied:
            return "Open Settings"
        case .notDetermined, .unknown:
            return "Allow notifications"
        }
    }

    private var skipNotificationsButtonTitle: String {
        notificationStatus == .authorized ? "Continue without changes" : "Not now"
    }

    @ViewBuilder
    private var notificationStatusBanner: some View {
        switch notificationStatus {
        case .authorized:
            Text("Notifications are already allowed for OneLoop.")
                .font(.footnote)
                .foregroundStyle(AppTheme.teal)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    AppTheme.elevatedCard,
                    in: RoundedRectangle(cornerRadius: 14)
                )
        case .denied:
            Text(
                "Notifications are turned off for OneLoop in iOS Settings. " +
                "You can enable them there, or continue and turn them on later."
            )
            .font(.footnote)
            .foregroundStyle(AppTheme.warning)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.elevatedCard,
                in: RoundedRectangle(cornerRadius: 14)
            )
        case .notDetermined, .unknown:
            EmptyView()
        }
    }

    private func handleAllowNotifications() async {
        switch notificationStatus {
        case .authorized:
            notificationsEnabled = true
            withAnimation(.snappy) { page = Page.policy.rawValue }

        case .denied:
            NotificationManager.shared.openSystemSettings()

        case .notDetermined, .unknown:
            isRequestingNotifications = true
            defer { isRequestingNotifications = false }

            let granted = await NotificationManager.shared
                .requestAuthorization()
            notificationStatus = await NotificationManager.shared
                .authorizationStatus

            if granted {
                notificationsEnabled = true
            }

            withAnimation(.snappy) {
                page = Page.policy.rawValue
            }
        }
    }

    // MARK: - Page 4: Policy

    private var policyPage: some View {
        onboardingScaffold(
            title: "Medical disclaimer",
            subtitle: "Please read carefully before using OneLoop."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text(AppInfo.medicalDisclaimerFull)
                    .font(.body)
                    .foregroundStyle(AppTheme.navy)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .background(
                        AppTheme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    }

                Toggle(isOn: $acceptedPolicy) {
                    Text(
                        "I understand OneLoop is a personal reminder tool, " +
                        "not a medical device or source of medical advice, " +
                        "and that optional account data may be stored with Supabase."
                    )
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.navy)
                }
                .tint(AppTheme.blue)
            }
        } footer: {
            primaryButton("I Agree — Continue") {
                withAnimation(.snappy) { page = Page.auth.rawValue }
            }
            .disabled(!acceptedPolicy)
            .opacity(acceptedPolicy ? 1 : 0.45)
        }
    }

    // MARK: - Page 5: Auth

    private var authPage: some View {
        ScrollView(showsIndicators: false) {
            AuthCardView(
                onAuthenticated: { finishOnboarding() },
                showsSignInLater: true,
                onSignInLater: { finishOnboarding() }
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Scaffold / helpers

    private func onboardingScaffold<Content: View, Footer: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.navy)

                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(AppTheme.mutedText)

                    content()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            footer()
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
    }

    private func aboutBullet(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.blue)
                .frame(width: 40, height: 40)
                .background(
                    AppTheme.cardBackground,
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
    }

    private func tutorialStep(
        number: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(AppTheme.blue, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
    }

    private func primaryButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(AppTheme.blue, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func finishOnboarding() {
        if !supportsLiquidGlass {
            useLiquidGlassNavigation = false
        }
        hasAcceptedDisclaimer = true
        hasCompletedOnboarding = true
    }
}

// MARK: - Backdrop

private struct OnboardingBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppTheme.blue.opacity(0.06))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.12)

                Circle()
                    .fill(AppTheme.lime.opacity(0.08))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: -geo.size.width * 0.4, y: geo.size.height * 0.55)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - TabView swipe lock

private struct OnboardingTabViewScrollLock: UIViewRepresentable {
    var isPagingEnabled: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = Self.findPagingScrollView(from: uiView) else {
                return
            }
            scrollView.isScrollEnabled = isPagingEnabled
            scrollView.bounces = isPagingEnabled
        }
    }

    private static func findPagingScrollView(from view: UIView) -> UIScrollView? {
        var current: UIView? = view
        while let node = current {
            if let scroll = node as? UIScrollView, scroll.isPagingEnabled {
                return scroll
            }
            for subview in node.subviews {
                if let found = findPagingScrollView(in: subview) {
                    return found
                }
            }
            current = node.superview
        }
        return nil
    }

    private static func findPagingScrollView(in root: UIView) -> UIScrollView? {
        if let scroll = root as? UIScrollView, scroll.isPagingEnabled {
            return scroll
        }
        for subview in root.subviews {
            if let found = findPagingScrollView(in: subview) {
                return found
            }
        }
        return nil
    }
}

#Preview {
    OnboardingView(
        hasCompletedOnboarding: .constant(false),
        hasAcceptedDisclaimer: .constant(false)
    )
}
