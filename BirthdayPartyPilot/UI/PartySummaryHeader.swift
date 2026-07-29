import SwiftUI

struct PartySummaryHeader: View {
    let context: PartyContext
    let phase: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PartyTheme.standardSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PartyTheme.standardSpacing) {
                    summaryIcon
                    summaryText
                    Spacer(minLength: PartyTheme.compactSpacing)
                }

                VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                    summaryIcon
                    summaryText
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: PartyTheme.compactSpacing) {
                    dateLabel

                    Text("·")
                        .foregroundStyle(.tertiary)

                    phaseLabel
                }

                VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                    dateLabel
                    phaseLabel
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding(PartyTheme.standardSpacing)
        .background(PartyTheme.approvalBackground)
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(context.childName)'s birthday, turning \(context.age), "
                + "\(context.theme), \(phase)"
        )
        .accessibilityIdentifier("party-summary-header")
    }

    private var summaryIcon: some View {
        Image(systemName: "sparkles")
            .font(.title2.weight(.semibold))
            .foregroundStyle(PartyTheme.accent)
            .accessibilityHidden(true)
    }

    private var summaryText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(context.childName)'s Birthday")
                .font(.title2.bold())
                .lineLimit(nil)

            Text("Turning \(context.age) · \(context.theme)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
        }
    }

    private var dateLabel: some View {
        Label {
            Text(
                context.partyDate,
                format: .dateTime.month(.abbreviated).day()
            )
        } icon: {
            Image(systemName: "calendar")
        }
    }

    private var phaseLabel: some View {
        Text(phase)
            .fontWeight(.semibold)
    }
}
