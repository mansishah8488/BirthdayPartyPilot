import SwiftUI

struct TaskStatusBadge: View {
    let status: PartyTaskStatus

    var body: some View {
        HStack(spacing: 6) {
            if status == .running {
                ProgressView()
                    .controlSize(.mini)
                    .tint(tint)
            } else {
                Image(systemName: iconName)
                    .accessibilityHidden(true)
            }

            Text(label)
                .lineLimit(nil)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(label)")
    }

    private var label: String {
        switch status {
        case .pending:
            "Pending"
        case .awaitingApproval:
            "Awaiting approval"
        case .running:
            "Running"
        case .completed:
            "Completed"
        case .failed:
            "Failed"
        case .declined:
            "Declined"
        case .cancelled:
            "Cancelled"
        }
    }

    private var iconName: String {
        switch status {
        case .pending:
            "clock"
        case .awaitingApproval:
            "checkmark.shield.fill"
        case .running:
            "hourglass"
        case .completed:
            "checkmark.circle.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        case .declined:
            "minus.circle"
        case .cancelled:
            "xmark.circle"
        }
    }

    private var tint: Color {
        switch status {
        case .pending, .declined, .cancelled:
            .secondary
        case .running, .awaitingApproval:
            PartyTheme.accent
        case .completed:
            .green
        case .failed:
            .red
        }
    }
}
