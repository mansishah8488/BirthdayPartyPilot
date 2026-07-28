import Foundation
import XCTest
@testable import BirthdayPartyPilot

@MainActor
final class BirthdayAgentPlanningTests: XCTestCase {
    func testSuccessfulPlanningStoresTasksAndTransitionsToReviewing() async {
        let expectedTasks = [
            PartyTask(
                title: "Test task",
                category: .cake,
                approvalRequirement: .none
            ),
        ]
        let planner = StubBirthdayPlanner(result: .success(expectedTasks))
        let agent = BirthdayAgent(
            context: testContext,
            planner: planner,
            tool: MockPartyTool()
        )
        var stateObservedByPlanner: BirthdayAgentState?
        planner.onCreatePlan = {
            stateObservedByPlanner = agent.state
        }

        XCTAssertEqual(agent.state, .idle)
        XCTAssertTrue(agent.tasks.isEmpty)

        await agent.start()

        XCTAssertEqual(stateObservedByPlanner, .planning)
        XCTAssertEqual(agent.tasks, expectedTasks)
        XCTAssertEqual(agent.state, .reviewing)
    }

    func testPlannerFailureKeepsTasksEmptyAndTransitionsToFailed() async {
        let planner = StubBirthdayPlanner(
            result: .failure(PlanningTestError.unavailable)
        )
        let agent = BirthdayAgent(
            context: testContext,
            planner: planner,
            tool: MockPartyTool()
        )
        var stateObservedByPlanner: BirthdayAgentState?
        planner.onCreatePlan = {
            stateObservedByPlanner = agent.state
        }

        await agent.start()

        XCTAssertEqual(stateObservedByPlanner, .planning)
        XCTAssertTrue(agent.tasks.isEmpty)
        XCTAssertEqual(agent.state, .failed("Planner unavailable."))
    }

    private var testContext: PartyContext {
        PartyContext(
            childName: "Viyana",
            age: 7,
            partyDate: Date(timeIntervalSince1970: 0),
            theme: "Rainbows",
            adultCount: 8,
            childCount: 12
        )
    }
}

@MainActor
private final class StubBirthdayPlanner: BirthdayPlanning {
    let result: Result<[PartyTask], Error>
    var onCreatePlan: (() -> Void)?

    init(result: Result<[PartyTask], Error>) {
        self.result = result
    }

    func createPlan(for context: PartyContext) async throws -> [PartyTask] {
        onCreatePlan?()
        return try result.get()
    }
}

private enum PlanningTestError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Planner unavailable."
    }
}
