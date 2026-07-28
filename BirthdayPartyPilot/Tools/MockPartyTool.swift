struct MockPartyTool: PartyTool {
    let name = "Mock Party Tool"

    func execute(task: PartyTask) async throws -> String {
        "Completed \(task.title)"
    }
}
