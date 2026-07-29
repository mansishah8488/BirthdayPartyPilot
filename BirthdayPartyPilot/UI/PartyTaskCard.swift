import SwiftUI

struct PartyTaskCard: View {
    let task: PartyTask
    var isApproved = false
    var isHighlighted = false
    var onApprove: (() -> Void)?
    var titleAccessibilityIdentifier: String?
    var positionLabel: String?
    /// Plan Review uses compact top-right symbols; Execution keeps labeled badges.
    var statusBadgeStyle: TaskStatusBadge.Style = .labeled
    var showsApprovalText = true

    var body: some View {
        VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
            switch statusBadgeStyle {
            case .symbol:
                compactRow
            case .labeled:
                labeledContent
            }

            if showsApprovalText {
                approvalLabel
            }

            if case let .failed(message) = task.status {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .lineLimit(nil)
            }

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

    /// Left → right: category, copy, status. Top → down: position, title, category/approval.
    private var compactRow: some View {
        HStack(alignment: .top, spacing: PartyTheme.standardSpacing) {
            categoryGlyph
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                if let positionLabel {
                    Text(positionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                taskTitle

                HStack(spacing: PartyTheme.compactSpacing) {
                    if !showsApprovalText {
                        approvalSymbol
                    }

                    Text(categoryName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            TaskStatusBadge(status: task.status, style: .symbol)
        }
        .accessibilityElement(children: .contain)
    }

    private var labeledContent: some View {
        HStack(alignment: .top, spacing: PartyTheme.standardSpacing) {
            categoryGlyph
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                if let positionLabel {
                    Text(positionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PartyTheme.compactSpacing) {
                        taskTitle
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer(minLength: PartyTheme.compactSpacing)

                        TaskStatusBadge(status: task.status, style: .labeled)
                    }

                    VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                        taskTitle
                        TaskStatusBadge(status: task.status, style: .labeled)
                    }
                }

                Text(categoryName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    private var categoryGlyph: some View {
        Image(systemName: categoryIcon)
            .font(.body.weight(.semibold))
            .foregroundStyle(PartyTheme.accent)
            .frame(width: 36, height: 36)
            .background(PartyTheme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel(categoryName)
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
    private var approvalSymbol: some View {
        switch task.approvalRequirement {
        case .none:
            Image(systemName: "info.circle.fill")
                .font(.subheadline)
                .foregroundStyle(PartyTheme.informationalTint)
                .accessibilityLabel("Informational")
        case .required:
            Image(systemName: isApproved ? "checkmark.shield.fill" : "shield.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    isApproved ? PartyTheme.successTint : PartyTheme.accent
                )
                .accessibilityLabel(isApproved ? "Pre-approved" : "Need approval")
                .accessibilityIdentifier(
                    isApproved ? "approval-granted-label" : "approval-required-label"
                )
        }
    }

    @ViewBuilder
    private var approvalLabel: some View {
        switch task.approvalRequirement {
        case .none:
            Label("Informational", systemImage: "info.circle.fill")
                .font(.subheadline)
                .foregroundStyle(PartyTheme.informationalTint)
        case .required:
            Label(
                isApproved ? "Pre-approved" : "Need approval",
                systemImage: isApproved ? "checkmark.shield.fill" : "shield.fill"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(
                isApproved ? PartyTheme.successTint : PartyTheme.accent
            )
            .accessibilityIdentifier(
                isApproved ? "approval-granted-label" : "approval-required-label"
            )
        }
    }

    private var cardBackground: Color {
        if isHighlighted || task.status == .awaitingApproval {
            PartyTheme.approvalBackground
        } else if case .failed = task.status {
            Color.red.opacity(0.1)
        } else if task.status == .completed {
            PartyTheme.successTint.opacity(0.1)
        } else if task.status == .declined {
            Color.primary.opacity(0.05)
        } else {
            PartyTheme.cardBackground
        }
    }

    private var borderColor: Color {
        if isHighlighted || task.status == .awaitingApproval {
            PartyTheme.accent.opacity(0.45)
        } else if case .failed = task.status {
            Color.red.opacity(0.35)
        } else if task.status == .completed {
            PartyTheme.successTint.opacity(0.35)
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
