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
            [.completed, .completed, .completed, .awaitingApproval, .pending, .pending]
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
        XCTAssertEqual(agent.tasks[5].status, .pending)
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
        await agent.approve(taskID: agent.tasks[5].id)

        XCTAssertEqual(tool.executedTaskIDs, agent.tasks.map(\.id))
        XCTAssertTrue(agent.tasks.allSatisfy { $0.status == .completed })
        XCTAssertEqual(agent.state, .completed)
        XCTAssertTrue(agent.executionLog.contains("Approved \(agent.tasks[3].title)."))
        XCTAssertTrue(agent.executionLog.contains("Approved \(agent.tasks[4].title)."))
        XCTAssertTrue(agent.executionLog.contains("Approved \(agent.tasks[5].title)."))
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

    func testReviewApprovalsAreOptionalBeforeExecution() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()

        XCTAssertTrue(agent.canExecutePlan)
        await agent.approve(taskID: agent.tasks[3].id)
        await agent.approve(taskID: agent.tasks[4].id)
        await agent.approve(taskID: agent.tasks[5].id)

        XCTAssertTrue(agent.isApproved(taskID: agent.tasks[3].id))
        XCTAssertTrue(agent.isApproved(taskID: agent.tasks[4].id))
        XCTAssertTrue(agent.isApproved(taskID: agent.tasks[5].id))
        XCTAssertTrue(agent.canExecutePlan)

        await agent.executePlan()

        XCTAssertEqual(tool.executedTaskIDs, agent.tasks.map(\.id))
        XCTAssertEqual(agent.state, .completed)
    }

    func testRestartAfterFailureClearsRunStateAndFreshPlanFailsFavorAgain() async {
        let planner = RecordingBirthdayPlanner()
        let tool = MockPartyTool()
        let agent = makeAgent(planner: planner, tool: tool)
        let originalContext = agent.context
        await agent.start()
        let originalTaskIDs = agent.tasks.map(\.id)
        await agent.approve(taskID: agent.tasks[3].id)
        await agent.approve(taskID: agent.tasks[4].id)
        await agent.approve(taskID: agent.tasks[5].id)
        await agent.executePlan()

        XCTAssertEqual(planner.createPlanCallCount, 1)
        XCTAssertTrue(agent.canRestart)
        XCTAssertNotNil(agent.failureMessage)

        agent.restart()

        XCTAssertEqual(agent.state, .idle)
        XCTAssertTrue(agent.tasks.isEmpty)
        XCTAssertTrue(agent.executionLog.isEmpty)
        XCTAssertNil(agent.currentTask)
        XCTAssertNil(agent.pendingApprovalTask)
        XCTAssertNil(agent.failureMessage)
        XCTAssertTrue(agent.canStart)
        XCTAssertFalse(agent.canRestart)
        XCTAssertEqual(agent.context, originalContext)
        XCTAssertTrue(originalTaskIDs.allSatisfy { !agent.isApproved(taskID: $0) })
        XCTAssertEqual(planner.createPlanCallCount, 1)

        await agent.start()

        let newTaskIDs = agent.tasks.map(\.id)
        XCTAssertEqual(planner.createPlanCallCount, 2)
        XCTAssertEqual(newTaskIDs.count, 6)
        XCTAssertTrue(Set(originalTaskIDs).isDisjoint(with: Set(newTaskIDs)))
        XCTAssertEqual(agent.state, .reviewing)

        await agent.executePlan()

        XCTAssertEqual(
            agent.tasks[2].status,
            .failed("Preparing the party-favor shopping list failed on its first attempt.")
        )
        XCTAssertEqual(
            Array(tool.executedTaskIDs.suffix(3)),
            Array(newTaskIDs.prefix(3))
        )
    }

    func testRestartAfterCompletionClearsRunStateAndPreservesContext() async {
        let tool = RecordingPartyTool()
        let agent = makeAgent(tool: tool)
        let originalContext = agent.context
        await agent.start()
        let originalTaskIDs = agent.tasks.map(\.id)
        await agent.approve(taskID: agent.tasks[3].id)
        await agent.approve(taskID: agent.tasks[4].id)
        await agent.approve(taskID: agent.tasks[5].id)
        await agent.executePlan()

        XCTAssertEqual(agent.state, .completed)
        XCTAssertTrue(agent.canRestart)

        agent.restart()

        XCTAssertEqual(agent.state, .idle)
        XCTAssertTrue(agent.tasks.isEmpty)
        XCTAssertTrue(agent.executionLog.isEmpty)
        XCTAssertNil(agent.currentTask)
        XCTAssertNil(agent.pendingApprovalTask)
        XCTAssertNil(agent.failureMessage)
        XCTAssertTrue(agent.canStart)
        XCTAssertFalse(agent.canRestart)
        XCTAssertEqual(agent.context, originalContext)
        XCTAssertTrue(originalTaskIDs.allSatisfy { !agent.isApproved(taskID: $0) })
    }

    func testRestartOutsideTerminalStatesDoesNothing() async {
        let idleAgent = makeAgent(tool: RecordingPartyTool())
        idleAgent.restart()
        XCTAssertEqual(idleAgent.state, .idle)
        XCTAssertTrue(idleAgent.tasks.isEmpty)

        let reviewingAgent = makeAgent(tool: RecordingPartyTool())
        await reviewingAgent.start()
        await reviewingAgent.approve(taskID: reviewingAgent.tasks[3].id)
        let reviewingTasks = reviewingAgent.tasks
        let reviewingLog = reviewingAgent.executionLog

        reviewingAgent.restart()

        XCTAssertEqual(reviewingAgent.state, .reviewing)
        XCTAssertEqual(reviewingAgent.tasks, reviewingTasks)
        XCTAssertEqual(reviewingAgent.executionLog, reviewingLog)
        XCTAssertTrue(reviewingAgent.isApproved(taskID: reviewingAgent.tasks[3].id))

        let awaitingAgent = makeAgent(tool: RecordingPartyTool())
        await awaitingAgent.start()
        await awaitingAgent.executePlan()
        let awaitingState = awaitingAgent.state
        let awaitingTasks = awaitingAgent.tasks
        let awaitingLog = awaitingAgent.executionLog

        awaitingAgent.restart()

        XCTAssertEqual(awaitingAgent.state, awaitingState)
        XCTAssertEqual(awaitingAgent.tasks, awaitingTasks)
        XCTAssertEqual(awaitingAgent.executionLog, awaitingLog)
        XCTAssertNotNil(awaitingAgent.pendingApprovalTask)
    }

    func testRestartWhilePlanningDoesNothing() async throws {
        let plannedTasks = try await DeterministicBirthdayPlanner().createPlan(
            for: testContext
        )
        let planner = SuspendingBirthdayPlanner()
        let agent = makeAgent(planner: planner, tool: RecordingPartyTool())
        let planningStarted = expectation(description: "Planning started")
        planner.onCreatePlan = {
            planningStarted.fulfill()
        }
        let startTask = Task {
            await agent.start()
        }
        await fulfillment(of: [planningStarted], timeout: 2)

        agent.restart()

        XCTAssertEqual(agent.state, .planning)
        XCTAssertTrue(agent.tasks.isEmpty)
        XCTAssertFalse(agent.canRestart)

        planner.complete(with: plannedTasks)
        await startTask.value
        XCTAssertEqual(agent.state, .reviewing)
    }

    func testRestartWhileExecutingDoesNothing() async {
        let tool = SuspendingFirstPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()
        let executionStarted = expectation(description: "Execution started")
        tool.onFirstExecution = {
            executionStarted.fulfill()
        }
        let executionTask = Task {
            await agent.executePlan()
        }
        await fulfillment(of: [executionStarted], timeout: 2)
        let executingState = agent.state
        let executingTasks = agent.tasks
        let executingLog = agent.executionLog

        agent.restart()

        XCTAssertEqual(agent.state, executingState)
        XCTAssertEqual(agent.tasks, executingTasks)
        XCTAssertEqual(agent.executionLog, executingLog)
        XCTAssertFalse(agent.canRestart)

        tool.completeFirstExecution()
        await executionTask.value
        XCTAssertEqual(agent.state, .awaitingApproval(agent.tasks[3].id))
    }

    func testMockPartyToolFailsFavorTaskOnlyOnFirstAttemptForSameID() async throws {
        let tool = MockPartyTool()
        let favorTask = PartyTask(
            title: "Prepare party-favor shopping list",
            category: .favors,
            approvalRequirement: .none
        )

        do {
            _ = try await tool.execute(task: favorTask)
            XCTFail("Expected the first favor attempt to fail")
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                "Preparing the party-favor shopping list failed on its first attempt."
            )
        }

        let result = try await tool.execute(task: favorTask)

        XCTAssertEqual(result, "Completed Prepare party-favor shopping list")
        XCTAssertEqual(tool.executedTaskIDs, [favorTask.id, favorTask.id])
    }

    func testFavorFailureStopsSequentialAgentExecution() async {
        let tool = MockPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()

        await agent.executePlan()

        XCTAssertEqual(tool.executedTaskIDs, Array(agent.tasks.prefix(3).map(\.id)))
        XCTAssertEqual(
            agent.tasks.prefix(3).map(\.category),
            [.cake, .food, .favors]
        )
        XCTAssertEqual(agent.tasks[0].status, .completed)
        XCTAssertEqual(agent.tasks[1].status, .completed)
        XCTAssertEqual(
            agent.tasks[2].status,
            .failed("Preparing the party-favor shopping list failed on its first attempt.")
        )
        XCTAssertEqual(agent.tasks[3].status, .pending)
        XCTAssertEqual(agent.tasks[4].status, .pending)
        XCTAssertEqual(agent.tasks[5].status, .pending)
        XCTAssertEqual(
            agent.state,
            .failed("Preparing the party-favor shopping list failed on its first attempt.")
        )
    }

    func testRetryFailedFavorTaskOnlyAndContinuesToVenueApproval() async {
        let planner = RecordingBirthdayPlanner()
        let tool = MockPartyTool()
        let agent = makeAgent(planner: planner, tool: tool)
        await agent.start()
        let originalTaskIDs = agent.tasks.map(\.id)

        await agent.executePlan()

        let favorTask = agent.tasks[2]
        XCTAssertEqual(planner.createPlanCallCount, 1)
        XCTAssertEqual(tool.executedTaskIDs, Array(originalTaskIDs.prefix(3)))
        XCTAssertEqual(
            favorTask.status,
            .failed("Preparing the party-favor shopping list failed on its first attempt.")
        )

        await agent.retryFailedTask()

        XCTAssertEqual(agent.tasks.map(\.id), originalTaskIDs)
        XCTAssertEqual(planner.createPlanCallCount, 1)
        XCTAssertEqual(
            tool.executedTaskIDs,
            [originalTaskIDs[0], originalTaskIDs[1], originalTaskIDs[2], originalTaskIDs[2]]
        )
        XCTAssertEqual(
            agent.tasks.map(\.status),
            [.completed, .completed, .completed, .awaitingApproval, .pending, .pending]
        )
        XCTAssertEqual(agent.state, .awaitingApproval(originalTaskIDs[3]))
        XCTAssertFalse(tool.executedTaskIDs.contains(originalTaskIDs[3]))
        XCTAssertTrue(
            agent.executionLog.contains(
                "Failed \(favorTask.title): Preparing the party-favor shopping list failed on its first attempt."
            )
        )
        XCTAssertTrue(
            agent.executionLog.contains("Retrying \(favorTask.title) with \(tool.name).")
        )
        XCTAssertTrue(
            agent.executionLog.contains(
                "Retry succeeded for \(favorTask.title): Completed \(favorTask.title)"
            )
        )

        let tasksAfterSuccessfulRetry = agent.tasks
        let logAfterSuccessfulRetry = agent.executionLog
        await agent.retryFailedTask()

        XCTAssertEqual(agent.tasks, tasksAfterSuccessfulRetry)
        XCTAssertEqual(agent.executionLog, logAfterSuccessfulRetry)
        XCTAssertEqual(planner.createPlanCallCount, 1)
        XCTAssertEqual(
            tool.executedTaskIDs,
            [originalTaskIDs[0], originalTaskIDs[1], originalTaskIDs[2], originalTaskIDs[2]]
        )
    }

    func testRetryOutsideFailedStateDoesNothing() async {
        let planner = RecordingBirthdayPlanner()
        let tool = MockPartyTool()
        let agent = makeAgent(planner: planner, tool: tool)
        await agent.start()
        let originalTasks = agent.tasks

        await agent.retryFailedTask()

        XCTAssertEqual(agent.state, .reviewing)
        XCTAssertEqual(agent.tasks, originalTasks)
        XCTAssertTrue(agent.executionLog.isEmpty)
        XCTAssertTrue(tool.executedTaskIDs.isEmpty)
        XCTAssertEqual(planner.createPlanCallCount, 1)
    }

    func testRetryFailedPlanningWithoutFailedTaskDoesNothing() async {
        let planner = FailingBirthdayPlanner()
        let tool = MockPartyTool()
        let agent = makeAgent(planner: planner, tool: tool)
        await agent.start()
        let failureState = agent.state

        await agent.retryFailedTask()

        XCTAssertEqual(agent.state, failureState)
        XCTAssertTrue(agent.tasks.isEmpty)
        XCTAssertTrue(agent.executionLog.isEmpty)
        XCTAssertTrue(tool.executedTaskIDs.isEmpty)
        XCTAssertEqual(planner.createPlanCallCount, 1)
    }

    func testDecliningApprovalTasksSkipsThemAndCompletesPlan() async {
        let tool = MockPartyTool()
        let agent = await makeAgentAtFirstApproval(tool: tool)
        let taskIDs = agent.tasks.map(\.id)
        let venueTask = agent.tasks[3]
        let rsvpTask = agent.tasks[4]
        let cakePickupTask = agent.tasks[5]
        let automaticExecutionIDs = [taskIDs[0], taskIDs[1], taskIDs[2], taskIDs[2]]

        await agent.decline(taskID: venueTask.id)

        XCTAssertEqual(agent.tasks[3].status, .declined)
        XCTAssertFalse(agent.isApproved(taskID: venueTask.id))
        XCTAssertEqual(agent.tasks[4].status, .awaitingApproval)
        XCTAssertEqual(agent.state, .awaitingApproval(rsvpTask.id))
        XCTAssertEqual(tool.executedTaskIDs, automaticExecutionIDs)
        XCTAssertTrue(agent.executionLog.contains("Declined \(venueTask.title)."))

        await agent.approve(taskID: venueTask.id)

        XCTAssertEqual(agent.tasks[3].status, .declined)
        XCTAssertFalse(agent.isApproved(taskID: venueTask.id))
        XCTAssertEqual(agent.state, .awaitingApproval(rsvpTask.id))
        XCTAssertEqual(tool.executedTaskIDs, automaticExecutionIDs)

        await agent.decline(taskID: rsvpTask.id)

        XCTAssertEqual(agent.tasks[4].status, .declined)
        XCTAssertFalse(agent.isApproved(taskID: rsvpTask.id))
        XCTAssertEqual(agent.tasks[5].status, .awaitingApproval)
        XCTAssertEqual(agent.state, .awaitingApproval(cakePickupTask.id))
        XCTAssertEqual(tool.executedTaskIDs, automaticExecutionIDs)
        XCTAssertFalse(tool.executedTaskIDs.contains(venueTask.id))
        XCTAssertFalse(tool.executedTaskIDs.contains(rsvpTask.id))
        XCTAssertTrue(agent.executionLog.contains("Declined \(rsvpTask.title)."))

        await agent.decline(taskID: cakePickupTask.id)

        XCTAssertEqual(agent.tasks[5].status, .declined)
        XCTAssertFalse(agent.isApproved(taskID: cakePickupTask.id))
        XCTAssertEqual(agent.state, .completed)
        XCTAssertEqual(tool.executedTaskIDs, automaticExecutionIDs)
        XCTAssertFalse(tool.executedTaskIDs.contains(cakePickupTask.id))
        XCTAssertTrue(agent.executionLog.contains("Declined \(cakePickupTask.title)."))
        XCTAssertEqual(agent.executionLog.last, "Plan completed.")

        await agent.approve(taskID: rsvpTask.id)
        await agent.approve(taskID: cakePickupTask.id)
        await agent.approve(taskID: venueTask.id)

        XCTAssertEqual(agent.state, .completed)
        XCTAssertEqual(agent.tasks[3].status, .declined)
        XCTAssertEqual(agent.tasks[4].status, .declined)
        XCTAssertEqual(agent.tasks[5].status, .declined)
        XCTAssertEqual(tool.executedTaskIDs, automaticExecutionIDs)
    }

    func testDecliningUnrelatedTaskDoesNothing() async {
        let tool = MockPartyTool()
        let agent = await makeAgentAtFirstApproval(tool: tool)
        let originalState = agent.state
        let originalTasks = agent.tasks
        let originalLog = agent.executionLog
        let originalExecutionIDs = tool.executedTaskIDs

        await agent.decline(taskID: UUID())

        XCTAssertEqual(agent.state, originalState)
        XCTAssertEqual(agent.tasks, originalTasks)
        XCTAssertEqual(agent.executionLog, originalLog)
        XCTAssertEqual(tool.executedTaskIDs, originalExecutionIDs)
    }

    func testDecliningOutsideAwaitingApprovalDoesNothing() async {
        let tool = MockPartyTool()
        let agent = makeAgent(tool: tool)
        await agent.start()
        let originalTasks = agent.tasks

        await agent.decline(taskID: agent.tasks[3].id)

        XCTAssertEqual(agent.state, .reviewing)
        XCTAssertEqual(agent.tasks, originalTasks)
        XCTAssertTrue(agent.executionLog.isEmpty)
        XCTAssertTrue(tool.executedTaskIDs.isEmpty)
        XCTAssertFalse(agent.isApproved(taskID: agent.tasks[3].id))
    }

    private func makeAgent(tool: any PartyTool) -> BirthdayAgent {
        makeAgent(planner: DeterministicBirthdayPlanner(), tool: tool)
    }

    private func makeAgentAtFirstApproval(tool: MockPartyTool) async -> BirthdayAgent {
        let agent = makeAgent(tool: tool)
        await agent.start()
        await agent.executePlan()
        await agent.retryFailedTask()
        return agent
    }

    private func makeAgent(
        planner: any BirthdayPlanning,
        tool: any PartyTool
    ) -> BirthdayAgent {
        BirthdayAgent(
            context: testContext,
            planner: planner,
            tool: tool
        )
    }

    private var testContext: PartyContext {
        PartyContext(
            childName: "Viyana",
            age: 7,
            partyDate: Date(timeIntervalSince1970: 0),
            theme: "Rainbows",
            adultCount: 8,
            childCount: 12,
            venue: "Test Venue"
        )
    }
}

@MainActor
private final class RecordingBirthdayPlanner: BirthdayPlanning {
    private(set) var createPlanCallCount = 0

    func createPlan(for context: PartyContext) async throws -> [PartyTask] {
        createPlanCallCount += 1
        return try await DeterministicBirthdayPlanner().createPlan(for: context)
    }
}

@MainActor
private final class SuspendingBirthdayPlanner: BirthdayPlanning {
    var onCreatePlan: (() -> Void)?
    private var continuation: CheckedContinuation<[PartyTask], Error>?

    func createPlan(for context: PartyContext) async throws -> [PartyTask] {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            onCreatePlan?()
        }
    }

    func complete(with tasks: [PartyTask]) {
        continuation?.resume(returning: tasks)
        continuation = nil
    }
}

@MainActor
private final class FailingBirthdayPlanner: BirthdayPlanning {
    private(set) var createPlanCallCount = 0

    func createPlan(for context: PartyContext) async throws -> [PartyTask] {
        createPlanCallCount += 1
        throw PlanningFailure.failed
    }
}

private enum PlanningFailure: LocalizedError {
    case failed

    var errorDescription: String? {
        "Planning failed."
    }
}

@MainActor
private final class SuspendingFirstPartyTool: PartyTool {
    let name = "Suspending Party Tool"
    var onFirstExecution: (() -> Void)?
    private(set) var executedTaskIDs: [UUID] = []
    private var shouldSuspend = true
    private var continuation: CheckedContinuation<String, Error>?

    func execute(task: PartyTask) async throws -> String {
        executedTaskIDs.append(task.id)

        guard shouldSuspend else {
            return "Recorded \(task.title)"
        }

        shouldSuspend = false
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            onFirstExecution?()
        }
    }

    func completeFirstExecution() {
        continuation?.resume(returning: "Recorded first task")
        continuation = nil
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
