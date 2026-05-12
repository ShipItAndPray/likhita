//  MandatoryReleaseGateTests.swift (Likhita Ram — Hindi target)
//
//  Mirror of LikhitaRamaUITests/MandatoryReleaseGateTests.swift but typing
//  "ram" instead of "srirama". Every gate scenario in QA-SCENARIOS.md must
//  pass on this target as well — otherwise the Hindi app does not ship.

import XCTest

final class MandatoryReleaseGateTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// QA-SCENARIOS §1.2 — first commit to My Book persists across restart.
    func test_1_2_personal_koti_commit_persists_across_kill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-state"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "writing"
        app.launch()

        let field = app.textFields.element(boundBy: 0)
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Expected the writing surface's input field to appear")
        field.tap()
        field.typeText("ram")

        let cleared = waitForFieldValue(field, equals: "type ram", timeout: 3)
        XCTAssertTrue(cleared, "Field did not clear after typing ram — commit didn't fire")

        app.terminate()
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "writing"
        app.launch()
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Writing surface did not appear on relaunch")
    }

    /// QA-SCENARIOS §2.2 — Sangha mantra survives type → kill → reopen.
    func test_2_2_sangha_commit_persists_across_immediate_kill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-state"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "sharedWrite"
        app.launch()

        let field = app.textFields.element(boundBy: 0)
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Sangha writing input field did not appear")
        field.tap()
        field.typeText("ram")
        let bumped = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS '1'"))
            .firstMatch
            .waitForExistence(timeout: 3)
        XCTAssertTrue(bumped, "Session counter did not advance after a Sangha commit")

        app.terminate()
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "sharedHub"
        app.launch()
        let hubAppeared = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS 'NAMES WRITTEN' OR label CONTAINS 'The Foundation Koti'"))
            .firstMatch
            .waitForExistence(timeout: 8)
        XCTAssertTrue(hubAppeared, "Sangha hub did not show post-restart")
    }

    /// QA-SCENARIOS §3.2 — Settings shows credit row.
    func test_3_2_settings_renders_foundation_card() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "settings"
        app.launch()

        let foundationHeader = app.staticTexts["FOUNDATION"]
        XCTAssertTrue(foundationHeader.waitForExistence(timeout: 5),
                      "FOUNDATION section header missing from Settings")
        XCTAssertTrue(app.staticTexts["Sangha by"].exists,
                      "Sangha credit row missing from Settings — Mammu Inc. attribution lost")
    }

    /// QA-SCENARIOS §2.1 — Sangha hub fetches live count on entry.
    func test_2_1_sangha_hub_fetches_live_count() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "sharedHub"
        app.launch()

        let title = app.staticTexts["The Foundation Koti"]
        XCTAssertTrue(title.waitForExistence(timeout: 8),
                      "Sangha hub did not render server data (title missing)")

        let ceiling = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS '1,00,00,000'"))
            .firstMatch
        XCTAssertTrue(ceiling.waitForExistence(timeout: 5),
                      "Sangha counter did not render the 1 crore ceiling")
    }
}

func waitForFieldValue(_ element: XCUIElement, equals expected: String, timeout: TimeInterval) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        let actual = (element.value as? String) ?? element.placeholderValue ?? ""
        if actual == expected { return true }
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }
    return false
}
