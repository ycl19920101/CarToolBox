//
//  NetworkManagerTests.swift
//  CarToolBoxTests
//
//  Created by Chunlin Yao on 2026/3/6.
//

import XCTest
@testable import CarToolBox

@MainActor
final class NetworkManagerTests: XCTestCase {

    var networkManager: NetworkManager!

    override func setUp() {
        super.setUp()
        networkManager = NetworkManager()
    }

    override func tearDown() {
        networkManager = nil
        super.tearDown()
    }

    func testNetworkManagerInitialization() {
        XCTAssertNotNil(networkManager)
        XCTAssertTrue(networkManager.isConnected)
    }

    func testInvalidURLError() {
        let error = NetworkError.invalidURL
        XCTAssertEqual(error.localizedDescription, "无效的URL")
    }

    func testNetworkUnavailableError() {
        let error = NetworkError.networkUnavailable
        XCTAssertEqual(error.localizedDescription, "网络不可用")
    }
}