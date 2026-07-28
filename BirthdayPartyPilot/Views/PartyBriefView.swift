import SwiftUI

struct PartyBriefView: View {
    let context: PartyContext
    let isPlanning: Bool
    let onCreatePlan: () -> Void

    var body: some View {
        List {
            Section("Party brief") {
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
            }

            Section {
                Button(action: onCreatePlan) {
                    Text("Create Birthday Plan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPlanning)
                .accessibilityLabel("Create Birthday Plan")
                .accessibilityIdentifier("create-plan-button")

                if isPlanning {
                    ProgressView("Creating birthday plan")
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("planning-progress")
                }
            }
        }
        .accessibilityIdentifier("party-brief-screen")
    }
}
