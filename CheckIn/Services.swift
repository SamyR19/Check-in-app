import Foundation
import CoreLocation
import UIKit
import UserNotifications
import Observation

/// Real CoreLocation — used to attach coordinates to check-ins and SOS.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var authorization: CLAuthorizationStatus = .notDetermined
    var lastLocation: CLLocation?

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func refresh() {
        guard isAuthorized else { return }
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if isAuthorized {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Leave lastLocation as-is; check-ins degrade gracefully to "no location".
    }
}

/// Real device battery. Requires UIDevice battery monitoring (enabled at app launch).
enum Device {
    static func batteryPercent() -> Int {
        let level = UIDevice.current.batteryLevel
        // Simulator reports -1; show full rather than broken.
        return level < 0 ? 100 : Int(level * 100)
    }
}

enum Permissions {
    static func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
