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
    func testCreatesPlanAndShowsSixTasks() throws {
        let app = XCUIApplication()
        launchFresh(app)

        let childName = app.descendants(matching: .any)["party-child-name"]
        XCTAssertTrue(childName.waitForExistence(timeout: 5))
        let childValue = childName.value as? String
        XCTAssertTrue(
            childName.label.contains("Viyana") || childValue?.contains("Viyana") == true
        )
        let summaryHeader = app.descendants(matching: .any)["party-summary-header"]
        XCTAssertTrue(summaryHeader.waitForExistence(timeout: 5))
        XCTAssertTrue(summaryHeader.label.contains("Viyana"))

        let createButton = app.buttons["create-plan-button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let reviewScreen = app.descendants(matching: .any)["plan-review-screen"]
        XCTAssertTrue(reviewScreen.waitForExistence(timeout: 10))
        XCTAssertTrue(summaryHeader.waitForExistence(timeout: 10))
        XCTAssertTrue(summaryHeader.label.contains("Plan review"))
        XCTAssertTrue(app.descendants(matching: .any)["plan-progress-summary"].waitForExistence(timeout: 5))

        // Status is symbol-only on Plan Review; assert via accessibility label.
        let pendingStatus = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Status: Pending"))
            .firstMatch
        XCTAssertTrue(pendingStatus.waitForExistence(timeout: 5))

        let approvalRequired = app.descendants(matching: .any)["approval-required-label"]
        scrollUntilExists(
            element: approvalRequired,
            named: "approval required label",
            in: app
        )
        XCTAssertTrue(
            approvalRequired.exists
                || app.staticTexts["Approval required"].exists
        )

        let taskTitles = [
            "Calculate cake servings",
            "Create food quantity checklist",
            "Prepare party-favor shopping list",
            "Confirm venue reservation details",
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
    func testPreApprovingRequiredTasksClearsNeedApprovalCount() throws {
        let app = XCUIApplication()
        launchFresh(app)

        let createButton = app.buttons["create-plan-button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let progressSummary = app.descendants(matching: .any)["plan-progress-summary"]
        XCTAssertTrue(progressSummary.waitForExistence(timeout: 10))
        XCTAssertTrue(
            progressSummary.label.localizedCaseInsensitiveContains("Need approval: 3"),
            "Expected initial Need approval count of 3. Label: \(progressSummary.label)"
        )

        for index in 1...3 {
            let approveButton = app.buttons
                .matching(NSPredicate(format: "label BEGINSWITH %@", "Approve "))
                .firstMatch
            scrollTo(
                element: approveButton,
                named: "approve required task \(index)",
                in: app
            )
            approveButton.tap()
        }

        scrollToTop(in: app)
        XCTAssertTrue(progressSummary.waitForExistence(timeout: 5))
        XCTAssertTrue(
            progressSummary.label.localizedCaseInsensitiveContains("Need approval: 0"),
            "Expected Need approval count to reach 0 after pre-approving all required tasks. Label: \(progressSummary.label)"
        )
        XCTAssertTrue(
            progressSummary.label.localizedCaseInsensitiveContains("Pre-approved: 3"),
            "Expected Pre-approved count to reach 3. Label: \(progressSummary.label)"
        )
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
        let failedStatus = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Status: Failed"))
            .firstMatch
        XCTAssertTrue(
            failedStatus.waitForExistence(timeout: 5)
                || app.staticTexts["Failed"].waitForExistence(timeout: 2)
                || app.descendants(matching: .any)["execution-failure-message"].waitForExistence(timeout: 2)
        )
        retryButton.tap()

        scrollToTop(in: app)
        let currentTask = app.staticTexts["current-task-title"]
        XCTAssertTrue(currentTask.waitForExistence(timeout: 5))
        expectation(
            for: NSPredicate(
                format: "label CONTAINS %@",
                "Confirm venue reservation details"
            ),
            evaluatedWith: currentTask
        )
        waitForExpectations(timeout: 5)

        let approveButton = app.buttons["approve-current-task-button"]
        let declineButton = app.buttons["decline-current-task-button"]
        scrollTo(element: declineButton, named: "decline venue confirmation", in: app)
        XCTAssertTrue(approveButton.exists)
        XCTAssertTrue(declineButton.exists)
        XCTAssertTrue(approveButton.label.contains("Confirm venue reservation details"))
        XCTAssertTrue(declineButton.label.contains("Confirm venue reservation details"))
        let awaitingStatus = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Status: Awaiting approval"))
            .firstMatch
        XCTAssertTrue(
            awaitingStatus.waitForExistence(timeout: 5)
                || app.staticTexts["Awaiting approval"].waitForExistence(timeout: 2)
        )
        declineButton.tap()

        scrollToTop(in: app)
        expectation(
            for: NSPredicate(format: "label CONTAINS %@", "Draft RSVP reminder"),
            evaluatedWith: currentTask
        )
        waitForExpectations(timeout: 5)

        scrollTo(element: declineButton, named: "decline RSVP", in: app)
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
        scrollUntilExists(
            element: completionMessage,
            named: "completion message",
            in: app
        )

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
    private func scrollUntilExists(
        element: XCUIElement,
        named name: String,
        in app: XCUIApplication,
        maxSwipes: Int = 8
    ) {
        for _ in 0..<maxSwipes {
            if element.exists {
                return
            }
            app.swipeUp()
        }

        XCTAssertTrue(element.waitForExistence(timeout: 2), "Expected \(name) to exist")
    }

    @MainActor
    private func launchFresh(_ app: XCUIApplication) {
        if app.state != .notRunning {
            app.terminate()
        }
        app.launch()
    }
}
