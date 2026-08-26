//
//  OnboardingView.swift
//  OneLoopUIv2
//
//  First-launch carousel, GoGreen-style:
//  Splash → Welcome → How it works → Notifications → Policy → Sign in
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
    @State private var splashConsumed = false
    @State private var acceptedPolicy = false
    @State private var isRequestingNotifications = false
    @State private var didAutoAdvanceSplash = false
    @State private var notificationStatus:
        NotificationManager.AuthorizationStatus = .notDetermined

    private enum Page: Int, CaseIterable {
        case splash = 0
        case welcome = 1
        case tutorial = 2
        case notifications = 3
        case policy = 4
        case auth = 5
    }

    private var lastPageIndex: Int { Page.auth.rawValue }
    private var policyPageIndex: Int { Page.policy.rawValue }
    private var onboardingPageCount: Int { Page.allCases.count }

    private var currentPage: Page {
        Page(rawValue: page) ?? .welcome
    }

    private var supportsLiquidGlass: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            OLSiblingPager(
                selection: $page,
                pageCount: onboardingPageCount,
                swipeEnabled: false,
                lockedBelow: splashConsumed ? Page.welcome.rawValue : 0
            ) { index in
                pageView(index)
            }
            .ignoresSafeArea()

            bottomChrome
        }
        .animation(OLMotion.sibling, value: page)
        .onChange(of: page) { _, newPage in
            if newPage >= Page.welcome.rawValue {
                lockSplashAfterTransition()
            }
            if newPage > policyPageIndex, !acceptedPolicy {
                withAnimation(OLMotion.sibling) { page = policyPageIndex }
            }
        }
        .onChange(of: acceptedPolicy) { _, isAccepted in
            if !isAccepted, page > policyPageIndex {
                withAnimation(OLMotion.sibling) { page = policyPageIndex }
            }
        }
        .interactiveDismissDisabled()
        .preferredColorScheme(
            useSystemAppearance ? nil : (useDarkMode ? .dark : .light)
        )
        .onAppear {
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

    // MARK: - Pinned chrome (Continue + dots stay put)

    @ViewBuilder
    private var bottomChrome: some View {
        if currentPage != .splash {
            VStack(spacing: 10) {
                if showsContinue {
                    OLPrimaryButton(
                        title: "Continue",
                        enabled: continueEnabled
                    ) {
                        handleContinue()
                    }
                }

                if currentPage == .notifications {
                    Button {
                        goToPage(.policy)
                    } label: {
                        Text("Not now")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.navy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRequestingNotifications)
                } else if showsContinue {
                    Color.clear.frame(height: 36)
                }

                OLPageDots(
                    count: Page.allCases.count - 1,
                    current: max(0, page - 1),
                    onDark: false
                )
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 34)
            .transition(.opacity)
        }
    }

    private var showsContinue: Bool {
        currentPage != .splash && currentPage != .auth
    }

    private var continueEnabled: Bool {
        if isRequestingNotifications { return false }
        if currentPage == .policy { return acceptedPolicy }
        return true
    }

    private func handleContinue() {
        switch currentPage {
        case .welcome:
            goToPage(.tutorial)
        case .tutorial:
            goToPage(.notifications)
        case .notifications:
            Task { await handleAllowNotifications() }
        case .policy:
            guard acceptedPolicy else { return }
            goToPage(.auth)
        case .splash, .auth:
            break
        }
    }

    @ViewBuilder
    private func pageView(_ index: Int) -> some View {
        switch Page(rawValue: index) {
        case .splash:
            splashPage
        case .welcome:
            welcomePage
        case .tutorial:
            tutorialPage
        case .notifications:
            notificationsPage
        case .policy:
            policyPage
        case .auth:
            authPage
        case nil:
            AppTheme.softBackground
        }
    }

    private func goToPage(_ newPage: Page) {
        withAnimation(OLMotion.sibling) {
            page = newPage.rawValue
        }
        if newPage != .splash {
            lockSplashAfterTransition()
        }
    }

    private func lockSplashAfterTransition() {
        guard !splashConsumed else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(520))
            splashConsumed = true
            if page < Page.welcome.rawValue {
                page = Page.welcome.rawValue
            }
        }
    }

    // MARK: - Page 0: Splash (GoGreen)

    private var splashPage: some View {
        ZStack {
            AppTheme.splashFill

            VStack(spacing: 10) {
                Text("ONELOOP")
                    .font(.system(size: 42, weight: .light, design: .default))
                    .tracking(6)
                    .foregroundStyle(AppTheme.splashWordmark)

                Text("UIv2")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .tracking(4)
                    .foregroundStyle(AppTheme.splashWordmark.opacity(0.85))
            }
            .offset(y: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            goToPage(.welcome)
        }
        .task {
            guard !didAutoAdvanceSplash else { return }
            didAutoAdvanceSplash = true
            try? await Task.sleep(for: .seconds(1.8))
            if page == Page.splash.rawValue {
                goToPage(.welcome)
            }
        }
        .accessibilityLabel("OneLoop UIv2")
        .accessibilityHint("Double tap to continue")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        photoStoryPage(
            title: "Welcome",
            subtitle: "we're glad that you are here",
            imageName: "OnboardingWelcomePlant",
            imageFill: true
        )
    }

    // MARK: - Page 2: How it works

    private var tutorialPage: some View {
        photoStoryPage(
            title: "Your Daily Loop",
            subtitle: "Add a medication, get a reminder, mark it taken. History stays even after you remove a med.",
            imageName: "OnboardingShelfPlants",
            imageFill: false
        )
    }

    // MARK: - Page 3: Notifications

    private var notificationsPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: OnboardingChrome.titleTopPadding)

            Image("OnboardingRootPlant")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 240)
                .padding(.horizontal, 36)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Text("Stay In Your Loop")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.navy)
                    .multilineTextAlignment(.center)

                Text(
                    "Allow notifications so OneLoop UIv2 can remind you at every scheduled dose. Reminders stay on this iPhone."
                )
                .font(.body)
                .foregroundStyle(AppTheme.teal)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            }

            notificationStatusBanner
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer(minLength: 8)
        }
        .padding(.bottom, OnboardingChrome.bottomReserve)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.softBackground)
        .task {
            notificationStatus = await NotificationManager.shared
                .authorizationStatus
            if notificationStatus == .authorized {
                notificationsEnabled = true
            }
        }
    }

    @ViewBuilder
    private var notificationStatusBanner: some View {
        switch notificationStatus {
        case .authorized:
            Text("Notifications are already allowed for OneLoop UIv2.")
                .font(.footnote)
                .foregroundStyle(AppTheme.teal)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    AppTheme.elevatedCard,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        case .denied:
            Text(
                "Notifications are turned off for OneLoop UIv2 in iOS Settings. " +
                "You can enable them there, or continue and turn them on later."
            )
            .font(.footnote)
            .foregroundStyle(AppTheme.warning)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.elevatedCard,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        case .notDetermined, .unknown:
            EmptyView()
        }
    }

    private func handleAllowNotifications() async {
        switch notificationStatus {
        case .authorized:
            notificationsEnabled = true
            goToPage(.policy)

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

            goToPage(.policy)
        }
    }

    // MARK: - Page 4: Policy (fixed chrome, text box scrolls)

    private var policyPage: some View {
        GeometryReader { geo in
            let headerHeight: CGFloat = 86
            let gaps: CGFloat = 42
            let boxHeight = max(
                140,
                geo.size.height
                    - OnboardingChrome.titleTopPadding
                    - headerHeight
                    - OnboardingChrome.toggleBlockHeight
                    - OnboardingChrome.bottomReserve
                    - gaps
            )

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A quiet note")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.navy)

                    Text("Please read carefully before using OneLoop UIv2.")
                        .font(.body)
                        .foregroundStyle(AppTheme.teal)
                }

                ScrollView(showsIndicators: true) {
                    Text(AppInfo.medicalDisclaimerFull)
                        .font(.body)
                        .foregroundStyle(AppTheme.navy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: boxHeight)
                .background(AppTheme.cardBackground)
                .clipShape(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }

                Toggle(isOn: $acceptedPolicy) {
                    Text(
                        "I understand OneLoop UIv2 is a personal reminder tool, " +
                        "not a medical device or source of medical advice, " +
                        "and that optional account data may be stored with Supabase."
                    )
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.navy)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .tint(AppTheme.blue)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    AppTheme.elevatedCard,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, OnboardingChrome.titleTopPadding)
            .padding(.bottom, OnboardingChrome.bottomReserve)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.softBackground)
    }

    // MARK: - Page 5: Auth + Skip

    private var authPage: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    finishOnboarding()
                } label: {
                    Text("Skip")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.navy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            AppTheme.cardBackground.opacity(0.7),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip sign in")
            }
            .padding(.horizontal, 20)
            .padding(.top, OnboardingChrome.titleTopPadding)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Image("OnboardingRootPlant")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)

                    AuthCardView(
                        onAuthenticated: { finishOnboarding() }
                    )
                    .padding(.horizontal, 20)

                    Text("You can create an account anytime in Settings.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }

            Color.clear.frame(height: 56)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.softBackground)
    }

    // MARK: - Photo story layout

    private func photoStoryPage(
        title: String,
        subtitle: String,
        imageName: String,
        imageFill: Bool
    ) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 40, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.navy)

                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(AppTheme.teal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, OnboardingChrome.titleTopPadding)

            Spacer(minLength: 8)

            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: imageFill ? 420 : 260)
                .clipped()
                .clipShape(
                    RoundedRectangle(cornerRadius: imageFill ? 0 : 8, style: .continuous)
                )
                .padding(.horizontal, imageFill ? 0 : 28)

            Spacer(minLength: 16)
        }
        .padding(.bottom, OnboardingChrome.bottomReserve)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.softBackground)
    }

    private func finishOnboarding() {
        if !supportsLiquidGlass {
            useLiquidGlassNavigation = false
        }
        hasAcceptedDisclaimer = true
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView(
        hasCompletedOnboarding: .constant(false),
        hasAcceptedDisclaimer: .constant(false)
    )
}
