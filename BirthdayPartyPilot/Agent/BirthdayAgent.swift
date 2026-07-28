import Combine
import Foundation

@MainActor
final class BirthdayAgent: ObservableObject {
    @Published private(set) var state: BirthdayAgentState = .idle
    @Published private(set) var tasks: [PartyTask] = []

    let context: PartyContext

    private let planner: any BirthdayPlanning

    init(
        context: PartyContext,
        planner: any BirthdayPlanning
    ) {
        self.context = context
        self.planner = planner
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
}
