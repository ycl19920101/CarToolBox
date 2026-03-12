//
//  VehicleDetailView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI

struct VehicleDetailView: View {
    @StateObject private var viewModel = VehicleViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    Text("错误: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .padding()
                } else if let status = viewModel.vehicleStatus {
                    ScrollView {
                        VStack(spacing: 20) {
                            BatteryView(
                                batteryLevel: status.batteryLevel,
                                isCharging: status.chargingStatus == .charging,
                                range: status.range
                            )
                            .padding()

                            VStack(alignment: .leading) {
                                HStack {
                                    Text("里程数")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(String(format: "%.1f", status.mileage)) km")
                                }
                                .padding()

                                HStack {
                                    Text("温度")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(String(format: "%.1f", status.temperature))°C")
                                }
                                .padding()

                                HStack {
                                    Text("状态")
                                        .font(.headline)
                                    Spacer()
                                    Text(status.isLocked ? "已锁车" : "已解锁")
                                        .foregroundColor(status.isLocked ? .green : .red)
                                }
                                .padding()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .padding()
                    }
                    .navigationTitle("车辆状态")
                    .refreshable {
                        await viewModel.fetchVehicleStatus()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchVehicleStatus()
                }
            }
        }
    }
}

#Preview {
    VehicleDetailView()
}