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
                        detail: planOverviewDetail
                    )
                    .id("plan-review-top")
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

                Section {
                    planProgressSummary
                        .listRowInsets(
                            EdgeInsets(
                                top: PartyTheme.compactSpacing / 2,
                                leading: PartyTheme.standardSpacing,
                                bottom: PartyTheme.compactSpacing / 2,
                                trailing: PartyTheme.standardSpacing
                            )
                        )
                        .listRowBackground(Color.clear)
                } header: {
                    PartySectionHeader(
                        title: "Progress",
                        subtitle: progressSubtitle
                    )
                }

                Section {
                    ForEach(tasks) { task in
                        PartyTaskCard(
                            task: task,
                            isApproved: isApproved(task.id),
                            isHighlighted: task.approvalRequirement == .required
                                && !isApproved(task.id),
                            onApprove: approvalAction(for: task),
                            statusBadgeStyle: .symbol,
                            showsApprovalText: false
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
                        title: "\(tasks.count)-task plan",
                        subtitle: "Listed in execution order."
                    )
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(PartyTheme.sectionSpacing)
            .defaultScrollAnchor(.top)
            .scrollContentBackground(.hidden)
            .background(PartyTheme.pageBackground)
            .accessibilityIdentifier("plan-review-screen")
            .safeAreaInset(edge: .bottom) {
                executeActionBar
            }
            .task {
                await Task.yield()
                proxy.scrollTo("plan-review-top", anchor: .top)
            }
        }
    }

    private var planProgressSummary: some View {
        VStack(alignment: .leading, spacing: PartyTheme.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(tasks.count) tasks planned")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: PartyTheme.compactSpacing)

                Text("\(progressStats.approvedCount) of \(progressStats.approvalRequiredCount) pre-approved")
                    .font(.subheadline)
                    .foregroundStyle(PartyTheme.secondaryText)
                    .accessibilityLabel(
                        "\(progressStats.approvedCount) of \(progressStats.approvalRequiredCount) pre-approvals granted"
                    )
            }

            ProgressView(
                value: Double(progressStats.approvedCount),
                total: Double(max(progressStats.approvalRequiredCount, 1))
            )
            .tint(PartyTheme.accent)
            .accessibilityLabel("Approval progress")
            .accessibilityValue(
                "\(progressStats.approvedCount) of \(progressStats.approvalRequiredCount) pre-approvals granted"
            )

            VStack(spacing: PartyTheme.compactSpacing) {
                PartyProgressStatPill(
                    value: progressStats.informationalCount,
                    label: String(localized: "Informational"),
                    tint: PartyTheme.informationalTint,
                    systemImage: "info.circle.fill"
                )
                PartyProgressStatPill(
                    value: progressStats.pendingApprovalCount,
                    label: String(localized: "Need approval"),
                    tint: PartyTheme.accent,
                    systemImage: "shield.fill"
                )
                PartyProgressStatPill(
                    value: progressStats.approvedCount,
                    label: String(localized: "Pre-approved"),
                    tint: PartyTheme.successTint,
                    systemImage: "checkmark.shield.fill"
                )
            }

            Text(
                progressStats.allSideEffectsPreApproved
                    ? "All side-effect tasks are pre-approved."
                    : "Pre-approve now, or decide when execution pauses."
            )
            .font(.footnote)
            .foregroundStyle(
                progressStats.allSideEffectsPreApproved
                    ? PartyTheme.successTint
                    : PartyTheme.secondaryText
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PartyTheme.standardSpacing)
        .background(PartyTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: PartyTheme.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("plan-progress-summary")
    }

    private var executeActionBar: some View {
        VStack(spacing: PartyTheme.compactSpacing) {
            Button(action: onExecutePlan) {
                Text("Start Plan Execution")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PartyTheme.compactSpacing)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canExecutePlan)
            .accessibilityLabel("Start Plan Execution")
            .accessibilityHint(
                "Runs informational tasks and pauses before tasks that need approval."
            )
            .accessibilityIdentifier("execute-plan-button")

            Text(
                "Informational tasks run automatically. Side-effect tasks still pause for approval."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PartyTheme.standardSpacing)
        .padding(.vertical, PartyTheme.compactSpacing)
        .background(.bar)
    }

    private var progressStats: PlanReviewProgressStats {
        PlanReviewProgressStats(tasks: tasks, isApproved: isApproved)
    }

    private var planOverviewDetail: String {
        "\(tasks.count) tasks · \(progressStats.approvalRequiredCount) require approval"
    }

    private var progressSubtitle: String? {
        if progressStats.approvalRequiredCount == 0 {
            return "No side-effect approvals are required."
        }

        if progressStats.allSideEffectsPreApproved {
            return "All side-effect tasks are pre-approved."
        }

        return "Pre-approvals are optional before starting."
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
