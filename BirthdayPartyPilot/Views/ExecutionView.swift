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

            if !tasks.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                        HStack {
                            Text(progressDescription)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Text("\(resolvedTaskCount) of \(tasks.count) resolved")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(
                            value: Double(resolvedTaskCount),
                            total: Double(tasks.count)
                        )
                        .tint(PartyTheme.accent)
                        .accessibilityLabel("Plan progress")
                        .accessibilityValue(
                            "\(resolvedTaskCount) of \(tasks.count) tasks resolved"
                        )
                    }
                } header: {
                    PartySectionHeader(
                        title: "Progress",
                        subtitle: "The plan pauses safely at approval boundaries."
                    )
                }
            }

            Section {
                if let currentTask {
                    PartyTaskCard(
                        task: currentTask,
                        isHighlighted: true,
                        titleAccessibilityIdentifier: "current-task-title"
                    )
                    .listRowInsets(
                        EdgeInsets(
                            top: PartyTheme.compactSpacing / 2,
                            leading: PartyTheme.standardSpacing,
                            bottom: PartyTheme.compactSpacing / 2,
                            trailing: PartyTheme.standardSpacing
                        )
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Text(isComplete ? "No tasks remaining" : "No task running")
                        .foregroundStyle(.secondary)
                }
            } header: {
                PartySectionHeader(
                    title: "Current task",
                    subtitle: currentTaskPositionDescription
                )
            }

            Section {
                if remainingTasks.isEmpty {
                    Text("No other task status to show.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(remainingTasks) { task in
                        PartyTaskCard(task: task)
                            .listRowInsets(
                                EdgeInsets(
                                    top: PartyTheme.compactSpacing / 2,
                                    leading: PartyTheme.standardSpacing,
                                    bottom: PartyTheme.compactSpacing / 2,
                                    trailing: PartyTheme.standardSpacing
                                )
                            )
                            .listRowBackground(Color.clear)
                    }
                }
            } header: {
                PartySectionHeader(
                    title: "Plan status",
                    subtitle: "Every task keeps its explicit workflow state."
                )
            }

            Section {
                if executionLog.isEmpty {
                    Text("No execution activity yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(
                        Array(executionLog.enumerated()),
                        id: \.offset
                    ) { index, entry in
                        HStack(alignment: .firstTextBaseline, spacing: PartyTheme.compactSpacing) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)

                            Text(entry)
                                .font(.footnote.monospaced())
                                .lineLimit(nil)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Activity \(index + 1): \(entry)")
                    }
                }
            } header: {
                PartySectionHeader(
                    title: "Execution log",
                    subtitle: "A readable record of agent and tool activity."
                )
            }

            if let failureMessage {
                Section {
                    Label {
                        Text(failureMessage)
                            .lineLimit(nil)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .font(.body.weight(.medium))
                        .foregroundStyle(.red)
                        .accessibilityLabel("Failure: \(failureMessage)")
                } header: {
                    PartySectionHeader(
                        title: "Needs attention",
                        subtitle: "Retry this task or restart the demo."
                    )
                }
            }

            if isComplete {
                Section {
                    VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
                        Label(
                            "Birthday plan completed",
                            systemImage: "checkmark.seal.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.green)

                        Text("All tasks were completed or safely declined.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                        .accessibilityIdentifier("completion-message")
                }
            }
        }
        .listStyle(.insetGrouped)
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

        return "Execution"
    }

    private var showsActionBar: Bool {
        canRetry || canApprove || canDecline || canRestart
    }

    private var actionBar: some View {
        VStack(spacing: PartyTheme.compactSpacing) {
            if canRetry {
                Button(action: onRetry) {
                    Label("Retry Failed Task", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Retry failed task")
                .accessibilityHint("Retries only the failed task.")
                .accessibilityIdentifier("retry-failed-task-button")
            }

            if let currentTask {
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
                Label("Restart Demo", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Restart birthday party demo")
            .accessibilityIdentifier("restart-demo-button")
        } else {
            Button("Restart Demo", action: onRestart)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel("Restart birthday party demo")
                .accessibilityIdentifier("restart-demo-button")
        }
    }
}
