import XCTest

final class WIMSCUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Validates the three-view (Map → List → Settings) navigation flow.
    func testThreeViewNavigation() throws {
        // Map tab should be selected by default
        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.exists)
        XCTAssertTrue(mapTab.isSelected)

        // Switch to List tab
        let listTab = app.tabBars.buttons["List"]
        XCTAssertTrue(listTab.exists)
        listTab.tap()
        XCTAssertTrue(listTab.isSelected)

        // Verify List navigation title is visible
        XCTAssertTrue(app.navigationBars["Superchargers"].exists)

        // Switch to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists)
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected)

        // Verify Settings navigation title
        XCTAssertTrue(app.navigationBars["Settings"].exists)

        // Return to Map
        mapTab.tap()
        XCTAssertTrue(mapTab.isSelected)
    }

    func testListSearchBarVisible() throws {
        app.tabBars.buttons["List"].tap()
        let searchField = app.searchFields["Search by name or city"]
        XCTAssertTrue(searchField.exists)
    }
}
