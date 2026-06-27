import SwiftUI

/// Eigenständige Design-Tokens des Packages — bewusst NICHT an die app-lokalen
/// DesignSystem-Tokens (Color.inkPrimary etc.) gebunden, damit beide Apps dieselbe
/// Komponente nutzen können. Themebar über eine Akzentfarbe; Neutraltöne kommen aus
/// System-Farben (nativer Look + Dark-Mode).
public struct FamilyTheme: Sendable {
    public var accent: Color
    public init(accent: Color) { self.accent = accent }

    public static let office = FamilyTheme(accent: Color(red: 0.91, green: 0.31, blue: 0.24)) // pilotRed
    public static let family = FamilyTheme(accent: Color(red: 0.30, green: 0.66, blue: 0.55)) // pilotGreen
}

// Neutrale Tokens als System-Farben (adaptiv).
extension Color {
    static let pfInkPrimary    = Color(uiColor: .label)
    static let pfInkSecondary  = Color(uiColor: .secondaryLabel)
    static let pfInkTertiary   = Color(uiColor: .tertiaryLabel)
    static let pfSurface       = Color(uiColor: .secondarySystemGroupedBackground)
    static let pfLine          = Color(uiColor: .separator)
}

enum PFSpacing {
    static let xs: CGFloat = 6
    static let s: CGFloat = 10
    static let m: CGFloat = 14
    static let l: CGFloat = 20
}
