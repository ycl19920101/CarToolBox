//
//  VehicleViewModel.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation
import Combine

@MainActor
class VehicleViewModel: ObservableObject {
    @Published var vehicleStatus: VehicleStatus?
    @Published var isLoading = false
    @Published var error: Error?

    func fetchVehicleStatus() async {
        isLoading = true
        error = nil

        VehicleService.shared().getVehicleStatus { [weak self] status, error in
            if let status = status {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.parseAndSaveStatus(status as! [String : Any])
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.error = error
                }
            }
        }
    }

    private func parseAndSaveStatus(_ statusDict: [String: Any]) {
        let batteryLevel = Double((statusDict["batteryLevel"] as? NSNumber)?.doubleValue ?? 0)
        let mileage = Double((statusDict["mileage"] as? NSNumber)?.doubleValue ?? 0)
        let isLocked = Bool((statusDict["isLocked"] as? NSNumber)?.boolValue ?? false)
        let temperature = Double((statusDict["temperature"] as? NSNumber)?.doubleValue ?? 0)
        let range = Double((statusDict["range"] as? NSNumber)?.doubleValue ?? 0)
        let chargingStatusString = (statusDict["chargingStatus"] as? String) ?? "not_charging"

        let chargingStatus: ChargingStatus = {
            switch chargingStatusString {
            case "charging":
                return .charging
            case "not_charging":
                return .notCharging
            case "fully_charged":
                return .fullyCharged
            default:
                return .notCharging
            }
        }()

        vehicleStatus = VehicleStatus(
            batteryLevel: batteryLevel,
            mileage: mileage,
            isLocked: isLocked,
            temperature: temperature,
            lastLocation: nil,
            range: range,
            chargingStatus: chargingStatus
        )
    }

    func toggleLock() async {
        guard let status = vehicleStatus else { return }

        VehicleService.shared().updateVehicleLock(!status.isLocked) { [weak self] success, error in
            if let successNum = success as? NSNumber, successNum.boolValue {
                DispatchQueue.main.async {
                    self?.vehicleStatus?.isLocked = !status.isLocked
                }
            }
        }
    }

    func getBatteryLevel() async {
        VehicleService.shared().getBatteryLevel { [weak self] level, error in
            if let levelNum = level as? NSNumber {
                DispatchQueue.main.async {
                    self?.vehicleStatus?.batteryLevel = levelNum.doubleValue
                }
            }
        }
    }

    func setAirConditioner(enabled: Bool, temperature: Double) async {
        isLoading = true
        error = nil

        VehicleService.shared().setAirConditioner(enabled, temperature: temperature) { [weak self] success, error in
            if let successNum = success as? NSNumber, successNum.boolValue {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.vehicleStatus?.temperature = temperature
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.error = error
                }
            }
        }
    }

    func setWindowPosition(position: Int32, openLevel: Double) async {
        isLoading = true
        error = nil

        VehicleService.shared().setWindowPosition(WindowPosition(rawValue: Int(position)) ?? .all, openLevel: openLevel) { [weak self] success, error in
            if let successNum = success as? NSNumber, successNum.boolValue {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.error = error
                }
            }
        }
    }

    func triggerHornAndFlash() async {
        isLoading = true
        error = nil

        VehicleService.shared().triggerHornAndFlash { [weak self] success, error in
            if let successNum = success as? NSNumber, successNum.boolValue {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.error = error
                }
            }
        }
    }
}
