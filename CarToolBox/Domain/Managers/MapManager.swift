//
//  MapManager.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import MapKit
import Combine

@MainActor
class MapManager: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var annotations = [MKAnnotationItem]()
    @Published var isTracking = false

    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateRegion(for: location)
            }
            .store(in: &cancellables)

        // 添加默认车辆位置
        addAnnotation(coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737), title: "我的车辆")
    }

    func updateRegion(for location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    func addAnnotation(coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MKAnnotationItem(
            coordinate: coordinate,
            title: title
        )
        annotations.append(annotation)
    }

    func centerOnCurrentLocation() {
        if let location = locationManager.currentLocation {
            updateRegion(for: location)
            isTracking = true
        }
    }
}

class MKAnnotationItem: NSObject, MKAnnotation, Identifiable {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let id = UUID()

    init(coordinate: CLLocationCoordinate2D, title: String?) {
        self.coordinate = coordinate
        self.title = title
        super.init()
    }
}