//
//  AppTheme.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI
import UIKit

enum AppTheme {
    // MARK: - Core colors

    /// Primary body / title text
    static let navy = Color(
        light: Color(red: 0.06, green: 0.08, blue: 0.12),
        dark: Color(red: 0.95, green: 0.97, blue: 1.00)
    )

    static let blue = Color(
        light: Color(red: 0.05, green: 0.28, blue: 0.72),
        dark: Color(red: 0.32, green: 0.54, blue: 1.00)
    )

    static let teal = Color(
        light: Color(red: 0.00, green: 0.42, blue: 0.44),
        dark: Color(red: 0.15, green: 0.78, blue: 0.72)
    )

    /// Accent / selection fill (kept brighter for chips and buttons)
    static let lime = Color(
        light: Color(red: 0.48, green: 0.74, blue: 0.12),
        dark: Color(red: 0.70, green: 0.93, blue: 0.20)
    )

    static let scheduleSelectionText = Color(
        light: Color(red: 0.05, green: 0.10, blue: 0.16),
        dark: Color(red: 0.03, green: 0.05, blue: 0.02)
    )

    static let actionText = Color(
        light: Color(red: 0.06, green: 0.14, blue: 0.03),
        dark: Color(red: 0.04, green: 0.07, blue: 0.02)
    )

    static let orange = Color(
        light: Color(red: 0.82, green: 0.24, blue: 0.04),
        dark: Color(red: 1.00, green: 0.48, blue: 0.20)
    )

    // MARK: - Surfaces

    /// Page background — white in light mode
    static let softBackground = Color(
        light: Color.white,
        dark: Color(red: 0.035, green: 0.045, blue: 0.065)
    )

    /// Cards — soft blue-grey in light mode
    static let cardBackground = Color(
        light: Color(red: 0.90, green: 0.92, blue: 0.95),
        dark: Color(red: 0.09, green: 0.105, blue: 0.14)
    )

    /// Nested / elevated surfaces inside cards
    static let elevatedCard = Color(
        light: Color(red: 0.84, green: 0.88, blue: 0.94),
        dark: Color(red: 0.13, green: 0.15, blue: 0.20)
    )

    static let cardBorder = Color(
        light: Color.black.opacity(0.10),
        dark: Color.white.opacity(0.10)
    )

    // MARK: - Text and states

    /// Secondary labels — darkened for light-mode readability
    static let mutedText = Color(
        light: Color(red: 0.26, green: 0.30, blue: 0.38),
        dark: Color(red: 0.62, green: 0.67, blue: 0.75)
    )

    /// Deeper green in light mode so icons/text stay readable on white
    static let success = Color(
        light: Color(red: 0.18, green: 0.55, blue: 0.20),
        dark: Color(red: 0.70, green: 0.93, blue: 0.20)
    )

    static let warning = orange
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(dark)
                    : UIColor(light)
            }
        )
    }
}
