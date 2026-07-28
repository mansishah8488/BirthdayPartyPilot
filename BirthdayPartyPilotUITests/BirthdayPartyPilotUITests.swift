//
//  BirthdayPartyPilotUITests.swift
//  BirthdayPartyPilotUITests
//
//  Created by Mansi Shah on 7/26/26.
//

import XCTest

final class BirthdayPartyPilotUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testCreatesPlanAndShowsFiveTasks() throws {
        let app = XCUIApplication()
        app.launch()

        let childName = app.descendants(matching: .any)["party-child-name"]
        XCTAssertTrue(childName.waitForExistence(timeout: 5))
        let childValue = childName.value as? String
        XCTAssertTrue(
            childName.label.contains("Viyana") || childValue?.contains("Viyana") == true
        )

        let createButton = app.buttons["create-plan-button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let reviewScreen = app.descendants(matching: .any)["plan-review-screen"]
        XCTAssertTrue(reviewScreen.waitForExistence(timeout: 5))

        let taskTitles = [
            "Calculate cake servings",
            "Create food quantity checklist",
            "Prepare party-favor shopping list",
            "Draft RSVP reminder",
            "Prepare cake pickup reminder",
        ]

        for title in taskTitles {
            let taskTitle = app.staticTexts[title]
            if !taskTitle.exists {
                app.swipeUp()
            }
            XCTAssertTrue(
                taskTitle.waitForExistence(timeout: 2),
                "Expected task title: \(title)"
            )
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
