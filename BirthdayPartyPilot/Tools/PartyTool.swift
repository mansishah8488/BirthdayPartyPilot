protocol PartyTool {
    var name: String { get }
    func execute(task: PartyTask) async throws -> String
}
