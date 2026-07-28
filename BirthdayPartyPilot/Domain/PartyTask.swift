import Foundation

enum PartyTaskCategory: Equatable, Sendable {
    case guests
    case cake
    case food
    case favors
    case gifts
    case venue
    case schedule
}

enum ApprovalRequirement: Equatable, Sendable {
    case none
    case required
}

enum PartyTaskStatus: Equatable, Sendable {
    case pending
    case awaitingApproval
    case running
    case completed
    case failed(String)
    case declined
    case cancelled
}

struct PartyTask: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let category: PartyTaskCategory
    let approvalRequirement: ApprovalRequirement
    var status: PartyTaskStatus

    init(
        id: UUID = UUID(),
        title: String,
        category: PartyTaskCategory,
        approvalRequirement: ApprovalRequirement,
        status: PartyTaskStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.approvalRequirement = approvalRequirement
        self.status = status
    }
}
