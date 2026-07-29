import Foundation
import XCTest
@testable import BirthdayPartyPilot

@MainActor
final class PlanReviewProgressStatsTests: XCTestCase {
    func testInitialCountsMatchDeterministicSixTaskPlan() {
        let tasks = samplePlan()
        let stats = PlanReviewProgressStats(tasks: tasks, isApproved: { _ in false })

        XCTAssertEqual(stats.informationalCount, 3)
        XCTAssertEqual(stats.approvalRequiredCount, 3)
        XCTAssertEqual(stats.pendingApprovalCount, 3)
        XCTAssertEqual(stats.approvedCount, 0)
        XCTAssertFalse(stats.allSideEffectsPreApproved)
    }

    func testPendingApprovalCountDecreasesAsTasksArePreApproved() {
        let tasks = samplePlan()
        let requiredIDs = tasks
            .filter { $0.approvalRequirement == .required }
            .map(\.id)
        var approved: Set<UUID> = []

        approved.insert(requiredIDs[0])
        var stats = PlanReviewProgressStats(
            tasks: tasks,
            isApproved: { approved.contains($0) }
        )
        XCTAssertEqual(stats.pendingApprovalCount, 2)
        XCTAssertEqual(stats.approvedCount, 1)
        XCTAssertFalse(stats.allSideEffectsPreApproved)

        approved.formUnion(requiredIDs)
        stats = PlanReviewProgressStats(
            tasks: tasks,
            isApproved: { approved.contains($0) }
        )
        XCTAssertEqual(stats.pendingApprovalCount, 0)
        XCTAssertEqual(stats.approvedCount, 3)
        XCTAssertEqual(stats.approvalRequiredCount, 3)
        XCTAssertTrue(stats.allSideEffectsPreApproved)
    }

    func testInformationalCountIgnoresApprovalState() {
        let tasks = samplePlan()
        let requiredIDs = Set(
            tasks.filter { $0.approvalRequirement == .required }.map(\.id)
        )
        let stats = PlanReviewProgressStats(
            tasks: tasks,
            isApproved: { requiredIDs.contains($0) }
        )

        XCTAssertEqual(stats.informationalCount, 3)
        XCTAssertEqual(stats.pendingApprovalCount, 0)
    }

    private func samplePlan() -> [PartyTask] {
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
                title: "Confirm venue reservation details",
                category: .venue,
                approvalRequirement: .required
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
