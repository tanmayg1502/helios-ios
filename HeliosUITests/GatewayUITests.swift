import XCTest

/// Opt-in integration scheme: start the documented local gateway fixture on port 18080 first.
final class GatewayUITests: XCTestCase {
    #if DEBUG
    @MainActor func testConnectReadTelemetryDisconnectAndDemo() throws {
        let app = XCUIApplication()
        app.launch()
        enableDeveloperMode(app)
        let endpoint = app.textFields["Gateway URL"]
        XCTAssertTrue(endpoint.waitForExistence(timeout: 5))
        endpoint.tap()
        endpoint.typeText("http://localhost:18080")
        let token = app.secureTextFields["Gateway bearer token"]
        token.tap()
        token.typeText("helios-local-fixture-token-32-chars-only")
        app.buttons["connectGateway"].tap()
        XCTAssertTrue(app.staticTexts["Gateway connected"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.staticTexts["FIXTURE • Simulated data"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["odometryFrame"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["odometryBodyFrame"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Developer fixture telemetry"
        shot.lifetime = .keepAlways
        add(shot)
        app.tabBars.buttons["Connect"].tap()
        app.buttons["Disconnect"].tap()
        XCTAssertTrue(app.staticTexts["Disconnected"].waitForExistence(timeout: 5))
        app.swipeUp()
        app.buttons["Use local sample"].tap()
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.staticTexts["Built to explore."].waitForExistence(timeout: 5))
    }

    @MainActor func testOperationsFixtureConfirmationStartAndStop() throws {
        let app = XCUIApplication()
        app.launch()
        enableDeveloperMode(app)
        let endpoint = app.textFields["Gateway URL"]
        XCTAssertTrue(endpoint.waitForExistence(timeout: 5))
        endpoint.tap()
        endpoint.typeText("http://localhost:18080")
        let token = app.secureTextFields["Gateway bearer token"]
        token.tap()
        token.typeText("helios-local-fixture-token-32-chars-only")
        app.buttons["connectGateway"].tap()
        XCTAssertTrue(app.staticTexts["Gateway connected"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Operations"].tap()
        guard app.staticTexts["SIMULATED GATEWAY"].waitForExistence(timeout: 5) else {
            XCTFail("Only a synthetic fixture may run the operations UI test")
            return
        }
        app.buttons["acquireControl"].tap()
        XCTAssertTrue(app.staticTexts["Control session active"].waitForExistence(timeout: 5))
        app.buttons["operation-motors"].tap()
        app.buttons["runOperation"].tap()
        let confirmation = app.buttons["Confirm and run"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.tap()
        let stop = app.buttons["stopJob-motors"].firstMatch
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Simulated motor service controls"
        attachment.lifetime = .keepAlways
        add(attachment)
        stop.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: stop)
        waitForExpectations(timeout: 8)
    }

    @MainActor private func enableDeveloperMode(_ app: XCUIApplication) {
        app.tabBars.buttons["Connect"].tap()
        let enable = app.buttons["Enable developer mode"]
        app.swipeUp()
        XCTAssertTrue(enable.waitForExistence(timeout: 5))
        enable.tap()
        app.buttons["Enable simulation"].tap()
        app.swipeDown()
    }

    @MainActor func testLaunchShowsNoSamplesAndSimulationRequiresOptIn() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["No live readings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Built to explore."].exists)
        app.tabBars.buttons["Map"].tap()
        XCTAssertTrue(app.staticTexts["Live map unavailable"].waitForExistence(timeout: 5))
        enableDeveloperMode(app)
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.staticTexts["DEVELOPER MODE • Simulation only"].exists)
        XCTAssertTrue(app.staticTexts["Built to explore."].exists)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["No live readings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Built to explore."].exists)
    }

    #else
    @MainActor func testDistributionBuildFailsClosedWithoutVerifiedEligibility() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["No live readings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Built to explore."].exists)
        app.tabBars.buttons["Map"].tap()
        XCTAssertTrue(app.staticTexts["Live map unavailable"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Connect"].tap()
        app.swipeUp()
        XCTAssertFalse(app.buttons["Enable developer mode"].exists)
        XCTAssertFalse(app.buttons["Use local sample"].exists)
        XCTAssertFalse(app.staticTexts["DEVELOPER MODE • Simulation only"].exists)
    }
    #endif

}
