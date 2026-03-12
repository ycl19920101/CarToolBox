//
//  VehicleViewUITests.swift
//  CarToolBoxUITests
//
//  Created by Chunlin Yao on 2026/3/6.
//

import XCTest

final class VehicleViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testTabBarExists() {
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    func testVehicleTabExists() {
        let vehicleTab = app.tabBars.buttons["车辆"]
        XCTAssertTrue(vehicleTab.exists)
    }

    func testNavigateToVehicleDetail() {
        app.tabBars.buttons["车辆"].tap()

        // 检查是否显示车辆状态按钮
        XCTAssertTrue(app.staticTexts["车辆状态"].exists)
    }

    func testCommunityTabExists() {
        let communityTab = app.tabBars.buttons["社区"]
        XCTAssertTrue(communityTab.exists)
    }
}