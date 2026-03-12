//
//  BatteryView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI

struct BatteryView: View {
    let batteryLevel: Double
    let isCharging: Bool
    let range: Double

    var body: some View {
        VStack(spacing: 20) {
            // 电池图标
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 60)

                RoundedRectangle(cornerRadius: 20)
                    .fill(batteryColor)
                    .frame(width: CGFloat((batteryLevel / 100) * 110), height: 50)
                    .offset(x: -5)
            }

            Text("\(Int(batteryLevel))%")
                .font(.title2)
                .fontWeight(.bold)

            Text("剩余里程: \(Int(range))km")
                .font(.caption)

            HStack {
                Image(systemName: isCharging ? "bolt.fill" : "bolt.slash.fill")
                Text(isCharging ? "充电中" : "未充电")
            }
            .foregroundColor(isCharging ? .green : .gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }

    private var batteryColor: Color {
        switch batteryLevel {
        case 0...20:
            return .red
        case 21...50:
            return .orange
        default:
            return .green
        }
    }
}

#Preview {
    BatteryView(batteryLevel: 75, isCharging: false, range: 320)
}