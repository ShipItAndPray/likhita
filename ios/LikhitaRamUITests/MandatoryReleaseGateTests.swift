//  MandatoryReleaseGateTests.swift (Likhita Ram — Hindi target)
//
//  Mirror of LikhitaRamaUITests/MandatoryReleaseGateTests.swift but typing
//  "ram" instead of "srirama" and using the Hindi app's bundle id. Every
//  gate scenario in QA-SCENARIOS.md must pass on this target as well —
//  otherwise the Hindi app does not ship.

import XCTest

private let LIKHITA_TEST_API_BASE = "https://likhita-kappa.vercel.app"

final class MandatoryReleaseGateTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func injectTestEnv(_ app: XCUIApplication) {
        app.launchEnvironment["LIKHITA_API_BASE"] = LIKHITA_TEST_API_BASE
    }

    /// QA-SCENARIOS §1.2 — first commit to My Book persists across restart.
    func test_1_2_personal_koti_commit_persists_across_kill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-state"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "writing"
        injectTestEnv(app)
        app.launch()

        let field = app.textFields.element(boundBy: 0)
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Expected the writing surface's input field to appear")

        app.terminate()
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "writing"
        injectTestEnv(app)
        app.launch()
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Writing surface did not appear on relaunch")
    }

    /// QA-SCENARIOS §2.2 — Sangha mantra survives type → kill → reopen.
    /// Uses the `--simulate-mantras=1` deterministic path; see Rama target
    /// notes for why XCUITest typeText is avoided here.
    func test_2_2_sangha_commit_persists_across_immediate_kill() throws {
        let countBefore = fetchSangaCount()
        XCTAssertNotNil(countBefore, "Could not reach /api/v1/shared/koti before test")
        guard let countBefore else { return }

        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-state", "--simulate-mantras=1"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "sharedHub"
        injectTestEnv(app)
        app.launch()
        sleep(10)

        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "sharedHub"
        injectTestEnv(app)
        app.launch()
        sleep(8)

        let countAfter = fetchSangaCount()
        XCTAssertNotNil(countAfter, "Could not reach /api/v1/shared/koti after test")
        guard let countAfter else { return }
        XCTAssertEqual(
            countAfter, countBefore + 1,
            "Sangha count did not advance by exactly 1 after simulate + kill + reopen. before=\(countBefore) after=\(countAfter)."
        )
    }

    /// Synchronously GET /api/v1/shared/koti and return current_count.
    private func fetchSangaCount() -> Int? {
        guard let url = URL(string: "\(LIKHITA_TEST_API_BASE)/api/v1/shared/koti") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("likhita-ram", forHTTPHeaderField: "X-App-Origin")
        let semaphore = DispatchSemaphore(value: 0)
        var resultCount: Int?
        URLSession.shared.dataTask(with: req) { data, _, _ in
            defer { semaphore.signal() }
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let koti = obj["koti"] as? [String: Any],
                  let c = koti["currentCount"] as? Int else { return }
            resultCount = c
        }.resume()
        _ = semaphore.wait(timeout: .now() + 8)
        return resultCount
    }

    /// QA-SCENARIOS §3.2 — Settings shows credit row.
    func test_3_2_settings_renders_foundation_card() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["LIKHITA_START_SCREEN"] = "settings"
        injectTestEnv(app)
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
        injectTestEnv(app)
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
