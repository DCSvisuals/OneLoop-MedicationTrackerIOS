//
//  AppTheme.swift
//  OneLoopUIv2
//
//  WCAG 2.2 AA, color-blind safe: blue is primary, orange is warning,
//  green is success only (never the global brand). Contrast targets
//  4.5:1 text / 3:1 large text and UI (1.4.3, 1.4.11). Status is never
//  color-only (1.4.1) — pair with icons/labels.
//

import SwiftUI
import UIKit

enum AppTheme {
    // MARK: - Core colors

    /// Primary body / title text — cool navy (not green)
    static let navy = Color(
        light: Color(red: 0.09, green: 0.12, blue: 0.18),
        dark: Color(red: 0.94, green: 0.95, blue: 0.98)
    )

    /// Primary accent / buttons — WCAG-safe blue
    static let blue = Color(
        light: Color(red: 0.12, green: 0.32, blue: 0.72),
        dark: Color(red: 0.55, green: 0.70, blue: 1.00)
    )

    /// Secondary muted slate (subtitles, not sage)
    static let teal = Color(
        light: Color(red: 0.28, green: 0.35, blue: 0.48),
        dark: Color(red: 0.70, green: 0.76, blue: 0.86)
    )

    /// Selected-chip fill — light blue, used with navy text
    static let lime = Color(
        light: Color(red: 0.82, green: 0.88, blue: 0.98),
        dark: Color(red: 0.18, green: 0.28, blue: 0.48)
    )

    static let scheduleSelectionText = Color(
        light: Color(red: 0.09, green: 0.12, blue: 0.18),
        dark: Color(red: 0.94, green: 0.95, blue: 0.98)
    )

    static let actionText = Color(
        light: Color(red: 0.99, green: 0.99, blue: 1.00),
        dark: Color(red: 0.07, green: 0.10, blue: 0.18)
    )

    /// Warning — orange (not red-vs-green)
    static let orange = Color(
        light: Color(red: 0.72, green: 0.38, blue: 0.08),
        dark: Color(red: 1.00, green: 0.68, blue: 0.32)
    )

    // MARK: - Surfaces

    static let softBackground = Color(
        light: Color(red: 0.96, green: 0.96, blue: 0.97),
        dark: Color(red: 0.07, green: 0.08, blue: 0.11)
    )

    static let cardBackground = Color(
        light: Color(red: 1.00, green: 1.00, blue: 1.00),
        dark: Color(red: 0.13, green: 0.15, blue: 0.20)
    )

    static let elevatedCard = Color(
        light: Color(red: 0.90, green: 0.92, blue: 0.96),
        dark: Color(red: 0.18, green: 0.21, blue: 0.28)
    )

    static let cardBorder = Color(
        light: Color.black.opacity(0.10),
        dark: Color.white.opacity(0.14)
    )

    // MARK: - Splash

    static let splashFill = Color(
        light: Color(red: 0.10, green: 0.16, blue: 0.28),
        dark: Color(red: 0.08, green: 0.12, blue: 0.22)
    )

    static let splashWordmark = Color(
        light: Color(red: 0.90, green: 0.93, blue: 0.98),
        dark: Color(red: 0.90, green: 0.93, blue: 0.98)
    )

    static let fieldFill = Color(
        light: Color(red: 0.93, green: 0.94, blue: 0.97),
        dark: Color(red: 0.16, green: 0.18, blue: 0.24)
    )

    // MARK: - Text and states

    static let mutedText = Color(
        light: Color(red: 0.32, green: 0.38, blue: 0.48),
        dark: Color(red: 0.68, green: 0.73, blue: 0.82)
    )

    /// Success only — tertiary, always paired with a checkmark/label
    static let success = Color(
        light: Color(red: 0.12, green: 0.45, blue: 0.28),
        dark: Color(red: 0.45, green: 0.82, blue: 0.58)
    )

    static let warning = orange

    // MARK: - Typography

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func rounded(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let pageTitle = Font.system(size: 36, weight: .bold, design: .serif)
    static let splashWordmarkFont = Font.system(size: 44, weight: .light, design: .default)
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
