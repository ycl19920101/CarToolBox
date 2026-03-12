//
//  ControlView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI

struct ControlView: View {
    let isLocked: Bool
    let onToggleLock: () -> Void
    let onACControl: () -> Void
    let onWindowControl: () -> Void
    let onHornAndFlash: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Lock control
            Button(action: onToggleLock) {
                HStack {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    Text(isLocked ? "解锁" : "锁车")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLocked ? .red : .green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // Remote control button group
            VStack(spacing: 15) {
                Button(action: onACControl) {
                    HStack {
                        Image(systemName: "snowflake")
                        Text("空调控制")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button(action: onWindowControl) {
                    HStack {
                        Image(systemName: "car")
                        Text("车窗控制")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button(action: onHornAndFlash) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("鸣笛闪灯")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

#Preview {
    ControlView(
        isLocked: true,
        onToggleLock: { },
        onACControl: { },
        onWindowControl: { },
        onHornAndFlash: { }
    )
}
