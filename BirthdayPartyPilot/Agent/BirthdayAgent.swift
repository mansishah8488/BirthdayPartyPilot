import Combine
import Foundation

@MainActor
final class BirthdayAgent: ObservableObject {
    @Published private(set) var state: BirthdayAgentState = .idle
    @Published private(set) var tasks: [PartyTask] = []
    @Published private(set) var executionLog: [String] = []

    let context: PartyContext

    private let planner: any BirthdayPlanning
    private let tool: any PartyTool
    private var approvedTaskIDs: Set<UUID> = []
    private var failedTaskID: UUID?
    private var nextTaskIndex = 0

    init(
        context: PartyContext,
        planner: any BirthdayPlanning,
        tool: any PartyTool
    ) {
        self.context = context
        self.planner = planner
        self.tool = tool
    }

    func start() async {
        guard state == .idle else {
            return
        }

        tasks = []
        state = .planning

        do {
            tasks = try await planner.createPlan(for: context)
            state = .reviewing
        } catch {
            tasks = []
            state = .failed(error.localizedDescription)
        }
    }

    func executePlan() async {
        guard state == .reviewing else {
            return
        }

        await executeRemainingTasks()
    }

    func retryFailedTask() async {
        guard case .failed = state,
              let failedTaskID,
              nextTaskIndex < tasks.count,
              tasks[nextTaskIndex].id == failedTaskID,
              case .failed = tasks[nextTaskIndex].status
        else {
            return
        }

        let task = tasks[nextTaskIndex]
        tasks[nextTaskIndex].status = .running
        state = .executing(task.id)
        executionLog.append("Retrying \(task.title) with \(tool.name).")

        do {
            let result = try await tool.execute(task: tasks[nextTaskIndex])
            tasks[nextTaskIndex].status = .completed
            executionLog.append("Retry succeeded for \(task.title): \(result)")
            self.failedTaskID = nil
            nextTaskIndex += 1
            await executeRemainingTasks()
        } catch {
            let message = error.localizedDescription
            tasks[nextTaskIndex].status = .failed(message)
            executionLog.append("Retry failed for \(task.title): \(message)")
            state = .failed(message)
        }
    }

    func approve(taskID: UUID) async {
        if state == .reviewing,
           let task = tasks.first(where: { $0.id == taskID }),
           task.approvalRequirement == .required,
           !approvedTaskIDs.contains(taskID) {
            approvedTaskIDs.insert(taskID)
            executionLog.append("Approved \(task.title).")
            return
        }

        guard state == .awaitingApproval(taskID),
              nextTaskIndex < tasks.count,
              tasks[nextTaskIndex].id == taskID
        else {
            return
        }

        approvedTaskIDs.insert(taskID)
        executionLog.append("Approved \(tasks[nextTaskIndex].title).")
        await executeRemainingTasks()
    }

    func decline(taskID: UUID) async {
        guard case let .awaitingApproval(awaitingTaskID) = state,
              awaitingTaskID == taskID,
              nextTaskIndex < tasks.count,
              tasks[nextTaskIndex].id == taskID,
              tasks[nextTaskIndex].approvalRequirement == .required,
              tasks[nextTaskIndex].status == .awaitingApproval
        else {
            return
        }

        tasks[nextTaskIndex].status = .declined
        executionLog.append("Declined \(tasks[nextTaskIndex].title).")
        nextTaskIndex += 1
        await executeRemainingTasks()
    }

    func isApproved(taskID: UUID) -> Bool {
        approvedTaskIDs.contains(taskID)
    }

    var canExecutePlan: Bool {
        guard state == .reviewing else {
            return false
        }

        return !tasks.isEmpty
    }

    var currentTask: PartyTask? {
        switch state {
        case let .awaitingApproval(taskID), let .executing(taskID):
            tasks.first { $0.id == taskID }
        case .failed:
            tasks.first {
                if case .failed = $0.status {
                    return true
                }
                return false
            }
        default:
            nil
        }
    }

    var completedTasks: [PartyTask] {
        tasks.filter { $0.status == .completed }
    }

    var failureMessage: String? {
        guard case let .failed(message) = state else {
            return nil
        }
        return message
    }

    var canRestart: Bool {
        switch state {
        case .planning, .executing:
            false
        case .idle, .reviewing, .awaitingApproval, .completed, .failed:
            true
        }
    }

    func restart() {
        guard canRestart else {
            return
        }

        approvedTaskIDs = []
        failedTaskID = nil
        nextTaskIndex = 0
        tasks = []
        executionLog = []
        state = .idle
    }

    private func executeRemainingTasks() async {
        while nextTaskIndex < tasks.count {
            let task = tasks[nextTaskIndex]

            if task.approvalRequirement == .required,
               !approvedTaskIDs.contains(task.id) {
                tasks[nextTaskIndex].status = .awaitingApproval
                state = .awaitingApproval(task.id)
                executionLog.append("Awaiting approval for \(task.title).")
                return
            }

            tasks[nextTaskIndex].status = .running
            state = .executing(task.id)
            executionLog.append("Executing \(task.title) with \(tool.name).")

            do {
                let result = try await tool.execute(task: tasks[nextTaskIndex])
                tasks[nextTaskIndex].status = .completed
                executionLog.append("\(task.title): \(result)")
                nextTaskIndex += 1
            } catch {
                let message = error.localizedDescription
                tasks[nextTaskIndex].status = .failed(message)
                failedTaskID = task.id
                executionLog.append("Failed \(task.title): \(message)")
                state = .failed(message)
                return
            }
        }

        state = .completed
        executionLog.append("Plan completed.")
    }
}
