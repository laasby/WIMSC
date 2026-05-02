import Foundation
import CoreLocation
import Observation

/// Wraps CLLocationManager and exposes the current location and authorisation status.
@Observable
public final class LocationService: NSObject {
    /// Simplified authorisation status.
    public enum AuthStatus {
        case notDetermined, denied, authorised
    }
    
    public private(set) var authStatus: AuthStatus = .notDetermined
    public private(set) var currentLocation: CLLocation?
    
    private let manager: CLLocationManager
    
    public override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        updateAuthStatus(manager.authorizationStatus)
    }
    
    /// Requests whenInUse location authorisation. No-op if already determined.
    public func requestAuthorisation() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Starts delivering location updates.
    public func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    /// Stops location updates.
    public func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Private
    
    private func updateAuthStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined: authStatus = .notDetermined
        case .denied, .restricted: authStatus = .denied
        case .authorizedWhenInUse, .authorizedAlways: authStatus = .authorised
        @unknown default: authStatus = .notDetermined
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.updateAuthStatus(status) }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in self.currentLocation = location }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal: location updates are opportunistic
    }
}
