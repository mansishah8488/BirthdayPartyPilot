import SwiftUI

struct ExecutionView: View {
    let context: PartyContext
    let tasks: [PartyTask]
    let currentTask: PartyTask?
    let executionLog: [String]
    let failureMessage: String?
    let isComplete: Bool
    let canRetry: Bool
    let canApprove: Bool
    let canDecline: Bool
    let canRestart: Bool
    let onRetry: () -> Void
    let onApprove: () -> Void
    let onDecline: () -> Void
    let onRestart: () -> Void

    var body: some View {
        List {
            Section {
                PartySummaryHeader(
                    context: context,
                    phase: phaseTitle,
                    detail: progressDescription
                )
                .listRowInsets(sectionInsets)
                .listRowBackground(Color.clear)
            }

            if !tasks.isEmpty {
                Section {
                    executionProgressSummary
                        .listRowInsets(sectionInsets)
                        .listRowBackground(Color.clear)
                } header: {
                    PartySectionHeader(
                        title: "Progress",
                        subtitle: progressSubtitle
                    )
                }
            }

            Section {
                if let currentTask {
                    PartyTaskCard(
                        task: currentTask,
                        isHighlighted: true,
                        titleAccessibilityIdentifier: "current-task-title",
                        statusBadgeStyle: .symbol,
                        showsApprovalText: false
                    )
                    .listRowInsets(cardInsets)
                    .listRowBackground(Color.clear)
                } else {
                    emptyStateCard(
                        text: isComplete ? "No tasks remaining" : "No task running"
                    )
                    .listRowInsets(cardInsets)
                    .listRowBackground(Color.clear)
                }
            } header: {
                PartySectionHeader(
                    title: "Current action",
                    subtitle: currentActionSubtitle
                )
            }

            if let failureMessage {
                Section {
                    failureCard(message: failureMessage)
                        .listRowInsets(cardInsets)
                        .listRowBackground(Color.clear)
                } header: {
                    PartySectionHeader(
                        title: "Needs attention",
                        subtitle: "Retry this task or restart the demo."
                    )
                }
            }

            Section {
                if remainingTasks.isEmpty {
                    emptyStateCard(text: "No other task status to show.")
                        .listRowInsets(cardInsets)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(remainingTasks) { task in
                        PartyTaskCard(
                            task: task,
                            isHighlighted: isAttentionTask(task),
                            statusBadgeStyle: .symbol,
                            showsApprovalText: false
                        )
                        .listRowInsets(cardInsets)
                        .listRowBackground(Color.clear)
                    }
                }
            } header: {
                PartySectionHeader(
                    title: "Plan status",
                    subtitle: "Completed, declined, and remaining tasks stay visible."
                )
            }

            Section {
                executionLogCard
                    .listRowInsets(cardInsets)
                    .listRowBackground(Color.clear)
            } header: {
                PartySectionHeader(
                    title: "Execution log",
                    subtitle: "A readable record of agent and tool activity."
                )
            }

            if isComplete {
                Section {
                    completionCard
                        .listRowInsets(cardInsets)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(PartyTheme.sectionSpacing)
        .defaultScrollAnchor(.top)
        .scrollContentBackground(.hidden)
        .background(PartyTheme.pageBackground)
        .accessibilityIdentifier("execution-screen")
        .safeAreaInset(edge: .bottom) {
            if showsActionBar {
                actionBar
            }
        }
    }

    private var executionProgressSummary: some View {
        VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(progressDescription)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: PartyTheme.compactSpacing)

                Text("\(resolvedTaskCount) of \(tasks.count) resolved")
                    .font(.subheadline)
                    .foregroundStyle(PartyTheme.secondaryText)
            }

            ProgressView(
                value: Double(resolvedTaskCount),
                total: Double(max(tasks.count, 1))
            )
            .tint(progressTint)
            .accessibilityLabel("Plan progress")
            .accessibilityValue(
                "\(resolvedTaskCount) of \(tasks.count) tasks resolved"
            )

            VStack(spacing: PartyTheme.compactSpacing) {
                PartyProgressStatPill(
                    value: completedTaskCount,
                    label: String(localized: "Completed"),
                    tint: PartyTheme.successTint,
                    systemImage: "checkmark.circle.fill"
                )
                PartyProgressStatPill(
                    value: remainingActiveCount,
                    label: String(localized: "In progress"),
                    tint: PartyTheme.accent,
                    systemImage: "clock.fill"
                )
                PartyProgressStatPill(
                    value: failedCount,
                    label: String(localized: "Failed"),
                    tint: .red,
                    systemImage: "exclamationmark.triangle.fill"
                )
                PartyProgressStatPill(
                    value: declinedCount,
                    label: String(localized: "Declined"),
                    tint: PartyTheme.secondaryText,
                    systemImage: "minus.circle.fill"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PartyTheme.standardSpacing)
        .background(PartyTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("execution-progress-summary")
    }

    private var executionLogCard: some View {
        Group {
            if executionLog.isEmpty {
                Text("No execution activity yet.")
                    .font(.subheadline)
                    .foregroundStyle(PartyTheme.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                    ForEach(
                        Array(executionLog.enumerated()),
                        id: \.offset
                    ) { index, entry in
                        HStack(alignment: .firstTextBaseline, spacing: PartyTheme.compactSpacing) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(PartyTheme.accent)
                                .frame(width: 18, alignment: .trailing)
                                .accessibilityHidden(true)

                            Text(entry)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                                .lineLimit(nil)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Activity \(index + 1): \(entry)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PartyTheme.standardSpacing)
        .background(PartyTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
    }

    private func failureCard(message: String) -> some View {
        Label {
            Text(message)
                .font(.body.weight(.medium))
                .lineLimit(nil)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PartyTheme.standardSpacing)
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.18), Color.red.opacity(0.06)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius)
                .strokeBorder(Color.red.opacity(0.35), lineWidth: 1.5)
        }
        .accessibilityLabel("Failure: \(message)")
        .accessibilityIdentifier("execution-failure-message")
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
            Label(
                "Birthday plan completed",
                systemImage: "checkmark.seal.fill"
            )
            .font(.headline)
            .foregroundStyle(PartyTheme.successTint)

            Text("All tasks were completed or safely declined.")
                .font(.subheadline)
                .foregroundStyle(PartyTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PartyTheme.standardSpacing)
        .background(
            LinearGradient(
                colors: [
                    PartyTheme.successTint.opacity(0.2),
                    PartyTheme.successTint.opacity(0.08),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
        .accessibilityIdentifier("completion-message")
    }

    private func emptyStateCard(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(PartyTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PartyTheme.standardSpacing)
            .background(PartyTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
    }

    private var actionBar: some View {
        VStack(spacing: PartyTheme.compactSpacing) {
            if canRetry {
                Button(action: onRetry) {
                    Text("Retry Failed Task")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PartyTheme.compactSpacing)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Retry failed task")
                .accessibilityHint("Retries only the failed task.")
                .accessibilityIdentifier("retry-failed-task-button")
            }

            if let currentTask, canApprove || canDecline {
                ApprovalActionBar(
                    taskTitle: currentTask.title,
                    canApprove: canApprove,
                    canDecline: canDecline,
                    onApprove: onApprove,
                    onDecline: onDecline
                )
            }

            if canRestart {
                restartButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PartyTheme.standardSpacing)
        .padding(.vertical, PartyTheme.compactSpacing)
        .background(.bar)
    }

    @ViewBuilder
    private var restartButton: some View {
        if isComplete {
            Button(action: onRestart) {
                Text("Restart Demo")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PartyTheme.compactSpacing)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Restart birthday party demo")
            .accessibilityIdentifier("restart-demo-button")
        } else {
            Button(action: onRestart) {
                Text("Restart Demo")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PartyTheme.compactSpacing)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityLabel("Restart birthday party demo")
            .accessibilityIdentifier("restart-demo-button")
        }
    }

    private var sectionInsets: EdgeInsets {
        EdgeInsets(
            top: PartyTheme.compactSpacing / 2,
            leading: PartyTheme.standardSpacing,
            bottom: PartyTheme.compactSpacing / 2,
            trailing: PartyTheme.standardSpacing
        )
    }

    private var cardInsets: EdgeInsets {
        EdgeInsets(
            top: PartyTheme.compactSpacing / 2,
            leading: PartyTheme.standardSpacing,
            bottom: PartyTheme.compactSpacing / 2,
            trailing: PartyTheme.standardSpacing
        )
    }

    private var remainingTasks: [PartyTask] {
        tasks.filter { $0.id != currentTask?.id }
    }

    private var resolvedTaskCount: Int {
        tasks.filter {
            switch $0.status {
            case .completed, .declined, .cancelled:
                true
            case .pending, .awaitingApproval, .running, .failed:
                false
            }
        }.count
    }

    private var completedTaskCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    private var remainingActiveCount: Int {
        tasks.filter {
            switch $0.status {
            case .pending, .awaitingApproval, .running:
                true
            default:
                false
            }
        }.count
    }

    private var failedCount: Int {
        tasks.filter {
            if case .failed = $0.status { return true }
            return false
        }.count
    }

    private var declinedCount: Int {
        tasks.filter { $0.status == .declined }.count
    }

    private var progressTint: Color {
        if failureMessage != nil {
            return .red
        }
        if isComplete {
            return PartyTheme.successTint
        }
        if canApprove || canDecline {
            return PartyTheme.accent
        }
        return PartyTheme.accent
    }

    private var progressSubtitle: String? {
        if isComplete {
            return "All tasks finished safely."
        }
        if failureMessage != nil {
            return "Resolve the failure to continue."
        }
        if canApprove || canDecline {
            return "Approve or decline to continue the plan."
        }
        return "The plan pauses safely at approval boundaries."
    }

    private var currentActionSubtitle: String? {
        if let currentTaskPositionDescription {
            return currentTaskPositionDescription
        }
        if isComplete {
            return "Nothing left to run."
        }
        return nil
    }

    private var currentTaskPositionDescription: String? {
        guard let currentTask,
              let index = tasks.firstIndex(where: { $0.id == currentTask.id })
        else {
            return nil
        }

        return "Task \(index + 1) of \(tasks.count)"
    }

    private var progressDescription: String {
        if isComplete {
            return "Plan complete"
        }

        if failureMessage != nil {
            return "Needs attention"
        }

        if canApprove || canDecline {
            return "Awaiting approval"
        }

        if let currentTaskPositionDescription {
            return currentTaskPositionDescription
        }

        return tasks.isEmpty ? "No plan available" : "Plan paused"
    }

    private var phaseTitle: String {
        if isComplete {
            return "Completed"
        }

        if failureMessage != nil {
            return "Needs attention"
        }

        if canApprove || canDecline {
            return "Awaiting approval"
        }

        if currentTask?.status == .running {
            return "Executing"
        }

        return "Execution"
    }

    private var showsActionBar: Bool {
        canRetry || canApprove || canDecline || canRestart
    }

    private func isAttentionTask(_ task: PartyTask) -> Bool {
        switch task.status {
        case .awaitingApproval, .failed:
            true
        case .pending, .running, .completed, .declined, .cancelled:
            false
        }
    }
}
