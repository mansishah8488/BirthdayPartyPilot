protocol BirthdayPlanning {
    func createPlan(for context: PartyContext) async throws -> [PartyTask]
}
