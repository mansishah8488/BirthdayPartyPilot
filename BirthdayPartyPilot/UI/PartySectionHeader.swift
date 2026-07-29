import SwiftUI

struct PartySectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
        }
        .textCase(nil)
        .accessibilityElement(children: .combine)
    }
}
