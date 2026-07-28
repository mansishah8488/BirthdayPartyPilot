import Foundation

final class MockPartyTool: PartyTool {
    let name = "Mock Party Tool"

    private(set) var executedTaskIDs: [UUID] = []
    private var attemptCountsByTaskID: [UUID: Int] = [:]

    func execute(task: PartyTask) async throws -> String {
        executedTaskIDs.append(task.id)
        attemptCountsByTaskID[task.id, default: 0] += 1

        if task.title == "Prepare party-favor shopping list",
           attemptCountsByTaskID[task.id] == 1 {
            throw MockPartyToolError.firstFavorAttemptFailed
        }

        return "Completed \(task.title)"
    }
}

private enum MockPartyToolError: LocalizedError {
    case firstFavorAttemptFailed

    var errorDescription: String? {
        "Preparing the party-favor shopping list failed on its first attempt."
    }
}
