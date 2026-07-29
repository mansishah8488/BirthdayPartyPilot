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
                    detail: "\(context.adultCount + context.childCount) guests at \(context.venue)"
                )
                .listRowInsets(
                    EdgeInsets(
                        top: PartyTheme.compactSpacing,
                        leading: PartyTheme.standardSpacing,
                        bottom: PartyTheme.compactSpacing,
                        trailing: PartyTheme.standardSpacing
                    )
                )
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Birthday child", value: context.childName)
                    .accessibilityIdentifier("party-child-name")
                LabeledContent("Age", value: "Turning \(context.age)")
                LabeledContent {
                    Text(
                        context.partyDate,
                        format: .dateTime.month(.wide).day().year()
                    )
                } label: {
                    Text("Date")
                }
                LabeledContent("Theme", value: context.theme)
                LabeledContent("Adults", value: "\(context.adultCount) adults")
                LabeledContent("Children", value: "\(context.childCount) children")
                LabeledContent("Venue", value: context.venue)
            } header: {
                PartySectionHeader(
                    title: "Party details",
                    subtitle: "The fixed brief used to create the plan."
                )
            }

            Section {
                Button(action: onCreatePlan) {
                    Label(
                        isPlanning ? "Creating Birthday Plan" : "Create Birthday Plan",
                        systemImage: isPlanning ? "sparkles" : "wand.and.stars"
                    )
                        .frame(maxWidth: .infinity)
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
}
