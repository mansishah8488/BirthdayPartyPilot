struct DeterministicBirthdayPlanner: BirthdayPlanning {
    func createPlan(for context: PartyContext) async throws -> [PartyTask] {
        [
            PartyTask(
                title: "Calculate cake servings",
                category: .cake,
                approvalRequirement: .none
            ),
            PartyTask(
                title: "Create food quantity checklist",
                category: .food,
                approvalRequirement: .none
            ),
            PartyTask(
                title: "Prepare party-favor shopping list",
                category: .favors,
                approvalRequirement: .none
            ),
            PartyTask(
                title: "Draft RSVP reminder",
                category: .guests,
                approvalRequirement: .required
            ),
            PartyTask(
                title: "Prepare cake pickup reminder",
                category: .schedule,
                approvalRequirement: .required
            ),
        ]
    }
}
