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

    func approve(taskID: UUID) async {
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
                executionLog.append("Failed \(task.title): \(message)")
                state = .failed(message)
                return
            }
        }

        state = .completed
        executionLog.append("Plan completed.")
    }
}
