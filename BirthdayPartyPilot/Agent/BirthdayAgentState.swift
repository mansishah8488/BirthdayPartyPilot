import Foundation

enum BirthdayAgentState: Equatable {
    case idle
    case planning
    case reviewing
    case awaitingApproval(UUID)
    case executing(UUID)
    case completed
    case failed(String)
}
