//
//  LegalViews.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

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
