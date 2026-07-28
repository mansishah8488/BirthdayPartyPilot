import Foundation
import SwiftUI

struct PlanReviewView: View {
    let tasks: [PartyTask]
    let isApproved: (UUID) -> Bool
    let canExecutePlan: Bool
    let onApprove: (UUID) -> Void
    let onExecutePlan: () -> Void

    var body: some View {
        List {
            Section("Plan review") {
                ForEach(tasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(task.title, systemImage: statusIcon(for: task.status))
                            .font(.headline)

                        LabeledContent("Category", value: categoryName(for: task.category))
                        LabeledContent(
                            "Approval",
                            value: approvalDescription(for: task)
                        )
                        LabeledContent("Status", value: statusName(for: task.status))

                        if task.approvalRequirement == .required,
                           !isApproved(task.id) {
                            Button("Approve") {
                                onApprove(task.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityLabel("Approve \(task.title)")
                            .accessibilityIdentifier("approve-\(task.id.uuidString)")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button("Execute Approved Plan", action: onExecutePlan)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canExecutePlan)
                    .accessibilityLabel("Execute Approved Plan")
                    .accessibilityIdentifier("execute-plan-button")

                if !canExecutePlan {
                    Text("Approve every required task before execution.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("plan-review-screen")
    }

    private func categoryName(for category: PartyTaskCategory) -> String {
        switch category {
        case .guests: "Guests"
        case .cake: "Cake"
        case .food: "Food"
        case .favors: "Favors"
        case .gifts: "Gifts"
        case .venue: "Venue"
        case .schedule: "Schedule"
        }
    }

    private func approvalDescription(for task: PartyTask) -> String {
        switch task.approvalRequirement {
        case .none:
            "Not required"
        case .required:
            isApproved(task.id) ? "Required · Approved" : "Required · Awaiting approval"
        }
    }

    private func statusName(for status: PartyTaskStatus) -> String {
        switch status {
        case .pending: "Pending"
        case .awaitingApproval: "Awaiting approval"
        case .running: "Running"
        case .completed: "Completed"
        case let .failed(message): "Failed: \(message)"
        case .cancelled: "Cancelled"
        }
    }

    private func statusIcon(for status: PartyTaskStatus) -> String {
        switch status {
        case .pending: "circle"
        case .awaitingApproval: "hand.raised.fill"
        case .running: "hourglass"
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }
}
