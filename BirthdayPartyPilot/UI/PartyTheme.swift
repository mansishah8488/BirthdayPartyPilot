import SwiftUI

enum PartyTheme {
    static let cardCornerRadius: CGFloat = 18
    static let pillCornerRadius: CGFloat = 14
    static let compactSpacing: CGFloat = 8
    static let standardSpacing: CGFloat = 16
    /// Vertical gap between List sections on Brief and Plan Review.
    static let sectionSpacing: CGFloat = 12

    static let accent = Color.accentColor
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let approvalBackground = Color.accentColor.opacity(0.12)
    /// Stronger than system `.secondary` for section subtitles on grouped backgrounds.
    static let secondaryText = Color(uiColor: .label).opacity(0.72)
    static let informationalTint = Color.blue
    static let successTint = Color.green
}
