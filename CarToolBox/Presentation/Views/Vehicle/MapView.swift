//
//  MapView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var mapManager = MapManager()

    var body: some View {
        NavigationView {
            Map(coordinateRegion: $mapManager.region,
                showsUserLocation: mapManager.isTracking,
                annotationItems: mapManager.annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    VStack {
                        Image(systemName: "car.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text(annotation.title ?? "车辆")
                            .font(.caption)
                            .padding(4)
                            .background(Color.white)
                            .cornerRadius(5)
                            .shadow(radius: 2)
                    }
                }
            }
            .navigationTitle("车辆位置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        mapManager.centerOnCurrentLocation()
                    }) {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Button("显示轨迹") {
                            // TODO: 显示轨迹
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Spacer()

                        Button("导航") {
                            // TODO: 打开系统导航
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            )
        }
    }
}

#Preview {
    MapView()
}