import SwiftUI

struct PartyBriefView: View {
    let context: PartyContext
    let isPlanning: Bool
    let onCreatePlan: () -> Void

    var body: some View {
        List {
            Section {
                PartySummaryHeader(
                    context: context,
                    phase: "Party brief",
                    detail: nil
                )
                .listRowInsets(
                    EdgeInsets(
                        top: PartyTheme.standardSpacing,
                        leading: PartyTheme.standardSpacing,
                        bottom: PartyTheme.compactSpacing,
                        trailing: PartyTheme.standardSpacing
                    )
                )
                .listRowBackground(Color.clear)
            }

            Section {
                VStack(alignment: .leading, spacing: PartyTheme.standardSpacing) {
                    briefFact(
                        title: "Birthday child",
                        value: context.childName,
                        systemImage: "gift"
                    )
                    .accessibilityIdentifier("party-child-name")

                    briefFact(
                        title: "Date",
                        value: context.partyDate.formatted(
                            .dateTime.month(.wide).day().year()
                        ),
                        systemImage: "calendar"
                    )

                    briefFact(
                        title: "Venue",
                        value: context.venue,
                        systemImage: "mappin.and.ellipse"
                    )

                    briefFact(
                        title: "Guests",
                        value: guestSummary,
                        systemImage: "person.2"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PartyTheme.standardSpacing)
                .background(PartyTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
                .listRowInsets(
                    EdgeInsets(
                        top: PartyTheme.compactSpacing,
                        leading: PartyTheme.standardSpacing,
                        bottom: PartyTheme.compactSpacing,
                        trailing: PartyTheme.standardSpacing
                    )
                )
                .listRowBackground(Color.clear)
            } header: {
                PartySectionHeader(
                    title: "Party details",
                    subtitle: "Date, venue, and guest counts for this plan."
                )
            }

            Section {
                Button(action: onCreatePlan) {
                    Text(
                        isPlanning
                            ? "Creating Birthday Plan"
                            : "Create Birthday Plan"
                    )
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PartyTheme.compactSpacing)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPlanning)
                .accessibilityLabel("Create Birthday Plan")
                .accessibilityHint("Creates a six-task birthday plan for review.")
                .accessibilityIdentifier("create-plan-button")

                if isPlanning {
                    ProgressView("Creating birthday plan")
                        .frame(maxWidth: .infinity)
                        .padding(.top, PartyTheme.compactSpacing)
                        .accessibilityIdentifier("planning-progress")
                }
            }
        }
        .listStyle(.insetGrouped)
        .defaultScrollAnchor(.top)
        .scrollContentBackground(.hidden)
        .background(PartyTheme.pageBackground)
        .accessibilityIdentifier("party-brief-screen")
    }

    private var guestSummary: String {
        "\(context.adultCount) adults · \(context.childCount) children"
    }

    private func briefFact(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(PartyTheme.accent)
                .accessibilityHidden(true)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .combine)
    }
}
