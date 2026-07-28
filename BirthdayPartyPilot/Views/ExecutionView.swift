import SwiftUI

struct ExecutionView: View {
    let currentTask: PartyTask?
    let completedTasks: [PartyTask]
    let executionLog: [String]
    let failureMessage: String?
    let isComplete: Bool
    let canRestart: Bool
    let onRestart: () -> Void

    var body: some View {
        List {
            Section("Current task") {
                if let currentTask {
                    Label(currentTask.title, systemImage: "hourglass")
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
                Button("Restart Demo", action: onRestart)
                    .disabled(!canRestart)
                    .accessibilityLabel("Restart birthday party demo")
                    .accessibilityIdentifier("restart-demo-button")
            }
        }
        .accessibilityIdentifier("execution-screen")
    }
}
