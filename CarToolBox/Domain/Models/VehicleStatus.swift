//
//  VehicleStatus.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation

struct VehicleStatus: Codable, Identifiable {
    var batteryLevel: Double
    var mileage: Double
    var isLocked: Bool
    var temperature: Double
    var lastLocation: Location?
    var range: Double
    var chargingStatus: ChargingStatus
    let id = UUID()
}

struct Location: Codable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
}

enum ChargingStatus: String, Codable {
    case charging = "charging"
    case notCharging = "not_charging"
    case fullyCharged = "fully_charged"
}