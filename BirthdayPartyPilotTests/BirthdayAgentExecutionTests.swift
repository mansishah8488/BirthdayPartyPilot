import Foundation
import XCTest
@testable import BirthdayPartyPilot

@MainActor
final class BirthdayAgentExecutionTests: XCTestCase {
    func testExecutePlanRunsAutomaticTasksSequentiallyAndPausesForApproval() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)

        await agent.executePlan()
        XCTAssertEqual(agent.state, .idle)
        XCTAssertTrue(tool.executedTaskIDs.isEmpty)

        await agent.start()
        await agent.executePlan()

        XCTAssertEqual(tool.executedTaskIDs, Array(agent.tasks.prefix(3).map(\.id)))
        XCTAssertEqual(
            agent.tasks.map(\.status),
            [.completed, .completed, .completed, .awaitingApproval, .pending]
        )
        XCTAssertEqual(agent.state, .awaitingApproval(agent.tasks[3].id))
        XCTAssertTrue(
            agent.executionLog.contains("Awaiting approval for \(agent.tasks[3].title).")
        )
    }

    func testWrongApprovalDoesNotResumeExecution() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()
        await agent.executePlan()

        let awaitingTaskID = agent.tasks[3].id
        await agent.approve(taskID: agent.tasks[4].id)

        XCTAssertEqual(agent.state, .awaitingApproval(awaitingTaskID))
        XCTAssertEqual(tool.executedTaskIDs, Array(agent.tasks.prefix(3).map(\.id)))
        XCTAssertEqual(agent.tasks[3].status, .awaitingApproval)
        XCTAssertEqual(agent.tasks[4].status, .pending)
    }

    func testApprovingCurrentTaskResumesAndPausesAtNextApproval() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()
        await agent.executePlan()

        await agent.approve(taskID: agent.tasks[3].id)

        XCTAssertEqual(tool.executedTaskIDs, Array(agent.tasks.prefix(4).map(\.id)))
        XCTAssertEqual(agent.tasks[3].status, .completed)
        XCTAssertEqual(agent.tasks[4].status, .awaitingApproval)
        XCTAssertEqual(agent.state, .awaitingApproval(agent.tasks[4].id))
    }

    func testApprovingAllRequiredTasksCompletesPlan() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()
        await agent.executePlan()

        await agent.approve(taskID: agent.tasks[3].id)
        await agent.approve(taskID: agent.tasks[4].id)

        XCTAssertEqual(tool.executedTaskIDs, agent.tasks.map(\.id))
        XCTAssertTrue(agent.tasks.allSatisfy { $0.status == .completed })
        XCTAssertEqual(agent.state, .completed)
        XCTAssertTrue(agent.executionLog.contains("Approved \(agent.tasks[3].title)."))
        XCTAssertTrue(agent.executionLog.contains("Approved \(agent.tasks[4].title)."))
        XCTAssertEqual(agent.executionLog.last, "Plan completed.")
    }

    func testToolFailureStopsExecutionAndUsesExistingFailedState() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()
        tool.failingTaskID = agent.tasks[0].id

        await agent.executePlan()

        XCTAssertEqual(tool.executedTaskIDs, [agent.tasks[0].id])
        XCTAssertEqual(agent.tasks[0].status, .failed("Recording tool failed."))
        XCTAssertTrue(agent.tasks.dropFirst().allSatisfy { $0.status == .pending })
        XCTAssertEqual(agent.state, .failed("Recording tool failed."))
        XCTAssertEqual(
            agent.executionLog.last,
            "Failed \(agent.tasks[0].title): Recording tool failed."
        )
    }

    func testReviewApprovalsEnableExecution() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()

        XCTAssertFalse(agent.canExecutePlan)
        await agent.approve(taskID: agent.tasks[3].id)
        await agent.approve(taskID: agent.tasks[4].id)

        XCTAssertTrue(agent.isApproved(taskID: agent.tasks[3].id))
        XCTAssertTrue(agent.isApproved(taskID: agent.tasks[4].id))
        XCTAssertTrue(agent.canExecutePlan)

        await agent.executePlan()

        XCTAssertEqual(tool.executedTaskIDs, agent.tasks.map(\.id))
        XCTAssertEqual(agent.state, .completed)
    }

    func testRestartClearsDemoState() async {
        let agent = makeAgent(tool: RecordingPartyTool())
        await agent.start()
        await agent.approve(taskID: agent.tasks[3].id)

        agent.restart()

        XCTAssertEqual(agent.state, .idle)
        XCTAssertTrue(agent.tasks.isEmpty)
        XCTAssertTrue(agent.executionLog.isEmpty)
    }

    private func makeAgent(tool: RecordingPartyTool) -> BirthdayAgent {
        BirthdayAgent(
            context: PartyContext(
                childName: "Viyana",
                age: 7,
                partyDate: Date(timeIntervalSince1970: 0),
                theme: "Rainbows",
                adultCount: 8,
                childCount: 12,
                venue: "Test Venue"
            ),
            planner: DeterministicBirthdayPlanner(),
            tool: tool
        )
    }
}

@MainActor
private final class RecordingPartyTool: PartyTool {
    let name = "Recording Party Tool"
    private(set) var executedTaskIDs: [UUID] = []
    var failingTaskID: UUID?

    func execute(task: PartyTask) async throws -> String {
        executedTaskIDs.append(task.id)

        if task.id == failingTaskID {
            throw RecordingPartyToolError.failed
        }

        return "Recorded \(task.title)"
    }
}

private enum RecordingPartyToolError: LocalizedError {
    case failed

    var errorDescription: String? {
        "Recording tool failed."
    }
}
