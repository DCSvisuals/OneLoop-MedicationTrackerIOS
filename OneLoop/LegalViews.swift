//
//  LegalViews.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

// MARK: - First-run medical disclaimer

struct MedicalDisclaimerGateView: View {
    @Binding var hasAcceptedDisclaimer: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.blue)
                        .frame(maxWidth: .infinity)

                    Text("Before you continue")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(AppInfo.medicalDisclaimerFull)
                        .font(.body)
                        .foregroundStyle(AppTheme.navy)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        "By tapping Continue, you confirm that you understand " +
                        "and agree to use OneLoop only as a personal reminder tool."
                    )
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.mutedText)
                }
                .padding(24)
            }
            .background(AppTheme.softBackground)
            .navigationTitle(AppInfo.appName)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    hasAcceptedDisclaimer = true
                } label: {
                    Text("I Understand — Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.blue)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Full legal screens

struct MedicalDisclaimerDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(AppInfo.medicalDisclaimerFull)
                    .font(.body)
                    .foregroundStyle(AppTheme.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)

                FloatingMenuScrollSpacer()
            }
            .padding(20)
        }
        .background(AppTheme.softBackground)
        .navigationTitle("Medical Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(AppInfo.privacyPolicyFull)
                    .font(.body)
                    .foregroundStyle(AppTheme.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)

                FloatingMenuScrollSpacer()
            }
            .padding(20)
        }
        .background(AppTheme.softBackground)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
