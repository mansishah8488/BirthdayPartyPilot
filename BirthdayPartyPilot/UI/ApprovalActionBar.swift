import SwiftUI

struct ApprovalActionBar: View {
    let taskTitle: String
    let canApprove: Bool
    let canDecline: Bool
    let onApprove: () -> Void
    let onDecline: () -> Void
    var approveIdentifier = "approve-current-task-button"
    var declineIdentifier = "decline-current-task-button"

    var body: some View {
        if canApprove || canDecline {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PartyTheme.compactSpacing) {
                    actions
                }

                VStack(spacing: PartyTheme.compactSpacing) {
                    actions
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if canApprove {
            Button("Approve", action: onApprove)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Approve \(taskTitle)")
                .accessibilityHint("Allows this task to continue.")
                .accessibilityIdentifier(approveIdentifier)
        }

        if canDecline {
            Button("Decline", role: .destructive, action: onDecline)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel("Decline \(taskTitle)")
                .accessibilityHint("Skips this task without executing it.")
                .accessibilityIdentifier(declineIdentifier)
        }
    }
}
