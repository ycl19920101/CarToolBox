//
//  VehicleViewModelTests.swift
//  CarToolBoxTests
//
//  Created by Chunlin Yao on 2026/3/6.
//

import XCTest
@testable import CarToolBox

@MainActor
final class VehicleViewModelTests: XCTestCase {

    var viewModel: VehicleViewModel!

    override func setUp() {
        super.setUp()
        viewModel = VehicleViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testFetchVehicleStatus() async throws {
        await viewModel.fetchVehicleStatus()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.vehicleStatus)
    }

    func testVehicleStatusProperties() async throws {
        await viewModel.fetchVehicleStatus()

        XCTAssertNotNil(viewModel.vehicleStatus)
        XCTAssertEqual(viewModel.vehicleStatus?.batteryLevel, 75.5)
        XCTAssertEqual(viewModel.vehicleStatus?.mileage, 12500.0)
        XCTAssertTrue(viewModel.vehicleStatus?.isLocked ?? false)
    }
}