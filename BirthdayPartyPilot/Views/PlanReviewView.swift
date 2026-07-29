import Foundation
import SwiftUI

struct PlanReviewView: View {
    let context: PartyContext
    let tasks: [PartyTask]
    let isApproved: (UUID) -> Bool
    let canExecutePlan: Bool
    let onApprove: (UUID) -> Void
    let onExecutePlan: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    PartySummaryHeader(
                        context: context,
                        phase: "Plan review",
                        detail: "\(tasks.count) tasks · \(approvalTaskCount) require approval"
                    )
                    .id("plan-review-top")
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

                Section {
                    ForEach(tasks) { task in
                        PartyTaskCard(
                            task: task,
                            isApproved: isApproved(task.id),
                            isHighlighted: task.approvalRequirement == .required,
                            onApprove: approvalAction(for: task)
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
                    }
                } header: {
                    PartySectionHeader(
                        title: "Six-task plan",
                        subtitle: "Approval-required tasks use the lavender treatment."
                    )
                }

                Section {
                    Button(action: onExecutePlan) {
                        Label("Start Plan Execution", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canExecutePlan)
                    .accessibilityLabel("Start Plan Execution")
                    .accessibilityHint(
                        "Runs informational tasks and pauses before tasks that need approval."
                    )
                    .accessibilityIdentifier("execute-plan-button")

                    Text("Approval-required tasks pause for a decision during execution.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .defaultScrollAnchor(.top)
            .scrollContentBackground(.hidden)
            .background(PartyTheme.pageBackground)
            .accessibilityIdentifier("plan-review-screen")
            .task {
                await Task.yield()
                proxy.scrollTo("plan-review-top", anchor: .top)
            }
        }
    }

    private var approvalTaskCount: Int {
        tasks.filter { $0.approvalRequirement == .required }.count
    }

    private func approvalAction(for task: PartyTask) -> (() -> Void)? {
        guard task.approvalRequirement == .required,
              !isApproved(task.id)
        else {
            return nil
        }

        return {
            onApprove(task.id)
        }
    }
}
