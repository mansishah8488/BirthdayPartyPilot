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
        launchFresh(app)

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
    func testRetryDeclineAndRestartAreWiredToExecutionScreen() throws {
        let app = XCUIApplication()
        launchFresh(app)

        let createButton = app.buttons["create-plan-button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 10))
        createButton.tap()

        let executeButton = app.buttons["execute-plan-button"]
        scrollTo(element: executeButton, named: "start execution", in: app)
        XCTAssertTrue(executeButton.isEnabled)
        executeButton.tap()

        let retryButton = app.buttons["retry-failed-task-button"]
        scrollTo(element: retryButton, named: "retry failed task", in: app)
        retryButton.tap()

        scrollToTop(in: app)
        let currentTask = app.staticTexts["current-task-title"]
        XCTAssertTrue(currentTask.waitForExistence(timeout: 5))
        expectation(
            for: NSPredicate(format: "label CONTAINS %@", "Draft RSVP reminder"),
            evaluatedWith: currentTask
        )
        waitForExpectations(timeout: 5)

        let approveButton = app.buttons["approve-current-task-button"]
        let declineButton = app.buttons["decline-current-task-button"]
        scrollTo(element: declineButton, named: "decline RSVP", in: app)
        XCTAssertTrue(approveButton.exists)
        XCTAssertTrue(declineButton.exists)
        declineButton.tap()

        scrollToTop(in: app)
        expectation(
            for: NSPredicate(format: "label CONTAINS %@", "Prepare cake pickup reminder"),
            evaluatedWith: currentTask
        )
        waitForExpectations(timeout: 5)

        scrollTo(element: declineButton, named: "decline cake pickup", in: app)
        declineButton.tap()

        let completionMessage = app.descendants(matching: .any)["completion-message"]
        XCTAssertTrue(completionMessage.waitForExistence(timeout: 5))

        let restartButton = app.buttons["restart-demo-button"]
        scrollTo(element: restartButton, named: "restart completed demo", in: app)
        XCTAssertTrue(restartButton.isEnabled)
        restartButton.tap()

        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["party-child-name"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func scrollTo(
        element: XCUIElement,
        named name: String,
        in app: XCUIApplication,
        maxSwipes: Int = 8
    ) {
        for _ in 0..<maxSwipes {
            if element.exists, element.isHittable {
                return
            }
            app.swipeUp()
        }

        XCTAssertTrue(element.waitForExistence(timeout: 2), "Expected \(name) to exist")
        XCTAssertTrue(element.isHittable, "Expected \(name) to be hittable")
    }

    @MainActor
    private func scrollToTop(in app: XCUIApplication, maxSwipes: Int = 8) {
        for _ in 0..<maxSwipes {
            app.swipeDown()
        }
    }

    @MainActor
    private func launchFresh(_ app: XCUIApplication) {
        if app.state != .notRunning {
            app.terminate()
        }
        app.launch()
    }
}
