import SwiftUI

struct PartyTaskCard: View {
    let task: PartyTask
    var isApproved = false
    var isHighlighted = false
    var onApprove: (() -> Void)?
    var titleAccessibilityIdentifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PartyTheme.standardSpacing) {
            VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PartyTheme.compactSpacing) {
                        taskTitle
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer(minLength: PartyTheme.compactSpacing)

                        TaskStatusBadge(status: task.status)
                    }

                    VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                        taskTitle
                        TaskStatusBadge(status: task.status)
                    }
                }

                Label(categoryName, systemImage: categoryIcon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                approvalLabel

                if case let .failed(message) = task.status {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .lineLimit(nil)
                }
            }
            .accessibilityElement(children: .combine)

            if let onApprove {
                ApprovalActionBar(
                    taskTitle: task.title,
                    canApprove: true,
                    canDecline: false,
                    onApprove: onApprove,
                    onDecline: {},
                    approveIdentifier: "approve-\(task.id.uuidString)"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PartyTheme.standardSpacing)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius)
                .strokeBorder(borderColor, lineWidth: isHighlighted ? 1.5 : 0.5)
        }
    }

    private var taskTitle: some View {
        Text(task.title)
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(nil)
            .accessibilityIdentifier(
                titleAccessibilityIdentifier
                    ?? "task-title-\(task.id.uuidString)"
            )
    }

    @ViewBuilder
    private var approvalLabel: some View {
        switch task.approvalRequirement {
        case .none:
            Label("Informational task", systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .required:
            Label(
                isApproved ? "Approval granted" : "Approval required",
                systemImage: isApproved ? "checkmark.shield.fill" : "shield"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isApproved ? Color.green : PartyTheme.accent)
        }
    }

    private var cardBackground: Color {
        if isHighlighted || task.status == .awaitingApproval {
            PartyTheme.approvalBackground
        } else {
            PartyTheme.cardBackground
        }
    }

    private var borderColor: Color {
        if isHighlighted || task.status == .awaitingApproval {
            PartyTheme.accent.opacity(0.45)
        } else {
            Color(uiColor: .separator).opacity(0.35)
        }
    }

    private var categoryName: String {
        switch task.category {
        case .guests:
            "Guests"
        case .cake:
            "Cake"
        case .food:
            "Food"
        case .favors:
            "Favors"
        case .gifts:
            "Gifts"
        case .venue:
            "Venue"
        case .schedule:
            "Schedule"
        }
    }

    private var categoryIcon: String {
        switch task.category {
        case .guests:
            "person.2"
        case .cake:
            "birthday.cake"
        case .food:
            "fork.knife"
        case .favors:
            "gift"
        case .gifts:
            "gift.fill"
        case .venue:
            "mappin.and.ellipse"
        case .schedule:
            "calendar"
        }
    }
}
