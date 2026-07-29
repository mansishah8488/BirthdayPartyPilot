import Foundation

/// Pure presentation counts for the Plan Review progress card.
struct PlanReviewProgressStats: Equatable, Sendable {
    let informationalCount: Int
    let pendingApprovalCount: Int
    let approvedCount: Int
    let approvalRequiredCount: Int

    init(tasks: [PartyTask], isApproved: (UUID) -> Bool) {
        informationalCount = tasks.filter { $0.approvalRequirement == .none }.count
        approvalRequiredCount = tasks.filter { $0.approvalRequirement == .required }.count
        approvedCount = tasks.filter {
            $0.approvalRequirement == .required && isApproved($0.id)
        }.count
        pendingApprovalCount = tasks.filter {
            $0.approvalRequirement == .required && !isApproved($0.id)
        }.count
    }

    var allSideEffectsPreApproved: Bool {
        approvalRequiredCount > 0 && pendingApprovalCount == 0
    }
}
