import SwiftUI

struct TaskStatusBadge: View {
    enum Style {
        /// Icon + text capsule used on Execution.
        case labeled
        /// Compact symbol for dense plan cards.
        case symbol
    }

    let status: PartyTaskStatus
    var style: Style = .labeled

    var body: some View {
        Group {
            switch style {
            case .labeled:
                labeledBadge
            case .symbol:
                symbolBadge
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(label)")
    }

    private var labeledBadge: some View {
        HStack(spacing: 6) {
            statusSymbol

            Text(label)
                .lineLimit(nil)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12), in: Capsule())
    }

    private var symbolBadge: some View {
        statusSymbol
            .font(.body.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .background(tint.opacity(0.12), in: Circle())
    }

    @ViewBuilder
    private var statusSymbol: some View {
        if status == .running {
            ProgressView()
                .controlSize(.mini)
                .tint(tint)
        } else {
            Image(systemName: iconName)
                .accessibilityHidden(true)
        }
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
            "shield.fill"
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
        case .pending, .cancelled:
            .secondary
        case .declined:
            PartyTheme.secondaryText
        case .running, .awaitingApproval:
            PartyTheme.accent
        case .completed:
            PartyTheme.successTint
        case .failed:
            .red
        }
    }
}
