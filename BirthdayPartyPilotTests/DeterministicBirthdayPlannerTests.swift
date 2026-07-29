import Foundation
import XCTest
@testable import BirthdayPartyPilot

@MainActor
final class DeterministicBirthdayPlannerTests: XCTestCase {
    func testCreatesExpectedSixTaskPlan() async throws {
        let context = PartyContext(
            childName: "Viyana",
            age: 7,
            partyDate: Date(timeIntervalSince1970: 0),
            theme: "Rainbows",
            adultCount: 8,
            childCount: 12,
            venue: "Test Venue"
        )

        let tasks = try await DeterministicBirthdayPlanner().createPlan(for: context)

        XCTAssertEqual(tasks.count, 6)
        XCTAssertEqual(
            tasks.map(\.title),
            [
                "Calculate cake servings",
                "Create food quantity checklist",
                "Prepare party-favor shopping list",
                "Confirm venue reservation details",
                "Draft RSVP reminder",
                "Prepare cake pickup reminder",
            ]
        )
        XCTAssertEqual(
            tasks.map(\.category),
            [.cake, .food, .favors, .venue, .guests, .schedule]
        )
        XCTAssertEqual(
            tasks.filter { $0.approvalRequirement == .required }.count,
            3
        )
        XCTAssertTrue(tasks.allSatisfy { $0.status == .pending })
    }
}
