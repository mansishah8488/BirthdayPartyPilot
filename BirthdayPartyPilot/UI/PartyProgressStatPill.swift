import SwiftUI

/// Gradient pill used by Plan Review and Execution progress cards.
struct PartyProgressStatPill: View {
    let value: Int
    let label: String
    let tint: Color
    let systemImage: String

    var body: some View {
        HStack(spacing: PartyTheme.compactSpacing) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value, format: .number)
                .font(.headline.monospacedDigit())
                .foregroundStyle(tint)
        }
        .padding(.horizontal, PartyTheme.standardSpacing)
        .padding(.vertical, PartyTheme.compactSpacing + 2)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.22), tint.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.pillCornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
