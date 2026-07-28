import SwiftUI

struct ExecutionView: View {
    let currentTask: PartyTask?
    let completedTasks: [PartyTask]
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
            Section("Current task") {
                if let currentTask {
                    Label {
                        Text(currentTask.title)
                            .accessibilityIdentifier("current-task-title")
                    } icon: {
                        Image(systemName: "hourglass")
                    }
                } else {
                    Text(isComplete ? "No tasks remaining" : "No task running")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Completed tasks (\(completedTasks.count))") {
                if completedTasks.isEmpty {
                    Text("No completed tasks yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(completedTasks) { task in
                        Label(task.title, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("Execution log") {
                if executionLog.isEmpty {
                    Text("No execution activity yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(executionLog.enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                    }
                }
            }

            if let failureMessage {
                Section("Failure") {
                    Label(failureMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            if isComplete {
                Section {
                    Label("Birthday plan completed", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("completion-message")
                }
            }

            Section {
                if canRetry {
                    Button("Retry Failed Task", action: onRetry)
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Retry failed task")
                        .accessibilityIdentifier("retry-failed-task-button")
                }

                if canApprove {
                    Button("Approve Current Task", action: onApprove)
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Approve current task")
                        .accessibilityIdentifier("approve-current-task-button")
                }

                if canDecline {
                    Button("Decline Current Task", role: .destructive, action: onDecline)
                        .accessibilityLabel("Decline current task")
                        .accessibilityIdentifier("decline-current-task-button")
                }

                Button("Restart Demo", action: onRestart)
                    .disabled(!canRestart)
                    .accessibilityLabel("Restart birthday party demo")
                    .accessibilityIdentifier("restart-demo-button")
            }
        }
        .accessibilityIdentifier("execution-screen")
    }
}
